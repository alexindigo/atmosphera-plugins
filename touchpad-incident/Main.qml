import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property bool busy: false
  property string resultState: "idle"
  property string lastIncident: ""
  property string lastError: ""
  readonly property bool coolingDown: cooldown.running
  readonly property bool canMark: !busy && !coolingDown

  function tr(key) {
    return pluginApi ? pluginApi.tr(key) : key;
  }

  function fail(message) {
    watchdog.stop();
    root.busy = false;
    root.resultState = "error";
    root.lastError = message;
    feedback.restart();
    ToastService.showError(root.tr("toast.title"), message, 7000);
  }

  function finish(exitCode) {
    if (!root.busy)
      return;

    watchdog.stop();
    var reply;
    try {
      reply = JSON.parse(markerOutput.text);
    } catch (error) {
      root.fail(markerErrors.text.trim() || root.tr("toast.invalid-reply"));
      return;
    }

    if (exitCode !== 0 || reply.error || typeof reply.incident !== "string" || reply.status !== "collecting") {
      root.fail(reply.error || markerErrors.text.trim() || root.tr("toast.failed"));
      return;
    }

    root.busy = false;
    root.resultState = "success";
    root.lastIncident = reply.incident;
    root.lastError = "";
    feedback.restart();
    cooldown.restart();
    ToastService.showNotice(root.tr("toast.title"), root.tr("toast.saved"), "pointer-check", 4000);
  }

  function markIncident() {
    // Shared Main instance prevents duplicate clicks across multiple bars.
    if (!root.canMark)
      return;

    feedback.stop();
    root.lastError = "";
    root.resultState = "busy";
    root.busy = true;
    watchdog.restart();
    markerProcess.running = true;
  }

  Process {
    id: markerProcess
    // Argument vector, not a shell expression. No label/other command is allowed.
    command: ["/usr/local/bin/touchpad-incident"]
    stdout: StdioCollector {
      id: markerOutput
    }
    stderr: StdioCollector {
      id: markerErrors
    }
    onExited: function (exitCode, exitStatus) {
      // Let stream collectors finish before interpreting the helper's JSON.
      Qt.callLater(function () { root.finish(exitCode); });
    }
  }

  Timer {
    id: watchdog
    interval: 10000
    onTriggered: {
      // Stops only this helper client, never the underlying capture service.
      root.busy = false;
      markerProcess.running = false;
      root.fail(root.tr("toast.timeout"));
    }
  }

  Timer {
    id: cooldown
    interval: 30000
  }

  Timer {
    id: feedback
    interval: 5000
    onTriggered: root.resultState = "idle"
  }

  IpcHandler {
    target: "plugin:touchpad-incident"
    function mark() {
      root.markIncident();
    }
    function status(): string {
      return JSON.stringify({
                              "busy": root.busy,
                              "coolingDown": root.coolingDown,
                              "state": root.resultState,
                              "lastIncident": root.lastIncident,
                              "lastError": root.lastError
                            });
    }
  }
}
