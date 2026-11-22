import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Services.Plugins
import qs.Widgets

// Real page Apply -> Main parser -> Panel consumer -> second page Apply.
ShellRoot {
  SettingsBootstrap { id: directories }
  Loader {
    active: directories.ready
    sourceComponent: Component {
      Item {
  id: root
  property bool started: false
  property string phase: "start"
  property var api: null
  property var main: null
  property var panel: null
  property var receipt: null
  property var manifest: JSON.parse(Quickshell.env("KEYBIND_CACHE_MANIFEST"))
  property int parserVersion: 0
  property string legacyData: ""
  function check(ok, label) { if (!ok) throw new Error("KEYBIND_CACHE_ASSERT: " + phase + " " + label); }
  function create(file, properties) {
    var component = Qt.createComponent("file://" + Registry.getPluginDir("keybind-cheatsheet") + "/" + file);
    check(component.status === Component.Ready, component.errorString());
    var item = component.createObject(scene, properties);
    check(!!item, file + " constructed");
    return item;
  }
  function find(item, predicate, seen) {
    seen = seen || new Set();
    if (!item || seen.has(item)) return null;
    seen.add(item);
    if (predicate(item)) return item;
    for (var list of [item.data, item.children]) {
      if (!list || typeof list === "function" || typeof list.length !== "number") continue;
      for (var child of list) { var match = find(child, predicate, seen); if (match) return match; }
    }
    return null;
  }
  function input(key, value) {
    var wrapper = find(popup.settingsPage, item => item.field === popup._pageApi.field(key));
    var control = find(wrapper, item => item.editCommitted !== undefined);
    check(!!control, "actual committed input " + key);
    control.text = String(value); control.editCommitted();
    check(!popup._pageApi.field(key).error, "committed input admitted " + key + ": " + popup._pageApi.field(key).error);
  }
  function resetButton(item) {
    if (typeof item.clicked === "function" && item.text === api.tr("settings.reset-defaults")) return item;
    for (var child of item.children || []) {
      var found = resetButton(child);
      if (found) return found;
    }
    return null;
  }
  function begin() {
    if (started || !directories.ready || !Settings.isLoaded) return;
    started = true;
    Service._openSettingsOwner("keybind-cheatsheet", function (settings) {
      Service.loadPluginState("keybind-cheatsheet", function (state) {
        try {
          check(!!settings, "actual preference owner");
          api = Service.createPluginAPI("keybind-cheatsheet", manifest, settings, {}, {}, state);
          var loaded = Object.assign({}, Service.loadedPlugins);
          loaded["keybind-cheatsheet"] = {api: api};
          Service.loadedPlugins = loaded;
          // Both legs use the normal production cache-selection boundary.
          main = create("Main.qml", {pluginApi: api});
          api.mainInstance = main;
          panel = create("Panel.qml", {pluginApi: api});
          if (Quickshell.env("KEYBIND_CACHE_COLD") === "1") {
            phase = "cold";
            return;
          }
          legacyData = JSON.stringify(api.pluginSettings.cheatsheetData);
          phase = "warm-ready";
        } catch (error) { console.error(String(error)); Qt.exit(2); }
      });
    });
  }
  function drive() {
    if (phase === "warm-ready" && main.settingsConsumer && main.settingsConsumer.worker && !main.settingsConsumer.worker.isCurrentlyParsing) {
      check(popup.openPluginSettings(manifest, "settings"), "actual shared page opens");
      phase = "first";
    } else if (phase === "first" && popup.opened && popup.settingsPage) {
      var reset = resetButton(popup.settingsPage);
      check(!!reset, "actual Reset defaults action");
      reset.clicked();
      phase = "reset-staged";
    } else if (phase === "reset-staged" && !popup.busy && !popup._editor.busy && popup._pageApi.field("niriConfigPath").pendingIntent === "reset") {
      input("niriConfigPath", Quickshell.env("KEYBIND_CACHE_SOURCE"));
      phase = "path-staged";
    } else if (phase === "path-staged" && !popup._editor.busy) {
      parserVersion = main.cheatsheetDataVersion;
      input("windowWidth", 1491);
      phase = "width-staged";
    } else if (phase === "width-staged" && !popup._editor.busy) {
      popup.applySettings();
      phase = "first-receipt";
    } else if (phase === "first-receipt" && receipt && !popup.busy) {
      check(receipt && receipt.status !== "failed" && receipt.refreshState === "current", "first native Apply: " + JSON.stringify(receipt));
      phase = "parser";
    } else if (phase === "parser" && main.cheatsheetDataVersion > parserVersion) {
      check(JSON.stringify(panel.rawCategories).includes("Run: fixture-command"), "actual parser result reaches actual Panel");
      parserVersion = main.cheatsheetDataVersion;
      input("windowWidth", 1492);
      receipt = null;
      phase = "second-staged";
    } else if (phase === "second-staged" && !popup._editor.busy) {
      popup.applySettings();
      phase = "second-receipt";
    } else if (phase === "second-receipt" && receipt && !popup.busy) {
      check(receipt && receipt.status !== "failed" && receipt.refreshState === "current", "second native Apply after runtime parser refresh: " + JSON.stringify(receipt));
      check(api.pluginSettings.windowWidth === 1492 && !popup.dirty, "second preference choice acknowledged");
      check(JSON.stringify(api.pluginSettings.cheatsheetData) === legacyData, "derived cache never mutates preference input");
      check(api.pluginSettings.detectedCompositor === "", "detected compositor stays out of preference input");
      check(JSON.stringify(api.state.cheatsheetData).includes("Run: fixture-command"), "shared cache belongs to state owner");
      popup.requestClose();
      console.log("KEYBIND_CACHE: SAVED_PASS");
      Qt.exit(0);
    } else if (phase === "cold") {
      check(main.settingsConsumer && main.settingsConsumer.worker === null, "cold startup selected the existing cache without launching the parser");
      check(api.pluginSettings.windowWidth === 1492, "cold preference consumer");
      check(JSON.stringify(panel.rawCategories).includes("Run: fixture-command"), "cold state cache reaches actual Panel");
      check(api.state.detectedCompositor === "niri", "cold compositor state");
      check(main.cheatsheetDataVersion === 1 && api.state.cheatsheetSource === main.settingsConsumer.sourceKey, "cold consumer did not need a parser refresh");
      console.log("KEYBIND_CACHE: COLD_PASS");
      Qt.exit(0);
    }
  }
  FloatingWindow {
    implicitWidth: 1000; implicitHeight: 800
    visible: directories.ready
    Item { id: scene; anchors.fill: parent }
    NPluginSettingsPopup {
      id: popup
      parent: Overlay.overlay
      onSettingsCompleted: result => root.receipt = result
    }
  }
  Connections { target: Settings; function onSettingsLoaded() { root.begin(); } }
  Connections { target: directories; function onReadyChanged() { root.begin(); } }
  Component.onCompleted: begin()
  Timer {
    interval: 40; repeat: true; running: true
    onTriggered: { try { root.drive(); } catch (error) { console.error(String(error)); Qt.exit(2); } }
  }
  Timer { interval: 30000; running: true; onTriggered: { console.error("KEYBIND_CACHE_ASSERT: watchdog", root.phase); Qt.exit(2); } }
      }
    }
  }
}
