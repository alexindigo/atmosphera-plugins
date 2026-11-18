# Niri Windows Map 1.0.5

Restores the focused-window accent, keeps resize textures stable, and sizes
Compact/Regular/Large by workspace-row height. Large maps scroll after reaching
the minimum row size; focus changes reveal their tile. Drops are accepted only
inside visible rows or the insert-above strip.

## Shell compatibility

The plugin API floor remains Atmosphera 0.9.0. Reliable startup focus, layout and
drag state also require the stale-seed fix in
[Atmosphera PR #29](https://github.com/alexindigo/atmosphera/pull/29), commit
`0e590f15a`. Older shell builds can overwrite newer niri events with old startup
replies and overlap window tiles. The companion shell change fixes that race;
it must also reach the 0.10.0 integration stack when the release merges main.

Ctrl+wheel's existing handler is unchanged; its real-input behavior remains
unverified. No native-host frame-pacing claim is made.

## Geometry regression

Inside the assigned VM, with `TMPDIR` set to its disk-backed workspace:

```bash
python3 -B .github/scripts/test-niri-map-geometry.py --output <new-output-directory>
```
