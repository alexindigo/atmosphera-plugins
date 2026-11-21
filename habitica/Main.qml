import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  property var _scoreOwner: null
  Component { id: clientFactory; HabiticaSettingsClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {settingsContext: context, pluginApi: pluginApi, observation: root,
      retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }});
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property bool isConfigured: settingsConsumer?.isConfigured ?? false
  readonly property var user: settingsConsumer?.user ?? ({})
  readonly property var stats: settingsConsumer?.stats ?? ({})
  readonly property var visibleDailies: settingsConsumer?.visibleDailies ?? []
  readonly property var visibleTodos: settingsConsumer?.visibleTodos ?? []
  readonly property var visibleHabits: settingsConsumer?.visibleHabits ?? []
  readonly property var tags: settingsConsumer?.tags ?? []
  readonly property int pendingCount: settingsConsumer?.pendingCount ?? 0
  readonly property bool isLoading: settingsConsumer?.isLoading ?? false
  readonly property bool isScoring: _scoreOwner !== null
  readonly property bool hasError: settingsConsumer?.hasError ?? false
  readonly property string errorMessage: settingsConsumer?.errorMessage ?? ""
  readonly property int lastFetchTimestamp: settingsConsumer?.lastFetchTimestamp ?? 0
  function refresh() { settingsConsumer?.refresh(); }
  function fetchAll(force) { settingsConsumer?.fetchAll(force); }
  function displayName() { return settingsConsumer?.displayName() ?? "Habitica"; }
  function levelText() { return settingsConsumer?.levelText() ?? "Level --"; }
  function hpText() { return settingsConsumer?.hpText() ?? "0 HP"; }
  function goldText() { return settingsConsumer?.goldText() ?? "0 gold"; }
  function xpText() { return settingsConsumer?.xpText() ?? "0 XP"; }
  function completeTask(task) { settingsConsumer?.completeTask(task); }
  function scoreHabit(task, direction) { settingsConsumer?.scoreHabit(task, direction); }
  function scoreChecklistItem(task, item) { settingsConsumer?.scoreChecklistItem(task, item); }
  function claimScore(worker) {
    if (!worker.active || !worker.client.current || (_scoreOwner && _scoreOwner !== worker)) return false;
    _scoreOwner = worker; return true;
  }
  function releaseScore(worker) { if (_scoreOwner === worker) _scoreOwner = null; }
  function cacheOwner(caller, worker) {
    return pluginApi?.settingsContext.current() && caller === settingsConsumer && caller.current && caller._worker === worker && worker.active && worker.userId === settingsConsumer.userId;
  }
  function cacheFor(caller, worker) {
    if (!cacheOwner(caller, worker)) return null;
    try {
      var stored = pluginApi.pluginSettings._habiticaCache;
      if (!stored) return null;
      var cached = typeof stored === "string" ? JSON.parse(stored) : stored;
      return cached.schema === 1 && cached.sourceUserId === worker.userId ? cached : null;
    } catch (error) { return null; }
  }
  function saveCache(caller, worker, data) {
    if (!cacheOwner(caller, worker)) return;
    pluginApi.pluginSettings._habiticaCache = JSON.stringify(Object.assign({schema: 1, sourceUserId: worker.userId}, data));
    pluginApi.saveSettings();
  }
  IpcHandler {
    target: "plugin:habitica"
    function refresh() { root.refresh(); }
    function toggle() { pluginApi?.withCurrentScreen(screen => pluginApi.togglePanel(screen)); }
  }
}
