import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root
  required property string queryCommand
  property bool active: true
  property int updateCount: 0
  function refresh() { if (active && !query.running) query.running = true; }
  function stop() { active = false; query.running = false; }
  Process {
    id: query
    command: ["sh", "-c", root.queryCommand]
    stdout: StdioCollector {
      onStreamFinished: {
        if (!root.active) return;
        var count = parseInt(text.trim());
        root.updateCount = isNaN(count) ? -1 : count;
        if (root.updateCount >= 0)
          Logger.i("UpdateCount", `Updates available: ${root.updateCount}`);
        else
          Logger.e("UpdateCount", `getNumUpdates return '${text.trim()}' cannot be parsed into int`);
      }
    }
  }
  Component.onCompleted: refresh()
  Component.onDestruction: stop()
}
