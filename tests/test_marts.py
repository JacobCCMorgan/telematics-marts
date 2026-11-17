"""Checks on the exported marts.

Three groups: the exported tables agree with the warehouse they were exported from; the marts reproduce the
numbers the downstream projects and the foundation have published (parity, so switching a project to the
marts cannot change its results); and no raw identifier reaches the public tables.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

import duckdb
import pandas as pd
import pytest

ROOT = Path(__file__).resolve().parents[1]
MARTS = ROOT / "data" / "marts"
INPUT = ROOT / "data" / "input"
DB = ROOT / "data" / "warehouse.duckdb"

MANIFEST = json.loads((MARTS / "manifest.json").read_text())
SUMMARY = json.loads((ROOT / "reports" / "summary.json").read_text())


def mart(name: str) -> pd.DataFrame:
    return pd.read_parquet(MARTS / f"{name}.parquet")


# ---------------------------------------------------------------- exported tables vs warehouse

@pytest.mark.skipif(not DB.exists(), reason="warehouse not built; run scripts/build.sh first")
@pytest.mark.parametrize("name", sorted(MANIFEST))
def test_export_matches_warehouse(name: str) -> None:
    con = duckdb.connect(str(DB), read_only=True)
    schema = MANIFEST[name]["schema"]
    rows = con.sql(f'select count(*) from "{schema}"."{name}"').fetchall()[0][0]
    assert rows == MANIFEST[name]["rows"] == len(mart(name))
    assert list(mart(name).columns) == MANIFEST[name]["columns"]


def test_summary_counts_match_manifest() -> None:
    assert SUMMARY["tables"] == {k: v["rows"] for k, v in MANIFEST.items()}


# ---------------------------------------------------------------- parity with the downstream projects

# eld-ecm-disconnect, reports/summary.json (population and classes)
ECM = {"flagged_customer": 182, "internal_test": 33, "internal_test_chronic": 15, "day4_observed": 143, "day4_severe": 26,
       "silent_reports_3day": 75897, "chronic": 14, "intermittent": 128, "transient": 40, "chronic_day4_observed": 13,
       "chronic_day4_severe": 9, "tiers": {"P1": 27, "P2": 18, "P3": 19, "P4": 118}}


def test_anomaly_window_reproduces_the_ecm_disconnect_project() -> None:
    w = mart("fct_device_anomaly_window")
    cust = w[~w["is_internal_test"]]
    assert len(cust) == ECM["flagged_customer"]
    assert int(w["is_internal_test"].sum()) == ECM["internal_test"]
    assert int((w["is_internal_test"] & (w["severity_class"] == "chronic")).sum()) == ECM["internal_test_chronic"]
    assert int(cust["moving_silent_reports_3day"].sum()) == ECM["silent_reports_3day"]
    assert int(cust["observed_day4"].sum()) == ECM["day4_observed"]
    assert int(cust["is_severe_day4"].sum()) == ECM["day4_severe"]
    classes = cust["severity_class"].value_counts()
    assert classes.to_dict() == {"intermittent": ECM["intermittent"], "transient": ECM["transient"], "chronic": ECM["chronic"]}
    chronic = cust[cust["severity_class"] == "chronic"]
    assert int(chronic["observed_day4"].sum()) == ECM["chronic_day4_observed"]
    assert int(chronic["is_severe_day4"].sum()) == ECM["chronic_day4_severe"]
    assert cust["priority_tier"].value_counts().to_dict() == ECM["tiers"]


def test_device_day_reproduces_the_project_denominators() -> None:
    d = mart("fct_device_day")
    three = d[d["source_table"] == "three_day_summary"]
    assert three["report_date"].nunique() == 3 and (three["moving_reports"] > 0).all()
    day4 = d[d["source_table"] == "anomaly_reports"]
    assert day4["report_date"].nunique() == 1 and day4["moving_reports"].isna().all()
    assert day4["device_key"].nunique() == 1845  # devices flagged on 28 Sep 2026 in the foundation
    # the three-day totals per device equal the rules engine's own totals
    inp = pd.read_parquet(INPUT / "fact_anomaly_device_3day.parquet").set_index("device_key")
    s = three.groupby("device_key")["moving_silent_reports"].sum()
    assert (s.reindex(inp.index).fillna(0).astype(int) == inp["rpm_na_n"].fillna(0).astype(int)).all()


# eld-subscription-lifecycle, reports/summary.json and README
LIFECYCLE = {"customer_rows": 13753, "orgs_active_2024": 2968, "purged_from_2026_table": 183, "snapshot_2024_rows": 4977}


def test_contract_terms_reproduce_the_lifecycle_project() -> None:
    t = mart("fct_contract_term")
    assert len(t) == LIFECYCLE["customer_rows"]
    assert t["contract_row_id"].is_unique
    # the renewal count is only defined when both dates exist and the term does not start before the contract
    gap = (pd.to_datetime(t["term_start_date"]) - pd.to_datetime(t["contract_date"])).dt.days
    assert t.loc[gap.isna(), "renewals_so_far"].isna().all()
    assert (t.loc[gap >= 0, "renewals_so_far"] == (gap[gap >= 0] / 365).round()).all()
    purged = mart("rpt_organizations_purged_after_2024").iloc[0]
    assert int(purged["organizations_active_2024"]) == LIFECYCLE["orgs_active_2024"]
    assert int(purged["organizations_purged"]) == LIFECYCLE["purged_from_2026_table"]


def test_snapshot_history_is_complete_and_dated_by_export() -> None:
    s = mart("snap_subscription_slot")
    v2024 = s[s["dbt_valid_from"] == pd.Timestamp("2024-01-05")]
    assert len(v2024) == 4959  # customer slots in the 2024 export (4,977 rows minus internal test and duplicates)
    assert (v2024["dbt_valid_to"] == pd.Timestamp("2026-09-28")).all()
    assert set(s["dbt_valid_from"].dt.date.astype(str)) == {"2024-01-05", "2026-09-28"}
    deleted = s[s["dbt_is_deleted"] == "True"]
    assert len(deleted) == 821 and (deleted["dbt_valid_from"] == pd.Timestamp("2026-09-28")).all()
    changes = mart("rpt_subscription_slot_changes")
    assert int(changes["slots"].sum()) == len(v2024)
    assert int(changes.set_index("outcome").loc["purged_from_crm", "slots"]) == len(deleted)


# telematics-data-foundation README (snapshot 2026-09-28)
FOUNDATION = {"reporting_customer_devices": 3456, "online_rate": 0.614, "backup_battery_at_most_20pct": 85,
              "never_read_vin_share": 0.40, "terms_exactly_365_share": 0.74, "never_reported_share": 0.295}


def test_fleet_snapshot_reproduces_the_foundation_readme() -> None:
    f = mart("rpt_fleet_snapshot").set_index("metric")
    assert int(f.loc["reporting_units", "value"]) == FOUNDATION["reporting_customer_devices"]
    assert round(float(f.loc["online_units", "share"]), 3) == FOUNDATION["online_rate"]
    assert int(f.loc["backup_battery_at_most_20pct_units", "value"]) == FOUNDATION["backup_battery_at_most_20pct"]
    assert round(float(f.loc["never_read_vin_units", "share"]), 2) == FOUNDATION["never_read_vin_share"]
    assert round(float(f.loc["contract_terms_exactly_365_days", "share"]), 2) == FOUNDATION["terms_exactly_365_share"]
    assert round(float(f.loc["never_reported_units", "share"]), 3) == FOUNDATION["never_reported_share"]
    g = mart("rpt_online_rate_by_generation").set_index("hw_generation")["online_rate"]
    assert g.round(2).to_dict() == {"A": 0.46, "B": 0.63, "C": 0.65}


# ---------------------------------------------------------------- dimensions are dimensions

def test_dimensions_are_unique_and_keys_resolve() -> None:
    dev, veh, org, acc = mart("dim_device"), mart("dim_vehicle"), mart("dim_organization"), mart("dim_driver_account")
    for df, key in [(dev, "device_key"), (veh, "vin_key"), (org, "org_key"), (acc, "account_key")]:
        assert df[key].is_unique and df[key].notna().all()
    assert dev["org_key"].dropna().isin(org["org_key"]).all()
    assert veh["org_key"].dropna().isin(org["org_key"]).all()
    assert mart("fct_contract_term")["org_key"].isin(org["org_key"]).all()
    assert mart("fct_device_day")["device_key"].isin(dev["device_key"]).all()


# ---------------------------------------------------------------- de-identification

PATTERNS = {
    "vin": re.compile(r"^[A-HJ-NPR-Z0-9]{17}$"),
    "imei": re.compile(r"^\d{15}$"),
    "iccid": re.compile(r"^\d{19,20}$"),
    "email": re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+"),
    "phone": re.compile(r"\(\d{3}\)\s?\d{3}-\d{4}|\b\d{3}-\d{3}-\d{4}\b"),
}
PSEUDONYM = re.compile(r"^(DEV|VIN|ORG|DOT|DRV|USR|REP|STF)-[0-9a-f]{10}$")


@pytest.mark.parametrize("path", sorted(list(MARTS.glob("*.parquet")) + list(INPUT.glob("*.parquet"))))
def test_no_identifier_leakage(path: Path) -> None:
    df = pd.read_parquet(path)
    for col in df.columns:
        if not (pd.api.types.is_string_dtype(df[col]) or df[col].dtype == object):
            continue
        values = df[col].dropna().astype(str).unique()
        for v in values:
            if PSEUDONYM.match(v):
                continue
            for name, rx in PATTERNS.items():
                assert not rx.search(v), f"{path.name}.{col}: {name}-like value {v!r}"
