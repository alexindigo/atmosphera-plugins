import QtQuick

Item {
  id: client
  required property var settingsContext
  required property var pluginApi
  required property var observation
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string userId: cfg.habiticaUserId ?? defaults.habiticaUserId ?? ""
  readonly property string apiToken: cfg.habiticaApiToken ?? defaults.habiticaApiToken ?? ""
  readonly property bool isConfigured: userId.trim() !== "" && apiToken.trim() !== ""
  readonly property int refreshInterval: Math.max(60, cfg.refreshInterval ?? defaults.refreshInterval ?? 300)
  readonly property int maxDailies: cfg.maxDailies ?? defaults.maxDailies ?? 8
  readonly property int maxTodos: cfg.maxTodos ?? defaults.maxTodos ?? 8
  readonly property int maxHabits: cfg.maxHabits ?? defaults.maxHabits ?? 8
  readonly property bool showHabits: cfg.showHabits ?? defaults.showHabits ?? false
  readonly property bool showChecklistItems: cfg.showChecklistItems ?? defaults.showChecklistItems ?? false
  readonly property bool enableTagFilter: cfg.enableTagFilter ?? defaults.enableTagFilter ?? false
  readonly property string selectedTagId: cfg.selectedTagId ?? defaults.selectedTagId ?? ""
  readonly property string sourceKey: JSON.stringify([userId, apiToken, refreshInterval, showHabits, enableTagFilter])
  property var _worker: null
  property bool _constructed: false
  readonly property var user: _worker?.user ?? ({})
  readonly property var stats: _worker?.stats ?? ({})
  readonly property var dailies: _worker?.dailies ?? []
  readonly property var todos: _worker?.todos ?? []
  readonly property var habits: _worker?.habits ?? []
  readonly property var tags: _worker?.tags ?? []
  readonly property bool isLoading: _worker?.isLoading ?? false
  readonly property bool isScoring: _worker?.isScoring ?? false
  readonly property bool hasError: _worker?.hasError ?? false
  readonly property string errorMessage: _worker?.errorMessage ?? ""
  readonly property int lastFetchTimestamp: _worker?.lastFetchTimestamp ?? 0
  readonly property var visibleDailies: limitTasks(filterTasks(dailies, "daily"), maxDailies)
  readonly property var visibleTodos: limitTasks(filterTasks(todos, "todo"), maxTodos)
  readonly property var visibleHabits: showHabits ? limitTasks(filterTasks(habits, "habit"), maxHabits) : []
  readonly property int dueDailiesCount: filterTasks(dailies, "daily").length
  readonly property int dueTodosCount: filterTasks(todos, "todo").length
  readonly property int pendingCount: dueDailiesCount + dueTodosCount
  function isDueDaily(task) {
    if (!task || task.type !== "daily" || task.completed) return false;
    if (!task.nextDue || task.nextDue.length === 0) return true;
    var today = new Date(); today.setHours(0, 0, 0, 0);
    return task.nextDue.some(function(value) { var due = new Date(value); due.setHours(0, 0, 0, 0); return due <= today; });
  }
  function filterTasks(list, type) {
    var tag = enableTagFilter ? selectedTagId : "";
    return (list || []).filter(function(task) {
      if (!task || (tag && (!task.tags || task.tags.indexOf(tag) === -1))) return false;
      return type === "daily" ? isDueDaily(task) : type === "todo" ? task.type === "todo" && !task.completed : type === "habit" ? task.type === "habit" : true;
    });
  }
  function limitTasks(list, limit) { return (list || []).slice(0, Math.max(1, limit)); }
  function displayName() { return user?.profile?.name || user?.auth?.local?.username || "Habitica"; }
  function levelText() { var level = stats?.lvl || 0; return level > 0 ? "Level " + level : "Level --"; }
  function hpText() { return Math.max(0, Math.round(stats?.hp || 0)) + " HP"; }
  function goldText() { return Math.floor(stats?.gp || 0) + " gold"; }
  function xpText() { var exp = Math.floor(stats?.exp || 0), next = Math.floor(stats?.toNextLevel || 0); return next > 0 ? exp + " / " + next + " XP" : exp + " XP"; }
  function taskSummary(task) {
    if (!task) return "";
    var parts = [];
    if (task.priority) parts.push("difficulty " + task.priority);
    if (task.streak) parts.push("streak " + task.streak);
    if (task.value !== undefined) parts.push("value " + Math.round(task.value * 10) / 10);
    return parts.join(" - ");
  }
  function fetchAll(force) { if (current) _worker?.fetchAll(force); }
  function refresh() { fetchAll(true); }
  function scoreTask(taskId, direction) { if (current) _worker?.scoreTask(taskId, direction); }
  function completeTask(task) { if (task) scoreTask(task.id || task._id, "up"); }
  function scoreHabit(task, direction) { if (task) scoreTask(task.id || task._id, direction); }
  function scoreChecklistItem(task, item) { if (current) _worker?.scoreChecklistItem(task, item); }
  function retireWorker() {
    if (!_worker) return;
    var old = _worker; _worker = null; old.active = false; old.destroy();
  }
  function replaceSource() {
    retireWorker();
    if (!current || !isConfigured) return;
    _worker = workerFactory.createObject(client, {client: client, pluginApi: pluginApi, observation: observation,
      configuration: Object.freeze({userId: userId, apiToken: apiToken, refreshInterval: refreshInterval, showHabits: showHabits, enableTagFilter: enableTagFilter})});
  }
  Component { id: workerFactory; HabiticaQueryWorker {} }
  onSourceKeyChanged: if (_constructed) replaceSource()
  onCurrentChanged: if (!current && _constructed) { retireWorker(); retire(client); }
  Component.onCompleted: { _constructed = true; replaceSource(); }
  Component.onDestruction: retireWorker()
}
