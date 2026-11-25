import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root
    property var pluginApi: null
    property var _settingsConsumers: new Map()
    Component { id: clientFactory; GithubFeedSettingsClient {} }
    function settingsConsumerFor(context) {
        if (!context || !context.current()) return null;
        if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
        var client = clientFactory.createObject(root, {settingsContext: context, pluginApi: pluginApi, observation: root,
            retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }});
        _settingsConsumers.set(context, client); return client;
    }
    readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
    readonly property var events: settingsConsumer?.events ?? []
    readonly property var rawEvents: settingsConsumer?.rawEvents ?? []
    readonly property var followingList: settingsConsumer?.followingList ?? []
    readonly property bool isLoading: settingsConsumer?.isLoading ?? false
    readonly property bool hasError: settingsConsumer?.hasError ?? false
    readonly property string errorMessage: settingsConsumer?.errorMessage ?? ""
    readonly property int lastFetchTimestamp: settingsConsumer?.lastFetchTimestamp ?? 0
    readonly property int notificationCount: settingsConsumer?.notificationCount ?? 0
    readonly property var notificationsList: settingsConsumer?.notificationsList ?? []
    function fetchFromGitHub() { settingsConsumer?.fetchFromGitHub(); }
    function fetchNotifications() { settingsConsumer?.fetchNotifications(); }
    function markAllNotificationsAsRead() { settingsConsumer?.markAllNotificationsAsRead(); }
    function markNotificationAsRead(id) { settingsConsumer?.markNotificationAsRead(id); }
    function getAvatarPath(login) { return settingsConsumer?.getAvatarPath(login) ?? ""; }

    readonly property string cacheDir: pluginApi?.pluginDir ? pluginApi.pluginDir + "/cache" : ""
    readonly property string avatarsDir: cacheDir + "/avatars"
    FileView { id: eventsCacheFile; path: root.cacheDir ? root.cacheDir + "/events.json" : ""; watchChanges: false }
    function accepts(worker) { return worker && worker.active && worker.client.current && worker.client._worker === worker; }
    function cacheOwner(worker) { return accepts(worker) && worker.client === settingsConsumer; }
    function cacheFor(worker) {
        if (!cacheOwner(worker)) return null;
        try {
            eventsCacheFile.waitForJob();
            var data = JSON.parse(eventsCacheFile.text());
            return data.schema === 1 && data.sourceUsername === worker.username && data.sourceOrigin === worker.githubWebUrl ? data : null;
        } catch (error) { return null; }
    }
    function saveCache(worker, data) {
        if (cacheOwner(worker)) eventsCacheFile.setText(JSON.stringify(Object.assign({schema: 1, sourceUsername: worker.username, sourceOrigin: worker.githubWebUrl}, data), null, 2));
    }
    property var _notified: new Set()
    Component {
        id: notificationFactory
        Process {
            id: notificationProcess
            property var worker
            property string targetUrl
            stdout: StdioCollector { onStreamFinished: if (root.accepts(notificationProcess.worker) && text.trim() === "default") Qt.openUrlExternally(notificationProcess.targetUrl) }
            onExited: destroy()
        }
    }
    function sendSystemNotification(worker, title, message, url, identity) {
        if (!accepts(worker) || !worker.client.enableSystemNotifications) return;
        var key = JSON.stringify([worker.githubWebUrl, worker.username, identity]);
        if (_notified.has(key)) return;
        _notified.add(key);
        var process = notificationFactory.createObject(root, {worker: worker, targetUrl: url || worker.githubWebUrl, command: ["notify-send", "-a", "GitHub Feed", "--action=default=Open", "--wait", title, message]});
        process.running = true;
    }
    property var availableAvatars: ({})
    property var _avatarQueue: []
    property var _avatar: null
    property bool _avatarReady: false
    function avatarKey(worker, login) { return encodeURIComponent(worker.githubWebUrl) + "__" + encodeURIComponent(login); }
    function avatarFor(worker, login) {
        var key = avatarKey(worker, login);
        return accepts(worker) && availableAvatars[key] ? "file://" + encodeURI(avatarsDir + "/" + key + ".png") : "";
    }
    function downloadAvatars(worker, events) {
        if (!accepts(worker)) return;
        var keys = new Set(_avatarQueue.map(entry => entry.key));
        if (_avatar) keys.add(_avatar.key);
        for (var event of events) {
            var actor = event.actor;
            if (!actor?.login || !actor.avatar_url) continue;
            var key = avatarKey(worker, actor.login);
            if (keys.has(key) || availableAvatars[key]) continue;
            keys.add(key); _avatarQueue.push({worker: worker, key: key, url: actor.avatar_url});
        }
        nextAvatar();
    }
    function nextAvatar() {
        if (!_avatarReady || _avatar) return;
        while (_avatarQueue.length) {
            var next = _avatarQueue.shift();
            if (!accepts(next.worker)) continue;
            _avatar = next;
            avatarCheck.command = ["test", "-f", avatarsDir + "/" + next.key + ".png"];
            avatarCheck.running = true; return;
        }
    }
    function finishAvatar(success) {
        if (success && _avatar && accepts(_avatar.worker)) {
            var copy = Object.assign({}, availableAvatars); copy[_avatar.key] = true; availableAvatars = copy;
        }
        _avatar = null; Qt.callLater(nextAvatar);
    }
    function retireWorker(worker) {
        _avatarQueue = _avatarQueue.filter(entry => entry.worker !== worker);
        // The singular admitted operation keeps its qualified target until exit.
        // Its callback checks the captured worker before publishing/continuing.
    }
    Process {
        id: ensureCacheDir
        command: ["mkdir", "-p", root.avatarsDir]
        running: root.cacheDir !== ""
        onExited: code => { root._avatarReady = code === 0; root.nextAvatar(); }
    }
    Process {
        id: avatarCheck
        onExited: code => {
            if (!root._avatar) return;
            if (!root.accepts(root._avatar.worker)) { root.finishAvatar(false); return; }
            if (code === 0) { root.finishAvatar(true); return; }
            avatarDownload.command = ["curl", "-s", "-L", "--max-time", "10", "-o", root.avatarsDir + "/" + root._avatar.key + ".png", root._avatar.url + "&s=80"];
            avatarDownload.running = true;
        }
    }
    Process { id: avatarDownload; onExited: code => root.finishAvatar(code === 0) }
    IpcHandler {
        target: "plugin:github-feed"
        function refresh() { root.fetchFromGitHub(); ToastService.showNotice("Refreshing GitHub feed..."); }
        function toggle() { pluginApi?.withCurrentScreen(screen => pluginApi.openPanel(screen)); }
        function setUsername(newUsername: string) {
            if (!pluginApi || !newUsername) return;
            pluginApi.pluginSettings.username = newUsername; pluginApi.saveSettings();
            ToastService.showNotice("GitHub username updated: " + newUsername);
        }
    }
}
