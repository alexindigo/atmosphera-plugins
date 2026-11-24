#!/usr/bin/env python3
"""Run the map consumer fixture inside each isolated shell config root."""
import argparse
import json
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("shell", "legacy-shell", "plugins", "output"):
        parser.add_argument(f"--{name}", required=True, type=Path)
    args = parser.parse_args()
    plugin = args.plugins.resolve() / "niri-windows-map"
    fixture = Path(__file__).with_name("niri-map-contract.qml.in")
    failed = False
    for lane, shell, legacy, reject in (("current", args.shell, False, False),
                                        ("legacy", args.legacy_shell, True, False),
                                        ("legacy-rejected", args.legacy_shell, True, True)):
        evidence = args.output.resolve() / lane
        evidence.mkdir(parents=True, exist_ok=False)
        bin_path = evidence / "bin"
        bin_path.mkdir()
        cli_log = evidence / "moves.log"
        cli = bin_path / "niri"
        cli.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$MAP_MOVES"\n'
                       'if [ "$3" = move-window-to-workspace ]; then exit "$MAP_REJECT"; fi\n')
        cli.chmod(0o755)
        env = dict(os.environ, MAP_LEGACY=str(int(legacy)), MAP_REJECT=str(int(reject)),
                   MAP_MOVES=str(cli_log), PATH=f"{bin_path}:{os.environ['PATH']}", QT_QPA_PLATFORM="wayland")
        env.pop("NIRI_SOCKET", None)
        for profile in ("CONFIG", "CACHE", "STATE", "DATA"):
            directory = evidence / profile.lower()
            directory.mkdir()
            env[f"XDG_{profile}_HOME"] = str(directory)
        with tempfile.TemporaryDirectory(prefix="MapContract_", dir=shell.resolve()) as tmp:
            # The entry point must be at the shell root for qs.* imports.
            entry = shell.resolve() / (Path(tmp).name + ".qml")
            try:
                shutil.copytree(plugin, Path(tmp) / "map")
                with entry.open("x") as stream:
                    stream.write(fixture.read_text().replace('"MapFixture"', f'"{Path(tmp).name}/map"'))
                with (evidence / "shell.log").open("w") as log:
                    process = subprocess.run(["qs", "-p", str(entry), "--no-color"], env=env,
                                             stdout=log, stderr=subprocess.STDOUT, timeout=25, check=False)
            finally:
                entry.unlink(missing_ok=True)
        text = (evidence / "shell.log").read_text()
        marker = re.search(r"MAP_CONTRACT\|(.*)", text)
        checks = json.loads(marker[1]) if marker else []
        actual = cli_log.read_text().splitlines() if cli_log.exists() else []
        expected = []
        if legacy:
            expected = ["msg action move-window-to-workspace 3 --window-id 9007199254740991 --focus false"]
            if not reject:
                expected.append("msg action move-workspace-to-index 1 --reference 3")
        checks.append({"name": "legacy reorder depends on checked move exit", "pass": actual == expected,
                       "actual": actual, "expected": expected})
        errors = re.findall(r"^.*(?:ERROR|ReferenceError|TypeError|Binding loop).*$", text, flags=re.M)
        passed = bool(marker) and process.returncode == 0 and not errors and all(c["pass"] for c in checks)
        (evidence / "result.json").write_text(json.dumps({"passed": passed, "checks": checks, "errors": errors}, indent=2) + "\n")
        print(f"{lane}: {sum(c['pass'] for c in checks)}/{len(checks)}; {'PASS' if passed else 'FAIL'}")
        if not passed:
            failed = True
            print("\n".join(errors[:4] + [c["name"] for c in checks if not c["pass"]]))
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
