import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root

    required property var client
    required property var observation
    required property string username
    required property string token
    required property string githubUrl
    readonly property var pluginApi: client.pluginApi
    property bool active: true
    function stop() {
        active = false;
        refreshTimer.stop();
        for (var process of [followingProcess, worker0, worker1, worker2, worker3, worker4, worker5, myReposProcess, notificationsProcess, markReadProcess]) process.running = false;
        markReadQueue = []; batchQueue = [];
    }

    readonly property bool debugMode: Quickshell.env("NOCTALIA_DEBUG") === "1"

    function logDebug(msg) {
        if (root.debugMode) Logger.d("GitHubFeed", msg)
    }

    property var rawEvents: []
    readonly property var events: filterEvents(rawEvents)

    property var followingList: []
    property bool isLoading: false
    property bool hasError: false
    property string errorMessage: ""
    property int lastFetchTimestamp: 0


    // Derived URL properties, empty githubUrl means use github.com; otherwise treat
    // githubUrl as the web base URL of a GitHub Enterprise Server instance.
    // The scheme is stripped from user input and always rebuilt as https://, so both
    // "github.mycompany.com" and "https://github.mycompany.com" produce identical URLs.
    readonly property string _githubHost: {
        if (!githubUrl || githubUrl.trim() === "") return ""
        return githubUrl.trim().replace(/^https?:\/\//, "").replace(/\/+$/, "")
    }
    readonly property string githubWebUrl: _githubHost ? "https://" + _githubHost : "https://github.com"
    readonly property string githubRestApiUrl: _githubHost ? "https://" + _githubHost + "/api/v3" : "https://api.github.com"
    readonly property string githubGraphqlUrl: _githubHost ? "https://" + _githubHost + "/api/graphql" : "https://api.github.com/graphql"

    readonly property int refreshInterval: client.refreshInterval
    readonly property int maxEvents: client.maxEvents

    readonly property int batchSize: 8
    readonly property int parallelCount: 6
    readonly property int maxRetries: 3
    readonly property int maxStarsPerUser: 3
    readonly property int maxReposPerUser: 2
    readonly property int maxForksPerUser: 2
    readonly property int maxPRsPerUser: 2

    readonly property bool showStars: client.showStars
    readonly property bool showForks: client.showForks
    readonly property bool showPRs: client.showPRs
    readonly property bool showRepoCreations: client.showRepoCreations
    readonly property bool showMyRepoStars: client.showMyRepoStars
    readonly property bool showMyRepoForks: client.showMyRepoForks
    readonly property bool notifyGitHubNotifications: client.notifyGitHubNotifications
    readonly property bool notifyStars: client.notifyStars
    readonly property bool notifyForks: client.notifyForks
    readonly property bool notifyPRs: client.notifyPRs
    readonly property bool notifyRepoCreations: client.notifyRepoCreations
    readonly property bool notifyMyRepoStars: client.notifyMyRepoStars
    readonly property bool notifyMyRepoForks: client.notifyMyRepoForks

    property var collectedEvents: []

    readonly property var urlResolvers: ({
        "PullRequest": function(url, repo, title) {
            var match = url.match(/\/pulls\/(\d+)$/);
            return match ? root.githubWebUrl + "/" + repo + "/pull/" + match[1] : root.githubWebUrl + "/" + repo;
        },
        "Issue": function(url, repo, title) {
            var match = url.match(/\/issues\/(\d+)$/);
            return match ? root.githubWebUrl + "/" + repo + "/issues/" + match[1] : root.githubWebUrl + "/" + repo;
        },
        "Release": function(url, repo, title) {
            return root.githubWebUrl + "/" + repo + "/releases/tag/" + encodeURIComponent(title);
        },
        "Discussion": function(url, repo, title) {
            var match = url.match(/\/discussions\/(\d+)$/);
            return match ? root.githubWebUrl + "/" + repo + "/discussions/" + match[1] : root.githubWebUrl + "/" + repo + "/discussions";
        },
        "Default": function(url, repo, title) {
            return url.replace(root.githubRestApiUrl + "/repos/", root.githubWebUrl + "/");
        }
        // FIXME: Notifications API does not include subject.url for CheckSuite events
        //        it is unclear how to construct the check-run url from the CheckSuite notification
    })

    function sendSystemNotification(title, message, url, identity) {
        if (active) observation.sendSystemNotification(root, title, message, url, identity);
    }

    property var userBatches: []
    property var batchQueue: []
    property int completedBatches: 0
    property int totalBatches: 0
    property int totalGraphQLCost: 0
    property double fetchStartTime: 0

    property var seenEventIds: []
    property var seenNotificationIds: []

    function filterEvents(rawList) {
        if (!rawList || rawList.length === 0) return []

        var now = Date.now()
        var sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000)

        var filtered = rawList.filter(function(event) {
            var eventDate = new Date(event.created_at).getTime()
            if (eventDate < sevenDaysAgo) return false

            if (event.isMyRepoEvent) {
                if (event.type === "WatchEvent") return root.showMyRepoStars
                if (event.type === "ForkEvent") return root.showMyRepoForks
                return true
            }

            switch (event.type) {
                case "WatchEvent":
                    return root.showStars
                case "ForkEvent":
                    return root.showForks
                case "PullRequestEvent":
                    return root.showPRs
                case "CreateEvent":
                    return root.showRepoCreations
                default:
                    return true
            }
        })

        return filtered.slice(0, root.maxEvents)
    }

    function loadFromCache() {
        if (!active) return;
        try {
            var cached = observation.cacheFor(root)
            if (!cached || !cached.events) {
                if (root.username && root.token) fetchFromGitHub()
                return
            }

            root.lastFetchTimestamp = cached.timestamp || 0
            root.followingList = cached.following || []
            var now = Math.floor(Date.now() / 1000)
            var age = now - root.lastFetchTimestamp

            if (age < root.refreshInterval) {
                root.rawEvents = cached.events
                Logger.i("GitHubFeed", "Using cached data (" + cached.events.length + " events), age: " + Math.floor(age / 60) + " min")
                populateSeenIdsFromCache()
                fetchNotifications()
            } else {
                Logger.i("GitHubFeed", "Cache expired, fetching fresh data")
                if (root.username && root.token) fetchFromGitHub()
            }
        } catch (e) {
            Logger.e("GitHubFeed", "Failed to parse cache: " + e)
            if (root.username && root.token) fetchFromGitHub()
        }
    }

    function populateSeenIdsFromCache() {
        const sync = (target, source) => {
            if (target.length === 0) {
                return source.map(item => item.id);
            }
            return target;
        };
        root.seenEventIds = sync(root.seenEventIds, root.rawEvents);
        root.seenNotificationIds = sync(root.seenNotificationIds, root.notificationsList);
    }

    function saveToCache() {
        if (active) observation.saveCache(root, {
                events: root.rawEvents,
                following: root.followingList,
                timestamp: Math.floor(Date.now() / 1000)
            });
    }

    property int followingPage: 1
    property var allFollowingUsers: []
    property bool batchFetchFailed: false

    Process {
        id: followingProcess

        property int page: 1

        command: root.username && root.token ? [
            "curl", "-s", "--max-time", "30",
            "-H", "Authorization: Bearer " + root.token,
            "-H", "Accept: application/vnd.github.v3+json",
            root.githubRestApiUrl + "/users/" + root.username + "/following?per_page=100&page=" + page
        ] : ["echo", "[]"]

        stdout: StdioCollector {
            onStreamFinished: {
                handleFollowingResponse(this.text)
            }
        }

        stderr: StdioCollector {}
    }

    // Only a complete fetch may replace the published feed and cache.
    function failFeedFetch(message) {
        if (!active || !root.isLoading) return;
        root.isLoading = false
        root.hasError = true
        root.errorMessage = message
        Logger.w("GitHubFeed", message)
    }

    function handleFollowingResponse(responseText) {
        if (!active) return;
        try {
            var users = JSON.parse(responseText)

            if (!Array.isArray(users)) {
                failFeedFetch(users?.message || "Invalid following response")
                return
            }

            users.forEach(function(u) {
                if (u && u.login) {
                    root.allFollowingUsers.push(u.login)
                }
            })

            if (users.length === 100) {
                followingProcess.page++
                logDebug("Fetching following page " + followingProcess.page + " (got " + root.allFollowingUsers.length + " so far)")
                followingProcess.running = true
            } else {
                finishFollowingFetch()
            }

        } catch (e) {
            failFeedFetch("Failed to parse following response: " + e)
        }
    }

    function finishFollowingFetch() {
        if (!active) return;
        root.followingList = root.allFollowingUsers
        Logger.i("GitHubFeed", "Following " + root.followingList.length + " users")

        if (root.followingList.length === 0) {
            Logger.w("GitHubFeed", "No following users found")
            fetchMyRepoEvents()
            return
        }

        root.userBatches = []
        for (var i = 0; i < root.followingList.length; i += root.batchSize) {
            root.userBatches.push(root.followingList.slice(i, i + root.batchSize))
        }

        root.totalBatches = root.userBatches.length
        root.completedBatches = 0
        root.collectedEvents = []
        root.totalGraphQLCost = 0
        root.fetchStartTime = Date.now()

        root.batchQueue = []
        for (var j = 0; j < root.totalBatches; j++) {
            root.batchQueue.push({ index: j, retryCount: 0 })
        }

        Logger.i("GitHubFeed", "Starting parallel fetch: " + root.totalBatches + " batches, " + root.parallelCount + " parallel")

        startParallelFetches()
    }

    function startParallelFetches() {
        var workers = [worker0, worker1, worker2, worker3, worker4, worker5]
        for (var i = 0; i < root.parallelCount; i++) {
            assignNextBatch(workers[i])
        }
    }

    function assignNextBatch(worker) {
        if (!active) return;
        if (root.batchQueue.length === 0) {
            checkAllBatchesComplete()
            return
        }

        var batchInfo = root.batchQueue.shift()
        var batch = root.userBatches[batchInfo.index]

        worker.batchIndex = batchInfo.index
        worker.retryCount = batchInfo.retryCount
        worker.command = buildBatchCommand(batch)
        worker.running = true
    }

    function buildBatchCommand(batch) {
        var query = "query {"

        for (var i = 0; i < batch.length; i++) {
            var user = batch[i]
            query += " u" + i + ": user(login: \"" + user + "\") {"
            query += " login avatarUrl"
            query += " starredRepositories(first: " + root.maxStarsPerUser + ", orderBy: {field: STARRED_AT, direction: DESC}) {"
            query += " nodes { nameWithOwner description }"
            query += " edges { starredAt }"
            query += " }"
            query += " repositories(first: " + root.maxReposPerUser + ", orderBy: {field: CREATED_AT, direction: DESC}, isFork: false, privacy: PUBLIC) {"
            query += " nodes { nameWithOwner createdAt description }"
            query += " }"
            query += " forkedRepos: repositories(first: " + root.maxForksPerUser + ", orderBy: {field: CREATED_AT, direction: DESC}, isFork: true, privacy: PUBLIC) {"
            query += " nodes { nameWithOwner createdAt description parent { nameWithOwner } }"
            query += " }"
            query += " pullRequests(first: " + root.maxPRsPerUser + ", orderBy: {field: CREATED_AT, direction: DESC}, states: [OPEN, MERGED]) {"
            query += " nodes { title createdAt state url repository { nameWithOwner } }"
            query += " }"
            query += " }"
        }

        query += " rateLimit { cost remaining } }"

        var payload = JSON.stringify({ query: query })

        return [
            "curl", "-s", "--max-time", "20",
            "-X", "POST",
            root.githubGraphqlUrl,
            "-H", "Authorization: Bearer " + root.token,
            "-H", "Content-Type: application/json",
            "-d", payload
        ]
    }

    function handleWorkerResponse(worker, responseText) {
        if (!active) return;
        var batchIndex = worker.batchIndex
        var retryCount = worker.retryCount

        var success = false
        var shouldRetry = false

        try {
            if (!responseText || responseText.trim() === "") {
                Logger.w("GitHubFeed", "Batch " + (batchIndex + 1) + " empty response")
                shouldRetry = true
            } else if (!responseText.trim().startsWith("{")) {
                Logger.w("GitHubFeed", "Batch " + (batchIndex + 1) + " non-JSON response")
                shouldRetry = true
            } else {
                var result = JSON.parse(responseText)

                if (result.data && result.data.rateLimit) {
                    root.totalGraphQLCost += result.data.rateLimit.cost || 0
                }

                if (!result.data || result.errors?.length) {
                    Logger.w("GitHubFeed", "Batch " + (batchIndex + 1) + " returned incomplete data")
                    shouldRetry = true
                } else {
                    processBatchData(result.data)
                    success = true
                    root.completedBatches++

                    var progress = Math.min(root.completedBatches * root.batchSize, root.followingList.length)
                    logDebug("Batch " + (batchIndex + 1) + "/" + root.totalBatches +
                        " done: " + progress + "/" + root.followingList.length + " users, events=" + root.collectedEvents.length)
                }
            }
        } catch (e) {
            Logger.e("GitHubFeed", "Batch " + (batchIndex + 1) + " parse error: " + e)
            shouldRetry = true
        }

        if (shouldRetry && retryCount < root.maxRetries) {
            logDebug("Batch " + (batchIndex + 1) + " retry " + (retryCount + 1) + "/" + root.maxRetries)
            root.batchQueue.push({ index: batchIndex, retryCount: retryCount + 1 })
        } else if (!success) {
            Logger.e("GitHubFeed", "Batch " + (batchIndex + 1) + " failed after " + retryCount + " retries")
            root.batchFetchFailed = true
            root.completedBatches++
        }

        assignNextBatch(worker)
    }

    function processBatchData(data) {
        var keys = Object.keys(data).filter(function(k) { return k.startsWith("u") })

        keys.forEach(function(key) {
            var userData = data[key]
            if (!userData || !userData.login) return

            var login = userData.login
            var avatarUrl = userData.avatarUrl || ""

            if (userData.starredRepositories && userData.starredRepositories.nodes && userData.starredRepositories.edges) {
                var nodes = userData.starredRepositories.nodes
                var edges = userData.starredRepositories.edges

                for (var i = 0; i < nodes.length && i < edges.length; i++) {
                    if (!nodes[i] || !edges[i] || !edges[i].starredAt) continue

                    root.collectedEvents.push({
                        id: "star_" + login + "_" + nodes[i].nameWithOwner + "_" + edges[i].starredAt,
                        type: "WatchEvent",
                        created_at: edges[i].starredAt,
                        actor: { login: login, avatar_url: avatarUrl },
                        repo: { name: nodes[i].nameWithOwner },
                        isFollowedUserEvent: true,
                        payload: { action: "started" },
                        description: nodes[i].description || ""
                    })
                }
            }

            if (userData.repositories && userData.repositories.nodes) {
                userData.repositories.nodes.forEach(function(repo) {
                    if (!repo || !repo.createdAt || !repo.nameWithOwner) return

                    root.collectedEvents.push({
                        id: "repo_" + login + "_" + repo.nameWithOwner,
                        type: "CreateEvent",
                        created_at: repo.createdAt,
                        actor: { login: login, avatar_url: avatarUrl },
                        repo: { name: repo.nameWithOwner },
                        isFollowedUserEvent: true,
                        payload: { ref_type: "repository" },
                        description: repo.description || ""
                    })
                })
            }

            if (userData.forkedRepos && userData.forkedRepos.nodes) {
                userData.forkedRepos.nodes.forEach(function(repo) {
                    if (!repo || !repo.createdAt || !repo.nameWithOwner) return

                    var parentRepo = repo.parent ? repo.parent.nameWithOwner : ""
                    root.collectedEvents.push({
                        id: "fork_" + login + "_" + repo.nameWithOwner,
                        type: "ForkEvent",
                        created_at: repo.createdAt,
                        actor: { login: login, avatar_url: avatarUrl },
                        repo: { name: parentRepo || repo.nameWithOwner },
                        isFollowedUserEvent: true,
                        payload: { forkee: { full_name: repo.nameWithOwner } },
                        description: repo.description || ""
                    })
                })
            }

            if (userData.pullRequests && userData.pullRequests.nodes) {
                userData.pullRequests.nodes.forEach(function(pr) {
                    if (!pr || !pr.createdAt || !pr.repository) return

                    root.collectedEvents.push({
                        id: "pr_" + login + "_" + pr.repository.nameWithOwner + "_" + pr.createdAt,
                        type: "PullRequestEvent",
                        created_at: pr.createdAt,
                        actor: { login: login, avatar_url: avatarUrl },
                        repo: { name: pr.repository.nameWithOwner },
                        isFollowedUserEvent: true,
                        payload: { action: pr.state === "MERGED" ? "merged" : "opened", pull_request: { title: pr.title, html_url: pr.url } },
                        description: pr.title || ""
                    })
                })
            }
        })
    }

    function checkAllBatchesComplete() {
        if (root.completedBatches >= root.totalBatches && root.batchQueue.length === 0) {
            if (root.batchFetchFailed) failFeedFetch("Could not refresh all followed users")
            else fetchMyRepoEvents()
        }
    }

    Process {
        id: worker0
        property int batchIndex: -1
        property int retryCount: 0
        stdout: StdioCollector {
            onStreamFinished: { handleWorkerResponse(worker0, this.text) }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: worker1
        property int batchIndex: -1
        property int retryCount: 0
        stdout: StdioCollector {
            onStreamFinished: { handleWorkerResponse(worker1, this.text) }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: worker2
        property int batchIndex: -1
        property int retryCount: 0
        stdout: StdioCollector {
            onStreamFinished: { handleWorkerResponse(worker2, this.text) }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: worker3
        property int batchIndex: -1
        property int retryCount: 0
        stdout: StdioCollector {
            onStreamFinished: { handleWorkerResponse(worker3, this.text) }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: worker4
        property int batchIndex: -1
        property int retryCount: 0
        stdout: StdioCollector {
            onStreamFinished: { handleWorkerResponse(worker4, this.text) }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: worker5
        property int batchIndex: -1
        property int retryCount: 0
        stdout: StdioCollector {
            onStreamFinished: { handleWorkerResponse(worker5, this.text) }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: myReposProcess

        stdout: StdioCollector {
            onStreamFinished: {
                handleMyReposResponse(this.text)
            }
        }

        stderr: StdioCollector {}

    }

    function fetchMyRepoEvents() {
        if (!active) return;
        if (!root.showMyRepoStars && !root.showMyRepoForks) {
            finalizeFetch()
            return
        }

        logDebug("Fetching stars/forks on your repos")

        var query = "query {"
        query += " user(login: \"" + root.username + "\") {"
        query += " repositories(first: 10, orderBy: {field: STARGAZERS, direction: DESC}, privacy: PUBLIC) {"
        query += " nodes {"
        query += " nameWithOwner"
        query += " stargazers(first: 5, orderBy: {field: STARRED_AT, direction: DESC}) {"
        query += " edges { starredAt node { login avatarUrl } }"
        query += " }"
        query += " forks(first: 5, orderBy: {field: CREATED_AT, direction: DESC}) {"
        query += " nodes { owner { login avatarUrl } createdAt }"
        query += " }"
        query += " }"
        query += " }"
        query += " }"
        query += " rateLimit { cost remaining }"
        query += " }"

        var payload = JSON.stringify({ query: query })

        myReposProcess.command = [
            "curl", "-s", "--max-time", "20",
            "-X", "POST",
            root.githubGraphqlUrl,
            "-H", "Authorization: Bearer " + root.token,
            "-H", "Content-Type: application/json",
            "-d", payload
        ]

        myReposProcess.running = true
    }

    function handleMyReposResponse(responseText) {
        if (!active) return;
        try {
            if (!responseText || responseText.trim() === "" || !responseText.trim().startsWith("{")) {
                failFeedFetch("My repositories response is invalid")
                return
            }

            var result = JSON.parse(responseText)

            if (result.data && result.data.rateLimit) {
                root.totalGraphQLCost += result.data.rateLimit.cost || 0
            }

            if (result.errors?.length || !Array.isArray(result.data?.user?.repositories?.nodes)) {
                failFeedFetch(result.errors?.[0]?.message || "No data for your repositories")
                return
            }

            var repos = result.data.user.repositories.nodes || []

            repos.forEach(function(repo) {
                if (!repo || !repo.nameWithOwner) return

                if (repo.stargazers && repo.stargazers.edges) {
                    repo.stargazers.edges.forEach(function(edge) {
                        if (!edge || !edge.node || !edge.starredAt) return
                        if (edge.node.login === root.username) return

                        root.collectedEvents.push({
                            id: "myrepo_star_" + edge.node.login + "_" + repo.nameWithOwner + "_" + edge.starredAt,
                            type: "WatchEvent",
                            created_at: edge.starredAt,
                            actor: { login: edge.node.login, avatar_url: edge.node.avatarUrl || "" },
                            repo: { name: repo.nameWithOwner },
                            isMyRepoEvent: true,
                            payload: { action: "started" },
                            description: ""
                        })
                    })
                }

                if (repo.forks && repo.forks.nodes) {
                    repo.forks.nodes.forEach(function(fork) {
                        if (!fork || !fork.owner || !fork.createdAt) return
                        if (fork.owner.login === root.username) return

                        root.collectedEvents.push({
                            id: "myrepo_fork_" + fork.owner.login + "_" + repo.nameWithOwner + "_" + fork.createdAt,
                            type: "ForkEvent",
                            created_at: fork.createdAt,
                            actor: { login: fork.owner.login, avatar_url: fork.owner.avatarUrl || "" },
                            repo: { name: repo.nameWithOwner },
                            isMyRepoEvent: true,
                            payload: {},
                            description: ""
                        })
                    })
                }
            })

            logDebug("Processed stars/forks on your repos, total events: " + root.collectedEvents.length)

        } catch (e) {
            failFeedFetch("Failed to parse my repositories response: " + e)
            return
        }

        finalizeFetch()
    }

    function fetchFromGitHub() {
        if (!active) return;
        if (!root.username || root.username.trim() === "") {
            Logger.w("GitHubFeed", "No username configured")
            root.hasError = true
            root.errorMessage = "Please configure your GitHub username in settings"
            return
        }

        if (!root.token || root.token.trim() === "") {
            Logger.w("GitHubFeed", "No token configured")
            root.hasError = true
            root.errorMessage = "Please add a GitHub Personal Access Token in settings"
            return
        }

        if (root.isLoading) {
            logDebug("Already fetching, skipping")
            return
        }

        Logger.i("GitHubFeed", "Fetching feed for user: " + root.username)
        root.isLoading = true
        root.hasError = false
        root.errorMessage = ""
        root.collectedEvents = []
        root.allFollowingUsers = []
        root.userBatches = []
        root.batchQueue = []
        root.completedBatches = 0
        root.totalBatches = 0
        root.totalGraphQLCost = 0
        root.batchFetchFailed = false

        followingProcess.page = 1
        followingProcess.running = true
        fetchNotifications()
    }

    property int notificationCount: 0
    property var notificationsList: []

    Process {
        id: notificationsProcess
        stdout: StdioCollector {
            onStreamFinished: {
                handleNotificationsResponse(this.text)
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
               if (this.text.trim().length > 0) Logger.w("GitHubFeed", "Notifications stderr: " + this.text)
            }
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
               Logger.e("GitHubFeed", "Notifications process exited with code " + exitCode)
            }
        }
    }

    function fetchNotifications() {
        if (!active) return;
        if (!root.username || !root.token) return

        Logger.i("GitHubFeed", "Fetching notifications...")
        notificationsProcess.command = [
            "curl", "-s", "--max-time", "10",
            "-H", "Authorization: Bearer " + root.token,
            "-H", "Accept: application/vnd.github.v3+json",
            root.githubRestApiUrl + "/notifications"
        ]
        notificationsProcess.running = true
    }

    function handleNotificationsResponse(response) {
        if (!active) return;
        try {
            if (!response || response.trim() === "") {
                return
            }

            var data = JSON.parse(response)
            if (Array.isArray(data)) {
                root.notificationCount = data.length

                var list = []
                data.forEach(function(n) {
                    var type = n.subject ? n.subject.type : "Notification"
                    var title = n.subject ? n.subject.title : ""
                    var repo = n.repository ? n.repository.full_name : ""
                    var url = ""

                    var resolver = root.urlResolvers[type] || root.urlResolvers["Default"];
                    if (n.subject && n.subject.url) {
                        url = resolver(n.subject.url, repo, title);
                    } else {
                        url = root.githubWebUrl + "/" + repo;
                    }

                    list.push({
                        id: n.id,
                        title: title,
                        type: type,
                        repo: repo,
                        updated_at: n.updated_at,
                        url: url,
                        unread: n.unread
                    })
                })

                if (root.seenNotificationIds.length > 0) {
                    list.forEach(function(n) {
                        if (root.seenNotificationIds.indexOf(n.id) === -1) {
                            if (root.notifyGitHubNotifications) {
                                sendSystemNotification("GitHub Notification", n.repo + ": " + n.title, n.url, "notification:" + n.id)
                            }
                        }
                    })
                }

                root.notificationsList = list
                root.seenNotificationIds = list.map(function(n) { return n.id })

                Logger.i("GitHubFeed", "Fetched " + data.length + " notifications")
            } else {
                Logger.e("GitHubFeed", "Failed to parse notifications: not an array. Response: " + response.substring(0, 100))
            }
        } catch (e) {
            Logger.e("GitHubFeed", "Error parsing notifications: " + e)
        }
    }

    function markAllNotificationsAsRead() {
        if (!active) return;
        if (!root.token || root.notificationsList.length === 0) return
        var ids = root.notificationsList.map(function(n) { return n.id })
        root.notificationsList = []
        root.notificationCount = 0
        for (var i = 0; i < ids.length; i++) {
            root.markReadQueue.push(ids[i])
        }
        if (!root.isMarkingRead) processMarkReadQueue()
    }

    property var markReadQueue: []
    property bool isMarkingRead: false

    Process {
        id: markReadProcess
        stdout: StdioCollector {}
        onExited: function(exitCode) {
            if (!root.active) return;
            if (exitCode !== 0) {
                Logger.e("GitHubFeed", "Failed to mark notification as read, exit code: " + exitCode)
            }
            root.isMarkingRead = false
            if (root.markReadQueue.length > 0) {
                processMarkReadQueue()
            } else {
                fetchNotifications()
            }
        }
    }

    function markNotificationAsRead(threadId) {
        if (!active) return;
        var updated = []
        for (var i = 0; i < root.notificationsList.length; i++) {
            if (root.notificationsList[i].id !== threadId) updated.push(root.notificationsList[i])
        }
        root.notificationsList = updated
        if (root.notificationCount > 0) root.notificationCount--

        root.markReadQueue.push(threadId)
        if (!root.isMarkingRead) processMarkReadQueue()
    }

    function processMarkReadQueue() {
        if (!active) return;
        if (root.markReadQueue.length === 0) return
        var threadId = root.markReadQueue.shift()
        root.isMarkingRead = true
        markReadProcess.command = [
            "curl", "-s", "--max-time", "10",
            "-X", "PATCH",
            "-H", "Authorization: Bearer " + root.token,
            "-H", "Accept: application/vnd.github.v3+json",
            root.githubRestApiUrl + "/notifications/threads/" + threadId
        ]
        markReadProcess.running = true
    }

    function finalizeFetch() {
        if (!active || !root.isLoading) return;
        root.collectedEvents.sort(function(a, b) {
            var dateA = new Date(a.created_at)
            var dateB = new Date(b.created_at)
            return dateB - dateA
        })

        var seen = {}
        var uniqueEvents = []
        for (var i = 0; i < root.collectedEvents.length; i++) {
            var event = root.collectedEvents[i]
            if (!seen[event.id]) {
                seen[event.id] = true
                uniqueEvents.push(event)
            }
        }

        if (root.seenEventIds.length > 0) {
            uniqueEvents.forEach(function(e) {
                if (root.seenEventIds.indexOf(e.id) === -1) {
                    var shouldNotify = false
                    if (e.isMyRepoEvent) {
                        if (e.type === "WatchEvent") shouldNotify = root.notifyMyRepoStars
                        else if (e.type === "ForkEvent") shouldNotify = root.notifyMyRepoForks
                    } else {
                        switch (e.type) {
                            case "WatchEvent": shouldNotify = root.notifyStars; break
                            case "ForkEvent": shouldNotify = root.notifyForks; break
                            case "PullRequestEvent": shouldNotify = root.notifyPRs; break
                            case "CreateEvent": shouldNotify = root.notifyRepoCreations; break
                        }
                    }

                    if (shouldNotify) {
                        var title = "GitHub Activity"
                        var msg = e.actor.login + " "
                        var eventUrl = root.githubWebUrl + "/" + e.repo.name
                        if (e.type === "WatchEvent") msg += "starred " + e.repo.name
                        else if (e.type === "ForkEvent") {
                            msg += "forked " + (e.payload.forkee ? e.payload.forkee.full_name : e.repo.name)
                            if (e.payload.forkee) eventUrl = root.githubWebUrl + "/" + e.payload.forkee.full_name
                        }
                        else if (e.type === "PullRequestEvent") {
                            msg += "opened/merged PR: " + e.payload.pull_request.title
                            if (e.payload.pull_request.html_url) eventUrl = e.payload.pull_request.html_url
                        }
                        else if (e.type === "CreateEvent") msg += "created repo " + e.repo.name

                        sendSystemNotification(title, msg, eventUrl, "event:" + e.id)
                    }
                }
            })
        }

        root.rawEvents = uniqueEvents
        root.seenEventIds = uniqueEvents.map(function(e) { return e.id })
        root.lastFetchTimestamp = Math.floor(Date.now() / 1000)
        root.isLoading = false
        root.hasError = false

        var byType = {}
        uniqueEvents.forEach(function(e) {
            var key = e.isMyRepoEvent ? "MyRepo:" + e.type : e.type
            byType[key] = (byType[key] || 0) + 1
        })

        var totalTime = ((Date.now() - root.fetchStartTime) / 1000).toFixed(1)
        Logger.i("GitHubFeed", "Fetch complete: " + uniqueEvents.length + " events from " +
            root.followingList.length + " users in " + totalTime + "s, GraphQL cost: " + root.totalGraphQLCost)
        logDebug("Events by type: " + JSON.stringify(byType))

        saveToCache()
        observation.downloadAvatars(root, root.events)
    }

    function getAvatarPath(actorLogin) {
        return active ? observation.avatarFor(root, actorLogin) : "";
    }

    Timer {
        id: refreshTimer
        interval: root.refreshInterval * 1000
        running: root.active && root.username !== "" && root.token !== ""
        repeat: true
        triggeredOnStart: false

        onTriggered: {
            logDebug("Timer triggered, checking if refresh needed")
            var now = Math.floor(Date.now() / 1000)
            var age = now - root.lastFetchTimestamp

            if (age >= root.refreshInterval) {
                fetchFromGitHub()
            }
        }
    }

    Component.onCompleted: Qt.callLater(loadFromCache)
    Component.onDestruction: stop()
}
