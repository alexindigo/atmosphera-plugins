import QtQuick
import qs.Commons

Item {
  id: client
  required property var settingsContext
  required property var pluginApi
  required property var observation
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string serverUrl: cfg.serverUrl ?? defaults.serverUrl ?? "https://ntfy.sh"
  readonly property string topics: cfg.topics ?? defaults.topics ?? ""
  readonly property string authMethod: cfg.authMethod ?? defaults.authMethod ?? "none"
  readonly property string authToken: cfg.authToken ?? defaults.authToken ?? ""
  readonly property string authUsername: cfg.authUsername ?? defaults.authUsername ?? ""
  readonly property string authPassword: cfg.authPassword ?? defaults.authPassword ?? ""
  readonly property int pollInterval: cfg.pollInterval ?? defaults.pollInterval ?? 30
  readonly property bool enableToasts: cfg.enableToasts ?? defaults.enableToasts ?? true
  readonly property int maxMessages: cfg.maxMessages ?? defaults.maxMessages ?? 100
  readonly property string sourceKey: JSON.stringify([serverUrl, topics, authMethod, authToken, authUsername, authPassword])
  readonly property string cleanTopics: topics.split(",").map(t => t.trim()).filter(t => t.length > 0).join(",")
  readonly property int unreadCount: messages.filter(message => !isMessageRead(message.id)).length
  property var messages: []
  readonly property bool isLoading: _request !== null
  property string errorMessage: ""
  property int lastPollTimestamp: 0
  property var _request: null
  property bool _constructed: false
  signal messagesUpdated()
  function _releaseRequest(xhr) {
    if (!xhr || _request !== xhr) return false;
    xhr.onreadystatechange = function() {};
    deadline.stop();
    _request = null;
    return true;
  }
  function cancel() {
    const xhr = _request;
    if (_releaseRequest(xhr)) xhr.abort();
  }
  function replaceSource() {
    cancel(); messages = []; lastPollTimestamp = 0; errorMessage = "";
    if (current) pollMessages();
  }
  function pollMessages() {
    if (!current || isLoading || !cleanTopics.length) return;
    var server = serverUrl.replace(/\/+$/, "");
    var url = server + "/" + encodeURIComponent(cleanTopics) + "/json?poll=1&since=" + (lastPollTimestamp > 0 ? lastPollTimestamp + 1 : Math.floor(Date.now() / 1000) - 86400);
    var xhr = new XMLHttpRequest(); _request = xhr;
    errorMessage = "";
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== XMLHttpRequest.DONE || !client.current || !client._releaseRequest(xhr)) return;
      if (xhr.status === 200) {
        try { client.parseMessages(xhr.responseText, server); }
        catch (error) { client.errorMessage = pluginApi?.tr("error.parse"); }
      } else client.errorMessage = pluginApi?.tr(xhr.status === 401 || xhr.status === 403 ? "error.auth" : xhr.status === 0 ? "error.network" : "error.server");
    };
    try {
      xhr.open("GET", url);
      if (authMethod === "token" && authToken.length > 0) xhr.setRequestHeader("Authorization", "Bearer " + authToken);
      else if (authMethod === "basic" && authUsername.length > 0) xhr.setRequestHeader("Authorization", "Basic " + Qt.btoa(authUsername + ":" + authPassword));
      deadline.restart();
      xhr.send();
    } catch (error) {
      if (_releaseRequest(xhr)) {
        xhr.abort();
        errorMessage = pluginApi?.tr("error.network");
      }
    }
  }
  function parseMessages(responseText, server) {
    var newMessages = [], latest = lastPollTimestamp;
    for (var line of responseText.split("\n")) {
      if (!line.trim()) continue;
      try {
        var msg = JSON.parse(line);
        if (msg.event !== "message") continue;
        if (msg.time && msg.time > latest) latest = msg.time;
        newMessages.push({id: msg.id || "", time: msg.time || 0, topic: msg.topic || "", title: msg.title || "", message: msg.message || "", priority: msg.priority || 3, tags: msg.tags || [], click: msg.click || ""});
      } catch (error) { Logger.d("ntfy", "Skipping malformed message"); }
    }
    lastPollTimestamp = latest;
    var ids = new Set(messages.map(message => message.id));
    var trulyNew = newMessages.filter(message => !ids.has(message.id));
    if (!trulyNew.length) return;
    if (enableToasts) observation.showToasts(client, server, trulyNew);
    var all = trulyNew.concat(messages);
    all.sort((a, b) => b.time - a.time);
    messages = all.length > maxMessages ? all.slice(0, maxMessages) : all;
    messagesUpdated();
  }
  function isMessageRead(messageId) { return observation.readMessageIdIndex.has(messageId); }
  function markAsRead(messageId) {
    if (current && messages.some(message => message.id === messageId)) observation.persistReadIds(client, [messageId]);
  }
  function markAllAsRead() { if (current) observation.persistReadIds(client, messages.map(message => message.id)); }
  Timer { interval: client.pollInterval * 1000; running: client.current && client.cleanTopics.length > 0; repeat: true; onTriggered: client.pollMessages() }
  // Qt's QML XMLHttpRequest does not expose a request timeout.
  Timer {
    id: deadline
    interval: 15000
    onTriggered: {
      const xhr = client._request;
      if (!client._releaseRequest(xhr)) return;
      xhr.abort();
      if (client.current) client.errorMessage = client.pluginApi?.tr("error.network");
    }
  }
  onSourceKeyChanged: if (_constructed) replaceSource()
  onMaxMessagesChanged: if (_constructed && messages.length > maxMessages) messages = messages.slice(0, maxMessages)
  onCurrentChanged: if (!current && _constructed) { cancel(); retire(client); }
  Component.onCompleted: { _constructed = true; replaceSource(); }
  Component.onDestruction: cancel()
}
