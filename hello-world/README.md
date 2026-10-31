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
The metadata is additive: the existing shell owner and plugin behavior remain
compatible. It introduces no user-file migration or new runtime API dependency.
