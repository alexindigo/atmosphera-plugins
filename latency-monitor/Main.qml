import QtQuick

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component { id: clientFactory; LatencySettingsClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
      pluginApi: pluginApi,
      settingsContext: context,
      retire: function(retired) {
        root._settingsConsumers.delete(context);
        retired.destroy();
      }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  // Existing non-placement Main callers remain explicitly plugin-level.
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property var hosts: settingsConsumer?.hosts ?? []
  readonly property var displayHost: settingsConsumer?.displayHost ?? null
  readonly property var worstHost: settingsConsumer?.worstHost ?? null
  readonly property string status: settingsConsumer?.status ?? "unknown"
  readonly property int intervalSeconds: settingsConsumer?.intervalSeconds ?? 5
  readonly property int thresholdGood: settingsConsumer?.thresholdGood ?? 20
  readonly property int thresholdWarning: settingsConsumer?.thresholdWarning ?? 70
  readonly property bool showHostName: settingsConsumer?.showHostName ?? true
  readonly property string barHost: settingsConsumer?.barHost ?? "worst"
  readonly property string colorGood: settingsConsumer?.colorGood ?? "#00ff7f"
  readonly property string colorWarning: settingsConsumer?.colorWarning ?? "#f1fa8c"
  readonly property string colorCritical: settingsConsumer?.colorCritical ?? "#ff5555"
  readonly property bool animations: settingsConsumer?.animations ?? true
}
