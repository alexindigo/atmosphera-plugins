import QtQuick

Item {
  id: root
  required property var pluginApi
  required property var settingsContext
  required property var retire
  readonly property bool current: settingsContext?.current() ?? false
  readonly property var cfg: settingsContext?.settingsView ?? ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
  readonly property string kubeconfigPath: cfg.kubeconfigPath ?? defaults.kubeconfigPath ?? ""
  readonly property int pollInterval: cfg.pollInterval ?? defaults.pollInterval ?? 60
  readonly property bool showErrorBadge: cfg.showErrorBadge ?? defaults.showErrorBadge ?? true
  readonly property string terminal: cfg.terminal ?? defaults.terminal ?? ""
  property bool _constructed: false
  property var _worker: null
  readonly property var contexts: _worker?.contexts ?? []
  readonly property string activeContext: _worker?.activeContext ?? ""
  readonly property var namespaces: _worker?.namespaces ?? []
  readonly property string activeNamespace: _worker?.activeNamespace ?? ""
  readonly property var pods: _worker?.pods ?? []
  readonly property var deployments: _worker?.deployments ?? []
  readonly property var statefulsets: _worker?.statefulsets ?? []
  readonly property var daemonsets: _worker?.daemonsets ?? []
  readonly property var services: _worker?.services ?? []
  readonly property var ingresses: _worker?.ingresses ?? []
  readonly property var configmaps: _worker?.configmaps ?? []
  readonly property var secrets: _worker?.secrets ?? []
  readonly property bool loading: _worker?.loading ?? false
  readonly property bool hasError: _worker?.hasError ?? false
  readonly property bool hasCriticalPod: _worker?.hasCriticalPod ?? false
  Component { id: workerFactory; KubectlQueryWorker {} }
  function _retireWorker() {
    if (!_worker) return;
    var old = _worker;
    _worker = null;
    old.stop(); old.destroy();
  }
  function _replaceQuery() {
    if (!_constructed) return;
    _retireWorker();
    if (!current) return;
    _worker = workerFactory.createObject(root, {pluginApi: pluginApi, settingsContext: settingsContext, kubeconfigPath: kubeconfigPath});
  }
  function fetchContexts() { if (current) _worker?.fetchContexts(); }
  function fetchNamespaces() { if (current) _worker?.fetchNamespaces(); }
  function fetchResources() { if (current) _worker?.fetchResources(); }
  function switchContext(name) { if (current) _worker?.switchContext(name); }
  function switchNamespace(name) { if (current) _worker?.switchNamespace(name); }
  function deleteResource(kind, name) { if (current) _worker?.deleteResource(kind, name); }
  function restartResource(kind, name) { if (current) _worker?.restartResource(kind, name); }
  function copyToClipboard(text) { if (current) _worker?.copyToClipboard(text); }
  function openTerminal(args) { if (current) _worker?.openTerminal(args); }
  onKubeconfigPathChanged: _replaceQuery()
  onCurrentChanged: if (!current && _constructed) { _retireWorker(); retire(root); }
  Component.onCompleted: { _constructed = true; _replaceQuery(); }
  Component.onDestruction: _retireWorker()
}
