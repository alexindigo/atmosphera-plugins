import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    property string editBackend: 
        displayBaseline.editBackend

    property string editDeeplApiKey: displayBaseline.editDeeplApiKey
    property bool editRealTime: displayBaseline.editRealTime
    property bool editShowPreview: displayBaseline.editShowPreview
    spacing: Style.marginM

    NComboBox {
        label: pluginApi?.tr("settings.backend-label") || "Translation Backend"
        description: pluginApi?.tr("settings.backend-description") || "Choose the translation service to use"
        model: [
            {
                "key": "google",
                "name": "Google Translate"
            },
            {
                "key": "deepl",
                "name": "DeepL"
            }
        ]
        currentKey: root.editBackend
        onSelected: key => root.editBackend = key
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.backend || "google"
    }

    NTextInput {
        visible: root.editBackend === "deepl"
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.apiKey-label") || "API Key"
        text: root.editDeeplApiKey
        onTextChanged: root.editDeeplApiKey = text
        placeholderText: pluginApi?.tr("settings.apiKey-placeholder") || "Enter your API key here"
    }

    NToggle {
        label: pluginApi?.tr("settings.realTime-label") || "Real-time Translation"
        description: pluginApi?.tr("settings.realTime-description") || "Translate as you type"
        checked: root.editRealTime
        onToggled: checked => root.editRealTime = checked
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.realTime || true
    }

    NToggle {
        label: pluginApi?.tr("settings.showPreview-label") || "Translation Preview"
        description: pluginApi?.tr("settings.showPreview-description") || "Show the translation result in the preview pane"
        checked: root.editShowPreview
        onToggled: checked => root.editShowPreview = checked
        defaultValue: true
    }

    NSettingsBaseline {
      id: displayBaseline
      readonly property string editBackend: pluginApi?.pluginSettings?.backend || pluginApi?.manifest?.metadata?.defaultSettings?.backend || "google"
      readonly property string editDeeplApiKey: pluginApi?.pluginSettings?.deeplApiKey || ""
      readonly property bool editRealTime: pluginApi?.pluginSettings?.realTimeTranslation !== undefined ? pluginApi.pluginSettings.realTimeTranslation : true
      readonly property bool editShowPreview: pluginApi?.pluginSettings?.showPreview !== undefined ? pluginApi.pluginSettings.showPreview : true
    }
    readonly property bool settingsDirty: displayBaseline.differs({editBackend: root.editBackend, editDeeplApiKey: root.editDeeplApiKey, editRealTime: root.editRealTime, editShowPreview: root.editShowPreview})

    function saveSettings() {
        if (!pluginApi) return;

        pluginApi.pluginSettings.backend = root.editBackend;
        pluginApi.pluginSettings.deeplApiKey = root.editDeeplApiKey;
        pluginApi.pluginSettings.realTimeTranslation = root.editRealTime;
        pluginApi.pluginSettings.showPreview = root.editShowPreview;
        pluginApi.saveSettings();
    }
}
