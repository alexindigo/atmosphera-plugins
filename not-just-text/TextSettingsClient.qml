import QtQuick
import qs.Services.UI

// Main owns one configuration client across all views of a runtime context.
Item {
  id: root
  required property var settingsContext
  required property var pluginApi
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: current ? settingsContext.settingsView : ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property bool refreshOnWallpaper: cfg.refreshOnWallpaper ?? defaults.refreshOnWallpaper ?? true
  readonly property string _queryIdentity: JSON.stringify([cfg.fortuneEnabled, cfg.fortuneOffensive, cfg.fortuneEqual, cfg.fortuneCategory, cfg.fortuneMaxLength, cfg.listEnabled, cfg.textFile])
  property bool _constructed: false
  property var _worker: null
  readonly property string fortuneText: _worker?.fortuneText ?? ""
  readonly property string listText: _worker?.listText ?? ""
  Component {
    id: workerFactory
    TextQueryWorker {}
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
                                            fortuneEnabled: cfg.fortuneEnabled ?? defaults.fortuneEnabled ?? false,
                                            fortuneOffensive: cfg.fortuneOffensive ?? defaults.fortuneOffensive ?? false,
                                            fortuneEqual: cfg.fortuneEqual ?? defaults.fortuneEqual ?? false,
                                            fortuneCategory: cfg.fortuneCategory ?? defaults.fortuneCategory ?? "",
                                            fortuneMaxLength: cfg.fortuneMaxLength ?? defaults.fortuneMaxLength ?? 60,
                                            listEnabled: cfg.listEnabled ?? defaults.listEnabled ?? false,
                                            textFile: cfg.textFile ?? defaults.textFile ?? ""
                                          });
  }
  function triggerFortune() { _worker?.triggerFortune(); }
  function pickFromFile() { _worker?.pickFromFile(); }
  Timer {
    id: debounce
    interval: 300
    repeat: false
    onTriggered: {
      if (root._worker?.fortuneEnabled) root.triggerFortune();
      if (root._worker?.listEnabled) root.pickFromFile();
    }
  }
  Connections {
    target: WallpaperService
    function onWallpaperChanged(screenName, path) {
      if (root.current && root.refreshOnWallpaper && (root._worker?.fortuneEnabled || root._worker?.listEnabled))
        debounce.restart();
    }
  }
  on_QueryIdentityChanged: _replaceQuery()
  onCurrentChanged: {
    if (!current && _constructed) {
      debounce.stop();
      _retireWorker();
      retire(root);
    }
  }
  Component.onCompleted: { _constructed = true; _replaceQuery(); }
  Component.onDestruction: _retireWorker()
}
