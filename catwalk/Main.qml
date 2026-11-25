import QtQuick
import Quickshell
import qs.Services.System

Item {
  id: root

  property var pluginApi: null

  // Main owns one configuration projection per captured runtime context.
  // Physical CPU sampling remains shared; thresholds/backgrounds do not.
  property var _settingsConsumers: new Map()
  property Component _consumerFactory: Component {
    QtObject {
      id: consumer
      required property var settingsContext
      required property var readCpu
      required property var retire
      readonly property bool current: settingsContext.current()
      readonly property var cfg: current ? settingsContext.settingsView : ({})
      readonly property real minimumThreshold: cfg.minimumThreshold ?? 10
      readonly property bool hideBackground: cfg.hideBackground ?? false
      readonly property real cpuUsage: current ? readCpu() : 0
      readonly property bool isRunning: current && cpuUsage >= minimumThreshold
      onCurrentChanged: {
        if (!current)
          retire(consumer);
      }
    }
  }
  function settingsConsumerFor(context) {
    if (!context || !context.current())
      return null;
    if (_settingsConsumers.has(context))
      return _settingsConsumers.get(context);
    var client = _consumerFactory.createObject(root, {
                                                 settingsContext: context,
                                                 readCpu: function () {
                                                   return root.cpuUsage;
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
  readonly property real minimumThreshold: settingsConsumer?.minimumThreshold ?? 10
  readonly property bool hideBackground: settingsConsumer?.hideBackground ?? false

  property real cpuUsage: SystemStatService.cpuUsage
  readonly property bool isRunning: settingsConsumer?.isRunning ?? false

  readonly property var icons: ["icons/my-active-0-symbolic.svg", "icons/my-active-1-symbolic.svg", "icons/my-active-2-symbolic.svg", "icons/my-active-3-symbolic.svg", "icons/my-active-4-symbolic.svg"]
  readonly property var idleIcons: ["icons/my-idle-0-symbolic.svg", "icons/my-idle-1-symbolic.svg", "icons/my-idle-2-symbolic.svg", "icons/my-idle-3-symbolic.svg"]
}
