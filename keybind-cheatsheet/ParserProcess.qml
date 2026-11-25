import Quickshell.Io

// A parser stage settles exactly once, including Process's failed-start path.
// Quickshell emits runningChanged but no exited when exec cannot start.
Process {
  id: process
  property bool pending: false
  signal settled(int exitCode, int exitStatus)
  function start() { pending = true; running = true; }
  function settle(code, status) {
    if (!pending) return;
    pending = false;
    settled(code, status);
  }
  onExited: (code, status) => settle(code, status)
  onRunningChanged: if (!running) settle(-1, 0)
}
