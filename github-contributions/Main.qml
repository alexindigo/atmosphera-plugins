import QtQuick
import Quickshell.Io

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component {
    id: clientFactory
    ContributionsSettingsClient {}
  }
  function settingsConsumerFor(context) {
    if (!context || !context.current())
      return null;
    if (_settingsConsumers.has(context))
      return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
                                              settingsContext: context,
                                              pluginApi: pluginApi,
                                              retire: function (retired) {
                                                root._settingsConsumers.delete(context);
                                                retired.destroy();
                                              }
                                            });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property string username: settingsConsumer?.username ?? ""
  readonly property string token: settingsConsumer?.token ?? ""
  readonly property var days: settingsConsumer?.days ?? []
  readonly property int totalContributions: settingsConsumer?.totalContributions ?? 0
  readonly property int currentStreak: settingsConsumer?.currentStreak ?? 0
  readonly property bool loading: settingsConsumer?.loading ?? false
  readonly property bool hasData: settingsConsumer?.hasData ?? false
  readonly property string errorMessage: settingsConsumer?.errorMessage ?? ""
  function refresh() {
    settingsConsumer?.refresh();
  }
  IpcHandler {
    target: "plugin:github-contributions"
    function refresh() {
      root.refresh();
    }
  }
}
