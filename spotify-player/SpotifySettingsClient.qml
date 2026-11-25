import QtQuick
import Quickshell
import Quickshell.Io
import "Auth.js" as Auth
import qs.Commons
import qs.Services.UI

// Main owns this client and its IO, not any particular Panel or Settings page.
Item {
  id: root
  required property var settingsContext
  required property var observation
  required property var retire
  readonly property bool current: settingsContext.current()
  property var _runtimeApi: null
  readonly property var cfg: _runtimeApi ? _runtimeApi.pluginSettings : settingsContext.settingsView
  readonly property int callbackPort: cfg.callbackPort ?? 8888
  readonly property string credentialsKey: JSON.stringify([cfg.clientId || "", cfg.clientSecret || "", cfg.callbackPort ?? 8888])
  readonly property string accessToken: cfg.accessToken || ""
  readonly property string playerId: cfg.playerId || ""
  readonly property bool busy: _authorization !== null || callbackServer.running || browser.running || _request !== null || _saving
  readonly property string status: busy ? "pending" : error ? "failed" : accessToken ? "token-available" : "not-authorized"
  property string error: ""
  property string availableDevices: ""
  property var searchResults: []
  property var playlistResults: []
  property bool shuffleState: false
  property var _authorization: null
  property var _request: null
  property bool _saving: false
  property int _generation: 0
  property var _processes: new Set()
  property var _slots: new Map()
  property bool _constructed: false
  property var _lifetime: ({alive: true})

  function inputFor(api) {
    if (!current || !api || api.apiRole === "settings-editor" || !api.settingsReady || api.settingsContext !== settingsContext) return null;
    _runtimeApi = api;
    // Applied runtime values, never settingsContext's optional live preview.
    var values = api.pluginSettings;
    return Object.freeze({api: api, clientId: values.clientId || "", clientSecret: values.clientSecret || "", rawPort: values.callbackPort ?? 8888,
      callbackPort: callbackPort, accessToken: values.accessToken || "", refreshToken: values.refreshToken || "", playerId: values.playerId || ""});
  }
  function accepts(input) {
    if (!current || !input || !input.api.settingsContext.current() || input.api.settingsContext !== settingsContext) return false;
    var values = input.api.pluginSettings;
    return values.clientId === input.clientId && values.clientSecret === input.clientSecret && (values.callbackPort ?? 8888) === input.rawPort;
  }
  function cancelProcesses() {
    var jobs = Array.from(_processes); _processes.clear(); _slots.clear();
    for (var job of jobs) { job.running = false; job.destroy(); }
  }
  function cancel() {
    ++_generation; _saving = false;
    clearAuthorization();
    browser.running = false;
    if (_request) finishTokenRequest(_request, true);
    cancelProcesses(); availableDevices = ""; searchResults = []; playlistResults = []; error = "";
  }
  Component {
    id: processFactory
    Process {
      id: job
      required property var completed
      required property string slot
      stdout: StdioCollector { id: output }
      stderr: StdioCollector {}
      onExited: (code, status) => {
        if (!root._processes.has(job)) return;
        root._processes.delete(job); root._slots.delete(slot); completed(code, output.text); job.destroy();
      }
    }
  }
  function run(command, input, completed, slot) {
    if (!accepts(input)) return false;
    var previous = _slots.get(slot);
    if (previous) { _processes.delete(previous); _slots.delete(slot); previous.running = false; previous.destroy(); }
    var generation = _generation;
    var job = processFactory.createObject(root, {command: command, slot: slot, completed: function(code, text) {
      if (generation !== root._generation || !root.accepts(input)) return;
      completed(code, text);
    }});
    _processes.add(job); _slots.set(slot, job); job.running = true; return true;
  }
  function randomString(length) {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    let result = "";
    for (let i = 0; i < length; i++) result += chars.charAt(Math.floor(Math.random() * chars.length));
    return result;
  }
  function authorize(api) {
    var input = inputFor(api);
    if (!input || busy) return false;
    if (!input.clientId || !input.clientSecret) { error = "credentials"; return false; }
    error = "";
    var state = randomString(16);
    _authorization = {input: input, state: state, generation: _generation};
    var redirect = "http://127.0.0.1:" + input.callbackPort + "/callback";
    callbackServer.command = ["python3", api.pluginDir + "/callback_server.py", String(input.callbackPort)];
    authorizationDeadline.restart();
    callbackServer.running = true;
    if (!_authorization) return false;
    browser.command = ["xdg-open", "https://accounts.spotify.com/authorize?" + Auth.formEncode({response_type: "code", client_id: input.clientId,
      scope: "user-read-playback-state user-modify-playback-state playlist-read-private", redirect_uri: redirect, state: state})];
    browser.startedForRequest = false;
    browser.running = true;
    return true;
  }
  function clearAuthorization() {
    _authorization = null;
    authorizationDeadline.stop();
    callbackServer.running = false;
  }
  function failAuthorization(reason) {
    if (!_authorization) return;
    clearAuthorization();
    browser.running = false;
    error = reason;
  }
  Timer {
    id: authorizationDeadline
    interval: 300000
    onTriggered: root.failAuthorization("callback")
  }
  Process {
    id: callbackServer
    stdout: SplitParser {
      onRead: line => {
        var pending = root._authorization;
        if (!pending || pending.generation !== root._generation || !root.accepts(pending.input)) return;
        const [code, state, error] = line.split(":");
        root.clearAuthorization();
        if (error !== "None" || state !== pending.state || !code || code === "None") { root.error = "callback"; return; }
        root.requestToken(pending.input, {code: code, redirect_uri: "http://127.0.0.1:" + pending.input.callbackPort + "/callback", grant_type: "authorization_code"});
      }
    }
    // Quickshell delivers the final stdout line before exited, and only
    // runningChanged for FailedToStart.
    onExited: root.failAuthorization("callback")
    onRunningChanged: if (!running) root.failAuthorization("callback")
  }
  Process {
    id: browser
    property bool startedForRequest: false
    onStarted: startedForRequest = true
    onExited: code => { if (code !== 0) root.failAuthorization("browser"); }
    onRunningChanged: if (!running && !startedForRequest) root.failAuthorization("browser")
  }
  Timer {
    id: tokenDeadline
    interval: 30000
    onTriggered: root.expireTokenRequest()
  }
  function finishTokenRequest(pending, abort) {
    if (_request !== pending) return false;
    tokenDeadline.stop();
    _request = null;
    if (pending.xhr) {
      pending.xhr.onreadystatechange = function() {};
      if (abort) pending.xhr.abort();
    }
    return true;
  }
  function expireTokenRequest() {
    if (_request && finishTokenRequest(_request, true)) error = "token-response";
  }
  function requestToken(input, values, after) {
    if (!accepts(input) || _request || _saving) return false;
    var generation = _generation, lifetime = _lifetime;
    var pending = {xhr: null};
    _request = pending;
    tokenDeadline.restart();
    pending.xhr = Auth.requestToken(Qt.btoa(input.clientId + ":" + input.clientSecret), values, function(tokens, failure) {
      if (!lifetime.alive || !root.finishTokenRequest(pending, false)) return;
      if (generation !== root._generation || !root.accepts(input)) return;
      if (failure) { root.error = failure; return; }
      root._saving = true;
      if (!observation.adoptTokens(root, input, tokens, function(ok) {
        if (!lifetime.alive || generation !== root._generation || !root.accepts(input)) return;
        root._saving = false;
        if (!ok) { root.error = "token-save"; return; }
        root.error = "";
        if (after) after();
      })) { root._saving = false; root.error = "token-owner"; }
    });
    return true;
  }
  function refreshAccessToken(api, after) {
    var input = inputFor(api);
    if (!input || busy || !input.refreshToken) return false;
    error = "";
    return requestToken(input, {refresh_token: input.refreshToken, grant_type: "refresh_token"}, after);
  }
  function devices(api) {
    var input = inputFor(api);
    if (!input || busy) return false;
    if ((api.pluginSettings.tokenExpiresAt || 0) <= Date.now() && input.refreshToken)
      return refreshAccessToken(api, function() { root.devices(api); });
    return query("https://api.spotify.com/v1/me/player/devices", input, function(data) {
      root.availableDevices = (data.devices || []).map(device => device.name + ": " + device.id).join("\n");
    }, "devices");
  }
  function query(url, input, completed, slot) {
    return request([url], input, function(text) {
      try { completed(JSON.parse(text)); } catch (failure) { root.error = "response"; }
    }, slot);
  }
  function request(args, input, completed, slot) {
    // curl can exit successfully for HTTP rejection. Keep the status out of
    // the body consumed by callers, and admit only successful HTTP responses.
    return run(["curl", "--write-out", "\n%{response_code}", "-H", "Authorization: Bearer " + input.accessToken].concat(args), input, function(code, text) {
      const status = /\n2[0-9]{2}$/.exec(text);
      if (code !== 0 || !status) { root.error = "request"; return; }
      completed(text.slice(0, status.index));
    }, slot);
  }
  function readShuffle(api) {
    var input = inputFor(api); if (!input?.accessToken) return false;
    return query("https://api.spotify.com/v1/me/player", input, data => root.shuffleState = data.shuffle_state || false, "read-shuffle");
  }
  function search(queryText, api) {
    var input = inputFor(api); if (!input || !queryText) return false;
    return query("https://api.spotify.com/v1/search?q=" + encodeURIComponent(queryText) + "&type=album%2Cplaylist%2Ctrack", input, function(data) {
      root.searchResults = [...data.tracks.items, ...data.albums.items, ...data.playlists.items.filter(Boolean)];
    }, "search");
  }
  function playlists(api) {
    var input = inputFor(api); if (!input) return false;
    return query("https://api.spotify.com/v1/me/playlists", input, data => root.playlistResults = data.items || [], "playlists");
  }
  function shuffle(input, state, closeAfter) {
    return request(["-X", "PUT", "https://api.spotify.com/v1/me/player/shuffle?state=" + state.toString() + (input.playerId ? "&device_id=" + input.playerId : "")], input, function() {
      root.shuffleState = state;
      if (closeAfter) input.api.closePanel(input.api.panelOpenScreen);
    }, "shuffle");
  }
  function shufflePlayback(api) {
    var input = inputFor(api); if (!input) return false;
    return shuffle(input, !shuffleState, false);
  }
  function play(data, api) {
    var input = inputFor(api); if (!input) return false;
    var body = data.type === "track" ? {uris: [data.uri]} : {context_uri: data.uri};
    var title = data.type !== "playlist" ? data.artists[0].name + " - " + data.name : data.name;
    var state = shuffleState;
    return request(["-X", "PUT", "https://api.spotify.com/v1/me/player/play" + (input.playerId ? "?device_id=" + input.playerId : ""), "--json", JSON.stringify(body)], input, function() {
      ToastService.showNotice(input.api.tr("panel.notif"), title, "music");
      root.shuffle(input, state, true);
    }, "play");
  }
  onCredentialsKeyChanged: if (_constructed) cancel()
  onAccessTokenChanged: if (_constructed) { cancelProcesses(); searchResults = []; playlistResults = []; availableDevices = ""; }
  onPlayerIdChanged: if (_constructed) cancelProcesses()
  onCurrentChanged: if (!current && _constructed) { cancel(); retire(root); }
  Component.onCompleted: _constructed = true
  Component.onDestruction: { _lifetime.alive = false; cancel(); }
}
