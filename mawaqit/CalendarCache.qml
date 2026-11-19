import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.Plugins

// One owner per Main instance; panels receive commands, never a settings alias.
Item {
  id: root
  required property var pluginApi
  readonly property bool ready: !!pluginApi?.pluginDir && !!pluginApi?.pluginId && Settings.isLoaded
  readonly property bool busy: _active !== null
  property var _queue: []
  property var _active: null
  property bool _started: false
  property string _output: ""

  onReadyChanged: if (ready) Qt.callLater(_next)

  function request(command, callback) {
    // Capture before queueing, so later caller mutation cannot alter submitted data.
    const body = JSON.stringify(command);
    _queue.push({body: body, callback: callback});
    _next();
  }

  function _next() {
    // API injection and Settings initialization can follow Main construction.
    // An unready dependency never acquires or removes the queued request.
    if (!ready || _active || !_queue.length) return;
    _active = _queue.shift();
    _started = false;
    _output = "";
    child.command = ["timeout", "20s", "python3", "-B", pluginApi.pluginDir + "/calendar-cache.py",
      Settings.cacheDir, pluginApi.pluginId, Registry.getPluginSettingsFile(pluginApi.pluginId),
      Registry.getLegacyPluginSettingsFile(pluginApi.pluginId)];
    child.stdinEnabled = true;
    child.running = true;
  }

  function _finish(result) {
    if (!_active) return;
    const callback = _active.callback;
    _active = null;
    if (result.status === "failed") Logger.w("Mawaqit", "Calendar cache:", result.error);
    // Queue ownership is released before callback reentry, preserving FIFO.
    Qt.callLater(_next);
    if (typeof callback === "function") callback(result);
  }

  Process {
    id: child
    stdout: StdioCollector { onStreamFinished: root._output = text }
    stderr: StdioCollector {}
    onStarted: {
      root._started = true;
      write(root._active.body);
      stdinEnabled = false;
    }
    onExited: function(code, status) {
      let result = {status: "failed", error: "cache-child"};
      try {
        const parsed = JSON.parse(root._output);
        if (status === 0 && code === 0 && parsed.status === "ready") result = parsed;
      } catch (error) {}
      root._finish(result);
    }
    onRunningChanged: {
      if (!running && !root._started && root._active)
        root._finish({status: "failed", error: "cache-start"});
    }
  }
}
