import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

QtObject {
    id: root

    required property var pluginApi
    required property var settingsContext
    required property string apiUrl
    required property string apiKey
    required property string configPath
    required property bool verifyTls
    required property var folderIds
    property bool active: true
    property bool _constructed: false
    function stop() {
        active = false;
        pendingPoll = false;
        pollTimer.stop();
        pollProcess.running = false;
    }
    property bool busy: false
    property bool pendingPoll: false
    property bool parsedCurrentRun: false
    property string lastStdout: ""
    property string lastStderr: ""

    readonly property var settings: settingsContext.settingsView
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})

    readonly property bool enabled: settings.enabled ?? defaults.enabled ?? true
    readonly property int pollIntervalMs: settings.pollIntervalMs ?? defaults.pollIntervalMs ?? 10000
    readonly property string scriptPath: (pluginApi?.pluginDir ?? "") + "/syncthing-status.py"

    function makeEmptySnapshot() {
        return {
            state: "unconfigured",
            detail: "",
            checkedAt: "",
            sources: {
                configPath: "",
                urlSource: "none",
                apiKeySource: "none",
                resolvedUrl: ""
            },
            devices: {
                configured: 0,
                connected: 0,
                paused: 0
            },
            totals: {
                monitoredFolders: 0,
                pausedFolders: 0,
                syncingFolders: 0,
                erroredFolders: 0,
                needItems: 0,
                needBytes: 0
            },
            folders: [],
            availableFolders: [],
            recentErrors: []
        };
    }

    property var snapshot: makeEmptySnapshot()

    readonly property string state: snapshot?.state ?? "unconfigured"
    readonly property string detail: snapshot?.detail ?? ""
    readonly property int configuredDevices: snapshot?.devices?.configured ?? 0
    readonly property int connectedDevices: snapshot?.devices?.connected ?? 0
    readonly property int pausedDevices: snapshot?.devices?.paused ?? 0
    readonly property int monitoredFolders: snapshot?.totals?.monitoredFolders ?? 0
    readonly property int pausedFolders: snapshot?.totals?.pausedFolders ?? 0
    readonly property int syncingFolders: snapshot?.totals?.syncingFolders ?? 0
    readonly property int erroredFolders: snapshot?.totals?.erroredFolders ?? 0
    readonly property int needItems: snapshot?.totals?.needItems ?? 0
    readonly property double needBytes: snapshot?.totals?.needBytes ?? 0
    readonly property var folders: snapshot?.folders ?? []
    readonly property var availableFolders: snapshot?.availableFolders ?? []
    readonly property var recentErrors: snapshot?.recentErrors ?? []
    readonly property string resolvedUrl: snapshot?.sources?.resolvedUrl ?? ""
    readonly property string resolvedConfigPath: snapshot?.sources?.configPath ?? ""
    readonly property string urlSource: snapshot?.sources?.urlSource ?? "none"
    readonly property string apiKeySource: snapshot?.sources?.apiKeySource ?? "none"
    readonly property string checkedAt: snapshot?.checkedAt ?? ""

    readonly property bool hasProblem: state === "offline"
                                      || state === "unauthorized"
                                      || state === "error"
                                      || state === "disconnected"

    function tr(key, params) {
        return pluginApi?.tr(key, params);
    }

    function stateLabel(code) {
        return tr("state." + code);
    }

    function sourceLabel(code) {
        return tr("source." + code);
    }

    function statusSummary() {
        if (!enabled) return tr("summary.disabled");
        if (state === "idle") {
            if (configuredDevices > 0) {
                return tr("summary.idle-devices", { "connected": connectedDevices, "configured": configuredDevices });
            }
            return tr("summary.idle-no-devices");
        }
        if (state === "syncing") {
            if (needItems > 0) return tr("summary.syncing-items", { "count": needItems });
            return tr("summary.syncing-folders", { "count": Math.max(syncingFolders, 1) });
        }
        return tr("summary." + state);
    }

    function statusColor(code) {
        if (!enabled) return AtmoColor.mOutline;
        if (code === "idle") return AtmoColor.mPrimary;
        if (code === "syncing") return AtmoColor.mSecondary;
        if (code === "paused") return AtmoColor.mOutline;
        if (code === "disconnected") return AtmoColor.mSecondary;
        if (code === "offline" || code === "unauthorized" || code === "error") return AtmoColor.mError;
        return AtmoColor.mOutline;
    }

    function statusBadgeBackground(code) {
        if (!enabled || code === "disabled") return AtmoColor.mOutline;
        if (code === "idle") return AtmoColor.mPrimary;
        if (code === "syncing") return AtmoColor.mSecondary;
        if (code === "paused") return AtmoColor.mSurfaceVariant;
        if (code === "disconnected") return AtmoColor.mSecondary;
        if (code === "offline" || code === "unauthorized" || code === "error") return AtmoColor.mError;
        return AtmoColor.mOutline;
    }

    function statusBadgeForeground(code) {
        if (!enabled || code === "disabled") return AtmoColor.mOnSurface;
        if (code === "idle") return AtmoColor.mOnPrimary;
        if (code === "syncing") return AtmoColor.mOnSecondary;
        if (code === "paused") return AtmoColor.mOnSurfaceVariant;
        if (code === "disconnected") return AtmoColor.mOnSecondary;
        if (code === "offline" || code === "unauthorized" || code === "error") return AtmoColor.mOnError;
        return AtmoColor.mOnSurface;
    }

    function statusBadgeIcon(code) {
        if (!enabled || code === "disabled") return "";
        if (code === "paused") return "player-pause";
        if (code === "disconnected" || code === "offline" || code === "unauthorized" || code === "error") return "x";
        return "";
    }

    function badgeText() {
        if (!enabled) return "";
        if (state === "syncing") {
            if (needItems > 99) return "99+";
            if (needItems > 0) return String(needItems);
            return String(Math.max(syncingFolders, 1));
        }
        return "";
    }

    function formatBytes(bytes) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = Number(bytes);
        let index = 0;
        while (value >= 1024 && index < units.length - 1) {
            value /= 1024;
            index++;
        }
        const rounded = (value >= 10 || index === 0) ? Math.round(value) : value.toFixed(1);
        return rounded + " " + units[index];
    }

    function formatCheckedAt(isoValue) {
        if (!isoValue) return "-";
        const parsed = new Date(isoValue);
        if (isNaN(parsed.getTime())) return isoValue;
        return parsed.toLocaleString(Qt.locale().name);
    }

    function requestPoll(force) {
        if (!active || !_constructed) return;
        if (!enabled && !force) return;
        if (!pluginApi) return;
        if (pollProcess.running) {
            pendingPoll = true;
            return;
        }
        parsedCurrentRun = false;
        lastStdout = "";
        lastStderr = "";
        pollProcess.running = true;
    }

    function applySnapshot(rawText) {
        if (!active) return;
        const text = (rawText || "").trim();
        if (!text) return;
        try {
            const parsed = JSON.parse(text);
            snapshot = parsed;
            parsedCurrentRun = true;
        } catch (error) {
            Logger.w("[syncthing-status] helper output is not valid JSON (", text.length, "bytes):", error);
        }
    }

    onEnabledChanged: {
        if (enabled) {
            pollTimer.restart();
            requestPoll(false);
        } else {
            pollTimer.stop();
        }
    }
    onPollIntervalMsChanged: requestPoll(false)

    Component.onCompleted: {
        _constructed = true;
        if (enabled) requestPoll(false);
    }
    Component.onDestruction: stop()

    readonly property Timer pollTimer: Timer {
        interval: root.pollIntervalMs
        repeat: true
        running: root.active && root.enabled
        onTriggered: root.requestPoll(false)
    }

    readonly property Process pollProcess: Process {
        command: {
            const args = [
                "python3", root.scriptPath,
                "--timeout", "5"
            ];
            if (root.apiUrl) {
                args.push("--url");
                args.push(root.apiUrl);
            }
            if (root.apiKey) {
                args.push("--api-key");
                args.push(root.apiKey);
            }
            if (root.configPath) {
                args.push("--config-path");
                args.push(root.configPath);
            }
            if (root.folderIds.length > 0) {
                args.push("--folders");
                args.push(root.folderIds.join(","));
            }
            if (root.verifyTls) {
                args.push("--verify-tls");
            }
            return args;
        }

        running: false

        onStarted: {
            root.busy = true;
        }

        onExited: (exitCode, exitStatus) => {
            if (!root.active) return;
            root.busy = false;
            if (!root.parsedCurrentRun) {
                const fallback = root.makeEmptySnapshot();
                fallback.state = "error";
                fallback.detail = root.lastStderr || ("Helper exited with code " + exitCode);
                root.snapshot = fallback;
            }
            if (root.pendingPoll) {
                root.pendingPoll = false;
                root.requestPoll(false);
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.active) return;
                root.lastStdout = text;
                root.applySnapshot(text);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (!root.active) return;
                root.lastStderr = text.trim();
                if (root.lastStderr) {
                    Logger.w("[syncthing-status]", root.lastStderr);
                }
            }
        }
    }

}
