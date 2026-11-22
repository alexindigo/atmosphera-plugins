import QtQuick
import "Constants.js" as Constants

Item {
  id: client
  required property var settingsContext
  required property var owner
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView
  readonly property string provider: cfg.ai?.provider || Constants.Providers.GOOGLE
  readonly property string model: cfg.ai?.models?.[provider] || owner.providers[provider]?.defaultModel || ""
  readonly property string envApiKey: owner.envApiKeys[provider] || ""
  readonly property string settingsApiKey: cfg.ai?.apiKeys?.[provider] || ""
  readonly property string apiKey: envApiKey !== "" ? envApiKey : settingsApiKey
  readonly property bool apiKeyManagedByEnv: envApiKey !== ""
  readonly property real temperature: cfg.ai?.temperature ?? owner.pluginApi?.manifest?.metadata?.defaultSettings?.ai?.temperature ?? 0.7
  readonly property string systemPrompt: cfg.ai?.systemPrompt || ""
  readonly property bool openaiLocal: cfg.ai?.openaiLocal ?? false
  readonly property string openaiBaseUrl: cfg.ai?.openaiBaseUrl || "https://api.openai.com/v1/chat/completions"
  readonly property real maxHistoryLength: cfg.maxHistoryLength || 100
  readonly property string translatorBackend: cfg.translator?.backend || "google"
  readonly property string sourceLanguage: cfg.translator?.sourceLanguage || "auto"
  readonly property string targetLanguage: cfg.translator?.targetLanguage || "en"
  readonly property string deeplApiKey: owner.envDeeplApiKey || cfg.translator?.deeplApiKey || ""
  readonly property bool deeplApiKeyManagedByEnv: owner.envDeeplApiKey !== ""
  readonly property string chatIdentity: JSON.stringify([provider, model, apiKey, temperature, systemPrompt, openaiLocal, openaiBaseUrl])
  readonly property string translationIdentity: JSON.stringify([translatorBackend, sourceLanguage, targetLanguage, deeplApiKey])
  function captureChat() {
    return current ? Object.freeze({context: settingsContext, identity: chatIdentity, provider: provider, model: model, apiKey: apiKey,
      temperature: temperature, systemPrompt: systemPrompt, openaiLocal: openaiLocal, openaiBaseUrl: openaiBaseUrl, maxHistoryLength: maxHistoryLength}) : null;
  }
  function captureTranslation(target, source) {
    return current ? Object.freeze({context: settingsContext, identity: translationIdentity, backend: translatorBackend,
      target: target || targetLanguage, source: source || sourceLanguage, apiKey: deeplApiKey}) : null;
  }
  property bool _constructed: false
  onChatIdentityChanged: if (_constructed) owner.retireRequests(client, "chat")
  onTranslationIdentityChanged: if (_constructed) owner.retireRequests(client, "translation")
  onCurrentChanged: if (!current && _constructed) retire(client)
  Component.onCompleted: _constructed = true
}
