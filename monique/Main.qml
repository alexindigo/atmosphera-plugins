import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Plugins

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
                                              return root.moniqueInstalled;
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

  property bool moniqueInstalled: false
  property string moniquePath: ""
  property string activeProfile: ""
  property var profiles: []
  property bool isRefreshing: false

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
    currentProfileProcess.running = true;
  }

  function switchProfile(name) {
    switchProcess.profileName = name;
    switchProcess.running = true;
  }

  Process {
    id: whichProcess
    command: ["which", "monique"]
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      if (exitCode === 0) {
        var resolved = String(whichProcess.stdout.text || "").trim();
        if (resolved !== "") {
          root.moniquePath = resolved;
          root.moniqueInstalled = true;
          root.isRefreshing = false;
          root.refresh();
          listProfilesProcess.running = true;
          return;
        }
      }
      root.moniqueInstalled = false;
      root.isRefreshing = false;
      Logger.w("Monique", "monique not found in PATH");
    }
  }

  Process {
    id: listProfilesProcess
    command: [root.moniquePath, "--list-profiles"]
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      if (exitCode === 0) {
        try {
          root.profiles = JSON.parse(String(listProfilesProcess.stdout.text || "[]").trim());
        } catch (e) {
          root.profiles = [];
          Logger.w("Monique", "Failed to parse profiles: " + e);
        }
      }
    }
  }

  Process {
    id: currentProfileProcess
    command: [root.moniquePath, "--current-profile"]
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      root.isRefreshing = false;
      if (exitCode === 0) {
        root.activeProfile = String(currentProfileProcess.stdout.text || "").trim();
      } else {
        root.activeProfile = "";
      }
    }
  }

  Process {
    id: switchProcess

    property string profileName: ""

    command: [root.moniquePath, "--switch-profile", profileName]
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: function (exitCode) {
      if (exitCode === 0) {
        root.activeProfile = switchProcess.profileName;
        ToastService.showNotice(pluginApi?.tr("toast.title"), pluginApi?.tr("toast.switched", {
                                                                              profile: switchProcess.profileName
                                                                            }), "device-desktop");
      } else {
        var err = String(switchProcess.stderr.text || "").trim();
        Logger.e("Monique", "Switch failed: " + err);
        ToastService.showWarning(pluginApi?.tr("toast.title"), err || pluginApi?.tr("toast.error"));
      }
    }
  }
}
