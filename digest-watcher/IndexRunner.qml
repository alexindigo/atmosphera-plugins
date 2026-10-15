import Quickshell.Io
import qs.Commons

Process {
  id: root

  property string helperPath: "/usr/local/bin/digest-index"
  property bool failureReported: false

  // The shell turns launch failures (missing/not executable) into exit codes,
  // so every helper failure follows the same observed completion path.
  command: ["/bin/sh", "-c", "exec \"$1\" >/dev/null 2>&1", "digest-watcher", helperPath]

  function refresh() {
    if (!running)
      running = true;
  }

  onExited: function (exitCode, exitStatus) {
    if (exitCode === 0 && exitStatus === 0) {
      failureReported = false;
    } else if (!failureReported) {
      Logger.w("digest-watcher", "Index helper " + helperPath + " failed (exit " + exitCode + ", status " + exitStatus + ")");
      failureReported = true;
    }
  }
}
