import QtQuick
import Quickshell
import Quickshell.Io

// One immutable applied source generation owns its Process, readers and XHRs.
Scope {
  id: root
  required property var policy
  required property string script
  required property var publish
  required property var reportError
  required property var online
  required property var stopped
  property var _lifetime: ({alive:true})
  property bool retired: false
  readonly property bool current: !retired && policy.context.current()
  property string localToken: ""
  readonly property string token: policy.remote ? policy.manualToken : localToken
  property bool ready: false
  property bool loadingToken: false
  property bool gatewayPending: false
  property bool sessionRunning: false
  property var requests: []
  property int tokenGeneration: 0
  property int stateRequest: 0
  property bool _stopped: false
  function cancelRequests(notify, credentialsOnly) {
    const old = requests; requests = [];
    for (const request of old) {
      if (credentialsOnly && !request.credentialBound) { requests = requests.concat([request]); continue; }
      request.xhr.onreadystatechange = null; request.xhr.abort();
      if (notify && current && request.settled) request.settled(null);
      if (notify && current && request.context.current()) request.callback(null);
    }
  }
  function retireConnection() {
    if (retired) return;
    retired = true;
    _lifetime.alive = false;
    retry.stop(); busyPoll.stop();
    cancelRequests();
    ready = false;
    if (bridgeProcess.running) bridgeProcess.running = false;
    else finishStop();
  }
  function finishStop() {
    if (_stopped) return;
    _stopped = true;
    stopped(root);
  }
  onCurrentChanged: if (!current && !retired) Qt.callLater(function() { if (root && !root.current) root.retireConnection(); })
  function requestJson(method, path, payload, callback, context, settled) {
    context = context || policy.context;
    if (!current || !context.current()) return false;
    const life = _lifetime;
    const generation = tokenGeneration;
    const credentialBound = path !== "/health" && path !== "/detect";
    const xhr = new XMLHttpRequest();
    requests = requests.concat([{xhr:xhr,callback:callback,context:context,credentialBound:credentialBound,settled:settled}]);
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== XMLHttpRequest.DONE || !life.alive) return;
      root.requests = root.requests.filter(function(value) { return value.xhr !== xhr; });
      if (!root.current || (credentialBound && generation !== root.tokenGeneration)) return;
      if (!context.current()) { if (settled) settled(null); return; }
      let data = null;
      if (xhr.status >= 200 && xhr.status < 300) {
        try { data = JSON.parse(xhr.responseText); }
        catch (error) { root.reportError("Invalid bridge response"); }
      } else root.reportError(xhr.status === 403 ? "Authentication failed: wrong bridge token" : "Bridge request failed: " + xhr.status);
      // Callback errors are not JSON errors and must never cause a second call.
      if (settled) settled(data);
      callback(data);
    };
    xhr.open(method, "http://" + policy.host + ":" + policy.port + path);
    if (token) xhr.setRequestHeader("X-Bridge-Token", token);
    if (method === "POST") {
      xhr.setRequestHeader("Content-Type", "application/json");
      xhr.send(JSON.stringify(payload || {}));
    } else xhr.send();
    return true;
  }
  function acceptState(data) {
    if (!current || !data) return;
    sessionRunning = Boolean(data.session?.running);
    publish(data);
    if (gatewayPending) {
      gatewayPending = false;
      const status = data.summary?.gateway?.status || data.hermes?.gateway_status || "";
      if (!policy.remote && policy.autoGateway && ["offline","stopped","unknown",""].includes(status))
        requestJson("POST", "/gateway/start", {}, function(value) { if (value) root.refreshState(); });
    }
  }
  function refreshState(context) {
    if (!current) return false;
    const sequence = ++stateRequest;
    return requestJson("GET", "/state", null, function(data) { if (sequence === root.stateRequest) root.acceptState(data); }, context);
  }
  function becameOnline() {
    if (!current) return;
    retry.stop(); retry.attempts = 0;
    if (ready || loadingToken) return;
    gatewayPending = !policy.remote;
    if (policy.remote) { ready = true; refreshState(); online(); }
    else {
      // The process may have just created the parent directory. A watcher
      // opened before that directory existed cannot observe the new file.
      stateFile.reload();
      loadingToken = true; tokenFile.reload();
    }
  }
  function ensureBridge() {
    if (!current || retry.running) return;
    requestJson("GET", "/health", null, function(data) {
      if (data?.bridge?.status === "online") {
        if (root.ready) root.refreshState(); else root.becameOnline();
      } else if (!root.policy.remote && root.policy.autoBridge) {
        root.startBridge(); retry.start();
      }
    });
  }
  function startBridge() {
    if (!current || policy.remote || bridgeProcess.running) return;
    bridgeProcess.command = ["python3",script,"--host",policy.host,"--port",String(policy.port),
      "--state-file",policy.stateFile,"--hermes-home",policy.hermesHome,"--hermes-command",policy.command];
    bridgeProcess.running = true;
  }
  Process {
    id: bridgeProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: function(code) {
      if (root.retired) root.finishStop();
      else if (code !== 0 && root.current) root.reportError("Bridge exited: " + code);
    }
  }
  FileView {
    id: stateFile
    path: root.current && !root.policy.remote ? root.policy.stateFile : ""
    watchChanges: root.current && !root.policy.remote
    printErrors: false
    onFileChanged: { root.stateRequest++; reload(); }
    onLoaded: {
      if (!root.current || root.policy.remote) return;
      root.stateRequest++;
      try { const text = stateFile.text(); if (text.trim()) root.acceptState(JSON.parse(text)); }
      catch (error) { root.reportError("Invalid state file"); }
    }
    onLoadFailed: if (root.current && root.ready) root.refreshState()
  }
  FileView {
    id: tokenFile
    path: root.current && !root.policy.remote ? root.policy.stateFile.replace(/\/[^/]*$/, "/bridge.token") : ""
    watchChanges: root.current && !root.policy.remote
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      if (!root.current || root.policy.remote) return;
      const value = tokenFile.text().trim();
      if (value !== root.localToken) { root.tokenGeneration++; root.localToken = value; root.cancelRequests(true, true); }
      if (root.loadingToken) { root.loadingToken = false; root.ready = true; root.refreshState(); root.online(); }
    }
    onLoadFailed: if (root.current) root.loadingToken = false
  }
  Timer {
    id: busyPoll
    interval: root.sessionRunning ? 1500 : root.policy.pollSeconds * 1000
    running: root.current && root.policy.remote
    repeat: true
    onTriggered: root.ensureBridge()
  }
  Timer {
    id: retry
    interval: 500
    repeat: true
    property int attempts: 0
    onTriggered: {
      attempts++;
      if (attempts > 20) { stop(); attempts = 0; root.reportError("Bridge failed to start"); return; }
      root.requestJson("GET", "/health", null, function(data) { if (data?.bridge?.status === "online") root.becameOnline(); });
    }
  }
  Component.onDestruction: { _lifetime.alive = false; cancelRequests(); }
}
