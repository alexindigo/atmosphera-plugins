import QtQuick
import Quickshell.Io

// One immutable request/process generation; the parent admits its callbacks.
Item {
  id: root
  required property var session
  required property string request
  function start() { bridge.running = true; }
  function write(text) { if (bridge.running) bridge.write(text); }
  function stop() { bridge.running = false; }
  Process {
    id: bridge
    running: false
    stdinEnabled: true
    command: ["python3", decodeURIComponent(String(Qt.resolvedUrl("helpers/hermes_ssh_bridge.py")).replace(/^file:\/\//, ""))]
    stdout: SplitParser { splitMarker: "\n"; onRead: data => root.session.handleMessage(root, data) }
    stderr: SplitParser { splitMarker: "\n"; onRead: data => root.session.bridgeError(root, String(data || "")) }
    onStarted: root.session.started(root)
    onExited: root.session.exited(root)
  }
  Component.onDestruction: stop()
}
