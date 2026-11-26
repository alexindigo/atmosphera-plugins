# Niri Windows Map

Restores the focused-window accent, keeps resize textures stable, and sizes
Compact/Regular/Large by workspace-row height. Large maps scroll after reaching
the minimum row size; focus changes reveal their tile. Drops are accepted only
inside visible rows or the insert-above strip.

Hold a tiled window and drag it within its workspace row to reorder it. A
vertical line inserts a column; a horizontal line inserts the window into a
stack. The moved window ends focused. Dropping in its original position does
nothing. Drag to another row, the trailing strip, or the insert-above strip to
move the window to another workspace.

## Shell compatibility

The plugin registry offers this version on Atmosphera 0.11.1 or newer.
Atmosphera 0.11.0 supports exact string workspace IDs with niriqml 0.3.0 and
map 1.0.18, but does not support within-row moves.

Ctrl+wheel's existing handler is unchanged; its real-input behavior remains
unverified. No native-host frame-pacing claim is made.

## Geometry regression

Inside the assigned VM, with `TMPDIR` set to its disk-backed workspace. The
output directory must not already exist:

```bash
python3 -B .github/scripts/test-niri-map-geometry.py --output "$TMPDIR/niri-map-geometry-run"
```
