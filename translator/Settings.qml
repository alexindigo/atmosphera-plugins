import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var backendField: pluginApi?.field("backend") ?? null
  readonly property var deeplApiKeyField: pluginApi?.field("deeplApiKey") ?? null
  readonly property var realTimeTranslationField: pluginApi?.field("realTimeTranslation") ?? null
  readonly property var showPreviewField: pluginApi?.field("showPreview") ?? null

  readonly property string editBackend: root.backendField?.value || "google"

  readonly property string editDeeplApiKey: root.deeplApiKeyField?.value || ""
  readonly property bool editRealTime: root.realTimeTranslationField?.value !== undefined ? root.realTimeTranslationField?.value : true
  readonly property bool editShowPreview: root.showPreviewField?.value !== undefined ? root.showPreviewField?.value : true
  spacing: Style.marginM

  NPluginSettingsField {
    field: root.backendField
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
      onSelected: key => root.backendField.set(key)
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.backend || "google"
    }
  }

  NPluginSettingsField {
    field: root.deeplApiKeyField
    visible: root.editBackend === "deepl"
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.apiKey-label") || "API Key"
      text: root.editDeeplApiKey
      onEditCommitted: root.deeplApiKeyField.set(text)
      placeholderText: pluginApi?.tr("settings.apiKey-placeholder") || "Enter your API key here"
    }
  }

  NPluginSettingsField {
    field: root.realTimeTranslationField
    NToggle {
      label: pluginApi?.tr("settings.realTime-label") || "Real-time Translation"
      description: pluginApi?.tr("settings.realTime-description") || "Translate as you type"
      checked: root.editRealTime
      onToggled: checked => root.realTimeTranslationField.set(checked)
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.realTime || true
    }
  }

  NPluginSettingsField {
    field: root.showPreviewField
    NToggle {
      label: pluginApi?.tr("settings.showPreview-label") || "Translation Preview"
      description: pluginApi?.tr("settings.showPreview-description") || "Show the translation result in the preview pane"
      checked: root.editShowPreview
      onToggled: checked => root.showPreviewField.set(checked)
      defaultValue: true
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi)
      return;

    pluginApi.saveSettings();
  }
}
