import QtQuick
import Quickshell

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component { id: clientFactory; NewsSettingsClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
      settingsContext: context, pluginApi: pluginApi,
      retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property var newsData: settingsConsumer?.newsData ?? []
  readonly property string errorMessage: settingsConsumer?.errorMessage ?? ""
  readonly property bool isLoading: settingsConsumer?.isLoading ?? false
  function requestRefresh() { settingsConsumer?.requestRefresh(); }
}
