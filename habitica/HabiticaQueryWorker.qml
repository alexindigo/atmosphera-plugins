import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

// Immutable account/chain generation. Inactive workers cannot continue or write.
Item {
  id: worker
  required property var configuration
  required property var client
  required property var observation
  required property var pluginApi
  property bool active: true
  readonly property string apiBaseUrl: "https://habitica.com/api/v3"
  readonly property string userId: configuration.userId
  readonly property string apiToken: configuration.apiToken
  readonly property bool isConfigured: userId.trim() !== "" && apiToken.trim() !== ""
  readonly property int refreshInterval: configuration.refreshInterval
  property var user: ({})
  property var stats: ({})
  property var dailies: []
  property var todos: []
  property var habits: []
  property var tags: []
  property bool isLoading: false
  property bool isScoring: false
  property bool hasError: false
  property string errorMessage: ""
  property int lastFetchTimestamp: 0
  property int avatarLastFetchTimestamp: 0
  property string _currentRequest: ""
  property var _currentCommand: ["true"]
  property string _nextKind: ""
  property string _nextMethod: "GET"
  property string _nextPath: ""
  property var _nextBody: null
  property string _scoringTaskId: ""
  function nowSeconds() { return Math.floor(Date.now() / 1000); }
  function userRequestPath() {
    var avatar = !user?.items || avatarLastFetchTimestamp <= 0 || nowSeconds() - avatarLastFetchTimestamp > 3600;
    return "/user?userFields=" + (avatar ? "stats,profile,preferences,items,notifications" : "stats,profile,preferences,notifications");
  }
  function requestCommand(method, path, body) {
    var args = ["curl", "-sS", "--max-time", "30", "-X", method,
      "-H", "x-api-user: " + userId.trim(), "-H", "x-api-key: " + apiToken.trim(),
      "-H", "x-client: " + userId.trim() + "-noctalia-habitica", "-H", "Accept: application/json"];
    if (body !== undefined && body !== null) args = args.concat(["-H", "Content-Type: application/json", "--data", JSON.stringify(body)]);
    args.push(apiBaseUrl + path);
    return args;
  }
  function runRequest(kind, method, path, body) {
    if (!active || !client.current || !isConfigured || apiProcess.running) return false;
    _currentRequest = kind;
    _currentCommand = requestCommand(method, path, body);
    apiProcess.running = true;
    return true;
  }
  function scheduleRequest(kind, method, path, body) {
    if (!active || !client.current) return;
    _nextKind = kind; _nextMethod = method; _nextPath = path; _nextBody = body === undefined ? null : body;
    nextRequestTimer.restart();
  }
  function fetchAll(force) {
    if (!active || !client.current || !isConfigured) return;
    if (!force && lastFetchTimestamp > 0 && nowSeconds() - lastFetchTimestamp < refreshInterval) return;
    if (apiProcess.running || isLoading || isScoring) return;
    isLoading = true; hasError = false; errorMessage = "";
    runRequest("user", "GET", userRequestPath());
  }
  function continueFetch() {
    if (!active) return;
    if (_currentRequest === "user") scheduleRequest("dailies", "GET", "/tasks/user?type=dailys");
    else if (_currentRequest === "dailies") scheduleRequest("todos", "GET", "/tasks/user?type=todos");
    else if (_currentRequest === "todos" && configuration.showHabits) scheduleRequest("habits", "GET", "/tasks/user?type=habits");
    else if ((_currentRequest === "todos" || _currentRequest === "habits") && configuration.enableTagFilter) scheduleRequest("tags", "GET", "/tags");
    else finishFetch();
  }
  function finishFetch() {
    if (!active || !client.current) return;
    lastFetchTimestamp = nowSeconds(); isLoading = false;
    observation.saveCache(client, worker, {
      user: user, stats: stats, dailies: dailies, todos: todos, habits: habits, tags: tags,
      timestamp: lastFetchTimestamp, avatarTimestamp: avatarLastFetchTimestamp
    });
  }
  function releaseScore() {
    observation.releaseScore(worker);
    isScoring = false; _scoringTaskId = "";
  }
  function handleApiResponse(kind, text, exitCode) {
    if (!active || !client.current) return;
    var response;
    try { response = JSON.parse(text); } catch (error) { response = null; }
    if (exitCode !== 0 || response?.success !== true) {
      isLoading = false; releaseScore(); hasError = true;
      errorMessage = exitCode !== 0 ? pluginApi?.tr("error.network") : response?.message || response?.error || pluginApi?.tr("error.request");
      return;
    }
    if (kind === "user") {
      var previous = user, next = response.data || ({});
      if (!next.items && previous.items) next.items = previous.items;
      user = next; stats = user.stats || ({});
      if (response.data?.items) avatarLastFetchTimestamp = nowSeconds();
      continueFetch();
    } else if (kind === "dailies") { dailies = response.data || []; continueFetch(); }
    else if (kind === "todos") { todos = response.data || []; continueFetch(); }
    else if (kind === "habits") { habits = response.data || []; continueFetch(); }
    else if (kind === "tags") { tags = response.data || []; finishFetch(); }
    else if (kind === "score") {
      releaseScore();
      if (response.data) stats = response.data;
      ToastService.showNotice(pluginApi?.tr("toast.taskScored"));
      isLoading = true; hasError = false; errorMessage = "";
      scheduleRequest("user", "GET", userRequestPath());
    }
  }
  function score(path, taskId) {
    if (!active || !client.current || !isConfigured || !taskId || isScoring || apiProcess.running || nextRequestTimer.running || !observation.claimScore(worker)) return;
    isScoring = true; _scoringTaskId = taskId;
    if (!runRequest("score", "POST", path)) releaseScore();
  }
  function scoreTask(taskId, direction) { score("/tasks/" + encodeURIComponent(taskId) + "/score/" + direction, taskId); }
  function scoreChecklistItem(task, item) {
    if (task && item) score("/tasks/" + encodeURIComponent(task.id || task._id) + "/checklist/" + encodeURIComponent(item.id) + "/score", task.id || task._id);
  }
  Process {
    id: apiProcess
    command: worker._currentCommand
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: exitCode => { if (worker.active && worker.client.current) worker.handleApiResponse(worker._currentRequest, String(stdout.text || ""), exitCode); }
  }
  Timer {
    id: nextRequestTimer
    interval: 1
    repeat: false
    onTriggered: {
      if (!worker.active || !worker.client.current) return;
      if (apiProcess.running) { nextRequestTimer.restart(); return; }
      worker.runRequest(worker._nextKind, worker._nextMethod, worker._nextPath, worker._nextBody);
    }
  }
  Timer { interval: worker.refreshInterval * 1000; repeat: true; running: worker.active && worker.client.current && worker.isConfigured; onTriggered: worker.fetchAll(false) }
  onActiveChanged: if (!active) { nextRequestTimer.stop(); apiProcess.running = false; releaseScore(); }
  Component.onCompleted: Qt.callLater(function() {
    if (!worker.active || !client.current) return;
    var cached = observation.cacheFor(client, worker);
    if (cached) {
      user = cached.user || ({}); stats = cached.stats || user.stats || ({});
      dailies = cached.dailies || []; todos = cached.todos || []; habits = cached.habits || []; tags = cached.tags || [];
      lastFetchTimestamp = cached.timestamp || 0; avatarLastFetchTimestamp = cached.avatarTimestamp || 0;
    }
    fetchAll(false);
  })
}
