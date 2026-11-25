import QtQuick

Item {
    id: client
    required property var settingsContext
    required property var pluginApi
    required property var observation
    required property var retire
    readonly property bool current: settingsContext.current()
    readonly property var cfg: settingsContext.settingsView
    readonly property string username: cfg.username || ""
    readonly property string token: cfg.token || ""
    readonly property string githubUrl: cfg.githubUrl || ""
    readonly property string sourceKey: JSON.stringify([username, token, githubUrl])
    readonly property int refreshInterval: cfg.refreshInterval || 1800
    readonly property int maxEvents: cfg.maxEvents || 50
    readonly property bool showStars: cfg.showStars ?? true
    readonly property bool showForks: cfg.showForks ?? true
    readonly property bool showPRs: cfg.showPRs ?? true
    readonly property bool showRepoCreations: cfg.showRepoCreations ?? true
    readonly property bool showMyRepoStars: cfg.showMyRepoStars ?? true
    readonly property bool showMyRepoForks: cfg.showMyRepoForks ?? true
    readonly property bool showNotificationBadge: cfg.showNotificationBadge ?? true
    readonly property bool colorizationEnabled: cfg.colorizationEnabled ?? false
    readonly property string colorizationIcon: cfg.colorizationIcon ?? "Primary"
    readonly property string colorizationBadge: cfg.colorizationBadge ?? "Primary"
    readonly property string colorizationBadgeText: cfg.colorizationBadgeText ?? "Primary"
    readonly property int defaultTab: cfg.defaultTab ?? 0
    readonly property bool enableSystemNotifications: cfg.enableSystemNotifications ?? false
    readonly property bool notifyGitHubNotifications: cfg.notifyGitHubNotifications ?? true
    readonly property bool notifyStars: cfg.notifyStars ?? true
    readonly property bool notifyForks: cfg.notifyForks ?? true
    readonly property bool notifyPRs: cfg.notifyPRs ?? true
    readonly property bool notifyRepoCreations: cfg.notifyRepoCreations ?? true
    readonly property bool notifyMyRepoStars: cfg.notifyMyRepoStars ?? true
    readonly property bool notifyMyRepoForks: cfg.notifyMyRepoForks ?? true
    property var _worker: null
    property bool _constructed: false
    Component { id: workerFactory; GithubFeedWorker {} }
    function stop() {
        var old = _worker; _worker = null;
        if (old) { old.stop(); observation.retireWorker(old); old.destroy(); }
    }
    function replaceSource() {
        stop();
        if (current && username.trim() && token.trim())
            _worker = workerFactory.createObject(client, {client: client, observation: observation, username: username, token: token, githubUrl: githubUrl});
    }
    readonly property var rawEvents: _worker?.rawEvents ?? []
    readonly property var events: _worker?.events ?? []
    readonly property var followingList: _worker?.followingList ?? []
    readonly property bool isLoading: _worker?.isLoading ?? false
    readonly property string configurationError: !username.trim() ? "Please configure your GitHub username in settings" : (!token.trim() ? "Please add a GitHub Personal Access Token in settings" : "")
    readonly property bool hasError: current && (configurationError !== "" || (_worker?.hasError ?? false))
    readonly property string errorMessage: current ? (configurationError || (_worker?.errorMessage ?? "")) : ""
    readonly property int lastFetchTimestamp: _worker?.lastFetchTimestamp ?? 0
    readonly property int notificationCount: _worker?.notificationCount ?? 0
    readonly property var notificationsList: _worker?.notificationsList ?? []
    readonly property string githubWebUrl: _worker?.githubWebUrl ?? "https://github.com"
    function fetchFromGitHub() { if (current) _worker?.fetchFromGitHub(); }
    function fetchNotifications() { if (current) _worker?.fetchNotifications(); }
    function markAllNotificationsAsRead() { if (current) _worker?.markAllNotificationsAsRead(); }
    function markNotificationAsRead(id) { if (current) _worker?.markNotificationAsRead(id); }
    function getAvatarPath(login) { return _worker?.getAvatarPath(login) ?? ""; }
    onSourceKeyChanged: if (_constructed) { stop(); Qt.callLater(replaceSource); }
    onCurrentChanged: if (_constructed && !current) { stop(); retire(client); }
    Component.onCompleted: { _constructed = true; replaceSource(); }
    Component.onDestruction: stop()
}
