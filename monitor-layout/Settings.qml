import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var backendField: pluginApi?.field("backend") ?? null
  readonly property var swayCommandField: pluginApi?.field("swayCommand") ?? null
  readonly property var hyprctlCommandField: pluginApi?.field("hyprctlCommand") ?? null
  readonly property var snapToGridField: pluginApi?.field("snapToGrid") ?? null
  readonly property var gridSizeField: pluginApi?.field("gridSize") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null

  readonly property string editBackend: root.backendField?.value ?? "auto"
  readonly property string editSwayCommand: root.swayCommandField?.value ?? "swaymsg"
  readonly property string editHyprctlCommand: root.hyprctlCommandField?.value ?? "hyprctl"
  readonly property bool editSnapToGrid: root.snapToGridField?.value ?? true
  readonly property string editGridSize: String(root.gridSizeField?.value ?? 40)
  readonly property string editIconColor: root.iconColorField?.value ?? "primary"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NPluginSettingsField {
      field: root.backendField
      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.backend.label")
        description: pluginApi?.tr("settings.backend.desc")
        model: [
          {
            "key": "auto",
            "name": pluginApi?.tr("settings.backend.auto")
          },
          {
            "key": "sway",
            "name": pluginApi?.tr("settings.backend.sway")
          },
          {
            "key": "hyprland",
            "name": pluginApi?.tr("settings.backend.hyprland")
          }
        ]
        currentKey: root.editBackend
        onSelected: key => root.backendField.set(key)
      }
    }

    NPluginSettingsField {
      field: root.swayCommandField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.swayCommand.label")
        description: pluginApi?.tr("settings.swayCommand.desc")
        text: root.editSwayCommand
        onEditCommitted: root.swayCommandField.set(text)
      }
    }

    NPluginSettingsField {
      field: root.hyprctlCommandField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.hyprctlCommand.label")
        description: pluginApi?.tr("settings.hyprctlCommand.desc")
        text: root.editHyprctlCommand
        onEditCommitted: root.hyprctlCommandField.set(text)
      }
    }

    NPluginSettingsField {
      field: root.snapToGridField
      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.snapToGrid.label")
        checked: root.editSnapToGrid
        onToggled: checked => root.snapToGridField.set(checked)
      }
    }

    NPluginSettingsField {
      field: root.gridSizeField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.gridSize.label")
        description: pluginApi?.tr("settings.gridSize.desc")
        text: root.editGridSize
        onEditCommitted: root.gridSizeField.set(Math.max(1, parseInt(text) || 40))
      }
    }

    NPluginSettingsField {
      field: root.iconColorField
      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.iconColor.label")
        description: pluginApi?.tr("settings.iconColor.desc")
        model: AtmoColor.colorKeyModel
        currentKey: root.editIconColor
        onSelected: key => root.iconColorField.set(key)
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      return;
    }

    pluginApi.saveSettings();
  }
}
