import QtQuick

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component { id: clientFactory; HassSettingsClient {} }
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
  readonly property string haUrl: settingsConsumer?.haUrl ?? ""
  readonly property string haToken: settingsConsumer?.haToken ?? ""
  readonly property bool connected: settingsConsumer?.connected ?? false
  readonly property bool authenticated: settingsConsumer?.authenticated ?? false
  readonly property bool authFailed: settingsConsumer?.authFailed ?? false
  readonly property bool isReconnecting: settingsConsumer?.isReconnecting ?? false
  readonly property var entities: settingsConsumer?.entities ?? null
  signal entityUpdated(string entity_id)
  Connections {
    target: root.settingsConsumer
    function onEntityUpdated(entity_id) { root.entityUpdated(entity_id); }
  }
  function reconnect() { settingsConsumer?.reconnect(); }
  function reloadSettings() { settingsConsumer?.reloadSettings(); }
  function refreshEntities() { settingsConsumer?.refreshEntities(); }
  function getAllStates(callback) { settingsConsumer?.getAllStates(callback); }
  function callService(domain, service, entity_id) { settingsConsumer?.callService(domain, service, entity_id); }
  function callLightService(entity_id, brightness, color_temp) { settingsConsumer?.callLightService(entity_id, brightness, color_temp); }
  function callLightRgbService(entity_id, r, g, b) { settingsConsumer?.callLightRgbService(entity_id, r, g, b); }
  function callLightHsService(entity_id, h, s) { settingsConsumer?.callLightHsService(entity_id, h, s); }
}
