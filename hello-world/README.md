# Hello World Plugin

A demonstration plugin for Noctalia Shell that showcases bar widget, desktop widget, control center widget, panel, and custom settings functionalities.

## Features

- **Bar Widget**: Displays "Hello World" with an icon in the bar
- **Desktop Widget**: Draggable widget for the desktop
- **Control Center Widget**: Quick access button in the control center
- **Panel**: Shows detailed plugin information and IPC command examples
- **Main**: Demonstrates custom IPC handlers
- **Settings**: Plugin settings UI

## Settings schema

The manifest declares the finite `message` and `iconColor` String preferences in
`metadata.settingsSchema` (format1). Defaults remain in `metadata.defaultSettings`.
The shared settings page exposes reactive buffered dirtiness and stages its save
callback through the popup's editor API. Saved feedback requires an acknowledged
saved/no-op result with a current refresh; failed/stale results retain the editor.
The shared popup also owns active native-control dirtiness and commits buffered
input before gathering Apply or checking Close; pages do not inspect input children
or duplicate that pending-input owner. This requires Atmosphera0.10.0.
The separate live desktop settings
page retains its existing ownership contract. There is no user-file migration.
