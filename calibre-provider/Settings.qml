import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  // Plugin API (injected by the settings dialog system)
  property var pluginApi: null
  readonly property var launcherField: pluginApi?.field("launcher") ?? null
  readonly property var forceGridField: pluginApi?.field("forceGrid") ?? null
  readonly property var recentlyOpenedMaxField: pluginApi?.field("recentlyOpenedMax") ?? null

  // Local state for editing
  readonly property string editLauncher: root.launcherField?.value || "xdg-open"
  readonly property bool editForceGrid: root.forceGridField?.value ?? false
  readonly property int editRecentlyOpenedMax: root.recentlyOpenedMaxField?.value ?? 36

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  // Calibre db
  ColumnLayout {
    spacing: Style.marginL

    NLabel {
      label: pluginApi?.tr("settings.launcher.title") || "Launcher"
      description: pluginApi?.tr("settings.launcher.description") || "The program used to open book files"
    }

    NPluginSettingsField {
      field: root.launcherField
      NTextInput {
        Layout.fillWidth: true
        placeholderText: "xdg-open"
        text: root.editLauncher
        onEditCommitted: root.launcherField.set(text)
      }
    }

    NPluginSettingsField {
      field: root.forceGridField
      NCheckbox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.forcegrid.label") || "Force grid view"
        description: pluginApi?.tr("settings.forcegrid.description") || "Always use grid view to display results. If disabled, use current launcher configuration"
        checked: root.editForceGrid
        onToggled: checked => root.forceGridField.set(checked)
      }
    }

    ColumnLayout {
      spacing: Style.marginM

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NLabel {
          label: pluginApi?.tr("settings.recentlyOpened.label") || "Recently opened count"
          description: pluginApi?.tr("settings.recentlyOpened.description") || "How many recently opened entries to remember"
        }

        NText {
          text: root.editRecentlyOpenedMax.toString()
        }
      }

      NPluginSettingsField {
        field: root.recentlyOpenedMaxField
        NSlider {
          id: rangeEditRecentlyOpenedMax
          objectName: "settings-range-editRecentlyOpenedMax"
          Layout.fillWidth: true
          from: 1
          to: 100
          value: root.editRecentlyOpenedMax
          stepSize: 1
          onMoved: {
            root.recentlyOpenedMaxField.set(value);
          }
        }
      }
    }
  }

  // Required: Save function called by the dialog
  function saveSettings() {
    pluginApi.saveSettings();
  }
}
