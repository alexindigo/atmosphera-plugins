import QtQuick

QtObject {
  id: root
  required property var pluginApi
  required property var settingsContext
  required property var retire
  readonly property bool current: settingsContext?.current() ?? false
  readonly property var cfg: settingsContext?.settingsView ?? ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
  readonly property string apiUrl: (cfg.apiUrl ?? defaults.apiUrl ?? "").trim()
  readonly property string apiKey: (cfg.apiKey ?? defaults.apiKey ?? "").trim()
  readonly property string configPath: (cfg.configPath ?? defaults.configPath ?? "").trim()
  readonly property bool verifyTls: cfg.verifyTls ?? defaults.verifyTls ?? false
  readonly property var folderIds: Array.from(cfg.folderIds ?? defaults.folderIds ?? [])
  readonly property string _queryIdentity: JSON.stringify([apiUrl, apiKey, configPath, verifyTls, folderIds])
  property bool _constructed: false
  property var _worker: null
  readonly property bool enabled: cfg.enabled ?? defaults.enabled ?? true
  readonly property int pollIntervalMs: cfg.pollIntervalMs ?? defaults.pollIntervalMs ?? 10000
  readonly property bool busy: _worker?.busy ?? false
  readonly property var snapshot: _worker?.snapshot ?? ({})
  readonly property string state: _worker?.state ?? "unconfigured"
  readonly property string detail: _worker?.detail ?? ""
  readonly property int configuredDevices: _worker?.configuredDevices ?? 0
  readonly property int connectedDevices: _worker?.connectedDevices ?? 0
  readonly property int pausedDevices: _worker?.pausedDevices ?? 0
  readonly property int monitoredFolders: _worker?.monitoredFolders ?? 0
  readonly property int pausedFolders: _worker?.pausedFolders ?? 0
  readonly property int syncingFolders: _worker?.syncingFolders ?? 0
  readonly property int erroredFolders: _worker?.erroredFolders ?? 0
  readonly property int needItems: _worker?.needItems ?? 0
  readonly property double needBytes: _worker?.needBytes ?? 0
  readonly property var folders: _worker?.folders ?? []
  readonly property var availableFolders: _worker?.availableFolders ?? []
  readonly property var recentErrors: _worker?.recentErrors ?? []
  readonly property string resolvedUrl: _worker?.resolvedUrl ?? ""
  readonly property string resolvedConfigPath: _worker?.resolvedConfigPath ?? ""
  readonly property string urlSource: _worker?.urlSource ?? "none"
  readonly property string apiKeySource: _worker?.apiKeySource ?? "none"
  readonly property string checkedAt: _worker?.checkedAt ?? ""
  readonly property bool hasProblem: _worker?.hasProblem ?? false
  property Component workerFactory: Component { SyncthingQueryWorker {} }
  function _retireWorker() {
    if (!_worker) return;
    var old = _worker;
    _worker = null;
    old.stop(); old.destroy();
  }
  function _replaceQuery() {
    if (!_constructed) return;
    _retireWorker();
    if (!current) return;
    _worker = workerFactory.createObject(root, {
      pluginApi: pluginApi, settingsContext: settingsContext,
      apiUrl: apiUrl, apiKey: apiKey, configPath: configPath,
      verifyTls: verifyTls, folderIds: folderIds
    });
  }
  function requestPoll(force) { if (current) _worker?.requestPoll(force); }
  function stateLabel(code) { return _worker?.stateLabel(code) ?? ""; }
  function sourceLabel(code) { return _worker?.sourceLabel(code) ?? ""; }
  function statusSummary() { return _worker?.statusSummary() ?? ""; }
  function statusColor(code) { return _worker?.statusColor(code) ?? "transparent"; }
  function statusBadgeBackground(code) { return _worker?.statusBadgeBackground(code) ?? "transparent"; }
  function statusBadgeForeground(code) { return _worker?.statusBadgeForeground(code) ?? "transparent"; }
  function statusBadgeIcon(code) { return _worker?.statusBadgeIcon(code) ?? ""; }
  function badgeText() { return _worker?.badgeText() ?? ""; }
  function formatBytes(bytes) { return _worker?.formatBytes(bytes) ?? ""; }
  function formatCheckedAt(value) { return _worker?.formatCheckedAt(value) ?? ""; }
  function setFolderSelection(ids, runtimeApi) {
    if (!current || runtimeApi?.settingsContext !== settingsContext) return false;
    runtimeApi.pluginSettings.folderIds = Array.from(ids);
    runtimeApi.saveSettings();
    return true;
  }
  function toggleFolder(folderId, runtimeApi) {
    var ids = Array.from(folderIds), index = ids.indexOf(folderId);
    if (index >= 0) ids.splice(index, 1); else ids.push(folderId);
    return setFolderSelection(ids, runtimeApi);
  }
  function _queueQuery() {
    if (!_constructed) return;
    _retireWorker();
    replacement.restart();
  }
  property Timer replacement: Timer { interval: 0; onTriggered: root._replaceQuery() }
  on_QueryIdentityChanged: _queueQuery()
  onCurrentChanged: if (!current && _constructed) { replacement.stop(); _retireWorker(); retire(root); }
  Component.onCompleted: { _constructed = true; _replaceQuery(); }
  Component.onDestruction: { replacement.stop(); _retireWorker(); }
}
