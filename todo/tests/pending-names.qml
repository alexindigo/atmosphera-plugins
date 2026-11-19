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
        property var receipt: null
        property string phase: "start"
        property var manifest: JSON.parse(Quickshell.env("MINOR_REVIEW_MANIFEST"))
        function check(ok, label) { if (!ok) throw new Error("MINOR_REVIEW_ASSERT: " + phase + " " + label); }
        function begin() {
          if (started || !Settings.isLoaded) return;
          started = true;
          Service._openSettingsOwner("todo", function (settings) {
            try {
              check(!!settings, "native preference owner");
              api = Service.createPluginAPI("todo", manifest, settings, {}, {}, {});
              var loaded = Object.assign({}, Service.loadedPlugins);
              loaded.todo = {api: api}; Service.loadedPlugins = loaded;
              popup.openPluginSettings(manifest, "settings"); phase = "open";
            } catch (error) { console.error(String(error)); Qt.exit(2); }
          });
        }
        function drive() {
          if (phase === "open" && popup.opened && popup.settingsPage) {
            var page = popup.settingsPage;
            if (Quickshell.env("MINOR_REVIEW_COLD") === "1") {
              check(page.pendingNames["1"] === "Renamed" && page.editPages.length === 3, "cold page names");
              check(page.editTodos[0].pageId === 0 && page.editCurrentPage === 0, "cold deleted-page migration");
              console.log("MINOR_REVIEW: COLD_PASS"); Qt.quit(); return;
            }
            page.setPendingName(1, "Renamed");
            page.newPageName = "Added"; page.addPage();
            var afterAdd = page.pendingNames["1"] === "Renamed";
            page.setPendingName(1, "Renamed");
            page.performPageDeletion(2);
            var afterDelete = page.pendingNames["1"] === "Renamed";
            check(afterAdd && afterDelete, "pending rename survives add=" + afterAdd + " delete=" + afterDelete);
            check(page.pendingNames["3"] === "Added" && page.pendingNames["2"] === undefined, "pending-name membership follows stable page IDs");
            popup.applySettings(); phase = "saved";
          } else if (phase === "saved" && !popup.busy) {
            check(receipt && receipt.status !== "failed" && receipt.refreshState === "current", "native Apply");
            check(api.pluginSettings.pages[1].name === "Renamed" && !popup.dirty, "renamed page reaches consumer and settles baseline");
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
