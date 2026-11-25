import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var api_keyField: pluginApi?.field("api_key") ?? null
  readonly property var ratingField: pluginApi?.field("rating") ?? null

  readonly property string valueApiKey: root.api_keyField?.value ?? ""
  readonly property string valueRating: root.ratingField?.value ?? "g"

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.d("GiphySearch", "Settings UI loaded");
  }

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NPluginSettingsField {
      field: root.api_keyField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.apiKey.label")
        description: pluginApi?.tr("settings.apiKey.description")
        text: root.valueApiKey
        onEditCommitted: root.api_keyField.set(text)
      }
    }

    NPluginSettingsField {
      field: root.ratingField
      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.rating.label")
        description: pluginApi?.tr("settings.rating.description")
        model: [
          {
            key: "g",
            name: "G"
          },
          {
            key: "pg",
            name: "PG"
          },
          {
            key: "pg-13",
            name: "PG-13"
          },
          {
            key: "r",
            name: "R"
          }
        ]
        currentKey: root.valueRating
        onSelected: key => root.ratingField.set(key)
      }
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("GiphySearch", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("GiphySearch", "Settings saved successfully");
    });
  }
}
