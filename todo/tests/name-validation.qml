import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Services.Plugins
import qs.Widgets

ShellRoot {
  SettingsBootstrap { id: bootstrap }
  Loader {
    active: bootstrap.ready
    sourceComponent: Component {
      Item {
        id: root
        property var api: null
        property var receipt: null
        property bool started: false
        property string phase: "start"
        readonly property bool empty: Quickshell.env("REVIEW23_CASE") === "empty"
        readonly property bool cold: Quickshell.env("MINOR_REVIEW_COLD") === "1"
        function check(ok, label) { if (!ok) throw new Error("REVIEW23_ASSERT: " + phase + " " + label); }
        function findRename(item) {
          if (typeof item.saveRename === "function" && item.originalName === "A") return item;
          for (var child of item.children || []) { var found = findRename(child); if (found) return found; }
          return null;
        }
        function begin() {
          if (started || !Settings.isLoaded) return;
          started = true;
          Service._openSettingsOwner("todo", function(owner) {
            try {
              check(!!owner, "native owner");
              api = Service.createPluginAPI("todo", JSON.parse(Quickshell.env("MINOR_REVIEW_MANIFEST")), owner, {}, {}, {});
              var loaded = Object.assign({}, Service.loadedPlugins); loaded.todo = {api:api}; Service.loadedPlugins = loaded;
              popup.openPluginSettings(api.manifest, "settings"); phase = "page";
            } catch(error) { console.error(String(error)); Qt.exit(2); }
          });
        }
        function outcome() {
          check(api.pluginSettings.pages[1].name === (empty ? "A" : "B") && api.pluginSettings.pages[2].name === (empty ? "B" : "C"), "complete final page-name set");
          check(api.pluginSettings.todos.length === 1 && api.pluginSettings.todos[0].opaque === "keep", "unrelated todo retained");
        }
        function drive() {
          if (phase === "page" && popup.opened && popup.settingsPage) {
            if (cold) { outcome(); console.log("MINOR_REVIEW: COLD_PASS"); Qt.quit(); return; }
            var page = popup.settingsPage;
            if (empty) {
              var delegate = findRename(page); check(!!delegate, "actual rename delegate");
              page.setPendingName(1, ""); delegate.saveRename();
              check(page.pendingNames["1"] === "A", "empty rename restores pending name");
            } else {
              var before = JSON.stringify(page.editPages);
              page.setPendingName(1, "Same"); page.setPendingName(2, " same ");
              var refused = false;
              try { page.saveSettings(); } catch(error) { refused = true; }
              check(refused && JSON.stringify(page.editPages) === before, "duplicate final names refuse before any partial rename");
              page.setPendingName(1, " B "); page.setPendingName(2, "C");
            }
            page.valueShowCompleted = false;
            popup.applySettings(); phase = "apply";
          } else if (phase === "apply" && !popup.busy) {
            check(receipt && receipt.status !== "failed" && receipt.refreshState === "current", "valid final names Apply " + JSON.stringify(receipt));
            outcome(); check(!popup.dirty, "settled page baseline");
            console.log("MINOR_REVIEW: SAVED_PASS"); Qt.quit();
          }
        }
        FloatingWindow { implicitWidth:1000; implicitHeight:800; visible:true; NPluginSettingsPopup { id:popup; parent:Overlay.overlay; onSettingsCompleted: result=>root.receipt=result } }
        Connections { target:Settings; function onSettingsLoaded() {root.begin();} }
        Component.onCompleted: begin()
        Timer {interval:40; repeat:true; running:true; onTriggered:{try{root.drive();}catch(error){console.error(String(error));Qt.exit(2);}}}
        Timer {interval:20000; running:true; onTriggered:{console.error("REVIEW23_ASSERT: watchdog",root.phase);Qt.exit(2);}}
      }
    }
  }
}
