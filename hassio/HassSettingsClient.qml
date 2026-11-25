import QtQuick

Item {
  id: root
  required property var pluginApi
  required property var settingsContext
  required property var retire
  readonly property bool current: settingsContext?.current() ?? false
  readonly property var cfg: settingsContext?.settingsView ?? ({})
  readonly property string haUrl: cfg.haUrl ?? ""
  readonly property string haToken: cfg.haToken ?? ""
  readonly property string _queryIdentity: JSON.stringify([haUrl, haToken])
  readonly property string _pinsIdentity: JSON.stringify(cfg.entities ?? [])
  property bool _constructed: false
  property var _worker: null
  readonly property bool connected: _worker?.connected ?? false
  readonly property bool authenticated: _worker?.authenticated ?? false
  readonly property bool authFailed: _worker?.authFailed ?? false
  readonly property bool isReconnecting: _worker?.isReconnecting ?? false
  readonly property var entities: _worker?.entities ?? null
  signal entityUpdated(string entity_id)
  signal sourceChanged()
  Connections {
    target: root._worker
    function onEntityUpdated(entity_id) { root.entityUpdated(entity_id); }
  }
  Component { id: workerFactory; HassQueryWorker {} }
  function _retireWorker() {
    if (!_worker) return;
    var old = _worker;
    _worker = null;
    old.stop();
    old.destroy();
    sourceChanged();
  }
  function _replaceQuery() {
    if (!_constructed) return;
    _retireWorker();
    if (!current) return;
    _worker = workerFactory.createObject(root, {pluginApi: pluginApi, settingsContext: settingsContext, haUrl: haUrl, haToken: haToken});
  }
  function reconnect() { if (current) _worker?.reconnect(); }
  function reloadSettings() { /* Source bindings replace the selected generation. */ }
  function refreshEntities() { if (current) _worker?.refreshEntities(); }
  function getAllStates(callback) { if (current) _worker?.getAllStates(callback); }
  function callService(domain, service, entity_id) { if (current) _worker?.callService(domain, service, entity_id); }
  function callLightService(entity_id, brightness, color_temp) { if (current) _worker?.callLightService(entity_id, brightness, color_temp); }
  function callLightRgbService(entity_id, r, g, b) { if (current) _worker?.callLightRgbService(entity_id, r, g, b); }
  function callLightHsService(entity_id, h, s) { if (current) _worker?.callLightHsService(entity_id, h, s); }
  function _queueQuery() {
    if (!_constructed) return;
    _retireWorker();
    replacement.restart();
  }
  Timer { id: replacement; interval: 300; onTriggered: root._replaceQuery() }
  on_QueryIdentityChanged: _queueQuery()
  on_PinsIdentityChanged: if (_constructed) refreshEntities()
  onCurrentChanged: {
    if (!current && _constructed) { replacement.stop(); _retireWorker(); retire(root); }
  }
  Component.onCompleted: { _constructed = true; _replaceQuery(); }
  Component.onDestruction: { replacement.stop(); _retireWorker(); }
}
