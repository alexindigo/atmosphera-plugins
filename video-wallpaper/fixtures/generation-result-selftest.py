#!/usr/bin/env python3
"""A real later-case postcondition failure must replace an earlier PASS receipt."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
for name in ('source', 'plugins', 'guest-profile', 'output'):
    parser.add_argument('--' + name, type=Path, required=True)
args = parser.parse_args()
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=False)
original = Path(__file__).with_name('generation-regression.py').read_text()
case_start = original.index('CASES = ')
case_end = original.index('\n', case_start)
mutated = original[:case_start] + "CASES = ('failure', 'retry')" + original[case_end:]
anchor = "                if passed and case == 'baseline-retry':"
assert mutated.count(anchor) == 1
mutated = mutated.replace(anchor, "                if passed and case == 'retry':\n                    raise AssertionError('injected later postcondition failure')\n" + anchor)
runner = output / 'generation-regression.py'
runner.write_text(mutated)
shutil.copy2(Path(__file__).with_suffix('.qml').with_name('generation-regression.qml'), output / 'generation-regression.qml')
command = [sys.executable, '-B', str(runner)]
for name in ('source', 'plugins', 'guest-profile'):
    command += ['--' + name, str(getattr(args, name.replace('-', '_')).resolve())]
command += ['--output', str(output / 'run')]
result = subprocess.run(command, capture_output=True, text=True, timeout=150)
(output / 'injected.log').write_text(result.stdout + result.stderr)
assert result.returncode != 0 and 'injected later postcondition failure' in result.stderr
receipt = json.loads((output / 'run/result.json').read_text())
assert receipt['status'] == 'FAIL', receipt
assert [(row['case'], row['status']) for row in receipt['cases']] == [('failure', 'PASS'), ('retry', 'FAIL')], receipt
print('generation failure receipt: PASS')
