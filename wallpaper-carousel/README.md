# Wallpaper Carousel

An Atmosphera plugin for browsing and picking wallpapers in a fullscreen,
skewed carousel. Based on [ilyamiro's original wallpaper picker](https://github.com/ilyamiro/nixos-configuration);
the shared carousel and upstream authorship/license are preserved.

## Installation and configuration

Install **Wallpaper Carousel** from the Atmosphera plugin manager and enable
it. Atmosphera must manage the wallpaper; choose its wallpaper directory in
**Settings → Wallpaper**. The plugin settings can override that directory and
configure wrap/infinite navigation, dimming, thumbnail dimensions and expansion.

The canonical entry points are `Main.qml` and `Settings.qml`. The retained
`WallpaperCarousel.qml`/`WallpaperCarouselSettings.qml` filenames delegate to
those native implementations, so they do not depend on DMS-only QML modules.

## Controls

Use Left/Right to navigate, Enter to apply, and Escape to close. Selecting a
wallpaper uses Atmosphera's wallpaper service, including its per-monitor setup.

| Command | Action |
|---|---|
| `qs -c atmosphera ipc call wallpaperCarousel toggle` | Open/close |
| `qs -c atmosphera ipc call wallpaperCarousel open` | Open |
| `qs -c atmosphera ipc call wallpaperCarousel close` | Close |
| `qs -c atmosphera ipc call wallpaperCarousel cycleNext` | Highlight next |
| `qs -c atmosphera ipc call wallpaperCarousel cyclePrevious` | Highlight previous |

Add compositor keybindings only after testing the plugin in a development VM.

## Credits

Original picker by [ilyamiro](https://github.com/ilyamiro/nixos-configuration).
The upstream screenshot/video wallpaper collection is by
[Andreas Rocha](https://www.andreasrocha.com/). Original plugin author: yngwe.
See the plugin manifest for its MIT license declaration.
