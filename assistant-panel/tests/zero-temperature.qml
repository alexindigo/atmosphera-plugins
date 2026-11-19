import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Services.Plugins
import qs.Widgets

ShellRoot {
  SettingsBootstrap { id: directories }
  Loader {
    active: directories.ready
    sourceComponent: Component {
      Item {
        id: root
        property bool started: false
        property var api: null
        property var main: null
        property var receipt: null
        property string phase: "start"
        property var manifest: JSON.parse(Quickshell.env("MINOR_REVIEW_MANIFEST"))
        function check(ok, label) { if (!ok) throw new Error("MINOR_REVIEW_ASSERT: " + phase + " " + label); }
        function begin() {
          if (started || !Settings.isLoaded) return;
          started = true;
          Service._openSettingsOwner("assistant-panel", function (settings) {
            try {
              check(!!settings, "native preference owner");
              api = Service.createPluginAPI("assistant-panel", manifest, settings, {}, {}, {});
              var loaded = Object.assign({}, Service.loadedPlugins);
              loaded["assistant-panel"] = {api: api};
              Service.loadedPlugins = loaded;
              var component = Qt.createComponent("file://" + Registry.getPluginDir("assistant-panel") + "/Main.qml");
              check(component.status === Component.Ready, component.errorString());
              main = component.createObject(root, {pluginApi: api});
              check(!!main && main.temperature === 0, "actual runtime temperature consumer");
              popup.openPluginSettings(manifest, "settings");
              phase = "open";
            } catch (error) { console.error(String(error)); Qt.exit(2); }
          });
        }
        function drive() {
          if (phase === "open" && popup.opened && popup.settingsPage) {
            check(popup.settingsPage.editTemperature === 0, "saved zero displayed, not defaulted");
            check(!popup.settingsPage.settingsDirty, "zero baseline is clean");
            if (Quickshell.env("MINOR_REVIEW_COLD") === "1") {
              console.log("MINOR_REVIEW: COLD_PASS"); Qt.quit(); return;
            }
            popup.settingsPage.editTemperature = 0.3;
            popup.applySettings(); phase = "first";
          } else if (phase === "first" && !popup.busy) {
            check(receipt && receipt.status !== "failed" && receipt.refreshState === "current", "first Apply");
            popup.settingsPage.editTemperature = 0;
            popup.applySettings(); phase = "zero";
          } else if (phase === "zero" && !popup.busy) {
            check(receipt && receipt.status !== "failed" && receipt.refreshState === "current", "zero Apply");
            check(api.pluginSettings.ai.temperature === 0, "runtime zero consumer");
            check(main.temperature === 0, "runtime temperature stays zero after Apply");
            check(!popup.dirty, "zero Apply settles baseline");
            console.log("MINOR_REVIEW: SAVED_PASS"); Qt.quit();
          }
        }
        FloatingWindow {
          implicitWidth: 1000; implicitHeight: 800; visible: true
          NPluginSettingsPopup { id: popup; parent: Overlay.overlay; onSettingsCompleted: result => root.receipt = result }
        }
        Connections { target: Settings; function onSettingsLoaded() { root.begin(); } }
        Component.onCompleted: begin()
        Timer { interval: 40; running: true; repeat: true; onTriggered: { try { root.drive(); } catch (error) { console.error(String(error)); Qt.exit(2); } } }
        Timer { interval: 20000; running: true; onTriggered: { console.error("MINOR_REVIEW_ASSERT: watchdog " + root.phase); Qt.exit(2); } }
      }
    }
  }
}
