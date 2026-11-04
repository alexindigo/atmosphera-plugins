import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property string valueApiKey: displayBaseline.valueApiKey
    property string valueRating: displayBaseline.valueRating

    spacing: Style.marginL

    Component.onCompleted: {
        Logger.d("GiphySearch", "Settings UI loaded");
    }

    ColumnLayout {
        spacing: Style.marginM
        Layout.fillWidth: true

        NTextInput {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.apiKey.label")
            description: pluginApi?.tr("settings.apiKey.description")
            text: root.valueApiKey
            onTextChanged: root.valueApiKey = text
        }

        NComboBox {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.rating.label")
            description: pluginApi?.tr("settings.rating.description")
            model: [
                { key: "g", name: "G" },
                { key: "pg", name: "PG" },
                { key: "pg-13", name: "PG-13" },
                { key: "r", name: "R" }
            ]
            currentKey: root.valueRating
            onSelected: key => root.valueRating = key
        }
    }

    NSettingsBaseline {
      id: displayBaseline
      readonly property string valueApiKey: cfg.api_key ?? defaults.api_key ?? ""
      readonly property string valueRating: cfg.rating ?? defaults.rating ?? "g"
    }
    readonly property bool settingsDirty: displayBaseline.differs({valueApiKey: root.valueApiKey, valueRating: root.valueRating})

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("GiphySearch", "Cannot save settings: pluginApi is null");
            return;
        }

        pluginApi.pluginSettings.api_key = root.valueApiKey;
        pluginApi.pluginSettings.rating = root.valueRating;
        pluginApi.saveSettings(function (result) {
            if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
                Logger.d("GiphySearch", "Settings saved successfully");
        });
    }
}
