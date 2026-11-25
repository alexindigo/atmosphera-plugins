import QtQuick

Item {
  id: root
  required property var settingsContext
  required property var observation
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView
  readonly property bool showNotifications: cfg.showNotifications ?? true
  // Preserve the old int boundary after seconds-to-milliseconds conversion.
  readonly property int pollInterval: (cfg.pollInterval ?? 5) * 1000
  property var _panels: new Map()
  readonly property bool panelOpen: _panels.size > 0
  readonly property bool logStreamActive: {
    var requested = false;
    _panels.forEach(function(logs) { requested = requested || logs; });
    return requested;
  }
  function registerPanel(token, logs) {
    if (!current) return;
    var panels = new Map();
    _panels.forEach(function(value, key) { panels.set(key, value); });
    panels.set(token, logs);
    _panels = panels;
    observation.updatePanelDemand();
  }
  function unregisterPanel(token) {
    var panels = new Map();
    _panels.forEach(function(value, key) { if (key !== token) panels.set(key, value); });
    _panels = panels;
    observation.updatePanelDemand();
  }
  Timer {
    interval: root.pollInterval
    running: root.current
    repeat: true
    onTriggered: root.observation.refresh()
  }
  Timer {
    interval: Math.max(root.pollInterval * 3, 15000)
    running: root.current && root.panelOpen
    repeat: true
    onTriggered: root.observation.refreshFull()
  }
  readonly property var configList: observation.configList
  readonly property var sessionList: observation.sessionList
  readonly property var configDetails: observation.configDetails
  readonly property var sessionStats: observation.sessionStats
  readonly property var configDump: observation.configDump
  readonly property var sessionLogs: observation.sessionLogs
  readonly property real connectedCount: observation.connectedCount
  readonly property bool isLoading: observation.isLoading
  function refresh() { if (current) observation.refresh(); }
  function refreshFull() { if (current) observation.refreshFull(); }
  function formatBytes(bytes) { return observation.formatBytes(bytes); }
  function getSessionStats(path) { return observation.getSessionStats(path); }
  function getConfigDump(path) { return observation.getConfigDump(path); }
  function isConfigPersistent(path) { return observation.isConfigPersistent(path); }
  function isPending(path) { return observation.isPending(path); }
  function isSessionActive(path) { return observation.isSessionActive(path); }
  function clearLogs() { if (current) observation.clearLogs(); }
  function loadConfigDetails(path) { if (current) observation.loadConfigDetails(path); }
  function connectTo(path) { if (current) observation.connectTo(path, showNotifications); }
  function disconnectFrom(path) { if (current) observation.disconnectFrom(path, showNotifications); }
  function restartSession(path) { if (current) observation.restartSession(path, showNotifications); }
  function importConfig(path, name, persistent) { if (current) observation.importConfig(path, name, persistent, showNotifications); }
  function renameConfig(path, name) { if (current) observation.renameConfig(path, name, showNotifications); }
  function deleteConfig(path) { if (current) observation.deleteConfig(path, showNotifications); }
  property bool _constructed: false
  onCurrentChanged: if (!current && _constructed) retire(root)
  Component.onCompleted: _constructed = true
}
