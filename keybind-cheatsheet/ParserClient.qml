import QtQuick
import qs.Services.Compositor

Item {
  id: root
  required property var settingsContext
  required property var pluginApi
  required property var publishCache
  required property var retire
  property bool retired: false
  readonly property bool current: settingsContext.current()
  readonly property var cfg: current ? settingsContext.appliedSettings : ({})
  readonly property string compositor: CompositorService.isHyprland ? "hyprland" : CompositorService.isNiri ? "niri" : CompositorService.isSway ? "sway" : CompositorService.isLabwc ? "labwc" : CompositorService.isMango ? "mango" : "unknown"
  // Only parser inputs invalidate a result. Colors and column policy are views.
  readonly property string sourceKey: JSON.stringify([compositor, cfg.niriConfigPath, cfg.hyprlandConfigPath, cfg.hyprlandLuaConfigPath, cfg.hyprlandParserMode, cfg.mangoConfigPath, cfg.modKeyVariable, cfg.showUndescribedBinds, cfg.mergeSequentialBinds, cfg.bindOverrides])
  property var categories: []
  property int cheatsheetDataVersion: 0
  property bool constructed: false
  property var worker: null
  Component { id: parserFactory; ParserGeneration {} }
  function releaseWorker() {
    if (!worker) return;
    const previous = worker;
    worker = null;
    previous.active = false;
    previous.destroy();
  }
  function replaceParser(useCache) {
    if (!constructed || retired) return;
    releaseWorker();
    categories = [];
    if (!current) return;
    if (useCache && publishCache && pluginApi.state?.cheatsheetSource === sourceKey) {
      categories = pluginApi.state.cheatsheetData ?? [];
      cheatsheetDataVersion++;
      return;
    }
    const source = sourceKey;
    const generation = parserFactory.createObject(root, {
      pluginApi: pluginApi, cfg: cfg, compositor: compositor,
      isCurrent: function() { return root.current && !root.retired && root.sourceKey === source; }
    });
    worker = generation;
    generation.finished.connect(function(data) {
      if (!root.current || root.retired || root.sourceKey !== source || root.worker !== generation) return;
      root.categories = data;
      root.cheatsheetDataVersion++;
      if (root.publishCache) root.publishCache(source, data, root.compositor);
    });
    generation.runParser();
  }
  function refresh() { if (current && !retired) replaceParser(false); }
  function retireClient() {
    if (retired) return;
    retired = true;
    releaseWorker();
    retire(root);
  }
  onSourceKeyChanged: replaceParser(false)
  onCurrentChanged: if (!current && constructed) retireClient()
  // API callbacks may be invalidated without a dependency signal on destruction.
  Timer { interval: 100; repeat: true; running: true; onTriggered: if (!root.settingsContext.current()) root.retireClient(); }
  Component.onCompleted: { constructed = true; replaceParser(true); }
  Component.onDestruction: { retired = true; releaseWorker(); }
}
