import QtQuick
import Quickshell.Io

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component {
    id: clientFactory
    GitSettingsClient {}
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
  // Existing plugin-level entry points remain explicitly plugin-scoped.
  readonly property string platform: settingsConsumer?.platform ?? "github"
  readonly property string repo: settingsConsumer?.repo ?? ""
  readonly property string group: settingsConsumer?.group ?? ""
  readonly property int refreshInterval: settingsConsumer?.refreshInterval ?? 60
  readonly property bool hasScope: settingsConsumer?.hasScope ?? false
  readonly property bool loading: settingsConsumer?.loading ?? false
  readonly property string lastError: settingsConsumer?.lastError ?? ""
  readonly property string lastUpdate: settingsConsumer?.lastUpdate ?? ""
  readonly property bool isBinInstalled: settingsConsumer?.isBinInstalled ?? false
  readonly property bool isAuthenticated: settingsConsumer?.isAuthenticated ?? false
  readonly property string username: settingsConsumer?.username ?? ""
  readonly property string avatarUrl: settingsConsumer?.avatarUrl ?? ""
  readonly property string bio: settingsConsumer?.bio ?? ""
  readonly property int issuesCount: settingsConsumer?.issuesCount ?? 0
  readonly property var issuesList: settingsConsumer?.issuesList ?? []
  readonly property int prsCount: settingsConsumer?.prsCount ?? 0
  readonly property var prsList: settingsConsumer?.prsList ?? []
  function refresh() {
    if (settingsConsumer)
      settingsConsumer.refresh();
  }
  function openUrl(url) {
    if (settingsConsumer)
      settingsConsumer.openUrl(url);
  }
  IpcHandler {
    target: "plugin:git-companion"
    function toggle() {
      if (root.pluginApi)
        root.pluginApi.withCurrentScreen(screen => root.pluginApi.openPanel(screen));
    }
    function refresh() {
      root.refresh();
    }
  }
}
