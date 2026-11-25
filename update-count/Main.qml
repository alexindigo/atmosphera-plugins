import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  readonly property url updaterJson: Qt.resolvedUrl("file://" + Settings.configDir + "/plugins/update-count/updaterConfigs.json")
  readonly property int minutesToMillis: 60_000

  property var updater: null
  property var _settingsConsumers: new Map()
  Component { id: clientFactory; UpdateSettingsClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
      pluginApi: pluginApi, settingsContext: context, domain: root,
      retire: function(retired) {
        root._settingsConsumers.delete(context);
        retired.destroy();
      }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property int updateCount: settingsConsumer?.updateCount ?? 0
  readonly property int updateIntervalMinutes: settingsConsumer?.updateIntervalMinutes ?? 30
  readonly property string updateTerminalCommand: settingsConsumer?.updateTerminalCommand ?? ""
  readonly property var customUpdater: settingsConsumer?.customUpdater ?? ({})

  //
  // ------ Initialization ------
  //
  property var updaters: []
  property int checkIndex: 0
  property var current: null

  FileView {
    id: updaterFile
    path: root.updaterJson

    onLoaded: {
      try {
        root.updaters = JSON.parse(updaterFile.text());
        root.runAllCmdChecks();
      } catch (e) {
        Logger.e("UpdateCount", "JSON Error in", root.updaterJson, ":", e);
      }
    }
  }

  function runAllCmdChecks() {
    if (!root.updaters || root.updaters.length === 0) {
      return;
    }

    root.checkIndex = 0;
    root.checkNext();
  }

  function checkNext() {
    if (root.checkIndex >= root.updaters.length) {
      startGetNumUpdates();
      return;
    }

    root.current = root.updaters[root.checkIndex++];
    cmdCheckProc.command = ["sh", "-c", root.current.cmdCheck];
    cmdCheckProc.running = true;
  }

  Process {
    id: cmdCheckProc

    onExited: function (exitCode, exitStatus) {
      if (exitCode === 0) {
        root.updater = root.current
        Logger.i("UpdateCount", `Initialization finished. Detected updater: ${root.updater.name}.`);
        root.startGetNumUpdates()
      } else {
        root.checkNext();
      }
    }
  }

  //
  // ------ Get number of updates ------
  //
  function startGetNumUpdates() {
    settingsConsumer?.startGetNumUpdates();
  }

  //
  // ------ Start update ------
  //
  function startDoSystemUpdate() {
    settingsConsumer?.startDoSystemUpdate();
  }

  // One action process remains at the domain owner. Capture originating policy
  // before launch; later context/source retirement cannot retarget that action.
  function performSystemUpdate(updateCmd, terminalCommand) {
    const ipcCmd = "qs -c noctalia-shell ipc call plugin:update-count check"
    const combinedCmd = updateCmd + " && " + ipcCmd

    const term = terminalCommand.trim();
    const fullCmd = (term.indexOf("{}") !== -1) ? term.replace("{}", combinedCmd) : term + " " + combinedCmd;

    doSystemUpdate.command = ["sh", "-c", fullCmd]
    doSystemUpdate.running = true;

    Logger.i("UpdateCount", `Executed update command: ${fullCmd}`);
  }

  Process {
    id: doSystemUpdate
  }

  //
  // ------ IPC ------
  //
  IpcHandler {
    target: "plugin:update-count"

    function check(): void {
      root.startGetNumUpdates()
    }

    function run(): void {
      root.startDoSystemUpdate()
    }
  }
}
