import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component { id: clientFactory; KubectlSettingsClient {} }
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
  readonly property var contexts: settingsConsumer?.contexts ?? []
  readonly property string activeContext: settingsConsumer?.activeContext ?? ""
  readonly property var namespaces: settingsConsumer?.namespaces ?? []
  readonly property string activeNamespace: settingsConsumer?.activeNamespace ?? ""
  readonly property var pods: settingsConsumer?.pods ?? []
  readonly property var deployments: settingsConsumer?.deployments ?? []
  readonly property var statefulsets: settingsConsumer?.statefulsets ?? []
  readonly property var daemonsets: settingsConsumer?.daemonsets ?? []
  readonly property var services: settingsConsumer?.services ?? []
  readonly property var ingresses: settingsConsumer?.ingresses ?? []
  readonly property var configmaps: settingsConsumer?.configmaps ?? []
  readonly property var secrets: settingsConsumer?.secrets ?? []
  readonly property bool loading: settingsConsumer?.loading ?? false
  readonly property bool hasError: settingsConsumer?.hasError ?? false
  readonly property bool hasCriticalPod: settingsConsumer?.hasCriticalPod ?? false
  function fetchContexts() { settingsConsumer?.fetchContexts(); }
  function fetchNamespaces() { settingsConsumer?.fetchNamespaces(); }
  function fetchResources() { settingsConsumer?.fetchResources(); }
  function switchContext(name) { settingsConsumer?.switchContext(name); }
  function switchNamespace(name) { settingsConsumer?.switchNamespace(name); }
  function deleteResource(kind, name) { settingsConsumer?.deleteResource(kind, name); }
  function restartResource(kind, name) { settingsConsumer?.restartResource(kind, name); }
  function copyToClipboard(text) { settingsConsumer?.copyToClipboard(text); }
  function openTerminal(args) { settingsConsumer?.openTerminal(args); }
  IpcHandler {
    target: "plugin:kubectl-ctx"
    function toggle() {
      root.pluginApi?.withCurrentScreen(screen => root.pluginApi.togglePanel(screen));
    }
    function refresh() { root.fetchContexts(); }
  }
}
