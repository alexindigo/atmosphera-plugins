import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

// One immutable query generation for one selected configuration. Inactive
// generations refuse collector/exit output before it can be published.
Item {
  id: root

  property var pluginApi: null
  required property var configuration
  required property var actionSettings
  property bool active: true

  readonly property var cfg: configuration
  property string systemStr: ""
  property string aurStr: ""
  property string flatpakStr: ""
  property var updates: []
  property bool refreshing: false
  property var noctaliaNames: ["noctalia-qs", "noctalia-shell"]
  property bool noctaliaUpdate: false

  function checkNoctalia(string) {
    if (noctaliaNames.some(name => string.includes(name)) && cfg.noctalia) {
      root.noctaliaUpdate = true;
      Logger.d("Arch Updater", "Noctalia updates found");
    } else {
      Logger.d("Arch Updater", "No Noctalia updates found");
    }
  }

  Process {
    id: getHomepage
    property string _output: ""
    property var _callback: null
    stdout: SplitParser {
      onRead: data => getHomepage._output += data + "\n"
    }
    onExited: {
      if (root.active && _callback)
        _callback(_output);
      _output = "";
      _callback = null;
    }
    function run(cmd, callback) {
      _output = "";
      _callback = callback;
      command = cmd;
      running = true;
    }
  }

  function openHomepage(source, id) {
    var url = "";
    switch (source) {
    case "system":
      getHomepage.run(["sh", "-c", "LC_ALL=C pacman -Si " + id + " 2>/dev/null | awk '/^URL/ {print $3; exit}'"], output => {
        url = output.trim();
        Logger.i("Arch Updater", "Opening Homepage (System): " + url);
        Qt.openUrlExternally(url);
      });
      break;
    case "aur":
      getHomepage.run(["sh", "-c", String(actionSettings().aurHomepageCmd || "").replace("{id}", id)], output => {
        url = output.trim();
        Logger.i("Arch Updater", "Opening Homepage (AUR): " + url);
        Qt.openUrlExternally(url);
      });
      break;
    case "flatpak":
      getHomepage.run(["sh", "-c", "LC_ALL=C appstreamcli get " + id + " 2>/dev/null | awk '/^Homepage/ {print $2}'"], output => {
        url = output.trim();
        Logger.i("Arch Updater", "Opening Homepage (Flatpak): " + url);
        Qt.openUrlExternally(url);
      });
      break;
    default:
      Logger.w("Arch Updater", "Unkown source: " + source);
      ToastService.showError("Unable to open Homepage<br>Unkown source: " + source);
      break;
    }
  }

  function refresh() {
    if (!active)
      return;
    Logger.i("Arch Updater", "Refreshing updates...");
    if (actionSettings().toast)
      ToastService.showNotice("Refreshing updates...");
    root.systemStr = "";
    root.aurStr = "";
    root.flatpakStr = "";
    root.updates = [];
    root.noctaliaUpdate = false;
    root.refreshing = true;
    // Configurable check command (output format: "name oldver -> newver").
    getSystemUpdates.command = ["sh", "-c", cfg.systemCmd];
    getSystemUpdates.running = true;
  }

  function rows(output, source, separator, nameColumn, oldColumn, newColumn) {
    var names = [];
    var result = [];
    for (var line of output.split("\n")) {
      var parts = line.split(separator);
      if (parts.length >= 4) {
        names.push(parts[nameColumn]);
        result.push({
                      id: parts[0],
                      name: parts[nameColumn],
                      oldVer: parts[oldColumn],
                      newVer: parts[newColumn],
                      source: source
                    });
      }
    }
    return {
      names: names,
      rows: result
    };
  }

  function startAur() {
    getAURUpdates.command = ["sh", "-c", cfg.aurCmd];
    getAURUpdates.running = true;
  }

  function startFlatpak() {
    if (cfg.flatpak)
      getFlatpakUpdates.running = true;
    else
      root.refreshing = false;
  }

  Process {
    id: getSystemUpdates
    onExited: (exitCode, exitStatus) => {
      if (root.active && exitCode !== 0) {
        Logger.w("Arch Updater", "Check command exited with code " + exitCode);
        root.refreshing = false;
      }
    }
    stdout: StdioCollector {
      onStreamFinished: {
        if (!root.active)
          return;
        var output = this.text.slice(0, -1);
        if (output) {
          var parsed = root.rows(output, "system", /\s+/, 0, 1, 3);
          root.systemStr = parsed.names.join("\n");
          root.updates = parsed.rows;
          Logger.d("Arch Updater", "System update count: " + parsed.names.length);
        } else {
          Logger.d("Arch Updater", "No system updates found");
        }
        root.startAur();
      }
    }
  }

  Process {
    id: getAURUpdates
    onExited: (exitCode, exitStatus) => {
      if (root.active && exitCode !== 0) {
        Logger.w("Arch Updater", "Check command exited with code " + exitCode);
        root.refreshing = false;
      }
    }
    stdout: StdioCollector {
      onStreamFinished: {
        if (!root.active)
          return;
        var output = this.text.slice(0, -1);
        if (!output) {
          Logger.d("Arch Updater", "No AUR updates found");
          root.startFlatpak();
          return;
        }
        var parsed = root.rows(output, "aur", /\s+/, 0, 1, 3);
        root.aurStr = parsed.names.join("\n");
        root.updates = root.updates.concat(parsed.rows);
        Logger.d("Arch Updater", "AUR update count: " + parsed.names.length);
        root.checkNoctalia(root.systemStr + root.aurStr);
        root.startFlatpak();
      }
    }
  }

  // Refreshes metadata using --no-deploy first so that the new version numbers
  // get fetched, then joins remote (new) with installed (old) versions by ID.
  Process {
    id: getFlatpakUpdates
    command: ["sh", "-c", "flatpak update --no-deploy --noninteractive >/dev/null 2>&1; join -t'\t' -j1 <(flatpak remote-ls --updates --columns=application,name,version 2>/dev/null | sort -t'\t' -k1,1) <(flatpak list --columns=application,version 2>/dev/null | sort -t'\t' -k1,1)"]
    onExited: (exitCode, exitStatus) => {
      if (root.active && exitCode !== 0) {
        Logger.w("Arch Updater", "Flatpak check exited with code " + exitCode);
        root.refreshing = false;
      }
    }
    stdout: StdioCollector {
      onStreamFinished: {
        if (!root.active)
          return;
        var output = this.text.slice(0, -1);
        if (output) {
          var parsed = root.rows(output, "flatpak", /\t+/, 1, 3, 2);
          root.flatpakStr = parsed.names.join("\n");
          root.updates = root.updates.concat(parsed.rows);
          Logger.d("Arch Updater", "Flatpak update count: " + parsed.names.length);
        } else {
          Logger.d("Arch Updater", "No flatpak updates found");
        }
        root.refreshing = false;
      }
    }
  }

  Timer {
    interval: root.cfg.refreshInterval * 60000
    running: root.active
    repeat: true
    onTriggered: {
      Logger.d("Arch Updater", "Timer refresh...");
      root.refresh();
    }
  }

  Component.onCompleted: refresh()
}
