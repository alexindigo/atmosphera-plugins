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

  function current() { return active && request.current(); }
  function start() {
    if (!current()) return;
    preScan.command = ["ls", "-1", request.directory];
    preScan.running = true;
  }
  function cancel() {
    active = false;
    preScan.running = false;
    receive.running = false;
    postScan.running = false;
  }

  Process {
    id: preScan
    stdout: StdioCollector { id: preOutput }
    stderr: StdioCollector {}
    onExited: function(code) {
      if (!root.current()) return;
      const text = String(preOutput.text || "").trim();
      root.preScanFiles = code === 0 && text.length > 0 ? text.split("\n") : [];
      Logger.d("Tailscale", "Pre-scan: " + root.preScanFiles.length + " files");
      receive.command = root.request.mode === "pkexec" ? ["pkexec", "tailscale", "file", "get", root.request.directory] : ["tailscale", "file", "get", root.request.directory];
      receive.running = true;
    }
  }
  Process {
    id: receive
    stdout: StdioCollector { id: receiveOutput }
    stderr: StdioCollector { id: receiveError }
    onStarted: {
      if (!root.current()) return;
      Logger.i("Tailscale", "Taildrop receive started in: " + root.request.directory);
    }
    onExited: function(code) {
      if (!root.current()) return;
      if (code === 0) {
        postScan.command = ["ls", "-1", root.request.directory];
        postScan.running = true;
        Logger.i("Tailscale", "Taildrop receive completed, running post-scan");
      } else {
        root.active = false;
        const output = (String(receiveError.text || "").trim() + "\n" + String(receiveOutput.text || "").trim()).trim();
        root.completed(root, {ok: false, output: output, exitCode: code});
      }
    }
  }
  Process {
    id: postScan
    stdout: StdioCollector { id: postOutput }
    stderr: StdioCollector {}
    onExited: function(code) {
      if (!root.current()) return;
      const text = String(postOutput.text || "").trim();
      const after = code === 0 && text.length > 0 ? text.split("\n") : [];
      const before = {};
      for (const name of root.preScanFiles) before[name] = true;
      const added = after.filter(name => !before[name]);
      root.active = false;
      root.completed(root, {ok: true, files: added});
    }
  }
}
