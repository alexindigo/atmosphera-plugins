import QtQuick
import Quickshell.Io

// One Process per admitted generation. Callbacks are injected by its owner;
// this component knows no conversation, provider, parser or consumer.
Process {
  id: worker
  required property var policy
  required property var delivered
  required property var settled
  property bool streaming: false
  property string output: ""
  property bool _finished: false
  property var _lifetime: ({alive: true})
  stdout: SplitParser {
    onRead: data => {
      if (!worker._finished) {
        worker.output += data + "\n";
        if (worker.streaming) worker.delivered(worker, data);
      }
    }
  }
  stderr: StdioCollector { id: errors }
  function finish(code) {
    if (_finished) return;
    _finished = true;
    settled(worker, code, output, errors.text);
  }
  function start() { running = true; }
  function cancel() { _finished = true; running = false; }
  onExited: code => finish(code)
  onRunningChanged: if (!running && !_finished) {
    var life = _lifetime;
    Qt.callLater(function() { if (life.alive) worker.finish(-1); });
  }
  Component.onDestruction: _lifetime.alive = false
}
