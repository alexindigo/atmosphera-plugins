import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var pluggedInScriptField: pluginApi?.field("pluggedInScript") ?? null
  readonly property var onBatteryScriptField: pluginApi?.field("onBatteryScript") ?? null

  readonly property string editPluggedInScript: root.pluggedInScriptField?.value || ""
  readonly property string editOnBatteryScript: root.onBatteryScriptField?.value || ""
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  NPluginSettingsField {
    field: root.pluggedInScriptField
    NTextInput {
      Layout.fillWidth: true
      fontFamily: Settings.data.ui.fontFixed
      label: tr("settings.plugged_in_label")
      description: tr("settings.plugged_in_desc")
      placeholderText: "command1; command2; /path/to/script; ..."
      text: root.editPluggedInScript
      onEditCommitted: root.pluggedInScriptField.set(text)
    }
  }
  NPluginSettingsField {
    field: root.onBatteryScriptField
    NTextInput {
      Layout.fillWidth: true
      fontFamily: Settings.data.ui.fontFixed
      label: tr("settings.on_battery_label")
      description: tr("settings.on_battery_desc")
      placeholderText: "command1; command2; /path/to/script; ..."
      text: root.editOnBatteryScript
      onEditCommitted: root.onBatteryScriptField.set(text)
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    NLabel {
      label: tr("settings.env_vars_title")
    }

    NLabel {
      description: `$BAT_PERCENTAGE: ${tr("settings.env_vars_percentage")}`
    }
    NLabel {
      description: `$BAT_STATE: ${tr("settings.env_vars_state")}`
    }
    NLabel {
      description: `$BAT_RATE: ${tr("settings.env_vars_rate")}`
    }
    NLabel {
      description: `$BAT_PATH: ${tr("settings.env_vars_path")}`
    }
  }

  function tr(key) {
    return pluginApi?.tr(key);
  }

  function saveSettings() {
    pluginApi.saveSettings();
  }
}
