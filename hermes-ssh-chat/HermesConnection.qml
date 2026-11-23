import QtQuick
import Quickshell.Io

// One immutable request/process generation; the parent admits its callbacks.
Item {
  id: root
  required property var session
  required property string request
  function start() { bridge.running = true; }
  function write(text) { if (bridge.running) bridge.write(text); }
  function retire() {
    // Main owns the helper until cleanup finishes, even if the session dies.
    session = null;
    bridge.running = false;
    if (bridge.running) deadline.start();
    else destroy();
  }
  Timer { id: deadline; interval: 6000; onTriggered: root.destroy() }
  Process {
    id: bridge
    running: false
    stdinEnabled: true
    command: ["python3", decodeURIComponent(String(Qt.resolvedUrl("helpers/hermes_ssh_bridge.py")).replace(/^file:\/\//, ""))]
    stdout: SplitParser { splitMarker: "\n"; onRead: data => root.session?.handleMessage(root, data) }
    stderr: SplitParser { splitMarker: "\n"; onRead: data => root.session?.bridgeError(root, String(data || "")) }
    onStarted: root.session?.started(root)
    onExited: {
      if (root.session) root.session.exited(root);
      else root.destroy();
    }
  }
  Component.onDestruction: bridge.running = false
}
