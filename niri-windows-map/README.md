# Niri Windows Map

Restores the focused-window accent, keeps resize textures stable, and sizes
Compact/Regular/Large by workspace-row height. Large maps scroll after reaching
the minimum row size; focus changes reveal their tile. Drops are accepted only
inside visible rows or the insert-above strip.

## Shell compatibility

The minimum Atmosphera version is 0.10.0. The map supports the older shell's
numeric IDs and the current shell's exact string IDs. On the current shell,
niri IPC requires niriqml 0.3.0 or newer and drops target stable workspace IDs.
On older shells, drops use the workspace's current position. Older map releases
do not support the current shell's string IDs; update the map before the shell.

Ctrl+wheel's existing handler is unchanged; its real-input behavior remains
unverified. No native-host frame-pacing claim is made.

## Geometry regression

Inside the assigned VM, with `TMPDIR` set to its disk-backed workspace. The
output directory must not already exist:

```bash
python3 -B .github/scripts/test-niri-map-geometry.py --output "$TMPDIR/niri-map-geometry-run"
```
