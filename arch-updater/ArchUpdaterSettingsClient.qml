import QtQuick

// One stable client per captured runtime identity. A changed check
// configuration starts a fresh immutable worker generation; the old one is
// retired before its processes can publish into the new selection.
Item {
  id: root
  required property var settingsContext
  required property var pluginApi
  required property var retire
  required property var admitUpdate
  readonly property bool current: settingsContext.current()
  readonly property var cfg: current ? settingsContext.settingsView : ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string systemCmd: cfg.systemCmd || defaults.systemCmd || ""
  readonly property string aurCmd: cfg.aurCmd || defaults.aurCmd || ""
  readonly property bool flatpak: cfg.flatpak ?? defaults.flatpak ?? false
  readonly property bool noctalia: cfg.noctalia ?? defaults.noctalia ?? true
  readonly property real refreshInterval: cfg.refreshInterval || defaults.refreshInterval || 120
  readonly property string _queryIdentity: JSON.stringify([systemCmd, aurCmd, flatpak, noctalia, refreshInterval])
  property var _worker: null
  property bool _constructed: false
  readonly property string systemStr: _worker?.systemStr ?? ""
  readonly property string aurStr: _worker?.aurStr ?? ""
  readonly property string flatpakStr: _worker?.flatpakStr ?? ""
  readonly property var updates: _worker?.updates ?? []
  readonly property bool refreshing: _worker?.refreshing ?? false
  readonly property bool noctaliaUpdate: _worker?.noctaliaUpdate ?? false
  function actionSettings() {
    return {
      toast: cfg.toast ?? defaults.toast ?? true,
      aurHomepageCmd: cfg.aurHomepageCmd || defaults.aurHomepageCmd || ""
    };
  }
  function refresh() {
    if (_worker)
      _worker.refresh();
  }
  function update() {
    if (!current)
      return false;
    return admitUpdate(cfg.updateCmd || defaults.updateCmd || "", actionSettings().toast);
  }
  function refreshAfterUpdate() {
    // A pre-exit query may still be in flight. Replace that read so it cannot
    // publish an old package list or absorb the post-update refresh.
    _replaceQuery();
  }
  function openHomepage(source, id) {
    if (_worker)
      _worker.openHomepage(source, id);
  }
  function _retireWorker() {
    if (!_worker)
      return;
    var old = _worker;
    _worker = null;
    old.active = false;
    old.destroy();
  }
  function _replaceQuery() {
    if (!_constructed)
      return;
    _retireWorker();
    if (!current)
      return;
    _worker = workerFactory.createObject(root, {
                                           pluginApi: pluginApi,
                                           actionSettings: root.actionSettings,
                                           configuration: Object.freeze({
                                                                          systemCmd: systemCmd,
                                                                          aurCmd: aurCmd,
                                                                          flatpak: flatpak,
                                                                          noctalia: noctalia,
                                                                          refreshInterval: refreshInterval
                                                                        })
                                         });
  }
  Component {
    id: workerFactory
    ArchUpdaterQueryWorker {}
  }
  on_QueryIdentityChanged: _replaceQuery()
  onCurrentChanged: {
    if (!current && _constructed) {
      _retireWorker();
      retire(root);
    }
  }
  Component.onCompleted: {
    _constructed = true;
    _replaceQuery();
  }
  Component.onDestruction: _retireWorker()
}
