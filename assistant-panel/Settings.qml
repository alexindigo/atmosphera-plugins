import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "Constants.js" as Constants
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var aiField: pluginApi?.field("ai") ?? null
  readonly property var translatorField: pluginApi?.field("translator") ?? null
  readonly property var maxHistoryLengthField: pluginApi?.field("maxHistoryLength") ?? null
  readonly property var panelDetachedField: pluginApi?.field("panelDetached") ?? null
  readonly property var panelPositionField: pluginApi?.field("panelPosition") ?? null
  readonly property var panelHeightRatioField: pluginApi?.field("panelHeightRatio") ?? null
  readonly property var panelWidthField: pluginApi?.field("panelWidth") ?? null
  readonly property var attachmentStyleField: pluginApi?.field("attachmentStyle") ?? null
  readonly property var scaleField: pluginApi?.field("scale") ?? null
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _savePending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._savePending = false;
      Logger.i("AssistantPanel", "Settings saved successfully");
    }
  }

  // ai and translator are atomic records: a member control's intent is the
  // whole record with that member changed.
  readonly property var aiValue: aiField?.value ?? ({})
  readonly property var translatorValue: translatorField?.value ?? ({})
  function setAi(patch) {
    return root.aiField.set(Object.assign(Object.create(null), root.aiValue, patch));
  }
  function setTranslator(patch) {
    return root.translatorField.set(Object.assign(Object.create(null), root.translatorValue, patch));
  }

  NText {
    Layout.fillWidth: true
    visible: root.pluginApi?.scopeKind === "instance"
    text: pluginApi?.tr("settings.sharedContent")
    wrapMode: Text.Wrap
    color: AtmoColor.mOnSurfaceVariant
    pointSize: Style.fontSizeS
  }

  // AI Settings
  readonly property string editProvider: aiValue.provider || Constants.Providers.GOOGLE
  readonly property var editModels: aiValue.models || ({})
  readonly property var editApiKeys: aiValue.apiKeys || ({})
  // Use per-provider model if configured (and non-empty), else return empty to show placeholder
  readonly property string editModel: editModels[editProvider] || ""
  readonly property string editApiKey: editApiKeys[editProvider] !== undefined ? editApiKeys[editProvider] : aiValue.apiKey || ""
  readonly property real editTemperature: aiValue.temperature ?? 0.7
  readonly property string editSystemPrompt: aiValue.systemPrompt || ""

  // Translator Settings
  readonly property string editTranslatorBackend: translatorValue.backend || "google"
  readonly property bool editRealTimeTranslation: translatorValue.realTimeTranslation ?? true
  readonly property string editDeeplApiKey: translatorValue.deeplApiKey || ""

  // General Settings
  readonly property int editMaxHistoryLength: maxHistoryLengthField?.value || 100

  // Panel Settings (detached, position, height, offset, width)
  readonly property bool editPanelDetached: panelDetachedField?.value ?? true
  readonly property string editPanelPosition: panelPositionField?.value || "right"
  readonly property real editPanelHeightRatio: panelHeightRatioField?.value || 0.85
  readonly property int editPanelWidth: panelWidthField?.value ?? 520
  readonly property string editAttachmentStyle: attachmentStyleField?.value || "connected"
  readonly property real editScale: scaleField?.value || 1

  // OpenAI Compatible specific settings
  readonly property bool editOpenAiLocal: aiValue.openaiLocal ?? false
  readonly property string editOpenAiBaseUrl: aiValue.openaiBaseUrl || "https://api.openai.com/v1/chat/completions"

  // Environment variable API keys - check if managed by env
  readonly property var envApiKeys: ({
                                       [Constants.Providers.GOOGLE]: Quickshell.env("NOCTALIA_AP_GOOGLE_API_KEY") || "",
                                       [Constants.Providers.OPENAI_COMPATIBLE]: Quickshell.env("NOCTALIA_AP_OPENAI_COMPATIBLE_API_KEY") || ""
                                     })
  readonly property bool apiKeyManagedByEnv: (envApiKeys[editProvider] || "") !== ""
  readonly property string envDeeplApiKey: Quickshell.env("NOCTALIA_AP_DEEPL_API_KEY") || ""
  readonly property bool deeplApiKeyManagedByEnv: envDeeplApiKey !== ""
  // ==================
  // Panel Settings Section
  // ==================
  NText {
    text: pluginApi?.tr("settings.panelSection")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.panelDetachedField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.panelDetached")
      description: pluginApi?.tr("settings.panelDetachedDesc")
      checked: root.editPanelDetached
      onToggled: function (checked) {
        root.panelDetachedField.set(checked);
        // Reset position if invalid for new mode
        if (checked) {
          // Switching to Detached: "top" and "bottom" become invalid -> default to "right"
          if (root.editPanelPosition === "top" || root.editPanelPosition === "bottom") {
            root.panelPositionField.set("right");
          }
        } else {
          // Switching to Attached: "center" becomes invalid -> default to "right"
          if (root.editPanelPosition === "center") {
            root.panelPositionField.set("right");
          }
        }
      }
      defaultValue: true
    }
  }

  NPluginSettingsField {
    field: root.panelPositionField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.panelPosition")
      description: pluginApi?.tr("settings.panelPositionDesc")
      model: root.editPanelDetached ? [
                                        {
                                          "key": "left",
                                          "name": pluginApi?.tr("settings.panelPositionLeft")
                                        },
                                        {
                                          "key": "center",
                                          "name": pluginApi?.tr("settings.panelPositionCenter")
                                        },
                                        {
                                          "key": "right",
                                          "name": pluginApi?.tr("settings.panelPositionRight")
                                        }
                                      ] : [
                                        {
                                          "key": "left",
                                          "name": pluginApi?.tr("settings.panelPositionLeft")
                                        },
                                        {
                                          "key": "top",
                                          "name": pluginApi?.tr("settings.panelPositionTop")
                                        },
                                        {
                                          "key": "bottom",
                                          "name": pluginApi?.tr("settings.panelPositionBottom")
                                        },
                                        {
                                          "key": "right",
                                          "name": pluginApi?.tr("settings.panelPositionRight")
                                        }
                                      ]
      currentKey: root.editPanelPosition
      onSelected: function (key) {
        root.panelPositionField.set(key);
      }
      defaultValue: "right"
    }
  }

  NPluginSettingsField {
    field: root.attachmentStyleField
    visible: !root.editPanelDetached
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.attachmentStyle")
      description: pluginApi?.tr("settings.attachmentStyleDesc")
      model: [
        {
          "key": "connected",
          "name": pluginApi?.tr("settings.attachConnected")
        },
        {
          "key": "floating",
          "name": pluginApi?.tr("settings.attachFloating")
        }
      ]
      currentKey: root.editAttachmentStyle
      onSelected: function (key) {
        root.attachmentStyleField.set(key);
      }
      defaultValue: "connected"
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    NLabel {
      label: pluginApi?.tr("settings.panelHeightRatio") + ": " + (root.editPanelHeightRatio * 100).toFixed(0) + "%"
      description: pluginApi?.tr("settings.panelHeightRatioDesc")
    }
    NPluginSettingsField {
      field: root.panelHeightRatioField
      NSlider {
        id: rangeEditPanelHeightRatio
        objectName: "settings-range-editPanelHeightRatio"
        Layout.fillWidth: true
        from: 0.3
        to: 1.0
        stepSize: 0.01
        value: root.editPanelHeightRatio
        onMoved: root.panelHeightRatioField.set(value)
      }
    }
    NLabel {
      label: pluginApi?.tr("settings.panelWidth") + ": " + root.editPanelWidth + "px"
      description: pluginApi?.tr("settings.panelWidthDesc")
    }
    NPluginSettingsField {
      field: root.panelWidthField
      NSlider {
        id: rangeEditPanelWidth
        objectName: "settings-range-editPanelWidth"
        Layout.fillWidth: true
        from: 320
        to: 1200
        stepSize: 1
        value: root.editPanelWidth
        onMoved: root.panelWidthField.set(value)
      }
    }
    NLabel {
      label: pluginApi?.tr("settings.uiScale") + ": " + (root.editScale * 100).toFixed(0) + "%"
      description: pluginApi?.tr("settings.uiScaleDesc")
    }
    NPluginSettingsField {
      field: root.scaleField
      NSlider {
        id: rangeEditScale
        objectName: "settings-range-editScale"
        Layout.fillWidth: true
        from: 0.5
        to: 2.0
        stepSize: 0.01
        value: root.editScale
        onMoved: root.scaleField.set(value)
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  // Provider configurations
  readonly property var providers: ({
                                      [Constants.Providers.GOOGLE]: {
                                        "name": "Google Gemini",
                                        "defaultModel": "gemini-2.5-flash",
                                        "requiresKey": true,
                                        "keyUrl": "https://aistudio.google.com/app/apikey"
                                      },
                                      [Constants.Providers.OPENAI_COMPATIBLE]: {
                                        "name": "OpenAI Compatible",
                                        // Default to GPT-4o-mini but this is purely a placeholder as it depends on the actual backend
                                        "defaultModel": "gpt-4o-mini",
                                        // requiresKey is dynamic based on "Local" toggle, handled in logic below
                                        "requiresKey": true,
                                        "keyUrl": ""
                                      }
                                    })

  spacing: Style.marginM

  Component.onCompleted: {
    Logger.i("AssistantPanel", "Settings UI loaded");
  }

  // ==================
  // AI Settings Section
  // ==================
  NText {
    text: pluginApi?.tr("settings.aiSection")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.aiField
    // Provider selection
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.provider")
      description: pluginApi?.tr("settings.providerDesc")
      model: [
        {
          "key": Constants.Providers.GOOGLE,
          "name": "Google Gemini"
        },
        {
          "key": Constants.Providers.OPENAI_COMPATIBLE,
          "name": "OpenAI Compatible"
        }
      ]
      currentKey: root.editProvider
      onSelected: function (key) {
        root.selectProvider(key);
      }
      defaultValue: Constants.Providers.GOOGLE
    }

    // OpenAI Compatible Extras
    ColumnLayout {
      Layout.fillWidth: true
      visible: root.editProvider === Constants.Providers.OPENAI_COMPATIBLE
      spacing: Style.marginS

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.local")
        description: pluginApi?.tr("settings.localDesc")
        checked: root.editOpenAiLocal
        onToggled: function (checked) {
          root.setAi({
                       openaiLocal: checked
                     });
        }
        defaultValue: false
      }

      NTextInput {
        Layout.fillWidth: true
        visible: true
        label: pluginApi?.tr("settings.baseUrl")
        description: pluginApi?.tr("settings.baseUrlDesc")
        text: root.editOpenAiBaseUrl
        placeholderText: "https://api.openai.com/v1/chat/completions"
        onEditCommitted: root.setAi({
                                      openaiBaseUrl: text
                                    })
      }

      // Note about Base URL and response API
      NText {
        Layout.fillWidth: true
        visible: true
        text: pluginApi?.tr("settings.baseUrlNote") + "https://platform.openai.com/docs/api-reference/chat/create" + pluginApi?.tr("settings.moreInfo")
        color: AtmoColor.mOnSurfaceVariant
        pointSize: Style.fontSizeXS
        wrapMode: Text.Wrap
        onLinkActivated: link => Qt.openUrlExternally(link)
      }
    }

    // Model selection
    NTextInput {
      objectName: "assistant-model"
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.model")
      description: pluginApi?.tr("settings.modelDesc")
      text: root.editModel
      onEditCommitted: root.setModel(text)
      placeholderText: providers[root.editProvider]?.defaultModel || ""
    }

    // API Key input (hidden for Ollama/Local)
    NTextInput {
      objectName: "assistant-api-key"
      Layout.fillWidth: true
      visible: {
        if (root.editProvider === Constants.Providers.OPENAI_COMPATIBLE && root.editOpenAiLocal)
          return false;
        return providers[root.editProvider]?.requiresKey ?? true;
      }
      label: pluginApi?.tr("settings.apiKey")
      description: {
        if (root.apiKeyManagedByEnv) {
          return pluginApi?.tr("settings.apiKeyManagedByEnv");
        }
        var provider = providers[root.editProvider];
        if (provider && provider.keyUrl) {
          return (pluginApi?.tr("settings.apiKeyDesc")) + ": " + provider.keyUrl;
        }
        return "";
      }
      placeholderText: root.apiKeyManagedByEnv ? pluginApi?.tr("settings.apiKeyEnvPlaceholder") : pluginApi?.tr("settings.apiKeyPlaceholder")
      text: root.apiKeyManagedByEnv ? "" : root.editApiKey
      enabled: !root.apiKeyManagedByEnv
      inputMethodHints: Qt.ImhHiddenText
      onEditCommitted: {
        if (!root.apiKeyManagedByEnv)
          root.setAi({
                       apiKeys: Object.assign(Object.create(null), root.editApiKeys, {
                                                [root.editProvider]: text
                                              })
                     });
      }
    }

    // Temperature slider
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NLabel {
        label: pluginApi?.tr("settings.temperature") + ": " + root.editTemperature.toFixed(1)
        description: pluginApi?.tr("settings.temperatureDesc")
      }

      NSlider {
        id: rangeEditTemperature
        objectName: "settings-range-editTemperature"
        Layout.fillWidth: true
        from: 0
        to: 2
        stepSize: 0.1
        value: root.editTemperature
        onMoved: root.setAi({
                              temperature: value
                            })
      }
    }

    // System prompt
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NLabel {
        label: pluginApi?.tr("settings.systemPrompt")
        description: pluginApi?.tr("settings.systemPromptDesc")
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        color: AtmoColor.mSurface
        radius: Style.radiusS
        border.color: AtmoColor.mOutline
        border.width: 1

        TextArea {
          anchors.fill: parent
          anchors.margins: Style.marginS
          text: root.editSystemPrompt
          placeholderText: pluginApi?.tr("settings.systemPromptPlaceholder")
          placeholderTextColor: AtmoColor.mOnSurfaceVariant
          color: AtmoColor.mOnSurface
          font.pointSize: Style.fontSizeS
          wrapMode: TextArea.Wrap
          background: null
          // Only focused typing is user intent; binding updates are not.
          onTextChanged: if (activeFocus)
                           root.setAi({
                                        systemPrompt: text
                                      })
        }
      }
    }
  }

  // Max history length
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: (pluginApi?.tr("settings.maxHistory")) + ": " + root.editMaxHistoryLength
      description: pluginApi?.tr("settings.maxHistoryDesc")
    }

    NPluginSettingsField {
      field: root.maxHistoryLengthField
      NSlider {
        id: rangeEditMaxHistoryLength
        objectName: "settings-range-editMaxHistoryLength"
        Layout.fillWidth: true
        from: 10
        to: 500
        stepSize: 10
        value: root.editMaxHistoryLength
        onMoved: root.maxHistoryLengthField.set(value)
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  // ==================
  // Translator Settings Section
  // ==================
  NText {
    text: pluginApi?.tr("settings.translatorSection")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.translatorField
    // Translator backend
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.translatorBackend")
      description: pluginApi?.tr("settings.translatorBackendDesc")
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
      currentKey: root.editTranslatorBackend
      onSelected: function (key) {
        root.setTranslator({
                             backend: key
                           });
      }
      defaultValue: "google"
    }

    // DeepL API key (only for DeepL)
    NTextInput {
      Layout.fillWidth: true
      visible: root.editTranslatorBackend === "deepl"
      label: pluginApi?.tr("settings.deeplApiKey")
      description: root.deeplApiKeyManagedByEnv ? (pluginApi?.tr("settings.apiKeyManagedByEnv")) : (pluginApi?.tr("settings.deeplApiKeyDesc"))
      placeholderText: root.deeplApiKeyManagedByEnv ? (pluginApi?.tr("settings.apiKeyEnvPlaceholder")) : (pluginApi?.tr("settings.apiKeyPlaceholder"))
      text: root.deeplApiKeyManagedByEnv ? "" : root.editDeeplApiKey
      enabled: !root.deeplApiKeyManagedByEnv
      inputMethodHints: Qt.ImhHiddenText
      onEditCommitted: {
        if (!root.deeplApiKeyManagedByEnv)
          root.setTranslator({
                               deeplApiKey: text
                             });
      }
    }

    // Real-time translation toggle
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.realTimeTranslation")
      description: pluginApi?.tr("settings.realTimeTranslationDesc")
      checked: root.editRealTimeTranslation
      onToggled: function (checked) {
        root.setTranslator({
                             realTimeTranslation: checked
                           });
      }
      defaultValue: true
    }
  }

  function setModel(text) {
    var modelText = (text || "").trim();
    var defaultModel = providers[root.editProvider]?.defaultModel || "";
    var models = Object.assign(Object.create(null), root.editModels);
    if (modelText !== "" && modelText !== defaultModel)
      models[root.editProvider] = modelText;
    else
      delete models[root.editProvider];
    return root.setAi({
                        models: models,
                        model: models[root.editProvider] || ""
                      });
  }

  function selectProvider(provider) {
    return root.setAi({
                        provider: provider,
                        model: root.editModels[provider] || ""
                      });
  }

  // Save function called by the settings dialog
  function saveSettings() {
    if (!pluginApi)
      return;
    if (pluginApi.saveSettings() !== false)
      root._savePending = true;
  }
}
