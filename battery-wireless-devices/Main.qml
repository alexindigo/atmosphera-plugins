import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Plugins

// Background logic for the Battery for Wireless Devices plugin.
//
// Polls scripts/scan.py on a timer, parses its normalized JSON, and exposes the
// live device list. The bar widget and settings UI both read `devices` from
// this instance via pluginApi.mainInstance.
Item {
  id: root

  // Injected by PluginService.
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component {
    id: pollFactory
    PluginSettingsPoller {}
  }
  function settingsConsumerFor(context) {
    if (!context || !context.current())
      return null;
    if (_settingsConsumers.has(context))
      return _settingsConsumers.get(context);
    var client = pollFactory.createObject(root, {
                                            settingsContext: context,
                                            sourceInterval: Qt.binding(function () {
                                              var s = context.settingsView.refreshInterval;
                                              return (typeof s === "number" && s > 0) ? s : 60;
                                            }),
                                            intervalScale: 1000,
                                            requestRefresh: function () {
                                              root.refresh();
                                            },
                                            retire: function (retired) {
                                              root._settingsConsumers.delete(context);
                                              retired.destroy();
                                            }
                                          });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null

  // Live, normalized device list: [{ id, name, type, battery, charging, source }].
  // Replaced wholesale on each successful scan so QML bindings re-fire.
  property var devices: []

  // True while a scan is in flight (used by the settings UI's refresh button).
  property bool scanning: false

  // Absolute path to the scan script. pluginDir is a plain filesystem path.
  readonly property string scriptPath: (pluginApi ? pluginApi.pluginDir : "") + "/scripts/scan.py"

  readonly property int refreshInterval: settingsConsumer?.sourceInterval ?? 60

  function refresh() {
    if (!pluginApi || scanner.running)
      return;
    root.scanning = true;
    scanner.running = true;
  }

  Component.onCompleted: refresh()

  Process {
    id: scanner
    command: ["python3", root.scriptPath]

    property string _buffer: ""

    // scan.py prints the JSON array on a single line; accumulate in case
    // the stream is delivered in multiple chunks.
    stdout: SplitParser {
      onRead: data => scanner._buffer += data
    }

    onExited: (exitCode, exitStatus) => {
      root.scanning = false;
      var text = _buffer.trim();
      _buffer = "";
      if (exitCode !== 0) {
        Logger.w("DeviceBattery", "scan.py exited with code", exitCode);
        return;
      }
      try {
        root.devices = JSON.parse(text);
      } catch (e) {
        Logger.e("DeviceBattery", "Failed to parse scan output:", e, "raw:", text);
      }
    }
  }

  // `qs -c noctalia-shell ipc call plugin:battery-wireless-devices refresh`
  IpcHandler {
    target: "plugin:battery-wireless-devices"

    function refresh(): string {
      root.refresh();
      return "Device battery scan triggered";
    }
  }
}
