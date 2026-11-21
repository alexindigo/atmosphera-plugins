import QtQuick

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component {
    id: clientFactory
    TextSettingsClient {}
  }
  function settingsConsumerFor(context) {
    if (!context || !context.current())
      return null;
    if (_settingsConsumers.has(context))
      return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
                                              settingsContext: context,
                                              pluginApi: pluginApi,
                                              retire: function(retired) {
                                                root._settingsConsumers.delete(context);
                                                retired.destroy();
                                              }
                                            });
    _settingsConsumers.set(context, client);
    return client;
  }
  // Existing nonplacement consumers retain their explicitly plugin-level owner.
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property string fortuneText: settingsConsumer?.fortuneText ?? ""
  readonly property string listText: settingsConsumer?.listText ?? ""
  function triggerFortune() { settingsConsumer?.triggerFortune(); }
  function pickFromFile() { settingsConsumer?.pickFromFile(); }
}
