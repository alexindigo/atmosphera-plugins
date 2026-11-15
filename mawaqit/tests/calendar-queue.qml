import QtQuick
import Quickshell
import qs.Commons

// Run from a shell source root with REVIEW_CALENDAR_PLUGIN pointing at mawaqit.
ShellRoot {
  SettingsBootstrap { id: directories }
  Loader {
    active: directories.ready
    sourceComponent: Component {
      Item {
        id: root
        property var cache: null
        property var callbacks: []
        property bool started: false
        function check(ok, message) {
          if (!ok) throw new Error("CALENDAR_QUEUE_ASSERT: " + message);
        }
        function api() {
          return {pluginDir: Quickshell.env("REVIEW_CALENDAR_PLUGIN"), pluginId: "mawaqit"};
        }
        function finish(label, result) {
          try {
            check(result.status === "ready", label + " helper result " + JSON.stringify(result));
            check(cache._active === null, "queue released before callback reentry");
            callbacks.push(label);
            if (label === "adopt") {
              cache.pluginApi = null;
              cache.request({op: "load", year: 2026, month: 12}, function (next) { root.finish("reentry", next); });
              check(!cache.busy && cache._queue.length === 2, "API loss retains queued and reentrant requests");
              Qt.callLater(function () { root.cache.pluginApi = root.api(); });
            }
            if (callbacks.length !== 3) return;
            check(JSON.stringify(callbacks) === JSON.stringify(["adopt", "load", "reentry"]), "FIFO callbacks delivered once");
            check(!cache.busy && cache._queue.length === 0, "queue drained");
            console.log("CALENDAR_QUEUE: PASS");
            Qt.exit(0);
          } catch (error) { console.error(String(error)); Qt.exit(2); }
        }
        function begin() {
          if (started || !Settings.isLoaded) return;
          started = true;
          try {
            const component = Qt.createComponent("file://" + Quickshell.env("REVIEW_CALENDAR_PLUGIN") + "/CalendarCache.qml");
            check(component.status === Component.Ready, component.errorString());
            const mode = Quickshell.env("REVIEW_CALENDAR_MODE");
            cache = component.createObject(root, {pluginApi: mode === "ready" ? api() : mode === "partial" ? {pluginId: "mawaqit"} : null});
            check(cache !== null, "actual CalendarCache constructed");
            const submitted = {op: "adopt"};
            cache.request(submitted, function (result) { root.finish("adopt", result); });
            submitted.op = "invalid-after-capture";
            cache.request({op: "load", year: 2026, month: 11}, function (result) { root.finish("load", result); });
            if (mode !== "ready") {
              check(!cache.busy && cache._queue.length === 2 && callbacks.length === 0, "unready API retains captured requests");
              Qt.callLater(function () { root.cache.pluginApi = root.api(); });
            }
          } catch (error) { console.error(String(error)); Qt.exit(2); }
        }
        Component.onCompleted: begin()
        Connections { target: Settings; function onSettingsLoaded() { root.begin(); } }
        Timer { interval: 10000; running: true; onTriggered: { console.error("CALENDAR_QUEUE_ASSERT: callback deadline"); Qt.exit(2); } }
      }
    }
  }
}
