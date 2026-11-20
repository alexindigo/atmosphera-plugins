import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null

  readonly property string iconColor: root.iconColorField?.value ?? "none"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NPluginSettingsField {
      field: root.iconColorField
      NColorChoice {
        label: pluginApi?.tr("settings.iconColor.label")
        description: pluginApi?.tr("settings.iconColor.desc")
        currentKey: root.iconColor
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
