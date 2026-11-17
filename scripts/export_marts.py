"""Write every mart, reporting table and snapshot to data/marts/*.parquet with a manifest.

The exported files are what downstream repositories copy into their data/input directories; CI rebuilds
them and fails if they differ from the committed copies. Floats are rounded to six decimals so that a
rebuild on another machine produces byte-identical tables.
"""
from __future__ import annotations

import json
from pathlib import Path

import duckdb
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "data" / "warehouse.duckdb"
OUT = ROOT / "data" / "marts"
SCHEMAS = ("marts", "snapshots")


def export() -> dict:
    OUT.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(DB), read_only=True)
    tables = con.sql(
        "select table_schema, table_name from information_schema.tables "
        "where table_schema in ('marts', 'snapshots') and table_type = 'BASE TABLE' order by 1, 2"
    ).fetchall()
    manifest: dict[str, dict] = {}
    for schema, name in tables:
        df = con.sql(f'select * from "{schema}"."{name}"').df()
        for col in df.columns:
            if pd.api.types.is_float_dtype(df[col]):
                df[col] = df[col].round(6)
        # a deterministic row order makes the Parquet files reproducible
        df = df.sort_values(list(df.columns), kind="mergesort", na_position="last").reset_index(drop=True)
        df.to_parquet(OUT / f"{name}.parquet", index=False)
        manifest[name] = {"schema": schema, "rows": len(df), "columns": list(df.columns)}
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def check() -> None:
    """Export to a temporary directory and compare with the committed tables by content (Parquet bytes can
    differ between writer versions, the data must not)."""
    import sys
    import tempfile

    global OUT
    committed = OUT
    with tempfile.TemporaryDirectory() as tmp:
        OUT = Path(tmp)
        fresh = export()
        OUT = committed
        manifest = json.loads((committed / "manifest.json").read_text())
        problems = []
        if fresh != manifest:
            problems.append("manifest.json differs")
        for name in manifest:
            a = pd.read_parquet(committed / f"{name}.parquet")
            b = pd.read_parquet(Path(tmp) / f"{name}.parquet")
            if not a.equals(b):
                problems.append(f"{name}.parquet differs")
        if problems:
            print("\n".join(problems))
            sys.exit(1)
        print(f"{len(manifest)} exported tables match the warehouse")


if __name__ == "__main__":
    import sys

    if "--check" in sys.argv:
        check()
    else:
        for name, meta in export().items():
            print(f"{meta['schema']}.{name}: {meta['rows']:,} rows, {len(meta['columns'])} columns")
