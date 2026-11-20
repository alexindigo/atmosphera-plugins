import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var niriConfigPathField: pluginApi?.field("niriConfigPath") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null

  readonly property string valueNiriConfigPath: root.niriConfigPathField?.value ?? "~/.config/niri/config.kdl"
  readonly property string valueIconColor: root.iconColorField?.value ?? "none"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NPluginSettingsField {
      field: root.niriConfigPathField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.niriConfigPath.label")
        description: pluginApi?.tr("settings.niriConfigPath.description")
        placeholderText: "~/.config/niri/config.kdl"
        text: root.valueNiriConfigPath
        onEditCommitted: root.niriConfigPathField.set(text)
      }
    }

    NPluginSettingsField {
      field: root.iconColorField
      NColorChoice {
        label: pluginApi?.tr("settings.iconColor.label")
        description: pluginApi?.tr("settings.iconColor.description")
        currentKey: root.valueIconColor
        onSelected: key => root.iconColorField.set(key)
      }
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }
}
