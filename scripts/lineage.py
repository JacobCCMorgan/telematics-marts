"""Write docs/lineage.mmd, a Mermaid graph of the project's lineage from dbt's manifest (sources, models
by layer, the snapshot and the exposures). Render it with the Mermaid CLI:

    mmdc -i docs/lineage.mmd -o docs/lineage.svg

dbt docs (`dbt docs generate && dbt docs serve`) give the interactive version with column-level details.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "target" / "manifest.json"
OUT = ROOT / "docs" / "lineage.mmd"

LAYERS = [("sources", "Sources (Parquet in data/input)"), ("staging", "Staging views"), ("intermediate", "Intermediate views"),
          ("marts", "Marts (tables)"), ("snapshots", "Snapshot"), ("exposures", "Downstream projects")]


def layer_of(node: dict) -> str:
    if node["resource_type"] == "source":
        return "sources"
    if node["resource_type"] == "snapshot":
        return "snapshots"
    if node["resource_type"] == "exposure":
        return "exposures"
    path = node.get("path", "")
    for key in ("staging", "intermediate", "marts"):
        if path.startswith(key):
            return key
    return "marts"


def main() -> None:
    m = json.loads(MANIFEST.read_text())
    nodes: dict[str, dict] = {}
    for uid, n in m["nodes"].items():
        if n["resource_type"] in ("model", "snapshot"):
            nodes[uid] = n
    for uid, n in m["sources"].items():
        nodes[uid] = {**n, "resource_type": "source", "name": n["name"]}
    for uid, n in m["exposures"].items():
        nodes[uid] = {**n, "resource_type": "exposure", "name": n["label"]}

    # dbt lists nodes in the order it read the files, which follows the order the filesystem returns
    # directory entries in and is not the same on every machine. Order by layer and name instead, so the
    # graph is identical wherever it is built.
    layer_rank = {key: i for i, (key, _) in enumerate(LAYERS)}
    nodes = dict(sorted(nodes.items(), key=lambda kv: (layer_rank[layer_of(kv[1])], kv[1]["name"], kv[0])))
    ident = {uid: f"n{i}" for i, uid in enumerate(nodes)}
    lines = ["flowchart TB"]
    for key, title in LAYERS:
        members = [uid for uid, n in nodes.items() if layer_of(n) == key]
        if not members:
            continue
        lines.append(f'  subgraph {key}["{title}"]')
        for uid in members:
            lines.append(f'    {ident[uid]}["{nodes[uid]["name"]}"]')
        lines.append("  end")
    order = {uid: i for i, uid in enumerate(nodes)}
    edges = {(order[dep], order[uid]) for uid, n in nodes.items()
             for dep in n.get("depends_on", {}).get("nodes", []) if dep in order}
    for src, dst in sorted(edges, key=lambda e: (e[1], e[0])):
        lines.append(f"  n{src} --> n{dst}")
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text("\n".join(lines) + "\n")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(nodes)} nodes")


if __name__ == "__main__":
    main()
