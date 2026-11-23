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
  property string parseStatus: "loading"
  property string _activeSource: ""
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
    const source = sourceKey;
    if (_activeSource !== source) {
      _activeSource = source;
      categories = [];
    }
    if (!current) return;
    if (useCache && publishCache) {
      const state = pluginApi.state;
      if (state?.cheatsheetSource === source && state.cheatsheetData?.length > 0) {
        categories = state.cheatsheetData;
        parseStatus = "ready";
        cheatsheetDataVersion++;
        return;
      }
      // Legacy rows and compositor must come from the same document. A
      // compositor match admits display only, never source-qualified reuse.
      if (!state?.cheatsheetSource) {
        for (const cache of [state, cfg]) {
          if (cache?.detectedCompositor === compositor && cache.cheatsheetData?.length > 0) {
            categories = cache.cheatsheetData;
            break;
          }
        }
      }
    }
    parseStatus = "loading";
    const generation = parserFactory.createObject(root, {
      pluginApi: pluginApi, cfg: cfg, compositor: compositor,
      isCurrent: function() { return root.current && !root.retired && root.sourceKey === source; }
    });
    worker = generation;
    generation.finished.connect(function(status, data) {
      if (!root.current || root.retired || root.sourceKey !== source || root.worker !== generation) return;
      root.parseStatus = status;
      if (status === "ready" || (root.categories.length === 0 && data?.length > 0))
        root.categories = data;
      root.cheatsheetDataVersion++;
      if (status === "ready" && root.publishCache) root.publishCache(source, data, root.compositor);
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
