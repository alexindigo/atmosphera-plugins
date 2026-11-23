import QtQuick

// Main-owned session identity. Views activate it but never replace its context.
Item {
  id: root
  required property var settingsContext
  required property var retire
  required property var newConnection
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView
  readonly property string autoSource: JSON.stringify([cfg.host, cfg.port, cfg.user, cfg.autoConnectOnStartup, cfg.terminalRows, cfg.terminalCols])
  property int _sourceGeneration: 0
  property bool _constructed: false
  property bool _active: false
  property bool _autoConnectAttempted: false
  property var _connection: null
  property var _pendingResize: null
  property var _tr: null
  property var _lifetime: ({alive: true})
  property string host: ""
  property int port: 22
  property string user: ""
  property string password: ""
  property string status: "idle"
  property string statusText: ""
  property string lastError: ""
  property string terminalBuffer: ""
  readonly property bool connecting: status === "connecting"
  readonly property bool connected: status === "connected"
  readonly property bool sessionActive: connecting || connected
  readonly property string targetLabel: user && host ? user + "@" + host : "Hermes"
  signal terminalOutput(string text)
  signal terminalReset()

  function tr(key, args) { return _tr ? _tr(key, args || ({})) : key; }
  function setting(key, fallback) { var value = cfg[key]; return value === undefined ? fallback : value; }
  function resetTerminal() { terminalBuffer = ""; terminalReset(); }
  function accepts(api) { return current && api && api.settingsContext === settingsContext; }
  function activate(api) {
    if (!accepts(api)) return;
    _tr = api.tr;
    if (!_active) {
      _active = true;
      host = setting("host", ""); port = setting("port", 22) || 22; user = setting("user", "");
      statusText = tr("status.disconnected");
    }
    maybeAutoConnect(api);
  }
  function maybeAutoConnect(api) {
    if (_autoConnectAttempted || !setting("autoConnectOnStartup", false)) return;
    _autoConnectAttempted = true;
    if (!setting("host", "") || !setting("user", "") || sessionActive) return;
    var generation = _sourceGeneration;
    var lifetime = _lifetime;
    var request = {host: setting("host", ""), port: setting("port", 22), user: setting("user", ""), rows: setting("terminalRows", 32), cols: setting("terminalCols", 180)};
    Qt.callLater(function() {
      if (lifetime.alive && root.accepts(api) && generation === root._sourceGeneration && !root.sessionActive && !root._connection)
        root.connect(api, request.host, request.port, request.user, "", request.rows, request.cols);
    });
  }
  function stopConnection() {
    var previous = _connection;
    _connection = null; // Fence callbacks before termination can emit anything.
    if (previous) previous.retire();
  }
  function connect(api, targetHost, targetPort, targetUser, targetPassword, rows, cols) {
    if (!accepts(api)) return false;
    ++_sourceGeneration; // A queued automatic attempt cannot replace manual intent.
    host = String(targetHost || "").trim();
    port = Math.max(1, Math.min(65535, Number(targetPort || 22)));
    user = String(targetUser || "").trim(); password = String(targetPassword || ""); lastError = "";
    if (!host || !user) {
      statusText = tr("status.missingTarget"); lastError = statusText;
      return false;
    }
    if (setting("rememberLastTarget", true)) {
      api.pluginSettings.host = host; api.pluginSettings.port = port; api.pluginSettings.user = user;
      api.saveSettings();
    }
    stopConnection(); resetTerminal(); status = "connecting";
    statusText = tr("status.connecting", {target: targetLabel});
    _connection = newConnection(root, JSON.stringify({type: "connect", host: host, port: port, user: user, password: password,
      rows: Math.max(1, Number(rows || setting("terminalRows", 32))), cols: Math.max(1, Number(cols || setting("terminalCols", 180)))}) + "\n");
    _connection.start();
    return true;
  }
  function acceptsConnection(connection) { return current && _connection === connection; }
  function send(text) {
    if (current && _connection && sessionActive)
      _connection.write(JSON.stringify({type: "input", text: String(text || "")}) + "\n");
  }
  function resize(rows, cols) {
    var payload = JSON.stringify({type: "resize", rows: Math.max(1, Number(rows || setting("terminalRows", 32))), cols: Math.max(1, Number(cols || setting("terminalCols", 180)))}) + "\n";
    if (current && _connection && sessionActive) _connection.write(payload);
    else if (current) _pendingResize = payload;
  }
  function started(connection) {
    if (!acceptsConnection(connection)) return;
    connection.write(connection.request);
    if (_pendingResize) { connection.write(_pendingResize); _pendingResize = null; }
  }
  function disconnect() {
    ++_sourceGeneration; _pendingResize = null; stopConnection();
    status = "idle"; statusText = tr("status.disconnected"); lastError = ""; password = ""; resetTerminal();
  }
  function handleMessage(connection, line) {
    if (!acceptsConnection(connection)) return;
    var msg;
    try { msg = JSON.parse(String(line || "").trim()); } catch (error) { return; }
    if (msg.type === "output") {
      var text = String(msg.text || ""); terminalBuffer += text; terminalOutput(text);
    } else if (msg.type === "status") {
      if (msg.status === "idle" && connecting) return;
      status = String(msg.status || status); statusText = String(msg.message || statusText);
    } else if (msg.type === "error") {
      lastError = String(msg.message || tr("status.error")); statusText = lastError;
    } else if (msg.type === "exit") disconnect();
  }
  function bridgeError(connection, text) {
    if (!acceptsConnection(connection) || !text.trim()) return;
    lastError = text.trim(); statusText = lastError;
  }
  function exited(connection) {
    if (!acceptsConnection(connection)) return;
    stopConnection();
    if (sessionActive) { status = "idle"; statusText = tr("status.bridgeExited"); password = ""; resetTerminal(); }
  }
  onAutoSourceChanged: ++_sourceGeneration
  onCurrentChanged: if (_constructed && !current) { disconnect(); retire(root); }
  Component.onCompleted: _constructed = true
  Component.onDestruction: { _lifetime.alive = false; stopConnection(); }
}
