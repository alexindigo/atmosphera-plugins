import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Portals
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM
  Layout.fillWidth: true

  required property var pluginApi
  readonly property var wallpapersFolderField: pluginApi?.field("wallpapersFolder") ?? null
  readonly property var currentWallpaperField: pluginApi?.field("currentWallpaper") ?? null
  required property bool active
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  readonly property bool isPlaying: pluginApi.pluginSettings.isPlaying || false

  readonly property string wallpapersFolder: root.wallpapersFolderField?.value || "~/Pictures/Wallpapers"

  readonly property string currentWallpaper: root.currentWallpaperField?.value || ""
  signal wallpaperSelected(string path)

  // Wallpaper Folder
  ColumnLayout {
    spacing: Style.marginS

    NLabel {
      enabled: root.active
      label: pluginApi?.tr("settings.wallpapers_folder.title_label") || "Wallpapers Folder"
      description: pluginApi?.tr("settings.wallpapers_folder.title_description") || "The folder that contains all the wallpapers, useful when using random wallpaper"
    }

    RowLayout {
      spacing: Style.marginS

      NPluginSettingsField {
        field: root.wallpapersFolderField
        NTextInput {
          enabled: root.active
          Layout.fillWidth: true
          placeholderText: pluginApi?.tr("settings.wallpapers_folder.input_placeholder") || "/path/to/folder/with/wallpapers"
          text: root.wallpapersFolder
          onEditCommitted: root.wallpapersFolderField.set(text)
        }
      }

      AtmoIconButton {
        enabled: root.active
        icon: "wallpaper-selector"
        tooltipText: pluginApi?.tr("settings.wallpapers_folder.icon_tooltip") || "Select wallpapers folder"
        onClicked: wallpapersFolderPicker.openFilePicker()
      }

      PortalFilePicker {
        id: wallpapersFolderPicker
        title: pluginApi?.tr("settings.wallpapers_folder.file_picker_title") || "Choose wallpapers folder"
        initialPath: root.wallpapersFolder
        selectionMode: "folders"

        onAccepted: paths => {
          if (paths.length > 0) {
            Logger.d("mpvpaper", "Selected the following wallpaper folder:", paths[0]);
            root.wallpapersFolderField.set(paths[0]);
          }
        }
      }
    }
  }

  // Select Wallpaper
  RowLayout {
    spacing: Style.marginS

    NLabel {
      enabled: root.active
      label: pluginApi?.tr("settings.select_wallpaper.title_label") || "Select Wallpaper"
      description: pluginApi?.tr("settings.select_wallpaper.title_description") || "Choose the current video wallpaper playing."
    }

    NPluginSettingsField {
      field: root.currentWallpaperField
      AtmoIconButton {
        enabled: root.active
        icon: "wallpaper-selector"
        tooltipText: pluginApi?.tr("settings.select_wallpaper.icon_tooltip") || "Select current wallpaper"
        onClicked: currentWallpaperPicker.openFilePicker()
      }
    }

    PortalFilePicker {
      id: currentWallpaperPicker
      title: pluginApi?.tr("settings.select_wallpaper.file_picker_title") || "Choose current wallpaper"
      initialPath: root.wallpapersFolder
      selectionMode: "files"

      onAccepted: paths => {
        if (paths.length > 0) {
          Logger.d("mpvpaper", "Selected the following current wallpaper:", paths[0]);
          root.wallpaperSelected(paths[0]);
        }
      }
    }
  }

  /********************************
  * Save settings functionality
  ********************************/
  function saveSettings() {
    if (!pluginApi) {
      Logger.e("mpvpaper", "Cannot save: pluginApi is null");
      return;
    }
  }
}
