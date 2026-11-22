import QtQuick
import Quickshell
import qs.Commons

Scope {
  id: root
  property var pluginApi: null
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property bool retired: false
  property var _lifetime: ({alive: true})
  property var _settingsConsumers: new Map()
  property var connection: null
  property var requestedContext: null
  property var pendingBoundary: null
  property var retiringConnection: null
  property var pendingModel: null
  property var activeModel: null
  readonly property bool boundaryCurrent: pendingBoundary?.policy.context.current() ?? true
  onBoundaryCurrentChanged: if (!boundaryCurrent) pendingBoundary = null
  readonly property var appliedPolicy: connection?.policy ?? null
  readonly property var requestedPolicy: requestedContext?.current() ? capturePolicy(requestedContext) : null
  readonly property bool pendingRestart: !!appliedPolicy && !!requestedPolicy && sourceKey(appliedPolicy) !== sourceKey(requestedPolicy)
  readonly property string bridgeHost: appliedPolicy?.host ?? "127.0.0.1"
  readonly property int bridgePort: appliedPolicy?.port ?? 19777
  readonly property string bridgeToken: connection?.token ?? ""
  readonly property bool clientOnlyMode: appliedPolicy?.remote ?? false
  readonly property string expandedStateFile: appliedPolicy?.stateFile ?? ""
  readonly property string expandedHermesHome: appliedPolicy?.hermesHome ?? ""
  readonly property string hermesCommand: appliedPolicy?.command ?? "hermes"
  readonly property bool autoStartBridge: appliedPolicy?.autoBridge ?? false
  readonly property bool autoStartGateway: appliedPolicy?.autoGateway ?? false
  readonly property int statusPollIntervalSec: settingsConsumer?.pollSeconds ?? 30
  readonly property string bridgeScript: (pluginApi?.pluginDir || ".") + "/scripts/hermes_bridge.py"
  property var state: ({bridge:{status:"offline",error:""},hermes:{status:"unknown"},session:{id:"",stored_id:"",running:false},messages:[],events:[],approval:{pending:false},summary:{}})

  Component { id: clientFactory; HermesClient {} }
  Component { id: connectionFactory; HermesConnection {} }
  function settingsConsumerFor(context) {
    if (retired || !context?.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    const life = _lifetime;
    const client = clientFactory.createObject(root, {
      settingsContext:context, defaults:defaults,
      poll:function() { if (life.alive) root.ensureBridge(context); },
      retire:function(value) { if (life.alive) root._settingsConsumers.delete(context); value.destroy(); }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  function expandHome(path) {
    if (path === "~") return Quickshell.env("HOME") || path;
    return path.startsWith("~/") ? (Quickshell.env("HOME") || "") + path.slice(1) : path;
  }
  function capturePolicy(context) {
    context = context || pluginApi?.settingsContext;
    if (retired || !context?.current()) return null;
    const client = settingsConsumerFor(context);
    const cfg = context.settingsView;
    const remote = client.remote;
    return {context:context, remote:remote,
      host:remote ? String(cfg.bridgeHost ?? defaults.bridgeHost ?? "127.0.0.1") : "127.0.0.1", port:client.bridgePort,
      stateFile:expandHome(String(cfg.stateFile ?? defaults.stateFile ?? "~/.cache/noctalia-hermes/state.json")),
      hermesHome:expandHome(String(cfg.hermesHome ?? defaults.hermesHome ?? "~/.hermes")),
      command:String(cfg.hermesCommand ?? defaults.hermesCommand ?? "hermes"),
      manualToken:remote ? String(cfg.bridgeTokenManual ?? defaults.bridgeTokenManual ?? "") : "",
      autoBridge:Boolean(cfg.autoStartBridge ?? defaults.autoStartBridge ?? true),
      autoGateway:Boolean(cfg.autoStartGateway ?? defaults.autoStartGateway ?? true), pollSeconds:client.pollSeconds,
      provider:String(cfg.defaultProvider ?? defaults.defaultProvider ?? ""), model:String(cfg.defaultModel ?? defaults.defaultModel ?? "")};
  }
  function sourceKey(policy) {
    return policy ? JSON.stringify([policy.remote,policy.host,policy.port,policy.stateFile,policy.hermesHome,policy.command,policy.manualToken,policy.autoBridge,policy.autoGateway]) : "";
  }
  function applySettings(context, trimModel) {
    const policy = capturePolicy(context);
    if (!policy) return false;
    requestedContext = policy.context;
    pendingModel = {policy:policy,provider:trimModel ? policy.provider.trim() : policy.provider,model:trimModel ? policy.model.trim() : policy.model,persist:false};
    // Saving never replaces a chat or its matching process/readers/token.
    if (!connection) return activatePolicy(policy);
    if (sourceKey(policy) === sourceKey(appliedPolicy)) flushModel();
    return true;
  }
  function activatePolicy(policy) {
    if (!policy?.context.current() || retiringConnection) return false;
    requestedContext = policy.context;
    const life = _lifetime;
    const next = connectionFactory.createObject(root, {
      policy:policy, script:bridgeScript,
      publish:function(data) { if (life.alive && root.connection === next) root.state = data; },
      reportError:function(message) { if (life.alive && root.connection === next) root.setBridgeError(message); },
      online:function() { if (life.alive && root.connection === next) { root.autoConfigure(); root.dispatchBoundary(); root.flushModel(); } },
      stopped:function(value) { if (life.alive) root.connectionStopped(value); }
    });
    connection = next;
    next.ensureBridge();
    return true;
  }
  function connectionStopped(value) {
    if (activeModel?.connection === value) activeModel = null;
    if (connection === value) {
      connection = null;
      setBridgeError("Bridge settings owner retired");
    }
    if (retiringConnection === value) retiringConnection = null;
    value.destroy();
    const boundary = pendingBoundary;
    if (boundary?.policy.context.current()) activatePolicy(boundary.policy);
    else pendingBoundary = null;
  }
  function replaceSession(path, payload, context) {
    const policy = capturePolicy(context);
    if (!policy || pendingBoundary || retiringConnection) return false;
    requestedContext = policy.context;
    pendingModel = {policy:policy,provider:policy.provider,model:policy.model,persist:false};
    pendingBoundary = {path:path,payload:payload,policy:policy};
    if (connection && sourceKey(policy) !== sourceKey(appliedPolicy)) {
      retiringConnection = connection;
      activeModel = null;
      connection = null;
      retiringConnection.retireConnection();
    } else if (!connection) activatePolicy(policy);
    else dispatchBoundary();
    return true;
  }
  function dispatchBoundary() {
    const boundary = pendingBoundary;
    const active = connection;
    if (!boundary || !active?.ready || !boundary.policy.context.current()) return;
    // Leave the boundary busy until its own endpoint acknowledges it.
    if (boundary.dispatched) return;
    boundary.dispatched = true;
    const life = _lifetime;
    active.requestJson("POST", boundary.path, boundary.payload, function(data) {
      if (!life.alive || root.pendingBoundary !== boundary) return;
      root.pendingBoundary = null;
      if (!data) return;
      active.acceptState(data.state || data);
      root.flushModel();
    }, boundary.policy.context);
  }
  function ensureBridge(context) {
    context = context || pluginApi?.settingsContext;
    if (!retired && context?.current()) connection?.ensureBridge();
  }
  function refreshState(context) {
    context = context || pluginApi?.settingsContext;
    if (!retired && context?.current()) connection?.refreshState(context);
  }
  function startBridge() { connection?.startBridge(); }
  function autoConfigure() {
    const active = connection;
    const api = pluginApi;
    // Detection is existing plugin-level initialization, never an instance save
    // or a remote server's home/command copied into the local shared owner.
    if (!active || active.policy.remote || active.policy.context !== api?.settingsContext || (api.pluginSettings.configured ?? false)) return;
    const life = _lifetime;
    active.requestJson("GET", "/detect", null, function(data) {
      if (!life.alive || root.connection !== active || !data || !api.settingsContext.current()) return;
      const s = api.pluginSettings;
      if (data.hermesHome && data.hermesHomeExists) s.hermesHome = data.hermesHome;
      if (data.hermesCommand) s.hermesCommand = data.hermesCommand;
      if (data.model?.name) s.defaultModel = data.model.name;
      if (data.model?.provider) s.defaultProvider = data.model.provider;
      s.configured = true;
      api.saveSettings();
    }, api.settingsContext);
  }
  function requestAction(path, payload, context) {
    context = context || pluginApi?.settingsContext;
    const active = connection;
    if (retired || !context?.current() || !active || pendingBoundary) return false;
    const life = _lifetime;
    return active.requestJson("POST", path, payload, function(data) {
      if (!life.alive || root.connection !== active || !data) return;
      if (data.state) active.acceptState(data.state);
      else if (path.startsWith("/gateway/")) active.refreshState(context);
    }, context);
  }
  function startGateway(context) { return requestAction("/gateway/start", {}, context); }
  function stopGateway(context) { return requestAction("/gateway/stop", {}, context); }
  function createSession(context) { return replaceSession("/session/create", {}, context); }
  function resumeSession(sessionId, context) { return replaceSession("/session/resume", {session_id:sessionId}, context); }
  function sendPrompt(text, context) { return requestAction("/prompt", {text:text}, context); }
  function interrupt(context) { return requestAction("/interrupt", {}, context); }
  function respondApproval(choice, all, context) { return requestAction("/approval", {choice:choice,all:all || false}, context); }
  function oneShot(text, context) { return requestAction("/oneshot", {text:text}, context); }
  function setModel(provider, model, persist, context) {
    const policy = capturePolicy(context);
    if (!policy || !model) return false;
    pendingModel = {policy:policy,provider:provider || "",model:model,persist:persist || false};
    flushModel();
    return true;
  }
  function flushModel() {
    const request = pendingModel;
    const active = connection;
    if (!request || activeModel || pendingBoundary || !active?.ready || !request.policy.context.current() || sourceKey(request.policy) !== sourceKey(appliedPolicy)) return;
    pendingModel = null;
    if (!request.model) return;
    request.connection = active;
    activeModel = request;
    const life = _lifetime;
    active.requestJson("POST", "/model", {provider:request.provider,model:request.model,persist:request.persist}, function() {}, request.policy.context, function(data) {
      if (!life.alive || root.connection !== active || root.activeModel !== request) return;
      root.activeModel = null;
      if (data?.state) active.acceptState(data.state);
      // A later accepted Apply replaces desired input while this request waits;
      // it is reconciled after settlement, not dropped or replayed as an action.
      if (root.pendingModel) root.flushModel();
      else if (!data && request.policy.context.current()) root.pendingModel = request;
    });
  }
  function listSessions(callback, context) {
    context = context || pluginApi?.settingsContext;
    if (retired || !context?.current() || !connection) return false;
    return connection.requestJson("GET", "/sessions", null, function(data) { callback(data?.sessions || []); }, context);
  }
  function setBridgeError(message) {
    const next = JSON.parse(JSON.stringify(state));
    next.bridge = {status:"offline",error:message};
    state = next;
  }
  function clearChat() {
    const next = JSON.parse(JSON.stringify(state));
    next.messages = []; next.events = [];
    next.approval = {pending:false,message:"",tool_name:"",request:{}};
    next.session.running = false;
    state = next;
  }

  property var pinnedPanelApi: null
  property bool pinnedPanelVisible: false
  property var pinnedPanelScreen: null
  readonly property bool pinnedPanelRequested: !!pinnedPanelApi && pinnedPanelApi.settingsContext.current() && (pinnedPanelApi.pluginSettings.panelPinned ?? defaults.panelPinned ?? false)
  function openPreferredPanel(screen, buttonItem, runtimeApi) {
    const api = runtimeApi || pluginApi;
    if (!api?.settingsContext.current()) return false;
    if (api.pluginSettings.panelPinned ?? defaults.panelPinned ?? false) return openPinnedPanel(screen, api);
    const life = _lifetime;
    if (screen) api.openPanel(screen, buttonItem || null);
    else api.withCurrentScreen(function(value) { if (life.alive && api.settingsContext.current() && value) api.openPanel(value, buttonItem || null); });
    return true;
  }
  function openPinnedPanel(screen, runtimeApi) {
    const api = runtimeApi || pluginApi;
    if (!api?.settingsContext.current()) return false;
    const life = _lifetime;
    function show(value) {
      if (!life.alive || !api.settingsContext.current() || !value) return;
      root.pinnedPanelApi = api;
      root.pinnedPanelScreen = value;
      root.pinnedPanelVisible = true;
      root.refreshState(api.settingsContext);
    }
    if (screen) show(screen); else api.withCurrentScreen(show);
    return true;
  }
  function closePinnedPanel(context) {
    if (!context || context === pinnedPanelApi?.settingsContext) pinnedPanelVisible = false;
  }
  function setPinnedPanelRequested(value, runtimeApi) {
    const api = runtimeApi || pluginApi;
    if (!api?.settingsContext.current()) return false;
    if (value) {
      openPinnedPanel(api.panelOpenScreen, api);
      if (api.panelOpenScreen) api.closePanel(api.panelOpenScreen);
    } else closePinnedPanel(api.settingsContext);
    return true;
  }
  PinnedPanelWindow {
    pluginApi: root.pinnedPanelApi
    panelScreen: root.pinnedPanelScreen
    active: root.pinnedPanelRequested && root.pinnedPanelVisible
  }
  Component.onCompleted: {
    const policy = capturePolicy(pluginApi?.settingsContext);
    if (policy) activatePolicy(policy);
    if (pluginApi?.pluginSettings.panelPinned ?? defaults.panelPinned ?? false) openPinnedPanel(null, pluginApi);
  }
  Component.onDestruction: {
    _lifetime.alive = false;
    retired = true;
    pendingBoundary = null;
    pendingModel = null;
    activeModel = null;
    connection?.retireConnection();
    retiringConnection?.retireConnection();
  }
}
