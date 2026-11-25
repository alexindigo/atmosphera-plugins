import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  property Component clientFactory: Component { SyncthingSettingsClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
      pluginApi: pluginApi, settingsContext: context,
      retire: function(retired) {
        root._settingsConsumers.delete(context);
        retired.destroy();
      }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property bool enabled: settingsConsumer?.enabled ?? false
  readonly property bool busy: settingsConsumer?.busy ?? false
  readonly property string state: settingsConsumer?.state ?? "unconfigured"
  readonly property var snapshot: settingsConsumer?.snapshot ?? ({})
  function requestPoll(force) { settingsConsumer?.requestPoll(force); }
  function statusSummary() { return settingsConsumer?.statusSummary() ?? ""; }
  function toggleFolder(id) { return settingsConsumer?.toggleFolder(id, root.pluginApi) ?? false; }
  function setFolderSelection(ids) { return settingsConsumer?.setFolderSelection(ids, root.pluginApi) ?? false; }
  property IpcHandler ipc: IpcHandler {
    target: "plugin:syncthing-status"
    function refresh() { root.requestPoll(true); }
    function toggle() {
      if (root.pluginApi?.pluginSettings) {
        root.pluginApi.pluginSettings.enabled = !root.enabled;
        root.pluginApi.saveSettings();
      }
    }
    function status() {
      return {enabled: root.enabled, busy: root.busy, state: root.state,
        summary: root.statusSummary(), devices: root.snapshot.devices, totals: root.snapshot.totals};
    }
  }
}
