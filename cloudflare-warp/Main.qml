import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Plugins
import qs.Services.UI

Item {
  id: root

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
                                              return context.settingsView.refreshInterval ?? 5000;
                                            }),
                                            pollingEnabled: Qt.binding(function () {
                                              return root.warpInstalled;
                                            }),
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
  readonly property int refreshInterval: settingsConsumer?.sourceInterval ?? 5000

  property bool warpInstalled: false
  property bool warpConnected: false
  property string warpMode: ""
  property bool isRefreshing: false
  property string lastToggleAction: ""

  Timer {
    id: statusDelayTimer
    interval: 1500
    repeat: false
    onTriggered: root.refresh()
  }

  Component.onCompleted: {
    checkInstalled();
  }

  function checkInstalled() {
    root.isRefreshing = true;
    whichProcess.running = true;
  }

  function refresh() {
    if (root.isRefreshing)
      return;
    root.isRefreshing = true;
    statusProcess.running = true;
  }

  function connect() {
    root.lastToggleAction = "connect";
    connectProcess.running = true;
  }

  function disconnect() {
    root.lastToggleAction = "disconnect";
    disconnectProcess.running = true;
  }

  function toggleWarp() {
    if (root.warpConnected) {
      disconnect();
    } else {
      connect();
    }
  }

  Process {
    id: whichProcess
    command: ["which", "warp-cli"]
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      root.warpInstalled = (exitCode === 0);
      root.isRefreshing = false;
      if (root.warpInstalled) {
        root.refresh();
      } else {
        Logger.w("CloudflareWarp", "warp-cli not found in PATH");
      }
    }
  }

  Process {
    id: statusProcess
    command: ["warp-cli", "status"]
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      root.isRefreshing = false;
      var output = String(statusProcess.stdout.text || "").trim();

      if (exitCode === 0 && output) {
        if (/status update:\s*disconnected/i.test(output)) {
          root.warpConnected = false;
        } else if (/status update:\s*connected/i.test(output)) {
          root.warpConnected = true;
        } else {
          root.warpConnected = false;
        }

        var modeMatch = output.match(/[Dd]aemon [Mm]ode:\s*(\S+)/);
        if (modeMatch) {
          root.warpMode = modeMatch[1];
        } else {
          root.warpMode = "";
        }
      } else {
        root.warpConnected = false;
        root.warpMode = "";
        if (exitCode !== 0) {
          Logger.w("CloudflareWarp", "warp-cli status failed: " + String(statusProcess.stderr.text || "").trim());
        }
      }
    }
  }

  Process {
    id: connectProcess
    command: ["warp-cli", "connect"]
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      if (exitCode === 0) {
        ToastService.showNotice(pluginApi?.tr("toast.title"), pluginApi?.tr("toast.connected"), "cloud-lock");
      } else {
        var err = String(connectProcess.stderr.text || "").trim();
        Logger.e("CloudflareWarp", "Connect failed: " + err);
        ToastService.showWarning(pluginApi?.tr("toast.title"), err || "Connect failed");
      }
      statusDelayTimer.start();
    }
  }

  Process {
    id: disconnectProcess
    command: ["warp-cli", "disconnect"]
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      if (exitCode === 0) {
        ToastService.showNotice(pluginApi?.tr("toast.title"), pluginApi?.tr("toast.disconnected"), "cloud-off");
      } else {
        var err = String(disconnectProcess.stderr.text || "").trim();
        Logger.e("CloudflareWarp", "Disconnect failed: " + err);
        ToastService.showWarning(pluginApi?.tr("toast.title"), err || "Disconnect failed");
      }
      statusDelayTimer.start();
    }
  }
}
