/*
 * SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
 *
 * SPDX-License-Identifier: MIT
 */

import QtQuick
import Quickshell.Io
import Quickshell.Services.Notifications

import qs.Commons

QtObject {
    id: root

    enum SGFXMode {
        Integrated,
        Hybrid,
        AsusMuxDgpu,
        NvidiaNoModeset,
        Vfio,
        AsusEgpu,
        None
    }

    enum SGFXAction {
        Logout,
        Reboot,
        SwitchToIntegrated,
        AsusEgpuDisable,
        Nothing
    }

    property var pluginApi: null
    property bool _retired: false
    property var _settingsConsumers: new Map()
    property var _refreshPolicy: null
    property var _pendingRefreshPolicy: null
    property var _modeOperation: null
    readonly property bool _refreshCurrent: !root._retired && (root._refreshPolicy?.context?.current() ?? false)
    readonly property bool _modeCurrent: !root._retired && (root._modeOperation?.policy.context.current() ?? false)
    readonly property string pluginId: pluginApi?.pluginId
    readonly property string pluginVersion: pluginApi?.manifest.version ?? "???"

    readonly property QtObject pluginSettings: QtObject {
        readonly property var _manifest: root.pluginApi?.manifest.metadata.defaultSettings ?? {}
        readonly property var _user: root.pluginApi?.pluginSettings ?? {}

        property bool debug: _user.debug ?? _manifest.debug ?? false

        // rog-control-center
        readonly property QtObject rogcc: QtObject {
            readonly property var _manifest: root.pluginApi?.manifest.metadata.defaultSettings.rogcc ?? {}
            readonly property var _user: root.pluginApi?.pluginSettings.rogcc ?? {}

            property bool listenToNotifications: _user.listenToNotifications ?? _manifest.listenToNotifications ?? false
        }

        readonly property QtObject supergfxctl: QtObject {
            readonly property var _manifest: root.pluginApi?.manifest.metadata.defaultSettings.supergfxctl ?? {}
            readonly property var _user: root.pluginApi?.pluginSettings.supergfxctl ?? {}

            property bool patchPending: _user.patchPending ?? _manifest.patchPending ?? true
            property bool polling: _user.polling ?? _manifest.polling ?? false
            property int pollingInterval: _user.pollingInterval ?? _manifest.pollingInterval ?? 3000
        }
    }

    readonly property bool available: sgfx.available
    readonly property bool busy: setModeProc.running || refreshProc.running

    readonly property string version: sgfx.version
    readonly property int mode: sgfx.mode
    readonly property int pendingAction: sgfx.pendingAction
    readonly property bool hasPendingAction: sgfx.pendingAction !== Main.SGFXAction.Nothing
    // An in-flight target is only a presentation hint while its owner is live.
    readonly property int pendingMode: _modeCurrent && _modeOperation.policy.patchPending ? _modeOperation.targetMode : sgfx.pendingMode

    readonly property Component clientFactory: Component { GpuSettingsClient {} }
    function settingsConsumerFor(context) {
        if (!context?.current() || _retired) return null;
        if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
        const client = clientFactory.createObject(root, {
            settingsContext: context, defaults: root.pluginApi.manifest.metadata.defaultSettings,
            available: Qt.binding(function () { return root.available; }),
            busy: Qt.binding(function () { return root.busy; }),
            requestRefresh: function () { root.refresh(context); },
            retire: function (retired) { root._settingsConsumers.delete(context); retired.destroy(); }
        });
        _settingsConsumers.set(context, client);
        return client;
    }

    function capturePolicy(context) {
        context = context || pluginApi?.settingsContext;
        const client = settingsConsumerFor(context);
        if (!client?.current) return null;
        return {context: context, debug: client.debug, patchPending: client.patchPending};
    }

    on_RefreshCurrentChanged: { if (!_refreshCurrent) refreshProc.running = false; }
    on_ModeCurrentChanged: { if (!_modeCurrent) setModeProc.running = false; }
    Component.onDestruction: { _retired = true; refreshProc.running = false; setModeProc.running = false; }

    Component.onCompleted: {
        refresh();
    }

    function isModeSupported(mode: int): bool {
        return (sgfx.supportedModesMask & (1 << mode)) !== 0;
    }

    function getModeIcon(mode: int): string {
        switch (mode) {
        case Main.SGFXMode.Integrated:
            return "cpu";
        case Main.SGFXMode.Hybrid:
            return "chart-circles";
        case Main.SGFXMode.AsusMuxDgpu:
            return "gauge";
        case Main.SGFXMode.NvidiaNoModeset:
            return "cpu-off";
        case Main.SGFXMode.Vfio:
            return "device-desktop-up";
        case Main.SGFXMode.AsusEgpu:
            return "external-link";
        default:
            return "question-mark";
        }
    }

    function getModeLabel(mode: int): string {
        switch (mode) {
        case Main.SGFXMode.Integrated:
            return root.pluginApi.tr("mode.Integrated");
        case Main.SGFXMode.Hybrid:
            return root.pluginApi.tr("mode.Hybrid");
        case Main.SGFXMode.AsusMuxDgpu:
            return root.pluginApi.tr("mode.AsusMuxDgpu");
        case Main.SGFXMode.NvidiaNoModeset:
            return root.pluginApi.tr("mode.NvidiaNoModeset");
        case Main.SGFXMode.Vfio:
            return root.pluginApi.tr("mode.Vfio");
        case Main.SGFXMode.AsusEgpu:
            return root.pluginApi.tr("mode.AsusEgpu");
        default:
            return root.pluginApi.tr("unknown");
        }
    }

    function getActionIcon(action: int): string {
        switch (action) {
        case Main.SGFXAction.Logout:
            return "logout";
        case Main.SGFXAction.Reboot:
            return "reload";
        case Main.SGFXAction.SwitchToIntegrated:
            return "cpu";
        case Main.SGFXAction.AsusEgpuDisable:
            return "external-link-off";
        case Main.SGFXAction.Nothing:
        default:
            return "check";
        }
    }

    function getActionLabel(action: int): string {
        switch (action) {
        case Main.SGFXAction.Logout:
            return I18n.tr("session-menu.logout");
        case Main.SGFXAction.Reboot:
            return I18n.tr("session-menu.reboot");
        case Main.SGFXAction.SwitchToIntegrated:
            return root.pluginApi.tr("action.SwitchToIntegrated");
        case Main.SGFXAction.AsusEgpuDisable:
            return root.pluginApi.tr("action.AsusEgpuDisable");
        case Main.SGFXAction.Nothing:
        default:
            return "";
        }
    }

    function getTooltip(): string {
        const label = root.getModeLabel(root.mode);
        if (!root.hasPendingAction) {
            return label;
        }
        return `${label} | ${root.getActionLabel(root.pendingAction)}`;
    }

    function refresh(context): bool {
        return _refreshWithPolicy(capturePolicy(context));
    }

    function _refreshWithPolicy(policy): bool {
        if (_retired || !policy?.context?.current()) return false;
        // Process.running=true used to queue one further query. Retain its
        // admitted policy rather than dropping it or pairing old output with it.
        _pendingRefreshPolicy = policy;
        _pumpRefresh();
        return true;
    }

    function _pumpRefresh() {
        if (_retired || refreshProc.running || !_pendingRefreshPolicy) return;
        const policy = _pendingRefreshPolicy;
        _pendingRefreshPolicy = null;
        if (!policy.context.current()) return;
        _refreshPolicy = policy;
        sgfx.refresh(policy);
    }

    function setMode(mode: int, context): bool {
        const policy = capturePolicy(context);
        if (!policy || _modeOperation) return false;
        return sgfx.setMode(mode, policy);
    }

    function logFor(policy, ...msg): void {
        if (policy?.debug) Logger.i(root.pluginId, `v${pluginVersion}/${version}`, ...msg);
    }
    function warnFor(policy, ...msg): void {
        if (policy?.debug) Logger.w(root.pluginId, `v${pluginVersion}/${version}`, ...msg);
    }
    function errorFor(policy, ...msg): void {
        if (policy?.debug) Logger.e(root.pluginId, `v${pluginVersion}/${version}`, ...msg);
    }

    function log(...msg): void {
        if (root.pluginSettings.debug) {
            Logger.i(root.pluginId, `v${pluginVersion}/${version}`, ...msg);
        }
    }

    function warn(...msg): void {
        if (root.pluginSettings.debug) {
            Logger.w(root.pluginId, `v${pluginVersion}/${version}`, ...msg);
        }
    }

    function error(...msg): void {
        if (root.pluginSettings.debug) {
            Logger.e(root.pluginId, `v${pluginVersion}/${version}`, ...msg);
        }
    }

    readonly property Process refreshProc: Process {
        id: refreshProc
        running: false
        command: ["supergfxctl", "--version", "--get", "--supported", "--pend-action", "--pend-mode"]
        stdout: StdioCollector {
            // TODO: supergfxctl sometimes takes time to exit after printing
            // investigate or find a workaround
            onStreamFinished: {
                if (root._refreshCurrent) sgfx.parseOutput(text.trim(), root._refreshPolicy);
            }
        }
        onExited: exitCode => {
            if (root._refreshCurrent && exitCode !== 0) {
                sgfx.available = false;
            }
            Qt.callLater(root._pumpRefresh);
        }
    }

    readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
    readonly property var pollingTimer: settingsConsumer?.pollingTimer ?? null

    readonly property Connections notificationListener: Connections {
        target: NotificationServer {
            onNotification: notification => {
                if (!root._retired) root.log(notification);
            }
        }
    }

    readonly property Process setModeProc: Process {
        stderr: StdioCollector {
            onStreamFinished: {
                if (root._modeCurrent && text) root.errorFor(root._modeOperation.policy, text);
            }
        }
        onExited: exitCode => {
            const operation = root._modeOperation;
            const current = root._modeCurrent;
            if (current && operation.policy.patchPending && exitCode === 0) {
                const action = sgfx.requiredAction(operation.targetMode, operation.baseMode);
                sgfx.manualRequest = {baseMode: operation.baseMode, targetMode: operation.targetMode, action: action};
                sgfx.pendingMode = operation.targetMode;
                sgfx.pendingAction = action;
            }
            root._modeOperation = null;
            if (!current) return;
            const policy = operation.policy;

            // per asusctl/rog-control-center, supergfxctl output after mode switch is unreliable, and requires reboot
            // (see https://gitlab.com/asus-linux/asusctl/-/blob/main/rog-control-center/src/notify.rs?ref_type=heads#L361)
            //
            // it is unclear whether thats actually true (the unreliable part, and the reboot part), since per supergfxctl readme
            // (see https://gitlab.com/asus-linux/supergfxctl)
            // 			If rebootless switch fails: you may need the following:
            // 			sudo sed -i 's/#KillUserProcesses=no/KillUserProcesses=yes/' /etc/systemd/logind.conf
            // as well as
            // 			Switch GPU modes
            // 			Switching to/from Hybrid mode requires a logout only. (no reboot)
            // 			Switching between integrated/vfio is instant. (no logout or reboot)
            //
            // after some testing on my machine, both seem to be incorrect as to what action needs to be taken:
            // integrated <-> hybrid: reboot
            // integrated -> dgpu: just works
            // dgpu <- integrated: reboot      // !!!!
            // hybrid <-> dgpu: logout
            //
            // most of the time
            // supergfxctl --pend-mode --pend-action
            // reports absolute nonsense, saying no action is required, or no mode is pending after switch
            //
            // for now, we provide the user with 2 options:
            // guess the required action ourselves or rely on supergfxctl
            root._refreshWithPolicy(policy);
        }
    }

    // internal helper dealing with supergfxctl
    readonly property QtObject sgfx: QtObject {
        property bool available: false
        property string version: "???"
        property int mode: Main.SGFXMode.None
        property int pendingAction: Main.SGFXAction.Nothing
        property int pendingMode: Main.SGFXMode.None
        // A daemon-reported pending mode is not an admitted manual command.
        property var manualRequest: null
        property int supportedModesMask: 0

        function isValidMode(v: int): bool {
            return modeEnumReversed.hasOwnProperty(v);
        }

        // TODO: perf of QJSVlue vs a switch statement
        readonly property var modeEnum: ({
                "Integrated": Main.SGFXMode.Integrated,
                "Hybrid": Main.SGFXMode.Hybrid,
                "AsusMuxDgpu": Main.SGFXMode.AsusMuxDgpu,
                "NvidiaNoModeset": Main.SGFXMode.NvidiaNoModeset,
                "Vfio": Main.SGFXMode.Vfio,
                "AsusEgpu": Main.SGFXMode.AsusEgpu,
                "None": Main.SGFXMode.None
            })

        readonly property var modeEnumReversed: Object.entries(modeEnum).reduce((obj, item) => (obj[item[1]] = item[0]) && obj, {})

        function actionFromString(message: string): int {
            switch (message) {
            case "Logout required to complete mode change":
                return Main.SGFXAction.Logout;
            case "Reboot required to complete mode change":
                return Main.SGFXAction.Reboot;
            case "You must switch to Integrated first":
                return Main.SGFXAction.SwitchToIntegrated;
            case "The mode must be switched to Integrated or Hybrid first":
                return Main.SGFXAction.AsusEgpuDisable;
            case "No action required":
                return Main.SGFXAction.Nothing;
            default:
                return Main.SGFXAction.Nothing;
            }
        }

        // patched up version of pending actions for mode switch
        // TODO: this WILL differ depending on hardware (maybe fw versions?)
        // supergfxctl has an option to force reboot to deal with finicky hw
        // probably should leave it up to supergfx to decide?
        // or give the user ability to configure actions
        readonly property var actionMatrix: ({
                [Main.SGFXMode.Hybrid]: ({
                        [Main.SGFXMode.Integrated]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.AsusEgpu]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.AsusMuxDgpu]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.Vfio]: Main.SGFXAction.SwitchToIntegrated
                    }),
                [Main.SGFXMode.Integrated]: ({
                        [Main.SGFXMode.Hybrid]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.AsusEgpu]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.AsusMuxDgpu]: Main.SGFXAction.Reboot
                    }),
                [Main.SGFXMode.NvidiaNoModeset]: ({
                        [Main.SGFXMode.AsusEgpu]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.AsusMuxDgpu]: Main.SGFXAction.Reboot
                    }),
                [Main.SGFXMode.Vfio]: ({
                        [Main.SGFXMode.AsusEgpu]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.Hybrid]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.AsusMuxDgpu]: Main.SGFXAction.Reboot
                    }),
                [Main.SGFXMode.AsusEgpu]: ({
                        [Main.SGFXMode.Integrated]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.Hybrid]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.NvidiaNoModeset]: Main.SGFXAction.Logout,
                        [Main.SGFXMode.Vfio]: Main.SGFXAction.SwitchToIntegrated,
                        [Main.SGFXMode.AsusMuxDgpu]: Main.SGFXAction.Reboot
                    }),
                [Main.SGFXMode.AsusMuxDgpu]: ({
                        [Main.SGFXMode.Integrated]: Main.SGFXAction.Reboot,
                        [Main.SGFXMode.Hybrid]: Main.SGFXAction.Reboot,
                        [Main.SGFXMode.NvidiaNoModeset]: Main.SGFXAction.Reboot,
                        [Main.SGFXMode.Vfio]: Main.SGFXAction.SwitchToIntegrated,
                        [Main.SGFXMode.AsusMuxDgpu]: Main.SGFXAction.Reboot
                    })
            })

        function setMode(modeEnum: int, policy): bool {
            if (!isValidMode(modeEnum)) {
                root.errorFor(policy, "tried setting mode to invalid int", modeEnum);
                return false;
            }

            root._modeOperation = {policy: policy, baseMode: mode, targetMode: modeEnum};
            setModeProc.command = ["supergfxctl", "--mode", modeEnumReversed[modeEnum]];
            setModeProc.running = true;

            root.logFor(policy, `Setting mode ${modeEnum}`);

            return true;
        }

        function refresh(policy): void {
            root.logFor(policy, "refreshing...");
            refreshProc.running = true;
        }

        function isVersionGreater(a, b) {
            return a.localeCompare(b, undefined, {
                numeric: true
            }) > 0;
        }

        function parseOutput(text: string, policy): bool {
            if (root._retired || !policy?.context?.current()) return false;
            root.logFor(policy, "[parseOutput] start");

            if (text == "") {
                available = false;
                return available;
            }

            const lines = text.split("\n");

            if (lines.length != 5) {
                available = false;
                return available;
            }

            const lineVersion = lines[0] || "???";
            const lineMode = lines[1] || "None";
            const lineSupported = lines[2] || "[]";
            const linePendAction = lines[3] || "No action required";
            let linePendMode = lines[4] || "";

            // set version as soon as possible
            // mainly so that .log functions print correct version
            version = lineVersion;

            root.logFor(policy, `[parseOutput] version=${lineVersion}, mode=${lineMode}, pendingMode=${linePendMode}, pendingAction=${linePendAction}`);

            if (linePendMode === "Unknown") {
                linePendMode = "None";
            }

            const newMode = modeEnum[lineMode] ?? Main.SGFXMode.None;
            const newPendingMode = modeEnum[linePendMode] ?? Main.SGFXMode.None;
            const newPendingAction = actionFromString(linePendAction);

            let newSupportedMask = 0;
            if (lineSupported.length > 2) {
                const trimmed = lineSupported.substring(1, lineSupported.length - 1);
                const modeNames = trimmed.split(",");
                const modeEnums = modeNames.map(name => modeEnum[name.trim()] ?? Main.SGFXMode.None).filter(m => m >= 0);

                // for versions < 5.2.7, add Integrated and Hybrid if current mode is AsusMuxDgpu
                // https://gitlab.com/asus-linux/supergfxctl/-/merge_requests/44
                if (!isVersionGreater(lineVersion, "5.2.7") && newMode === Main.SGFXMode.AsusMuxDgpu) {
                    root.warnFor(policy, "fixing supergfxctl bug [merge request #44]: adding missing Integrated and Hybrid modes");

                    if (!modeEnums.includes(Main.SGFXMode.Integrated))
                        modeEnums.push(Main.SGFXMode.Integrated);
                    if (!modeEnums.includes(Main.SGFXMode.Hybrid))
                        modeEnums.push(Main.SGFXMode.Hybrid);
                }

                for (let i = 0; i < modeEnums.length; i++) {
                    newSupportedMask |= 1 << modeEnums[i];
                }
            } else {
                root.warnFor(policy, "[parseOutput] no supported modes reported");
            }

            supportedModesMask = newSupportedMask;

            if (!policy.patchPending) {
                manualRequest = null;
                mode = newMode;
                pendingMode = newPendingMode;
                pendingAction = newPendingAction;
            } else {
                if (!manualRequest) {
                    mode = newMode;
                    pendingMode = newPendingMode;
                    pendingAction = requiredAction(mode, newPendingMode);
                    root.logFor(policy, "[parseOutput] state updated:", `mode=${mode}, pendingMode=${pendingMode}, pendingAction=${pendingAction}`);
                } else {
                    mode = manualRequest.baseMode;
                    pendingMode = manualRequest.targetMode;
                    pendingAction = manualRequest.action;
                    root.logFor(policy, "[parseOutput] retaining admitted manual mode request");
                }
            }

            available = true;

            root.logFor(policy, `[parseOutput] completed successfully (available=${available}, supportedMask=0x${newSupportedMask.toString(16)})`);

            return available;
        }

        function requiredAction(newMode: int, curMode: int): int {
            const row = actionMatrix[newMode];
            return row?.[curMode] ?? Main.SGFXAction.Nothing;
        }
    }
}
