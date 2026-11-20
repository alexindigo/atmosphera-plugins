import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string valueIconColor: root.iconColorField?.value ?? defaults.iconColor

  spacing: Style.marginL

  NPluginSettingsField {
    field: root.iconColorField
    NComboBox {
      label: pluginApi?.tr("settings.iconColor.label")
      description: pluginApi?.tr("settings.iconColor.desc")
      model: AtmoColor.colorKeyModel
      currentKey: root.valueIconColor
      onSelected: key => root.iconColorField.set(key)
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("PluginManager", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("PluginManager", "Settings saved");
    });
  }
}
