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
      results.push({name: name, actual: actual, expected: expected, passed: JSON.stringify(actual) === JSON.stringify(expected)});
    }
    const view=Qt.rect(0,40,200,100), phantom=Qt.rect(0,0,200,40), origin=Qt.point(0,40);
    const rows=[{id:"0",y:0,height:32},{id:"9007199254740992",y:34,height:32},{id:"9007199254740993",y:68,height:48,trailing:true},{id:"14",y:118,height:32}];
    function target(x,y) {return Geometry.targetAt(Qt.point(x,y),view,phantom,origin,1,rows,200);}
    check("above phantom is not a target",target(50,-1),null);
    check("phantom width is bounded",target(-1,20),null);
    check("phantom is visible target",target(50,20),{kind:"insert"});
    check("visible ordinary row with ID zero",target(50,50),{kind:"row",id:"0"});
    check("row gap is not painted target",target(50,73),null);
    check("trailing row uses its actual height",Geometry.targetAt(Qt.point(50,147),Qt.rect(0,40,200,120),phantom,origin,1,rows.slice(0,3),200),{kind:"trailing"});
    check("hidden ordinary row is not target",target(50,160),null);
    check("outside viewport width is not target",target(201,60),null);
    check("scrolled map uses shared root transform",Geometry.targetAt(Qt.point(50,50),view,phantom,Qt.point(0,6),1,rows,200),{kind:"row",id:"9007199254740992"});
    check("oversized tile preserves an interior offset",Geometry.revealOffset(12,600,300,100,1000),100);
    check("oversized tile left anchor is stable",Geometry.revealOffset(12,600,300,12,1000),12);
    check("oversized tile right anchor is stable",Geometry.revealOffset(12,600,300,312,1000),312);
    check("fitting tile reveals nearest right edge",Geometry.revealOffset(400,100,300,0,1000),200);
    check("fitting tile reveals nearest left edge",Geometry.revealOffset(20,100,300,200,1000),20);
    const dragRows=[{id:"0",y:0,height:50},{id:"1",y:52,height:52},{y:106,height:44,trailing:true}];
    const bounds=Qt.rect(0,0,240,50);
    function hold(point, offset, ticks) {
      // A build without edge scrolling leaves the current offset unchanged.
      if (typeof Geometry.dragScroll === "function") {
        for (let i=0; i<ticks; i++)
          offset=Geometry.dragScroll(point,view,bounds,offset,16);
      }
      return offset;
    }
    function dropAt(point, offset) {
      return Geometry.targetAt(point,view,phantom,Qt.point(-offset.x,40-offset.y),1,dragRows,440);
    }
    const bottom=Qt.point(50,139), below=Qt.point(50,160), insert=Qt.point(50,20);
    const start=Qt.point(0,0), floor=Qt.point(0,50);
    check("stationary bottom pointer starts over an ordinary row",dropAt(bottom,start),{kind:"row",id:"1"});
    check("stationary pointer re-hits trailing strip at vertical floor",dropAt(bottom,hold(bottom,start,30)),{kind:"trailing"});
    check("bottom overshoot scrolls all the way but accepts drops only after reentry",
          [dropAt(below,hold(below,start,30)),dropAt(bottom,hold(below,start,30))],[null,{kind:"trailing"}]);
    check("phantom holds the current vertical offset",hold(insert,floor,30),floor);
    check("phantom still inserts at full scroll",dropAt(insert,hold(insert,floor,30)),{kind:"insert"});
    check("top edge of real viewport reaches the start",hold(Qt.point(50,40),floor,30),start);
    check("right overshoot reaches horizontal floor",hold(Qt.point(220,90),start,30),Qt.point(240,0));
    check("left overshoot reaches horizontal start",hold(Qt.point(-20,90),Qt.point(240,0),30),start);
    check("edge speed ramps in 32px and caps at 1200px/s",[hold(Qt.point(50,124),start,1).y,hold(below,start,1).y],[9.6,19.2]);
    check("viewport center does not scroll",hold(Qt.point(100,90),Qt.point(80,20),30),Qt.point(80,20));
    const zoom=1.5, zoomed=Qt.point(50,139);
    check("scaled stationary pointer resolves the trailing strip using the new offset",
          Geometry.targetAt(zoomed,view,phantom,Qt.point(0,40-hold(zoomed,start,30).y),zoom,
                            [{id:"1",y:0,height:82},{y:84,height:30,trailing:true}],440),{kind:"trailing"});
    check("bottom stop fits whole rows and a compact strip",Geometry.trailingLandingSpace(304,56,4,7,30),30);
    check("already aligned bottom stop adds no space",Geometry.trailingLandingSpace(274,56,4,7,30),0);
    check("fitting content adds no space",Geometry.trailingLandingSpace(304,56,4,4,30),0);
    check("a viewport shorter than one slot and the strip adds no space",Geometry.trailingLandingSpace(84,56,4,7,30),0);
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
    passed = process.returncode == 0 and len(cases) == 29 and all(row['passed'] for row in cases)
    (args.output / 'result.json').write_text(json.dumps(dict(passed=passed, exit_code=process.returncode, cases=cases), indent=2) + '\n')
    for row in cases:
        print(row['name'], 'PASS' if row['passed'] else 'FAIL')
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
