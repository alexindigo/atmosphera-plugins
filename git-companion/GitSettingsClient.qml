import QtQuick

// One stable client per captured runtime identity. Query workers are immutable
// generations: replacement retires the old process callbacks before destruction.
Item {
  id: root
  required property var settingsContext
  required property var pluginApi
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: current ? settingsContext.settingsView : ({})
  readonly property string platform: cfg.platform ?? "github"
  readonly property string repo: cfg.repo ?? ""
  readonly property string group: cfg.group ?? ""
  readonly property int refreshInterval: cfg.refreshInterval ?? 60
  readonly property bool hasScope: group.trim().length > 0 || repo.trim().length > 0
  readonly property string _queryIdentity: JSON.stringify([platform, repo, group, refreshInterval])
  property var _worker: null
  property bool _constructed: false
  readonly property bool loading: _worker?.loading ?? false
  readonly property string lastError: _worker?.lastError ?? ""
  readonly property string lastUpdate: _worker?.lastUpdate ?? ""
  readonly property bool isBinInstalled: _worker?.isBinInstalled ?? false
  readonly property bool isAuthenticated: _worker?.isAuthenticated ?? false
  readonly property string username: _worker?.username ?? ""
  readonly property string avatarUrl: _worker?.avatarUrl ?? ""
  readonly property string bio: _worker?.bio ?? ""
  readonly property int issuesCount: _worker?.issuesCount ?? 0
  readonly property var issuesList: _worker?.issuesList ?? []
  readonly property int prsCount: _worker?.prsCount ?? 0
  readonly property var prsList: _worker?.prsList ?? []
  function refresh() {
    if (_worker)
      _worker.refresh();
  }
  function openUrl(url) {
    if (_worker)
      _worker.openUrl(url);
  }
  function _retireWorker() {
    if (!_worker)
      return;
    var old = _worker;
    _worker = null;
    old.active = false;
    // Quickshell Process destruction kills owned children. All collectors
    // and exit handlers also refuse inactive generations before publication.
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
                                           configuration: Object.freeze({
                                                                          platform: platform,
                                                                          repo: repo,
                                                                          group: group,
                                                                          refreshInterval: refreshInterval
                                                                        })
                                         });
  }
  Component {
    id: workerFactory
    GitQueryWorker {}
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
