#!/usr/bin/env python3
"""Validate registry.json against the plugin manifests it indexes.

Asserts (per docs: registry contract in README.md):
  1. Every registry entry has a matching <id>/manifest.json, and vice versa.
  2. minNoctaliaVersion / minAtmospheraVersion match the manifest's values
     (present in both, or absent from both).
  3. Every present version value matches ^\\d+\\.\\d+\\.\\d+$ (no v prefix,
     no pre-release suffix).
  4. Every minNoctaliaVersion major is <= 4 (the v4 banner).
  5. entry.version equals manifest.version (catches stale plugin dirs).

Exit 0 on success, 1 with a per-problem report otherwise.
"""

import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")


def main():
    problems = []
    reg_path = os.path.join(REPO, "registry.json")
    with open(reg_path) as fh:
        registry = json.load(fh)["plugins"]

    ids_in_registry = {e["id"] for e in registry}
    ids_on_disk = {
        d for d in os.listdir(REPO)
        if os.path.isdir(os.path.join(REPO, d)) and os.path.exists(os.path.join(REPO, d, "manifest.json"))
    }

    for pid in sorted(ids_in_registry - ids_on_disk):
        problems.append(f"{pid}: in registry but no manifest.json on disk")
    for pid in sorted(ids_on_disk - ids_in_registry):
        problems.append(f"{pid}: manifest.json on disk but missing from registry")

    for entry in registry:
        pid = entry["id"]
        manifest_path = os.path.join(REPO, pid, "manifest.json")
        if not os.path.exists(manifest_path):
            continue
        with open(manifest_path) as fh:
            manifest = json.load(fh)

        for key in ("minNoctaliaVersion", "minAtmospheraVersion"):
            m_val = manifest.get(key)
            e_val = entry.get(key)
            if m_val != e_val:
                problems.append(f"{pid}: {key} mismatch — manifest {m_val!r} vs registry {e_val!r}")
            val = e_val if e_val is not None else m_val
            if val is not None and not VERSION_RE.match(str(val)):
                problems.append(f"{pid}: {key} malformed — {val!r} (must be x.y.z)")

        mnv = entry.get("minNoctaliaVersion")
        if mnv is not None:
            try:
                major = int(str(mnv).split(".")[0])
                if major > 4:
                    problems.append(f"{pid}: minNoctaliaVersion major {major} > 4 (v4 banner)")
            except ValueError:
                problems.append(f"{pid}: minNoctaliaVersion major not numeric — {mnv!r}")

        if entry.get("version") != manifest.get("version"):
            problems.append(f"{pid}: version mismatch — manifest {manifest.get('version')!r} vs registry {entry.get('version')!r}")

    count = len(registry)
    if problems:
        print(f"{count} entries checked, {len(problems)} problem(s):")
        for p in problems:
            print(f"  - {p}")
        return 1
    print(f"{count} entries checked, 0 problems")
    return 0


if __name__ == "__main__":
    sys.exit(main())
