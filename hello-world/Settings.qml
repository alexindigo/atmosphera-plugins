import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var messageField: pluginApi?.field("message") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string valueMessage: root.messageField?.value ?? defaults.message
  readonly property string valueIconColor: root.iconColorField?.value ?? defaults.iconColor
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.d("HelloWorld", "Settings UI loaded");
  }

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

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

    NPluginSettingsField {
      field: root.messageField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.message.label")
        description: pluginApi?.tr("settings.message.desc")
        placeholderText: pluginApi?.tr("settings.message.placeholder")
        text: root.valueMessage
        onEditCommitted: root.messageField.set(text)
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("HelloWorld", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("HelloWorld", "Settings saved successfully");
    });
  }
}
