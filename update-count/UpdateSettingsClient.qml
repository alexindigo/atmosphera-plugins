import QtQuick

Item {
  id: root
  required property var pluginApi
  required property var settingsContext
  required property var domain
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
  readonly property int updateIntervalMinutes: cfg.updateIntervalMinutes || defaults.updateIntervalMinutes || 30
  readonly property string updateTerminalCommand: cfg.updateTerminalCommand || defaults.updateTerminalCommand || ""
  readonly property var updater: domain.updater
  readonly property var customUpdater: ({name: "custom", cmdGetNumUpdates: cfg.customCmdGetNumUpdates || "", cmdDoSystemUpdate: cfg.customCmdDoSystemUpdate || ""})
  readonly property string _queryCommand: customUpdater.cmdGetNumUpdates || updater?.cmdGetNumUpdates || ""
  property bool _constructed: false
  property var _worker: null
  readonly property int updateCount: _worker?.updateCount ?? 0
  Component { id: workerFactory; UpdateCountQueryWorker {} }
  function _retireWorker() {
    if (!_worker) return;
    var old = _worker;
    _worker = null;
    old.stop(); old.destroy();
  }
  function _replaceQuery() {
    if (!_constructed) return;
    _retireWorker();
    if (!current || !_queryCommand) return;
    _worker = workerFactory.createObject(root, {queryCommand: _queryCommand});
  }
  function startGetNumUpdates() { if (current) _worker?.refresh(); }
  function startDoSystemUpdate() {
    if (current)
      domain.performSystemUpdate(customUpdater.cmdDoSystemUpdate || updater?.cmdDoSystemUpdate || "echo 'No update cmd found.'", updateTerminalCommand);
  }
  Timer {
    id: poll
    interval: root.updateIntervalMinutes * 60000
    running: root.current
    repeat: true
    onTriggered: root.startGetNumUpdates()
  }
  on_QueryCommandChanged: _replaceQuery()
  onCurrentChanged: if (!current && _constructed) { poll.stop(); _retireWorker(); retire(root); }
  Component.onCompleted: { _constructed = true; _replaceQuery(); }
  Component.onDestruction: { poll.stop(); _retireWorker(); }
}
