import QtQuick
import Quickshell.Io

Process {
  id: worker
  required property var policy
  required property var becameStarted
  required property var delivered
  required property var settled
  property bool cancelled: false
  property bool _finished: false
  property var _lifetime: ({alive: true})
  property string stderrBuffer: ""
  stdinEnabled: true
  stdout: SplitParser { onRead: line => { if (!worker.cancelled && !worker._finished) worker.delivered(worker, line); } }
  stderr: StdioCollector { onStreamFinished: worker.stderrBuffer = text || "" }
  onStarted: if (!cancelled && !_finished) becameStarted(worker)
  onExited: code => finish(code)
  onRunningChanged: {
    if (!running && !cancelled && !_finished) {
      var life = _lifetime;
      Qt.callLater(function() { if (life.alive && !worker.cancelled && !worker._finished) worker.finish(-1); });
    }
  }
  function finish(code) {
    if (_finished || cancelled) return;
    _finished = true;
    settled(worker, code);
  }
  function cancel() { cancelled = true; running = false; }
  Component.onDestruction: _lifetime.alive = false
}
