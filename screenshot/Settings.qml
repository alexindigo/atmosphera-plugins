import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var modeField: pluginApi?.field("mode") ?? null

  readonly property string editMode: root.modeField?.value || "region"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  NPluginSettingsField {
    field: root.modeField
    NComboBox {
      label: pluginApi?.tr("settings.mode.label")
      description: pluginApi?.tr("settings.mode.description")
      model: [
        {
          "key": "region",
          "name": pluginApi?.tr("settings.mode.region")
        },
        {
          "key": "screen",
          "name": pluginApi?.tr("settings.mode.screen")
        }
      ]
      currentKey: root.editMode
      onSelected: key => root.modeField.set(key)
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.mode || "region"
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;

    pluginApi.saveSettings();
  }
}
