#!/usr/bin/env python3
"""Run the map's pure geometry contract in Qt inside the assigned test VM."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess

QML = '''import QtQuick
import Quickshell
import "MapGeometry.js" as Geometry
ShellRoot {
  Component.onCompleted: {
    const results=[];
    function check(name, actual, expected) {
      results.push({name: name, actual: actual, expected: expected, passed: actual === expected});
    }
    const view=Qt.rect(0,40,200,100), phantom=Qt.rect(0,0,200,40), origin=Qt.point(0,40);
    const rows=[{id:11,y:0,height:32},{id:12,y:34,height:32},{id:13,y:68,height:48},{id:14,y:118,height:32}];
    function target(x,y) {return Geometry.targetAt(Qt.point(x,y),view,phantom,origin,1,rows,200);}
    check("above phantom is not a target",target(50,-1),0);
    check("phantom width is bounded",target(-1,20),0);
    check("phantom is visible target",target(50,20),-1);
    check("visible ordinary row",target(50,50),11);
    check("row gap is not painted target",target(50,73),0);
    check("trailing row uses its actual height",Geometry.targetAt(Qt.point(50,147),Qt.rect(0,40,200,120),phantom,origin,1,rows.slice(0,3),200),13);
    check("hidden ordinary row is not target",target(50,160),0);
    check("outside viewport width is not target",target(201,60),0);
    check("scrolled map uses shared root transform",Geometry.targetAt(Qt.point(50,50),view,phantom,Qt.point(0,6),1,rows,200),12);
    check("oversized tile preserves an interior offset",Geometry.revealOffset(12,600,300,100,1000),100);
    check("oversized tile left anchor is stable",Geometry.revealOffset(12,600,300,12,1000),12);
    check("oversized tile right anchor is stable",Geometry.revealOffset(12,600,300,312,1000),312);
    check("fitting tile reveals nearest right edge",Geometry.revealOffset(400,100,300,0,1000),200);
    check("fitting tile reveals nearest left edge",Geometry.revealOffset(20,100,300,200,1000),20);
    console.log("MAP_GEOMETRY|"+JSON.stringify(results));Qt.callLater(function () { Qt.quit(); });
  }
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if not os.environ.get('TMPDIR'):
        parser.error('set TMPDIR to the guest disk-backed workspace')
    args.output.mkdir()
    source = Path(__file__).resolve().parents[2] / 'niri-windows-map/MapGeometry.js'
    shutil.copy2(source, args.output / source.name)
    (args.output / 'shell.qml').write_text(QML)
    with (args.output / 'shell.log').open('x') as log:
        process = subprocess.run(['timeout', '--kill-after=3', '20', 'qs', '-p', str(args.output), '--no-color'],
                                 stdout=log, stderr=subprocess.STDOUT, timeout=25)
    lines = [line.split('MAP_GEOMETRY|', 1)[1] for line in (args.output / 'shell.log').read_text().splitlines() if 'MAP_GEOMETRY|' in line]
    cases = json.loads(lines[-1]) if lines else []
    passed = process.returncode == 0 and len(cases) == 14 and all(row['passed'] for row in cases)
    (args.output / 'result.json').write_text(json.dumps(dict(passed=passed, exit_code=process.returncode, cases=cases), indent=2) + '\n')
    for row in cases:
        print(row['name'], 'PASS' if row['passed'] else 'FAIL')
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
