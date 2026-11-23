import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root
    property var pluginApi: null
    property var selectedContext: null
    property bool retired: false
    property bool componentReady: false
    readonly property var policyContext: selectedContext || pluginApi?.settingsContext
    readonly property bool policyCurrent: !retired && (policyContext?.current() ?? false)
    readonly property var cfg: policyCurrent ? policyContext.settingsView : ({})
    readonly property bool automationEnabled: policyCurrent && (cfg.enabled ?? true)
    readonly property int maxVisible: cfg.maxVisible ?? 4
    readonly property bool perWorkspace: cfg.perWorkspace ?? false
    readonly property bool onlyAtMax: cfg.onlyAtMax ?? true
    readonly property var workspaceMaxVisible: cfg.workspaceMaxVisible ?? ({})
    readonly property int debounceMs: cfg.debounceMs ?? 300
    readonly property int maxEventsPerSecond: cfg.maxEventsPerSecond ?? 20
    readonly property string scriptPath: (pluginApi?.pluginDir ?? "") + "/auto-tile.py"
    readonly property string configFilePath: (pluginApi?.pluginDir ?? "") + "/runtime-config.json"
    readonly property bool running: daemonProcess.running
    property string status: "stopped"
    property var activePolicy: null
    property var queuedConfig: null
    property int generation: 0
    property int admittedMaxVisible: 4
    property int admittedDebounceMs: 300
    property int admittedMaxEvents: 20
    property bool admittedPerWorkspace: false
    property bool admittedOnlyAtMax: true
    readonly property string liveConfig: JSON.stringify({maxVisible: maxVisible, onlyAtMax: onlyAtMax, perWorkspace: perWorkspace, workspaceMaxVisible: workspaceMaxVisible})
    onLiveConfigChanged: if (componentReady) hotReloadConfig()
    onDebounceMsChanged: if (componentReady) restartDaemon()
    onMaxEventsPerSecondChanged: if (componentReady) restartDaemon()
    onAutomationEnabledChanged: if (componentReady) reconcileDaemon()
    onPolicyCurrentChanged: if (componentReady) reconcileDaemon()

    function applySettings(context) {
        context = context || pluginApi?.settingsContext;
        if (retired || !context?.current()) return false;
        selectedContext = context;
        restartDaemon();
        return true;
    }
    function capturePolicy(context) {
        context = context || selectedContext || pluginApi?.settingsContext;
        if (retired || !context?.current()) return null;
        // Read the admitted context directly. The selectedContext binding graph
        // may not have reevaluated its presentation properties inside this call.
        const values = context.settingsView;
        admittedMaxVisible = values.maxVisible ?? 4;
        admittedDebounceMs = values.debounceMs ?? 300;
        admittedMaxEvents = values.maxEventsPerSecond ?? 20;
        admittedPerWorkspace = values.perWorkspace ?? false;
        admittedOnlyAtMax = values.onlyAtMax ?? true;
        const workspaces = values.workspaceMaxVisible ?? ({});
        return {context: context, generation: generation, maxVisible: admittedMaxVisible, debounceMs: admittedDebounceMs,
            maxEventsPerSecond: admittedMaxEvents, perWorkspace: admittedPerWorkspace, onlyAtMax: admittedOnlyAtMax,
            config: JSON.stringify({maxVisible: admittedMaxVisible, onlyAtMax: admittedOnlyAtMax, perWorkspace: admittedPerWorkspace, workspaceMaxVisible: workspaces}), workspaceConfig: JSON.stringify(workspaces)};
    }
    function current(policy) {
        return !retired && policy && policy.generation === generation && policy.context === policyContext && policy.context.current();
    }
    function reconcileDaemon() {
        if (!componentReady || retired) return;
        if (!automationEnabled) { stopDaemon(); return; }
        if (!daemonProcess.running) startDaemon();
    }
    function startDaemon() {
        if (!componentReady || !automationEnabled || daemonProcess.running) return;
        const policy = capturePolicy();
        if (!current(policy)) return;
        activePolicy = policy;
        const args = ["python3", scriptPath, "--max-visible", String(policy.maxVisible),
            "--debounce", String(policy.debounceMs / 1000.0), "--max-events", String(policy.maxEventsPerSecond),
            "--config-file", configFilePath, policy.onlyAtMax ? "--only-at-max" : "--no-only-at-max"];
        if (policy.perWorkspace) args.push("--per-workspace", "--workspace-config", policy.workspaceConfig);
        daemonProcess.command = args;
        status = "starting";
        daemonProcess.running = true;
    }
    function stopDaemon() {
        generation++;
        restartTimer.stop();
        queuedConfig = null;
        configWriter.running = false;
        if (daemonProcess.running) daemonProcess.signal(15);
    }
    function restartDaemon(context) {
        if (context) return applySettings(context);
        if (!componentReady || retired) return false;
        stopDaemon();
        restartTimer.restart();
        return true;
    }
    function hotReloadConfig() {
        if (!componentReady || !automationEnabled || !daemonProcess.running) return;
        queuedConfig = capturePolicy();
        writeNextConfig();
    }
    function writeNextConfig() {
        if (configWriter.running) return;
        const policy = queuedConfig;
        queuedConfig = null;
        if (!current(policy) || !daemonProcess.running) return;
        configWriter.policy = policy;
        configWriter.command = ["sh", "-c", 'printf "%s\\n" "$1" > "$2"', "sh", policy.config, configFilePath];
        configWriter.running = true;
    }
    function saveField(key, value, runtimeApi) {
        runtimeApi = runtimeApi || pluginApi;
        if (retired || !runtimeApi?.settingsContext?.current()) return false;
        runtimeApi.pluginSettings[key] = value;
        runtimeApi.saveSettings();
        const changedContext = policyContext !== runtimeApi.settingsContext;
        selectedContext = runtimeApi.settingsContext;
        if (changedContext) restartDaemon();
        else if (key === "enabled") reconcileDaemon();
        else hotReloadConfig();
        return true;
    }
    function setEnabled(value, runtimeApi) { return saveField("enabled", value, runtimeApi); }
    function setMaxVisible(count, runtimeApi) {
        if (count < 1 || count > 8) return false;
        return saveField("maxVisible", count, runtimeApi);
    }
    function setWorkspaceMaxVisible(wsId, count, runtimeApi) {
        if (count < 1 || count > 8) return false;
        runtimeApi = runtimeApi || pluginApi;
        if (!runtimeApi?.settingsContext?.current()) return false;
        const updated = Object.assign({}, runtimeApi.settingsContext.settingsView.workspaceMaxVisible || {});
        updated[String(wsId)] = count;
        return saveField("workspaceMaxVisible", updated, runtimeApi);
    }
    function setPerWorkspace(value, runtimeApi) { return saveField("perWorkspace", value, runtimeApi); }
    function setOnlyAtMax(value, runtimeApi) { return saveField("onlyAtMax", value, runtimeApi); }
    function getMaxVisibleForWorkspace(wsId, context) {
        context = context || policyContext;
        if (!context?.current()) return 4;
        const values = context.settingsView;
        const config = values.workspaceMaxVisible;
        return values.perWorkspace && config && String(wsId) in config ? config[String(wsId)] : (values.maxVisible ?? 4);
    }
    Process {
        id: configWriter
        property var policy: null
        onExited: code => {
            if (code === 0 && root.current(policy) && root.daemonProcess.running) root.daemonProcess.signal(10);
            policy = null;
            Qt.callLater(function() { if (root) root.writeNextConfig(); });
        }
    }
    readonly property Process daemonProcess: Process {
        onStarted: root.status = "running"
        onExited: (exitCode, exitStatus) => {
            const previous = root.activePolicy;
            root.activePolicy = null;
            root.status = exitCode === 0 || exitStatus !== 0 ? "stopped" : "error";
            if (root.current(previous) && root.automationEnabled && exitCode !== 0 && exitStatus === 0) restartTimer.restart();
            else if (root.automationEnabled && !root.retired) Qt.callLater(function() { if (root) root.reconcileDaemon(); });
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) Logger.w("AutoTile", text.trim()) }
    }
    Timer { id: restartTimer; interval: 2000; repeat: false; onTriggered: root.reconcileDaemon() }
    IpcHandler {
        target: "plugin:niri-auto-tile"
        function toggle() { root.setEnabled(!(root.pluginApi?.settingsContext?.settingsView.enabled ?? true), root.pluginApi); }
        function setColumns(count: int) { root.setMaxVisible(count); }
        function status() { return {running: root.running, enabled: root.automationEnabled, status: root.status, maxVisible: root.maxVisible, perWorkspace: root.perWorkspace}; }
    }
    Component.onCompleted: { componentReady = true; reconcileDaemon(); }
    Component.onDestruction: { retired = true; componentReady = false; stopDaemon(); }
}
