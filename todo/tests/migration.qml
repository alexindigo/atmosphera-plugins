import QtQuick
import Quickshell
import qs.Commons
import qs.Services.Plugins

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
        function check(ok, label) { if (!ok) throw new Error("MINOR_REVIEW_ASSERT: " + phase + " " + label); }
        function begin() {
          if (started || !Settings.isLoaded) return;
          started = true;
          Service._openSettingsOwner("todo", function (settings) {
            try {
              check(!!settings, "native preference owner");
              api = Service.createPluginAPI("todo", JSON.parse(Quickshell.env("MINOR_REVIEW_MANIFEST")), settings, {}, {}, {});
              if (Quickshell.env("MINOR_REVIEW_COLD") === "1") { phase = "cold"; return; }
              api.settingsOwner.completed.connect(function (result) { if (result.operation === "save") receipt = result; });
              var component = Qt.createComponent("file://" + Registry.getPluginDir("todo") + "/Main.qml");
              check(component.status === Component.Ready, component.errorString());
              main = component.createObject(root, {pluginApi: api});
              check(!!main, "actual Main created");
              phase = "saved";
            } catch (error) { console.error(String(error)); Qt.exit(2); }
          });
        }
        function drive() {
          if (phase !== "cold" && (phase !== "saved" || !receipt)) return;
          if (phase === "saved") check(receipt.status === "saved" || receipt.status === "nothing_to_save", "native save receipt " + JSON.stringify(receipt));
          var todos = api.pluginSettings.todos;
          check(todos.length === 2 && todos[0].opaque === "keep", "rows and unknown members retained");
          for (var todo of todos) check(todo.pageId === 0 && todo.priority === "medium" && todo.details === "", "migrated fields reach preference consumer");
          console.log(phase === "cold" ? "MINOR_REVIEW: COLD_PASS" : "MINOR_REVIEW: SAVED_PASS"); Qt.quit();
        }
        Connections { target: Settings; function onSettingsLoaded() { root.begin(); } }
        Component.onCompleted: begin()
        Timer { interval: 40; running: true; repeat: true; onTriggered: { try { root.drive(); } catch (error) { console.error(String(error)); Qt.exit(2); } } }
        Timer { interval: 20000; running: true; onTriggered: { console.error("MINOR_REVIEW_ASSERT: watchdog " + root.phase); Qt.exit(2); } }
      }
    }
  }
}
