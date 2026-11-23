import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import "ProviderLogic.js" as ProviderLogic
import "Constants.js" as Constants

Item {
  id: root
  property var pluginApi: null
  // Conversation, input, translation and the existing cache remain common.
  property var _conversation: ({messages: [], historyLimit: null})
  readonly property var messages: _conversation.messages
  property bool isGenerating: false
  property string currentResponse: ""
  property string errorMessage: ""
  property string translatedText: ""
  property bool isTranslating: false
  property string translationError: ""
  property string activeTab: "ai"
  property string chatInputText: ""
  property int chatInputCursorPosition: 0
  readonly property string cacheDir: typeof Settings !== "undefined" && Settings.cacheDir ? Settings.cacheDir + "plugins/assistant-panel/" : ""
  readonly property string stateCachePath: cacheDir + "state.json"
  readonly property var providers: ({
    [Constants.Providers.GOOGLE]: {name: "Google Gemini", defaultModel: "gemini-2.5-flash", streamEndpoint: "https://generativelanguage.googleapis.com/v1beta/models/{model}:streamGenerateContent?alt=sse&key={apiKey}"},
    [Constants.Providers.OPENAI_COMPATIBLE]: {name: "OpenAI Compatible", defaultModel: "gpt-4o-mini", endpoint: ""}
  })
  readonly property var envApiKeys: ({
    [Constants.Providers.GOOGLE]: Quickshell.env("NOCTALIA_AP_GOOGLE_API_KEY") || "",
    [Constants.Providers.OPENAI_COMPATIBLE]: Quickshell.env("NOCTALIA_AP_OPENAI_COMPATIBLE_API_KEY") || ""
  })
  readonly property string envDeeplApiKey: Quickshell.env("NOCTALIA_AP_DEEPL_API_KEY") || ""
  property var _settingsConsumers: new Map()
  property var _chatRequest: null
  property var _translationRequest: null
  property var _lifetime: ({alive: true})
  property bool saveStateQueued: false
  Component { id: clientFactory; AssistantSettingsClient {} }
  Component { id: requestFactory; AssistantRequest {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {settingsContext: context, owner: root,
      retire: function(retired) {
        root.retireRequests(retired, "all"); root._settingsConsumers.delete(context); retired.destroy();
      }});
    _settingsConsumers.set(context, client);
    return client;
  }
  function _consumer(context) { return settingsConsumerFor(context === undefined ? pluginApi?.settingsContext : context); }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  // Compatibility/IPC access is explicitly plugin-level, never a view's selection.
  readonly property string provider: settingsConsumer?.provider || Constants.Providers.GOOGLE
  readonly property string model: settingsConsumer?.model || ""
  readonly property string apiKey: settingsConsumer?.apiKey || ""
  readonly property bool apiKeyManagedByEnv: settingsConsumer?.apiKeyManagedByEnv ?? false
  readonly property real temperature: settingsConsumer?.temperature ?? 0.7
  readonly property string systemPrompt: settingsConsumer?.systemPrompt || ""
  readonly property bool openaiLocal: settingsConsumer?.openaiLocal ?? false
  readonly property string openaiBaseUrl: settingsConsumer?.openaiBaseUrl || ""
  readonly property string translatorBackend: settingsConsumer?.translatorBackend || "google"
  readonly property string sourceLanguage: settingsConsumer?.sourceLanguage || "auto"
  readonly property string targetLanguage: settingsConsumer?.targetLanguage || "en"
  readonly property string deeplApiKey: settingsConsumer?.deeplApiKey || ""
  readonly property bool deeplApiKeyManagedByEnv: envDeeplApiKey !== ""
  function retireRequests(client, kind) {
    if ((kind === "all" || kind === "chat") && _chatRequest?.policy.context === client.settingsContext) _cancelChat(false);
    if ((kind === "all" || kind === "translation") && _translationRequest?.policy.context === client.settingsContext) _cancelTranslation();
  }
  Component.onCompleted: { Logger.i("AssistantPanel", "Plugin initialized"); ensureCacheDir(); }
  Component.onDestruction: _lifetime.alive = false
  function ensureCacheDir() { if (cacheDir) Quickshell.execDetached(["mkdir", "-p", cacheDir]); }
  FileView {
    id: stateCacheFile
    path: root.stateCachePath
    watchChanges: false
    onLoaded: root.loadStateFromCache()
    onLoadFailed: error => {
      if (error !== 2) Logger.e("AssistantPanel", "Failed to load state cache: " + error);
    }
  }
  function loadStateFromCache() {
    var result = ProviderLogic.processLoadedState(stateCacheFile.text());
    if (!result) return;
    if (result.error) { Logger.e("AssistantPanel", "Failed to parse state cache: " + result.error); return; }
    _conversation = {messages: result.messages, historyLimit: null}; activeTab = result.activeTab;
    chatInputText = result.chatInputText; chatInputCursorPosition = result.chatInputCursorPosition;
  }
  Timer { id: saveStateTimer; interval: 500; onTriggered: root.performSaveState() }
  function saveState(context) {
    if (!_consumer(context)) return false;
    _queueState();
    return true;
  }
  function _queueState() { saveStateQueued = true; saveStateTimer.restart(); }
  function _recordConversation(next, limit) {
    _conversation = {messages: next, historyLimit: limit};
    _queueState();
  }
  function performSaveState() {
    if (!saveStateQueued || !cacheDir) return;
    saveStateQueued = false;
    try {
      ensureCacheDir();
      stateCacheFile.setText(ProviderLogic.prepareStateForSave(_conversation, activeTab, chatInputText, chatInputCursorPosition));
    } catch(error) { Logger.e("AssistantPanel", "Failed to save state cache: " + error); }
  }
  function addMessage(role, content, limit, prefix = messages) {
    var message = {id: Date.now().toString(), role: role, content: content, timestamp: new Date().toISOString()};
    _recordConversation([...prefix, message], limit);
    return message;
  }
  function clearMessages(context) {
    var client = _consumer(context);
    if (!client) return false;
    _cancelChat(false); _recordConversation([], client.maxHistoryLength);
    return true;
  }
  function _chatPolicy(context) {
    var policy = _consumer(context)?.captureChat();
    if (!policy) return null;
    if (!(policy.provider === Constants.Providers.OPENAI_COMPATIBLE && policy.openaiLocal) && policy.apiKey.trim() === "") {
      errorMessage = pluginApi?.tr("errors.noApiKey"); ToastService.showError(errorMessage); return null;
    }
    if (policy.provider !== Constants.Providers.GOOGLE && policy.provider !== Constants.Providers.OPENAI_COMPATIBLE) {
      errorMessage = "Unknown provider selected. Please check settings."; return null;
    }
    return policy;
  }
  function sendMessage(text, context) {
    if (!text || text.trim() === "" || isGenerating) return false;
    var policy = _chatPolicy(context);
    if (!policy) return false;
    addMessage("user", text.trim(), policy.maxHistoryLength); _startChat(policy); return true;
  }
  function editMessage(id, text, context) {
    if (isGenerating || !text || text.trim() === "") return false;
    var index = messages.findIndex(message => message.id === id);
    if (index === -1) return false;
    var policy = _chatPolicy(context);
    if (!policy) return false;
    addMessage("user", text.trim(), policy.maxHistoryLength, messages.slice(0, index)); _startChat(policy); return true;
  }
  function regenerateLastResponse(context) {
    if (isGenerating || messages.length < 2) return false;
    var policy = _chatPolicy(context);
    if (!policy) return false;
    for (var index = messages.length - 1; index >= 0; --index) {
      if (messages[index].role !== "assistant") continue;
      _recordConversation(messages.slice(0, index), policy.maxHistoryLength); _startChat(policy); return true;
    }
    return false;
  }
  function buildConversationHistory() { return messages.map(message => ({role: message.role, content: message.content})); }
  function _startChat(policy) {
    var history = buildConversationHistory();
    var command = policy.provider === Constants.Providers.GOOGLE
      ? ProviderLogic.buildGeminiCommand(providers[Constants.Providers.GOOGLE].streamEndpoint, policy.model, policy.apiKey, policy.systemPrompt, history, policy.temperature)
      : ProviderLogic.buildOpenAICommand(policy.openaiBaseUrl, policy.apiKey, policy.model, policy.systemPrompt, history, policy.temperature);
    isGenerating = true; currentResponse = ""; errorMessage = "";
    var life = _lifetime;
    var worker = requestFactory.createObject(root, {policy: policy, curlArgs: command.args, streaming: true,
      delivered: function(source, data) { if (life.alive) root._chatData(source, data); },
      settled: function(source, code, output, errors) { if (life.alive) root._chatDone(source, code, output, errors); }});
    _chatRequest = worker; worker.start();
  }
  function _chatData(worker, data) {
    if (_chatRequest !== worker || !worker.policy.context.current()) return;
    var result = worker.policy.provider === Constants.Providers.GOOGLE ? ProviderLogic.parseGeminiStream(data) : ProviderLogic.parseOpenAIStream(data);
    if (!result) return;
    if (result.content) currentResponse += result.content;
    else if (result.error && !result.error.startsWith("Error parsing SSE")) errorMessage = result.error;
    else if (result.raw) {
      try {
        var error = JSON.parse(worker.output);
        if (error.error) errorMessage = error.error.message || "API error";
      } catch(error) {} // Incomplete JSON stream, same provider parser policy.
    }
  }
  function _chatDone(worker, code, output, errors) {
    if (_chatRequest !== worker) return;
    var policy = worker.policy;
    if (!policy.context.current()) { _cancelChat(false); return; }
    _chatRequest = null; isGenerating = false;
    if (errors && policy.provider === Constants.Providers.GOOGLE) {
      try { var error = JSON.parse(errors); if (error.error?.message) errorMessage = error.error.message; } catch(error) {}
    }
    if (worker.rejectedHttp(code)) {
      // Curl preserves the error body, but none of it is a successful message.
      currentResponse = "";
      errorMessage = ProviderLogic.requestError(output) || errorMessage || pluginApi?.tr("errors.requestFailed");
    } else if (code !== 0 && currentResponse === "") {
      if (errorMessage === "") errorMessage = pluginApi?.tr(policy.provider === Constants.Providers.OPENAI_COMPATIBLE && policy.openaiLocal ? "errors.localNotRunning" : "errors.requestFailed");
    } else {
      if (currentResponse.trim() !== "") addMessage("assistant", currentResponse.trim(), policy.maxHistoryLength);
      chatInputText = ""; chatInputCursorPosition = 0; _queueState();
    }
    worker.destroy();
  }
  function stopGeneration() { _cancelChat(true); }
  function _cancelChat(keepPartial) {
    var worker = _chatRequest; _chatRequest = null;
    if (worker) {
      worker.cancel();
      if (keepPartial && worker.policy.context.current() && currentResponse.trim() !== "") addMessage("assistant", currentResponse.trim(), worker.policy.maxHistoryLength);
      worker.destroy();
    }
    isGenerating = false; currentResponse = "";
  }
  function translate(text, target, source, context) {
    var policy = _consumer(context)?.captureTranslation(target, source);
    if (!policy) return false;
    _cancelTranslation();
    if (!text || text.trim() === "") { translatedText = ""; return true; }
    var command = policy.backend === "google" ? ProviderLogic.buildGoogleTranslateCommand(text.trim(), policy.target, policy.source)
      : policy.backend === "deepl" ? ProviderLogic.buildDeepLTranslateCommand(text.trim(), policy.target, policy.apiKey) : null;
    translationError = "";
    if (!command || command.error) { translationError = pluginApi?.tr("errors.noDeeplKey"); return false; }
    isTranslating = true;
    var life = _lifetime;
    var worker = requestFactory.createObject(root, {policy: policy, curlArgs: command.args, delivered: function() {},
      settled: function(request, code, output, errors) { if (life.alive) root._translationDone(request, code, output); }});
    _translationRequest = worker; worker.start(); return true;
  }
  function _translationDone(worker, code, output) {
    if (_translationRequest !== worker) return;
    if (!worker.policy.context.current()) { _cancelTranslation(); return; }
    _translationRequest = null; isTranslating = false;
    if (code !== 0) translationError = pluginApi?.tr("errors.translationFailed");
    else {
      var result = ProviderLogic.parseTranslateResponse(worker.policy.backend, output);
      if (result.error) translationError = result.error === "Empty response" ? pluginApi?.tr("errors.emptyResponse")
        : result.error === "Failed to parse response" ? pluginApi?.tr("errors.parseError") : result.error;
      else if (result.text) translatedText = result.text;
    }
    worker.destroy();
  }
  function _cancelTranslation() {
    var worker = _translationRequest; _translationRequest = null;
    if (worker) { worker.cancel(); worker.destroy(); }
    isTranslating = false;
  }
  IpcHandler {
    target: "plugin:assistant-panel"
    function toggle() { pluginApi?.withCurrentScreen(screen => pluginApi.togglePanel(screen)); }
    function open() { pluginApi?.withCurrentScreen(screen => pluginApi.openPanel(screen)); }
    function close() { pluginApi?.withCurrentScreen(screen => pluginApi.closePanel(screen)); }
    function send(message: string) { if (root.sendMessage(message)) ToastService.showNotice(pluginApi?.tr("toast.messageSent")); }
    function clear() { root.clearMessages(); ToastService.showNotice(pluginApi?.tr("toast.historyCleared")); }
    function translateText(text: string, targetLang: string) { root.translate(text, targetLang || root.targetLanguage); }
    function setProvider(providerName: string) {
      if (pluginApi && root.providers[providerName]) {
        pluginApi.pluginSettings.ai.provider = providerName; pluginApi.saveSettings();
        ToastService.showNotice(pluginApi?.tr("toast.providerChanged") + " " + root.providers[providerName].name);
      }
    }
    function setModel(modelName: string) {
      if (!pluginApi || !modelName) return;
      if (!pluginApi.pluginSettings.ai) pluginApi.pluginSettings.ai = {};
      pluginApi.pluginSettings.ai.model = modelName;
      try {
        var existing = pluginApi.pluginSettings.ai.models || {};
        existing[pluginApi.pluginSettings.ai.provider || root.provider] = modelName;
        pluginApi.pluginSettings.ai.models = existing;
      } catch(error) { pluginApi.pluginSettings.ai.models = {}; }
      pluginApi.saveSettings(); ToastService.showNotice(pluginApi?.tr("toast.modelChanged") + " " + modelName);
    }
  }
}
