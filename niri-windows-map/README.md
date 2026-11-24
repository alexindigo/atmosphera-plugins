# Niri Windows Map

Restores the focused-window accent, keeps resize textures stable, and sizes
Compact/Regular/Large by workspace-row height. Large maps scroll after reaching
the minimum row size; focus changes reveal their tile. Drops are accepted only
inside visible rows or the insert-above strip.

## Shell compatibility

The plugin registry offers this version on Atmosphera 0.11.0 or newer. The map
retains its numeric-ID fallback for older shells, where drops use the workspace's
current position. With the current shell and niriqml 0.3.0 or newer, drops target
exact string workspace IDs. When upgrading to Atmosphera 0.11.0, also update the
map: older map releases do not support the new IDs.

Ctrl+wheel's existing handler is unchanged; its real-input behavior remains
unverified. No native-host frame-pacing claim is made.

## Geometry regression

Inside the assigned VM, with `TMPDIR` set to its disk-backed workspace. The
output directory must not already exist:

```bash
python3 -B .github/scripts/test-niri-map-geometry.py --output "$TMPDIR/niri-map-geometry-run"
```
