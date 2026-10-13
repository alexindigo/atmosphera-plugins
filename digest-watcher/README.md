# Digest Watcher

An Atmosphera-native bar button and panel for a model/research digest feed.
Requires Atmosphera **0.8.0 or newer**. The bell highlights when the feed has
new entries; clicking opens titles/summaries, clicking an entry copies its
path, and Shift+click opens it with the desktop's default application.

## Feed and helper contract

The plugin reads `$HOME/Digest/.index.json` and calls the existing
`/usr/local/bin/digest-index` helper every two minutes. The helper is responsible
for rebuilding the index; the plugin never installs or configures it.

The index contains `maxMtime` (numeric latest modification time), `count`, and
an `entries` array. Each entry may contain `title`, `summary`, `rel`, `path`,
`week`, `date` and `fit`. Opening the panel persists `seenMtime` using the normal
plugin settings API. `wl-copy` is needed for copying paths; `xdg-open` handles
opening them. An absent or partially written index leaves the existing/empty
view in place until the next valid refresh.

## Installation

Install Digest Watcher from **Settings → Plugins → Available → All**, enable
it and place its widget on the bar. Version1.0.1 uses the current
`AtmoIconButton`/`AtmoColor` APIs and per-screen capsule sizing.

For an older manually installed unsourced copy, preserve its settings and
layout before converting it to a source-backed installation. Merely publishing
this registry entry does not change that old copy's source identity. Do not
enable two copies of the polling widget simultaneously.

## License

MIT. Original author: domovoy#arch.
