import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Plugins
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property bool retired: false
  property var servicePolicy: null
  property var pendingPolicy: null
  property var requests: []
  property var _settingsConsumers: new Map()
  readonly property string bindAddress: servicePolicy?.host ?? ""
  readonly property int port: servicePolicy?.port ?? 0
  readonly property string token: servicePolicy?.token ?? ""
  readonly property string serverUrl: "http://" + bindAddress + ":" + port
  readonly property string scriptPath: (pluginApi?.pluginDir || "") + "/server.py"

  // Preserve the original QML int boundary after Number(), before argv and
  // seconds scaling. These are admission slots, never a preference store.
  property int admittedPort: 0
  function capturePolicy(context) {
    context = context || pluginApi?.settingsContext;
    if (retired || !context?.current()) return null;
    const values = context.settingsView;
    admittedPort = Number(values.port ?? defaults.port ?? 55854);
    return {context: context, host: String(values.bindAddress ?? defaults.bindAddress ?? "127.0.0.1"),
      port: admittedPort, token: String(values.token ?? defaults.token ?? "")};
  }
  Component { id: pollFactory; PluginSettingsPoller {} }
  function settingsConsumerFor(context) {
    if (retired || !context?.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    const client = pollFactory.createObject(root, {
      settingsContext: context,
      sourceInterval: Qt.binding(function() { return Math.max(1, Number(context.settingsView.pollIntervalSec ?? defaults.pollIntervalSec ?? 2)); }),
      intervalScale: 1000,
      pollingEnabled: Qt.binding(function() { return !root.retired && (root.serviceRunning || root.serviceStarting); }),
      requestRefresh: function() { root.refresh(context); },
      retire: function(value) { root._settingsConsumers.delete(context); value.destroy(); }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property int pollIntervalSec: settingsConsumer?.sourceInterval ?? 2
  readonly property bool serviceCurrent: !retired && (servicePolicy?.context?.current() ?? false)
  onServiceCurrentChanged: {
    const policy = servicePolicy;
    if (!serviceCurrent && policy) Qt.callLater(function() {
      if (!root) return;
      if (root.servicePolicy === policy && !root.policyCurrent(policy)) root.stopService();
    });
  }
  readonly property bool pendingCurrent: !retired && (pendingPolicy?.context?.current() ?? false)
  onPendingCurrentChanged: {
    const policy = pendingPolicy;
    if (!pendingCurrent && policy) Qt.callLater(function() {
      if (!root) return;
      if (root.pendingPolicy === policy && !policy.context.current()) { root.pendingPolicy = null; restartDelay.stop(); }
    });
  }

  property bool serviceRunning: false
  property bool serviceStarting: false
  property string serviceError: ""
  property int runningCount: 0
  property var agents: []
  property int lastUpdatedAt: 0

  Component.onCompleted: {
    Logger.i("AgentSessionStatus", "Plugin loaded")
    restartService()
  }

  Component.onDestruction: {
    retired = true
    stopService()
  }

  Timer {
    id: restartDelay
    interval: 300
    repeat: false
    onTriggered: root.startService()
  }

  IpcHandler {
    target: "plugin:agent-session-status"

    function refresh() {
      root.refreshAndPrune()
    }

    function restart() {
      root.restartService()
    }

    function toggle() {
      if (root.pluginApi) {
        root.pluginApi.withCurrentScreen(screen => {
          root.pluginApi.togglePanel(screen)
        })
      }
    }
  }

  Process {
    id: serviceProcess
    stdout: StdioCollector {
      onStreamFinished: {
        var out = (text || "").trim()
        if (out) Logger.i("AgentSessionStatus", out)
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        var err = (text || "").trim()
        if (err) {
          root.serviceError = err
          Logger.w("AgentSessionStatus", err)
        }
      }
    }
    onStarted: {
      root.serviceStarting = true
      root.serviceError = ""
      const admitted = root.servicePolicy
      Qt.callLater(function() { if (root && root.policyCurrent(admitted)) root.refresh(); })
    }
    onExited: (exitCode, exitStatus) => {
      root.serviceRunning = false
      root.serviceStarting = false
      if (exitCode !== 0 && root.serviceCurrent) {
        root.serviceError = pluginApi?.tr("service.exited", { code: exitCode })
      }
    }
  }

  function startService() {
    if (!pendingCurrent) return
    // Process.running stays true until exit; no new server may bind before it.
    if (serviceProcess.running) { restartDelay.restart(); return; }
    servicePolicy = pendingPolicy
    pendingPolicy = null
    if (!root.token || root.token.trim() === "") {
      root.serviceError = pluginApi?.tr("service.missingToken")
      root.serviceRunning = false
      return
    }

    serviceProcess.command = [
      "python3",
      root.scriptPath,
      "--host",
      root.bindAddress,
      "--port",
      root.port.toString(),
      "--token",
      root.token
    ]
    serviceProcess.running = true
  }

  function stopService() {
    servicePolicy = null
    pendingPolicy = null
    restartDelay.stop()
    const old = requests
    requests = []
    for (const request of old) request.abort()
    if (serviceProcess.running) {
      serviceProcess.signal(15)
      serviceProcess.running = false
    }
    serviceRunning = false
    serviceStarting = false
    runningCount = 0
    agents = []
    lastUpdatedAt = 0
  }

  function restartService(context) {
    const policy = capturePolicy(context)
    if (!policy) return false
    stopService()
    pendingPolicy = policy
    runningCount = 0
    agents = []
    lastUpdatedAt = 0
    restartDelay.restart()
    return true
  }

  function policyCurrent(policy) {
    return !retired && policy && policy === servicePolicy && policy.context.current();
  }

  function applySnapshot(payload) {
    root.runningCount = Number(payload.runningCount ?? 0)
    root.agents = payload.agents ?? []
    root.lastUpdatedAt = Number(payload.updatedAt ?? 0)
    root.serviceRunning = true
    root.serviceStarting = false
    root.serviceError = ""
  }

  function refresh(context) {
    return requestSnapshot(false, context);
  }

  function refreshAndPrune(context) {
    return requestSnapshot(true, context);
  }

  function requestSnapshot(prune, context) {
    context = context || pluginApi?.settingsContext;
    const policy = servicePolicy;
    if (!context?.current() || !policyCurrent(policy)) return false;
    var xhr = new XMLHttpRequest()
    requests = requests.concat([xhr]);
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== XMLHttpRequest.DONE) return
      requests = requests.filter(function(request) { return request !== xhr; });
      if (!context.current() || !policyCurrent(policy)) return;
      if (xhr.status !== 200) {
        root.serviceError = pluginApi?.tr("service.refreshFailed", { status: xhr.status })
        return
      }
      try {
        var payload = JSON.parse(xhr.responseText)
        root.applySnapshot(prune ? (payload.snapshot ?? payload) : payload)
      } catch (e) {
        root.serviceError = pluginApi?.tr("service.badResponse")
      }
    }
    xhr.onerror = function() {
      if (context.current() && policyCurrent(policy)) root.serviceError = pluginApi?.tr("service.unreachable")
    }
    const url = "http://" + policy.host + ":" + policy.port;
    xhr.open(prune ? "POST" : "GET", url + (prune ? "/sessions/prune-inactive" : "/sessions"))
    if (prune) xhr.setRequestHeader("Authorization", "Bearer " + policy.token)
    xhr.send()
    return true;
  }
}
