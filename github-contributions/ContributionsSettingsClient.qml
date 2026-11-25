import QtQuick

// A replacement account always starts with its own empty result generation.
Item {
  id: root
  required property var settingsContext
  required property var pluginApi
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: current ? settingsContext.settingsView : ({})
  readonly property string username: (cfg.username ?? "").trim()
  readonly property string token: (cfg.token ?? "").trim()
  readonly property string _queryIdentity: JSON.stringify([username, token, cfg.refreshInterval])
  property var _worker: null
  property bool _constructed: false
  readonly property var days: _worker?.days ?? []
  readonly property int totalContributions: _worker?.totalContributions ?? 0
  readonly property int currentStreak: _worker?.currentStreak ?? 0
  readonly property bool loading: _worker?.loading ?? false
  readonly property bool hasData: _worker?.hasData ?? false
  readonly property string errorMessage: _worker?.errorMessage ?? ""
  function refresh() {
    _worker?.refresh();
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
                                           configuration: cfg
                                         });
  }
  Component {
    id: workerFactory
    ContributionsQueryWorker {}
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
