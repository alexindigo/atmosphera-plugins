import QtQuick

// A context owns file-query generations, never a live output/provider owner.
Item {
  id: root
  required property var pluginApi
  required property var settingsContext
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView ?? ({})
  readonly property string configPath: cfg.niriConfigPath || "~/.config/niri/config.kdl"
  readonly property var outputs: current && parser ? parser.outputs : []
  readonly property bool loading: current && parser ? parser.loading : false
  property var parser: null
  property bool constructed: false

  function cancel() {
    const previous = parser;
    parser = null;
    if (previous) { previous.cancel(); previous.destroy(); }
  }
  function refresh(replace = false) {
    if (!current || (!replace && loading)) return false;
    cancel();
    parser = parserComponent.createObject(root, {configPath: configPath});
    parser.start();
    return true;
  }
  Component { id: parserComponent; NiriConfigParser {} }
  onConfigPathChanged: { if (constructed) refresh(true); }
  onCurrentChanged: {
    if (!current && constructed) { cancel(); retire(root); }
  }
  Component.onCompleted: { constructed = true; refresh(); }
  Component.onDestruction: cancel()
}
