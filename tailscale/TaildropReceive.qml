import QtQuick
import Quickshell.Io
import qs.Commons

// One admitted receive generation. It never reads a replacement Main request.
Item {
  id: root
  required property var request
  required property var completed
  property bool active: true
  property var preScanFiles: []
  property var pendingStep: null

  function current() { return active && request.current(); }
  function launch(step, command) {
    pendingStep = step;
    step.command = command;
    step.running = true;
  }
  function settleStep(step) {
    if (!current() || pendingStep !== step) return false;
    pendingStep = null;
    return true;
  }
  function startFailed(step) {
    // Normal exit settles first; FailedToStart only reports runningChanged.
    if (!step.running && settleStep(step)) finish({ok: false, output: "", exitCode: -1});
  }
  function finish(result) {
    active = false;
    completed(root, result);
  }
  function start() {
    if (!current()) return;
    launch(preScan, ["ls", "-1", request.directory]);
  }
  function cancel() {
    active = false;
    pendingStep = null;
    preScan.running = false;
    receive.running = false;
    postScan.running = false;
  }

  Process {
    id: preScan
    stdout: StdioCollector { id: preOutput }
    stderr: StdioCollector {}
    onRunningChanged: root.startFailed(preScan)
    onExited: function(code) {
      if (!root.settleStep(preScan)) return;
      const text = String(preOutput.text || "").trim();
      root.preScanFiles = code === 0 && text.length > 0 ? text.split("\n") : [];
      Logger.d("Tailscale", "Pre-scan: " + root.preScanFiles.length + " files");
      root.launch(receive, root.request.mode === "pkexec" ? ["pkexec", "tailscale", "file", "get", root.request.directory] : ["tailscale", "file", "get", root.request.directory]);
    }
  }
  Process {
    id: receive
    stdout: StdioCollector { id: receiveOutput }
    stderr: StdioCollector { id: receiveError }
    onRunningChanged: root.startFailed(receive)
    onStarted: {
      if (!root.current()) return;
      Logger.i("Tailscale", "Taildrop receive started in: " + root.request.directory);
    }
    onExited: function(code) {
      if (!root.settleStep(receive)) return;
      if (code === 0) {
        root.launch(postScan, ["ls", "-1", root.request.directory]);
        Logger.i("Tailscale", "Taildrop receive completed, running post-scan");
      } else {
        const output = (String(receiveError.text || "").trim() + "\n" + String(receiveOutput.text || "").trim()).trim();
        root.finish({ok: false, output: output, exitCode: code});
      }
    }
  }
  Process {
    id: postScan
    stdout: StdioCollector { id: postOutput }
    stderr: StdioCollector {}
    onRunningChanged: root.startFailed(postScan)
    onExited: function(code) {
      if (!root.settleStep(postScan)) return;
      const text = String(postOutput.text || "").trim();
      const after = code === 0 && text.length > 0 ? text.split("\n") : [];
      const before = {};
      for (const name of root.preScanFiles) before[name] = true;
      const added = after.filter(name => !before[name]);
      root.finish({ok: true, files: added});
    }
  }
}
