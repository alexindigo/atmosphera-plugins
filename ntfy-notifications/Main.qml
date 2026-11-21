import QtQuick
import Quickshell.Io
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  property var _notified: new Set()
  Component { id: clientFactory; NtfySettingsClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
      settingsContext: context, pluginApi: pluginApi, observation: root,
      retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property var messages: settingsConsumer?.messages ?? []
  readonly property int unreadCount: settingsConsumer?.unreadCount ?? 0
  readonly property bool isLoading: settingsConsumer?.isLoading ?? false
  readonly property string errorMessage: settingsConsumer?.errorMessage ?? ""
  readonly property string topics: settingsConsumer?.topics ?? ""
  // The pre-existing protected operational leaf retains its one Main writer.
  readonly property var readMessageIds: pluginApi?.pluginSettings?.readMessageIds ?? []
  function pollMessages() { settingsConsumer?.pollMessages(); }
  function isMessageRead(messageId) { return settingsConsumer?.isMessageRead(messageId) ?? false; }
  function markAsRead(messageId) { settingsConsumer?.markAsRead(messageId); }
  function markAllAsRead() { settingsConsumer?.markAllAsRead(); }
  function persistReadIds(caller, ids) {
    if (!caller.current || _settingsConsumers.get(caller.settingsContext) !== caller || !pluginApi?.settingsContext.current()) return;
    var merged = readMessageIds.slice();
    for (var id of ids) if (merged.indexOf(id) === -1) merged.push(id);
    pluginApi.pluginSettings.readMessageIds = merged;
    pluginApi.saveSettings();
  }
  function showToasts(caller, server, incoming) {
    if (!caller.current || !caller.enableToasts) return;
    var fresh = incoming.filter(function(message) {
      var key = JSON.stringify([server, message.id]);
      if (root._notified.has(key)) return false;
      root._notified.add(key);
      return true;
    });
    if (fresh.length === 1) ToastService.showNotice(fresh[0].title || fresh[0].topic || pluginApi?.tr("toast.newMessage"), fresh[0].message, "bell");
    else if (fresh.length > 1) ToastService.showNotice(pluginApi?.tr("toast.newMessages", {count: fresh.length}), "", "bell");
  }
  IpcHandler {
    target: "plugin:ntfy-notifications"
    function refresh() { root.pollMessages(); }
    function toggle() { pluginApi?.withCurrentScreen(screen => pluginApi.togglePanel(screen)); }
  }
}
