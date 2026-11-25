import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    // One physical lifecycle; accepting a policy does not replace its content writer.
    property var selectedContext: null
    readonly property var policyContext: selectedContext || pluginApi?.settingsContext
    readonly property bool policyCurrent: policyContext?.current() ?? false
    property bool _constructed: false
    property bool _destroying: false
    property var _queryPolicy: null
    property var _tabletModePolicy: null
    property bool _tabletModeRefreshPending: false
    property var _applyPolicy: null
    property var _hyprTouchQueuedPolicy: null
    property var _hyprTouchActivePolicy: null
    property var _autoRotateSessionPolicy: null
    property var _autoRotateRestorePolicy: null
    property bool _restartStateWatcher: false
    property var transformsByOutput: ({})
    property var hyprMonitorStateByOutput: ({})
    property var busyByOutput: ({})
    property string _queryReason: ""
    property string _queryOutputName: ""
    property string _applyOutputName: ""
    property string _applyTarget: ""
    property bool _applyShouldShowSuccessToast: false
    property bool _applyShouldShowErrorToast: true
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
    readonly property var cfg: policyCurrent ? policyContext.settingsView : ({})
    readonly property var sharedCfg: pluginApi?.pluginSettings ?? ({})
    readonly property bool showSuccessToast: cfg.showSuccessToast ?? defaults.showSuccessToast ?? true
    readonly property bool autoTabletBarDensity: cfg.autoTabletBarDensity ?? defaults.autoTabletBarDensity ?? false
    readonly property bool exclusiveDockInTabletMode: cfg.exclusiveDockInTabletMode ?? defaults.exclusiveDockInTabletMode ?? false
    readonly property bool autoRotateInTabletMode: cfg.autoRotateInTabletMode ?? defaults.autoRotateInTabletMode ?? false
    readonly property bool autoRotateOutsideTabletMode: cfg.autoRotateOutsideTabletMode ?? defaults.autoRotateOutsideTabletMode ?? false
    readonly property bool syncHyprTouchTransform: cfg.syncHyprTouchTransform ?? defaults.syncHyprTouchTransform ?? true
    readonly property bool flipVerticalSensorOrientation: cfg.flipVerticalSensorOrientation ?? defaults.flipVerticalSensorOrientation ?? false
    readonly property string buttonBehavior: cfg.buttonBehavior ?? defaults.buttonBehavior ?? "toggle-auto-rotate-lock"
    readonly property string tabletBarDensity: cfg.tabletBarDensity ?? defaults.tabletBarDensity ?? "default"
    readonly property string tabletModeStateFile: cfg.tabletModeStateFile ?? defaults.tabletModeStateFile ?? "/tmp/noctalia-tablet-mode"
    readonly property string lastNonTabletBarDensity: sharedCfg.lastNonTabletBarDensity ?? defaults.lastNonTabletBarDensity ?? ""
    readonly property string lastNonTabletDockType: sharedCfg.lastNonTabletDockType ?? defaults.lastNonTabletDockType ?? ""
    readonly property bool lastNonTabletDockEnabled: sharedCfg.lastNonTabletDockEnabled ?? defaults.lastNonTabletDockEnabled ?? true
    property bool _tabletDensityManaged: false
    property bool _tabletDockManaged: false
    property bool _tabletModeDetected: false
    property bool _rotationLocked: false
    property string _autoRotateOutputName: ""
    property string _autoRotateSavedTransform: ""
    property string _autoRotatePendingTransform: ""
    property string _autoRotateLastAppliedTransform: ""
    property string _autoRotateRestoreOutputName: ""
    property string _autoRotateRestoreTransform: ""
    property bool _autoRotateSessionActive: false
    property string compositorBackend: "unknown"
    property bool _backendUnsupportedNotified: false
    property string _hyprEventBuffer: ""
    property string _hyprTouchQueuedOutputName: ""
    property string _hyprTouchQueuedTarget: ""
    property string _hyprTouchActiveOutputName: ""
    property string _hyprTouchActiveTarget: ""
    property var _hyprTouchApplyNames: []
    property int _hyprTouchApplyIndex: 0
    property var _hyprTouchFailedNames: []
    property var _logQueue: []

    function capturePolicy(context) {
        context = context || pluginApi?.settingsContext;
        if (!context?.current() || _destroying) return null;
        const values = context.settingsView;
        return {context: context, backend: compositorBackend,
            stateFile: values.tabletModeStateFile ?? defaults.tabletModeStateFile ?? "/tmp/noctalia-tablet-mode",
            showSuccessToast: values.showSuccessToast ?? defaults.showSuccessToast ?? true,
            buttonBehavior: values.buttonBehavior ?? defaults.buttonBehavior ?? "toggle-auto-rotate-lock",
            autoRotateInTabletMode: values.autoRotateInTabletMode ?? defaults.autoRotateInTabletMode ?? false,
            autoRotateOutsideTabletMode: values.autoRotateOutsideTabletMode ?? defaults.autoRotateOutsideTabletMode ?? false,
            flipVerticalSensorOrientation: values.flipVerticalSensorOrientation ?? defaults.flipVerticalSensorOrientation ?? false,
            syncHyprTouchTransform: values.syncHyprTouchTransform ?? defaults.syncHyprTouchTransform ?? true};
    }

    function activatePolicy(context) {
        context = context || pluginApi?.settingsContext;
        if (!context?.current() || _destroying) return false;
        if (policyContext !== context) _endAutoRotateSession();
        selectedContext = context;
        _syncTabletModeState(_tabletModeDetected);
        refreshTabletModeState();
        return true;
    }


    function _copyMap(map) {
        return Object.assign({}, map || {})
    }

    function _log(message) {
        if (_destroying) return;
        var next = root._logQueue.slice()
        next.push(new Date().toISOString() + " " + message)
        root._logQueue = next
        root._syncLogQueue()
    }

    function _syncLogQueue() {
        if (root._destroying || debugLogProc.running || !root._logQueue.length)
            return

        var next = root._logQueue.slice()
        var line = next.shift()
        root._logQueue = next
        debugLogProc.command = [
            "sh",
            "-c",
            "printf '%s\n' \"$1\" >> /tmp/2-in-1-tools.log",
            "2-in-1-tools",
            line
        ]
        debugLogProc.running = true
    }

    function _backendName() {
        switch (root.compositorBackend) {
        case "hyprland": return "Hyprland"
        case "niri": return "Niri"
        default: return "unknown compositor"
        }
    }

    function _isBackendSupported() {
        return root.compositorBackend === "niri" || root.compositorBackend === "hyprland"
    }

    function _notifyUnsupportedBackendOnce() {
        if (root._backendUnsupportedNotified)
            return
        root._backendUnsupportedNotified = true
        root._log("unsupported backend notification shown; backend=" + root.compositorBackend)
        ToastService.showError("2-in-1-tools supports Niri and Hyprland only")
    }

    function _normalizeTransform(transform) {
        var value = (transform || "").toString().trim().toLowerCase()
        switch (value) {
        case "0":
            return "Normal"
        case "1":
            return "90"
        case "2":
            return "180"
        case "3":
            return "270"
        case "90":
        case "180":
        case "270":
            return value
        case "normal":
        case "":
            return "Normal"
        default:
            return "Normal"
        }
    }

    function _barDensity() {
        return Settings.data?.bar?.density ?? "default"
    }

    function _dockType() {
        return Settings.data?.dock?.dockType ?? "floating"
    }

    function _dockEnabled() {
        return Settings.data?.dock?.enabled ?? true
    }

    function _savePluginSetting(key, value) {
        if (!pluginApi || !root.policyCurrent || root._destroying) return
        pluginApi.pluginSettings[key] = value
        pluginApi.saveSettings()
    }

    function _applyTabletDensity() {
        var target = (root.tabletBarDensity || "default").trim()
        if (!target)
            target = "default"

        if (!root._tabletDensityManaged) {
            if (!root.lastNonTabletBarDensity)
                root._savePluginSetting("lastNonTabletBarDensity", root._barDensity())
            root._tabletDensityManaged = true
        }

        if (Settings.data?.bar && Settings.data.bar.density !== target)
            Settings.data.bar.density = target
    }

    function _restoreDesktopDensity() {
        if (!root._tabletDensityManaged)
            return

        var restoreDensity = root.lastNonTabletBarDensity || "default"
        if (Settings.data?.bar && Settings.data.bar.density !== restoreDensity)
            Settings.data.bar.density = restoreDensity

        root._tabletDensityManaged = false
        if (root.lastNonTabletBarDensity)
            root._savePluginSetting("lastNonTabletBarDensity", "")
    }

    function _applyTabletDockMode() {
        if (!Settings.data?.dock)
            return

        if (!root._tabletDockManaged) {
            root._savePluginSetting("lastNonTabletDockType", root._dockType())
            root._savePluginSetting("lastNonTabletDockEnabled", root._dockEnabled())
            root._tabletDockManaged = true
        }

        if (!Settings.data.dock.enabled)
            Settings.data.dock.enabled = true
        if (Settings.data.dock.dockType !== "exclusive")
            Settings.data.dock.dockType = "exclusive"
    }

    function _restoreDesktopDockMode() {
        if (!root._tabletDockManaged)
            return

        if (Settings.data?.dock) {
            Settings.data.dock.enabled = root.lastNonTabletDockEnabled
            Settings.data.dock.dockType = root.lastNonTabletDockType || "floating"
        }

        root._tabletDockManaged = false
        root._savePluginSetting("lastNonTabletDockType", "")
        root._savePluginSetting("lastNonTabletDockEnabled", true)
    }

    function _syncTabletModeState(active) {
        if (!root.policyCurrent || root._destroying) return;
        root._log("tablet mode state: " + (active ? "on" : "off"))
        root._tabletModeDetected = active

        if (!root.autoTabletBarDensity) {
            root._restoreDesktopDensity()
            if (!active && root.lastNonTabletBarDensity)
                root._savePluginSetting("lastNonTabletBarDensity", "")
        } else if (active)
            root._applyTabletDensity()
        else {
            if (!root._tabletDensityManaged && root.lastNonTabletBarDensity)
                root._savePluginSetting("lastNonTabletBarDensity", "")
            root._restoreDesktopDensity()
        }

        if (!root.exclusiveDockInTabletMode) {
            root._restoreDesktopDockMode()
            if (!active && root.lastNonTabletDockType)
                root._savePluginSetting("lastNonTabletDockType", "")
        } else if (active)
            root._applyTabletDockMode()
        else
            root._restoreDesktopDockMode()

        root._syncAutoRotateLifecycle()
    }

    function refreshTabletModeState() {
        if (!root.policyCurrent || root._destroying || tabletModeProc.running)
            return

        root._tabletModePolicy = root.capturePolicy(root.policyContext);
        if (root.compositorBackend === "hyprland") {
            tabletModeProc.command = [
                "sh",
                "-c",
                "if [ -f \"$1\" ]; then cat \"$1\"; elif command -v hyprctl >/dev/null 2>&1; then hyprctl -j devices; else printf unknown; fi",
                "2-in-1-tools",
                root.tabletModeStateFile
            ]
        } else {
            tabletModeProc.command = [
                "sh",
                "-c",
                "if [ -f \"$1\" ]; then cat \"$1\"; else printf off; fi",
                "2-in-1-tools",
                root.tabletModeStateFile
            ]
        }
        tabletModeProc.running = true
    }

    function _parseStateBool(value) {
        if (typeof value === "boolean")
            return value
        if (typeof value === "number")
            return value !== 0
        if (typeof value !== "string")
            return null

        var lowered = value.trim().toLowerCase()
        if (lowered === "on" || lowered === "true" || lowered === "1" || lowered === "open")
            return true
        if (lowered === "off" || lowered === "false" || lowered === "0" || lowered === "closed")
            return false
        return null
    }

    function _isTabletSwitchName(name) {
        var lowered = (name || "").toString().trim().toLowerCase()
        if (!lowered)
            return false
        return lowered.indexOf("tablet") !== -1 || lowered.indexOf("intel hid switches") !== -1
    }

    function _handleHyprEventLine(line) {
        var text = (line || "").trim()
        if (!text || text.indexOf("switch>>") !== 0)
            return

        var payload = text.slice(8)
        var parts = payload.split(",")
        if (parts.length < 2)
            return

        root._log("hypr switch event: " + payload)

        var firstState = root._parseStateBool(parts[0])
        var lastState = root._parseStateBool(parts[parts.length - 1])
        var state = firstState !== null ? firstState : lastState
        var switchName = firstState !== null
            ? parts.slice(1).join(",").trim()
            : parts.slice(0, parts.length - 1).join(",").trim()

        if (!root._isTabletSwitchName(switchName))
            return

        if (state === null) {
            root._log("hypr switch event ignored; no state parsed for " + switchName)
            return
        }

        root._log("hypr tablet switch parsed: " + switchName + "=" + (state ? "on" : "off"))
        root._syncTabletModeState(state)
    }

    function _processHyprEventData(data) {
        if (!data)
            return

        var chunk = data.toString()
        if (!chunk)
            return

        if (chunk.indexOf("\n") === -1) {
            root._handleHyprEventLine(chunk)
            return
        }

        root._hyprEventBuffer += chunk
        var newlineIndex = root._hyprEventBuffer.indexOf("\n")
        while (newlineIndex !== -1) {
            var line = root._hyprEventBuffer.slice(0, newlineIndex)
            if (line.endsWith("\r"))
                line = line.slice(0, -1)
            root._handleHyprEventLine(line)
            root._hyprEventBuffer = root._hyprEventBuffer.slice(newlineIndex + 1)
            newlineIndex = root._hyprEventBuffer.indexOf("\n")
        }
    }

    function _syncHyprEventListener() {
        if (!root.policyCurrent || root._destroying || root.compositorBackend !== "hyprland") {
            hyprEventProc.running = false
            root._hyprEventBuffer = ""
            return
        }

        if (hyprEventProc.running)
            return

        root._hyprEventBuffer = ""
        hyprEventProc.command = [
            "sh",
            "-c",
            "socket=\"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock\"; if [ ! -S \"$socket\" ]; then exit 1; fi; if command -v socat >/dev/null 2>&1; then exec socat -u UNIX-CONNECT:\"$socket\" -; elif command -v nc >/dev/null 2>&1; then exec nc -U \"$socket\"; else exit 1; fi"
        ]
        root._log("starting Hyprland event listener")
        hyprEventProc.running = true
    }

    function _syncNiriStateFileWatcher() {
        if (!root.policyCurrent || root._destroying || !root._isBackendSupported()) {
            niriStateWatchProc.running = false
            return
        }

        if (niriStateWatchProc.running)
            return

        niriStateWatchProc.command = [
            "sh",
            "-c",
            "if ! command -v inotifywait >/dev/null 2>&1; then exit 1; fi; target=\"$1\"; dir=$(dirname \"$target\"); file=$(basename \"$target\"); mkdir -p \"$dir\"; inotifywait -m -e close_write,create,moved_to --format '%f' \"$dir\" | while IFS= read -r changed; do [ \"$changed\" = \"$file\" ] && printf '%s\\n' \"$changed\"; done",
            "2-in-1-tools",
            root.tabletModeStateFile
        ]
        root._log("starting tablet mode state file watcher")
        niriStateWatchProc.running = true
    }

    function _syncTabletModeWatchers() {
        root._syncHyprEventListener()
        root._syncNiriStateFileWatcher()
    }

    function _tabletModeFromHyprDevices(parsed) {
        if (!parsed || typeof parsed !== "object")
            return null

        var switches = Array.isArray(parsed.switches) ? parsed.switches : []
        if (!switches.length)
            return null

        var foundTabletSwitch = false
        for (var i = 0; i < switches.length; ++i) {
            var sw = switches[i]
            var name = ((sw && sw.name) ? sw.name : "").toString().toLowerCase()
            if (!root._isTabletSwitchName(name))
                continue

            foundTabletSwitch = true
            var state = null
            var keys = ["state", "status", "enabled", "on", "active", "switchState", "isOn"]
            for (var j = 0; j < keys.length; ++j) {
                var key = keys[j]
                if (sw[key] === undefined)
                    continue
                state = root._parseStateBool(sw[key])
                if (state !== null)
                    break
            }

            if (state === true)
                return true
        }

        if (foundTabletSwitch)
            return false
        return null
    }

    function _setBusy(outputName, busy) {
        if (!outputName) return
        var next = _copyMap(root.busyByOutput)
        next[outputName] = busy
        root.busyByOutput = next
    }

    function _setTransform(outputName, transform) {
        if (!outputName) return
        var next = _copyMap(root.transformsByOutput)
        next[outputName] = root._normalizeTransform(transform)
        root.transformsByOutput = next
    }

    function transformForOutput(outputName) {
        return root._normalizeTransform(root.transformsByOutput[outputName] || "Normal")
    }

    function isBusy(outputName) {
        return !!root.busyByOutput[outputName]
    }

    function transformLabel(transform) {
        switch (transform) {
        case "90": return "90 degrees"
        case "180": return "180 degrees"
        case "270": return "270 degrees"
        default: return "Normal"
        }
    }

    function _nextTransform(transform) {
        switch (transform) {
        case "Normal": return "90"
        case "90": return "180"
        case "180": return "270"
        default: return "Normal"
        }
    }

    function _transformArg(transform) {
        return transform === "Normal" ? "normal" : transform
    }

    function _hyprTransformId(transform) {
        switch (root._normalizeTransform(transform)) {
        case "90": return "1"
        case "180": return "2"
        case "270": return "3"
        default: return "0"
        }
    }

    function _touchOutputName(device) {
        if (!device || typeof device !== "object")
            return ""

        var keys = ["output", "boundOutput", "mappedOutput", "outputName", "bound_output", "mapped_output"]
        for (var i = 0; i < keys.length; ++i) {
            var key = keys[i]
            if (device[key] === undefined || device[key] === null)
                continue
            var value = device[key].toString().trim()
            if (value)
                return value
        }

        return ""
    }

    function _hyprTouchDevices(parsed) {
        if (!parsed || typeof parsed !== "object")
            return []

        if (Array.isArray(parsed.touch))
            return parsed.touch

        var keys = Object.keys(parsed)
        for (var i = 0; i < keys.length; ++i) {
            var key = keys[i]
            if (key.toLowerCase().indexOf("touch") === -1)
                continue
            var value = parsed[key]
            if (Array.isArray(value))
                return value
        }

        return []
    }

    function _matchingHyprTouchNames(devices, outputName) {
        var names = []
        var requestedOutput = (outputName || "").toString().trim()
        var hasBoundMatches = false
        var unboundNames = []

        for (var i = 0; i < devices.length; ++i) {
            var device = devices[i]
            var name = ((device && device.name) ? device.name : "").toString().trim()
            if (!name)
                continue

            var boundOutput = root._touchOutputName(device)
            if (requestedOutput && boundOutput === requestedOutput) {
                hasBoundMatches = true
                names.push(name)
                continue
            }

            if (!boundOutput)
                unboundNames.push(name)
        }

        if (!hasBoundMatches)
            names = names.concat(unboundNames)

        if (!names.length && devices.length === 1) {
            var fallbackName = ((devices[0] && devices[0].name) ? devices[0].name : "").toString().trim()
            if (fallbackName)
                names.push(fallbackName)
        }

        var unique = []
        var seen = ({})
        for (var j = 0; j < names.length; ++j) {
            var candidate = names[j]
            if (!candidate || seen[candidate])
                continue
            seen[candidate] = true
            unique.push(candidate)
        }

        return unique
    }

    function _requestHyprTouchTransformSync(outputName, target, policy) {
        if (!policy?.context?.current() || policy.backend !== "hyprland" || !policy.syncHyprTouchTransform || root._destroying)
            return
        if (!outputName)
            return

        root._hyprTouchQueuedOutputName = outputName
        root._hyprTouchQueuedTarget = root._normalizeTransform(target)
        root._hyprTouchQueuedPolicy = policy
        root._syncHyprTouchTransformQueue()
    }

    function _syncHyprTouchTransformQueue() {
        if (root._destroying || !root._hyprTouchQueuedPolicy?.context?.current()) return;
        if (hyprTouchQueryProc.running || hyprTouchApplyProc.running)
            return
        if (!root._hyprTouchQueuedOutputName)
            return

        root._hyprTouchActiveOutputName = root._hyprTouchQueuedOutputName
        root._hyprTouchActiveTarget = root._hyprTouchQueuedTarget || "Normal"
        root._hyprTouchActivePolicy = root._hyprTouchQueuedPolicy
        root._hyprTouchQueuedOutputName = ""
        root._hyprTouchQueuedTarget = ""

        hyprTouchQueryProc.command = ["hyprctl", "-j", "devices"]
        hyprTouchQueryProc.running = true
    }

    function _startNextHyprTouchApply() {
        if (root._destroying || !root._hyprTouchActivePolicy?.context?.current()) return false;
        if (root._hyprTouchApplyIndex >= root._hyprTouchApplyNames.length)
            return false

        var name = root._hyprTouchApplyNames[root._hyprTouchApplyIndex]
        var transformId = root._hyprTransformId(root._hyprTouchActiveTarget)
        hyprTouchApplyProc.command = ["hyprctl", "keyword", "device[" + name + "]:transform", transformId]
        hyprTouchApplyProc.running = true
        return true
    }

    function _buildQueryCommand(policy) {
        switch (policy.backend) {
        case "hyprland":
            return ["hyprctl", "-j", "monitors"]
        case "niri":
            return ["niri", "msg", "--json", "outputs"]
        default:
            return []
        }
    }

    function _hyprMonitorRule(state, transformId) {
        if (!state || !state.name)
            return ""

        var width = state.width > 0 ? state.width : 0
        var height = state.height > 0 ? state.height : 0
        var refresh = state.refresh > 0 ? state.refresh : 60
        var x = state.x || 0
        var y = state.y || 0
        var scale = state.scale > 0 ? state.scale : 1
        var mode = width > 0 && height > 0 ? (width + "x" + height + "@" + refresh) : "preferred"
        var position = x + "x" + y

        return state.name + "," + mode + "," + position + "," + scale + ",transform," + transformId
    }

    function _buildApplyCommand(outputName, target, policy) {
        switch (policy.backend) {
        case "hyprland": {
            var state = root.hyprMonitorStateByOutput[outputName]
            var rule = root._hyprMonitorRule(state, root._hyprTransformId(target))
            if (!rule)
                return []
            return ["hyprctl", "keyword", "monitor", rule]
        }
        case "niri":
            return ["niri", "msg", "output", outputName, "transform", root._transformArg(target)]
        default:
            return []
        }
    }

    function _isInternalOutput(outputName) {
        return /^(eDP|LVDS|DSI)/.test(outputName || "")
    }

    function _internalDisplayFromOutputs(outputs) {
        if (!outputs)
            return ""

        var names = Object.keys(outputs)
        for (var i = 0; i < names.length; ++i) {
            if (root._isInternalOutput(names[i]))
                return names[i]
        }

        return names.length === 1 ? names[0] : ""
    }

    function _orientationToTransform(orientation, policy) {
        policy = policy || root.capturePolicy(root.policyContext);
        if (!policy?.context?.current()) return "";
        switch ((orientation || "").trim().toLowerCase()) {
        case "normal": return "Normal"
        case "bottom-up": return "180"
        case "left-up": return policy.flipVerticalSensorOrientation ? "270" : "90"
        case "right-up": return policy.flipVerticalSensorOrientation ? "90" : "270"
        default: return ""
        }
    }

    function _extractOrientationFromText(text) {
        var match = /Accelerometer orientation(?: changed)?:\s*([a-z-]+)/i.exec(text || "")
        return match ? match[1] : ""
    }

    function _requestOutputs(reason, outputName, context) {
        const policy = root.capturePolicy(context || root.policyContext);
        if (!policy || queryProc.running)
            return false

        if (!root._isBackendSupported()) {
            if (root.compositorBackend !== "unknown")
                root._notifyUnsupportedBackendOnce()
            else
                root._log("suppressed output query while backend is unknown; reason=" + reason + "; output=" + outputName)
            return false
        }

        root._queryReason = reason || ""
        root._queryOutputName = outputName || ""
        root._queryPolicy = policy
        queryProc.command = root._buildQueryCommand(policy)
        if (!queryProc.command.length)
            return false
        queryProc.running = true
        return true
    }

    function _setAutoRotatePendingTransform(transform) {
        var normalized = root._normalizeTransform(transform)
        if (!root._autoRotateSessionActive || !root._autoRotateOutputName)
            return
        if (root._rotationLocked)
            return
        if (normalized === root._autoRotateLastAppliedTransform)
            return

        root._autoRotatePendingTransform = normalized
        root._syncAutoRotateLifecycle()
    }

    function _startOrientationMonitor() {
        if (!root.policyCurrent || root._destroying || orientationProc.running)
            return

        root._log("starting monitor-sensor for auto-rotate")
        orientationProc.command = ["monitor-sensor", "--accel"]
        orientationProc.running = true
    }

    function _pollCurrentOrientation() {
        if (!root._shouldAutoRotate() || !root._autoRotateSessionActive || root._rotationLocked)
            return
        if (orientationPollProc.running)
            return

        orientationPollProc.command = [
            "sh",
            "-c",
            "monitor-sensor --accel | while IFS= read -r line; do case \"$line\" in *\"Accelerometer orientation\"*) printf '%s\\n' \"$line\"; break;; esac; done"
        ]
        orientationPollProc.running = true
    }

    function _stopOrientationMonitor() {
        if (orientationProc.running)
            orientationProc.running = false
    }

    function _beginAutoRotateSession(outputName, policy) {
        if (!outputName || !policy?.context?.current() || policy.context !== root.policyContext || root._destroying)
            return

        root._autoRotateOutputName = outputName
        root._autoRotateSavedTransform = root.transformForOutput(outputName)
        root._autoRotateLastAppliedTransform = root._autoRotateSavedTransform
        root._autoRotatePendingTransform = ""
        root._autoRotateSessionActive = true
        root._autoRotateSessionPolicy = policy
        root._log("auto-rotate session started; output=" + outputName + "; locked=" + root._rotationLocked + "; saved=" + root._autoRotateSavedTransform)
        if (!root._rotationLocked)
            root._startOrientationMonitor()
    }

    function _applyTransform(outputName, target, shouldShowSuccessToast, shouldShowErrorToast, policy) {
        policy = policy || root.capturePolicy(root.policyContext);
        if (!policy?.context?.current() || root._destroying || !outputName || applyProc.running)
            return false

        if (!root._isBackendSupported()) {
            if (root.compositorBackend !== "unknown")
                root._notifyUnsupportedBackendOnce()
            else
                root._log("suppressed transform apply while backend is unknown; output=" + outputName)
            return false
        }

        root._applyOutputName = outputName
        root._applyTarget = root._normalizeTransform(target)
        root._applyPolicy = policy
        root._applyShouldShowSuccessToast = !!shouldShowSuccessToast
        root._applyShouldShowErrorToast = shouldShowErrorToast !== false
        root._setBusy(outputName, true)
        applyProc.command = root._buildApplyCommand(outputName, root._applyTarget, policy)
        if (!applyProc.command.length) {
            root._setBusy(outputName, false)
            if (root._applyShouldShowErrorToast)
                ToastService.showError("Unable to rotate output on " + root._backendName())
            return false
        }
        applyProc.running = true
        return true
    }

    function _endAutoRotateSession() {
        root._stopOrientationMonitor()

        if (!root._autoRotateSessionActive) {
            root._autoRotateOutputName = ""
            root._autoRotateSavedTransform = ""
            root._autoRotatePendingTransform = ""
            root._autoRotateLastAppliedTransform = ""
            return
        }

        var outputName = root._autoRotateOutputName
        var restoreTransform = root._autoRotateSessionPolicy?.autoRotateOutsideTabletMode ? (root._autoRotateSavedTransform || "Normal") : "Normal"
        root._autoRotateRestorePolicy = root._autoRotateSessionPolicy
        root._autoRotateSessionPolicy = null
        root._log("auto-rotate session ended; output=" + outputName + "; restore=" + restoreTransform)

        root._autoRotateSessionActive = false
        root._autoRotateOutputName = ""
        root._autoRotateSavedTransform = ""
        root._autoRotatePendingTransform = ""
        root._autoRotateLastAppliedTransform = ""

        root._autoRotateRestoreOutputName = outputName
        root._autoRotateRestoreTransform = restoreTransform
    }

    function _shouldAutoRotate() {
        return root.policyCurrent && !root._destroying && root.autoRotateInTabletMode && (root._tabletModeDetected || root.autoRotateOutsideTabletMode)
    }

    function _syncAutoRotateLifecycle() {
        if (root._destroying) return;
        // Restore the previous session before starting a newly admitted policy.
        if (root._autoRotateRestoreOutputName && !applyProc.running) {
            const output = root._autoRotateRestoreOutputName;
            const transform = root._autoRotateRestoreTransform || "Normal";
            const policy = root._autoRotateRestorePolicy;
            root._autoRotateRestoreOutputName = "";
            root._autoRotateRestoreTransform = "";
            root._autoRotateRestorePolicy = null;
            if (policy?.context?.current()) {
                if (!root._applyTransform(output, transform, false, false, policy)) {
                    root._autoRotateRestoreOutputName = output;
                    root._autoRotateRestoreTransform = transform;
                    root._autoRotateRestorePolicy = policy;
                }
                return;
            }
        }
        if (!root.policyCurrent) {
            root._stopOrientationMonitor();
            return;
        }
        var shouldAutoRotate = root._shouldAutoRotate()

        if (!shouldAutoRotate) {
            const wasActive = root._autoRotateSessionActive;
            root._endAutoRotateSession()
            if (wasActive) root._syncAutoRotateLifecycle();
            return
        }

        if (!root._autoRotateSessionActive) {
            root._requestOutputs("auto-rotate-start", "")
            return
        }

        if (!root._autoRotateOutputName) {
            root._endAutoRotateSession()
            return
        }

        if (root._rotationLocked) {
            root._stopOrientationMonitor()
            return
        }

        root._startOrientationMonitor()

        if (!root._autoRotatePendingTransform || applyProc.running)
            return

        var pending = root._autoRotatePendingTransform
        root._autoRotatePendingTransform = ""
        if (!root._applyTransform(root._autoRotateOutputName, pending, false, false))
            root._autoRotatePendingTransform = pending
    }

    function refreshTransform(outputName, context) {
        if (!outputName)
            return
        root._requestOutputs("refresh-output", outputName, context)
    }

    function cycleTransform(outputName, context) {
        const policy = root.capturePolicy(context);
        if (!policy || !root.activatePolicy(policy.context)) return;
        if (!outputName) {
            ToastService.showError("No output selected for rotation")
            return
        }
        if (root.isBusy(outputName) || applyProc.running) return

        var current = root.transformForOutput(outputName)
        var target = root._nextTransform(current)

        root._applyTransform(outputName, target, policy.showSuccessToast, true, policy)
    }

    function buttonUsesManualRotate(context) {
        return root.capturePolicy(context)?.buttonBehavior === "manual-rotate"
    }

    function buttonIconName(context) {
        if (root.buttonUsesManualRotate(context))
            return "rotate-cw"
        return root._rotationLocked ? "lock-square" : "rotate-clockwise"
    }

    function buttonTooltip(outputName, context) {
        const policy = root.capturePolicy(context);
        if (root.buttonUsesManualRotate(context)) {
            var transform = outputName ? root.transformForOutput(outputName) : "Normal"
            return "Rotate display · Current: " + root.transformLabel(transform)
        }

        if (!policy?.autoRotateInTabletMode)
            return root._rotationLocked
                ? "Rotation locked"
                : "Rotation unlocked"
        if (!root._tabletModeDetected && !policy?.autoRotateOutsideTabletMode)
            return root._rotationLocked
                ? "Rotation locked"
                : "Rotation unlocked"
        if (!root._autoRotateOutputName)
            return "Auto-rotate is unavailable because no internal display was detected"
        return root._rotationLocked ? "Rotation locked" : "Auto-rotate enabled"
    }

    function buttonEnabled(outputName, context) {
        if (root.buttonUsesManualRotate(context))
            return root._isBackendSupported() && !!outputName && !root.isBusy(outputName)
        return root.buttonVisible(outputName, context)
    }

    function buttonVisible(outputName, context) {
        const policy = root.capturePolicy(context);
        if (!policy) return false;
        if (root.buttonUsesManualRotate(context))
            return true
        return root._isBackendSupported()
            && policy.autoRotateInTabletMode
            && (root._tabletModeDetected || policy.autoRotateOutsideTabletMode)
    }

    function activatePrimaryButton(outputName, context) {
        const policy = root.capturePolicy(context);
        if (!policy || !root.activatePolicy(policy.context)) return;
        if (policy.buttonBehavior === "manual-rotate") {
            root.cycleTransform(outputName, policy.context)
            return
        }

        root.toggleAutoRotateLock()
    }

    function toggleAutoRotateLock() {
        root._rotationLocked = !root._rotationLocked
        root._log("rotation lock toggled: " + (root._rotationLocked ? "locked" : "unlocked"))

        if (!root._rotationLocked) {
            if (root._autoRotateOutputName)
                root._requestOutputs("refresh-output", root._autoRotateOutputName)
            root._pollCurrentOrientation()
        }
        root._syncAutoRotateLifecycle()
    }

    Process {
        id: backendDetectProc
        stdout: StdioCollector {}

        command: ["sh", "-c", "if [ -n \"$HYPRLAND_INSTANCE_SIGNATURE\" ]; then printf hyprland; elif [ -n \"$NIRI_SOCKET\" ]; then printf niri; elif [ -n \"$XDG_CURRENT_DESKTOP\" ] && printf '%s' \"$XDG_CURRENT_DESKTOP\" | grep -qi hypr; then printf hyprland; elif [ -n \"$XDG_CURRENT_DESKTOP\" ] && printf '%s' \"$XDG_CURRENT_DESKTOP\" | grep -qi niri; then printf niri; else printf unknown; fi"]

        onExited: (exitCode, exitStatus) => {
            if (root._destroying || exitCode !== 0)
                return

            var detected = backendDetectProc.stdout.text.trim().toLowerCase()
            if (detected !== "hyprland" && detected !== "niri")
                detected = "unknown"
            root._log("backend detected: " + detected)
            root.compositorBackend = detected
        }
    }

    Process {
        id: debugLogProc
        onExited: (exitCode, exitStatus) => root._syncLogQueue()
    }

    Process {
        id: queryProc
        stdout: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            const policy = root._queryPolicy;
            if (root._destroying || !policy?.context?.current()) {
                root._queryReason = "";
                root._queryOutputName = "";
                return;
            }
            if (exitCode !== 0) {
                root._queryReason = ""
                root._queryOutputName = ""
                root._syncAutoRotateLifecycle()
                return
            }

            try {
                var parsed = JSON.parse(queryProc.stdout.text.trim())
                var outputs = ({})
                var hyprState = ({})

                if (policy.backend === "hyprland" && Array.isArray(parsed)) {
                    for (var i = 0; i < parsed.length; ++i) {
                        var monitor = parsed[i]
                        if (!monitor || !monitor.name)
                            continue

                        var transform = monitor.transform
                        outputs[monitor.name] = {
                            logical: {
                                transform: root._normalizeTransform(transform)
                            }
                        }

                        hyprState[monitor.name] = {
                            name: monitor.name,
                            width: Number(monitor.width) || 0,
                            height: Number(monitor.height) || 0,
                            refresh: Number(monitor.refreshRate) || 0,
                            x: Number(monitor.x) || 0,
                            y: Number(monitor.y) || 0,
                            scale: Number(monitor.scale) || 1
                        }
                    }
                    root.hyprMonitorStateByOutput = hyprState
                } else if (policy.backend === "niri" && parsed && typeof parsed === "object")
                    outputs = parsed

                var names = Object.keys(outputs)
                for (var j = 0; j < names.length; ++j) {
                    var outputName = names[j]
                    var output = outputs[outputName]
                    if (output && output.logical && output.logical.transform !== undefined)
                        root._setTransform(outputName, output.logical.transform)
                }

                if (root._queryReason === "auto-rotate-start")
                    root._beginAutoRotateSession(root._internalDisplayFromOutputs(outputs), policy)
            } catch (error) {
                console.warn("2-in-1-tools: failed to parse outputs JSON:", error)
            } finally {
                root._queryReason = ""
                root._queryOutputName = ""
                root._syncAutoRotateLifecycle()
            }
        }
    }

    Process {
        id: applyProc
        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            var outputName = root._applyOutputName
            root._setBusy(outputName, false)
            const policy = root._applyPolicy;
            if (root._destroying || !policy?.context?.current()) return;

            if (exitCode === 0) {
                root._setTransform(outputName, root._applyTarget)
                root._requestHyprTouchTransformSync(outputName, root._applyTarget, policy)
                if (root._applyShouldShowSuccessToast)
                    ToastService.showNotice("Display rotated to " + root.transformLabel(root._applyTarget))
                root.refreshTransform(outputName, policy.context)
                if (outputName === root._autoRotateOutputName)
                    root._autoRotateLastAppliedTransform = root._applyTarget
                root._syncAutoRotateLifecycle()
                return
            }

            if (root._applyShouldShowErrorToast) {
                var message = "Failed to rotate output on " + root._backendName()
                var detail = applyProc.stderr.text.trim()
                if (detail)
                    message += ": " + detail
                ToastService.showError(message)
            }
            root.refreshTransform(outputName, policy.context)
            root._syncAutoRotateLifecycle()
        }
    }

    Process {
        id: hyprTouchQueryProc
        stdout: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (root._destroying || !root._hyprTouchActivePolicy?.context?.current()) {
                root._syncHyprTouchTransformQueue();
                return;
            }
            if (exitCode !== 0) {
                root._hyprTouchActiveOutputName = ""
                root._hyprTouchActiveTarget = ""
                root._syncHyprTouchTransformQueue()
                return
            }

            try {
                var parsed = JSON.parse(hyprTouchQueryProc.stdout.text.trim())
                var touchDevices = root._hyprTouchDevices(parsed)
                root._hyprTouchApplyNames = root._matchingHyprTouchNames(touchDevices, root._hyprTouchActiveOutputName)
                root._hyprTouchApplyIndex = 0
                root._hyprTouchFailedNames = []

                if (!root._hyprTouchApplyNames.length) {
                    root._hyprTouchActiveOutputName = ""
                    root._hyprTouchActiveTarget = ""
                    root._syncHyprTouchTransformQueue()
                    return
                }

                root._startNextHyprTouchApply()
            } catch (error) {
                console.warn("2-in-1-tools: failed to parse Hyprland devices JSON for touch sync:", error)
                root._hyprTouchActiveOutputName = ""
                root._hyprTouchActiveTarget = ""
                root._syncHyprTouchTransformQueue()
            }
        }
    }

    Process {
        id: hyprTouchApplyProc
        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (root._destroying || !root._hyprTouchActivePolicy?.context?.current()) {
                root._syncHyprTouchTransformQueue();
                return;
            }
            var name = root._hyprTouchApplyNames[root._hyprTouchApplyIndex]
            if (exitCode !== 0 && name)
                root._hyprTouchFailedNames = root._hyprTouchFailedNames.concat([name])

            root._hyprTouchApplyIndex += 1
            if (root._startNextHyprTouchApply())
                return

            if (root._hyprTouchFailedNames.length) {
                console.warn("2-in-1-tools: failed to sync Hyprland touch transform for:", root._hyprTouchFailedNames.join(", "))
                var detail = hyprTouchApplyProc.stderr.text.trim()
                if (detail)
                    console.warn("2-in-1-tools: touch sync error:", detail)
            }

            root._hyprTouchApplyNames = []
            root._hyprTouchApplyIndex = 0
            root._hyprTouchFailedNames = []
            root._hyprTouchActiveOutputName = ""
            root._hyprTouchActiveTarget = ""
            root._syncHyprTouchTransformQueue()
        }
    }

    Process {
        id: tabletModeProc
        stdout: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            const policy = root._tabletModePolicy;
            if (root._tabletModeRefreshPending) {
                root._tabletModeRefreshPending = false;
                root.refreshTabletModeState();
                return;
            }
            if (root._destroying || !policy?.context?.current() || policy.context !== root.policyContext || policy.stateFile !== root.tabletModeStateFile || exitCode !== 0)
                return

            var raw = tabletModeProc.stdout.text.trim()
            var state = root._parseStateBool(raw)
            if (state !== null) {
                root._syncTabletModeState(state)
                return
            }

            if (root.compositorBackend !== "hyprland")
                return

            try {
                var parsed = JSON.parse(raw)
                var detected = root._tabletModeFromHyprDevices(parsed)
                if (detected !== null)
                    root._syncTabletModeState(detected)
            } catch (error) {
                console.warn("2-in-1-tools: failed to parse Hyprland devices JSON:", error)
            }
        }
    }

    Process {
        id: hyprEventProc
        stdout: SplitParser {
            onRead: data => root._processHyprEventData(data)
        }

        onExited: (exitCode, exitStatus) => {
            root._log("Hyprland event listener exited; code=" + exitCode)
            if (!root._destroying && root.policyCurrent && root.compositorBackend === "hyprland")
                hyprEventRestartTimer.restart()
        }
    }

    Process {
        id: niriStateWatchProc
        stdout: SplitParser {
            onRead: data => {
                niriStateWatchDebounceTimer.restart()
            }
        }

        onExited: (exitCode, exitStatus) => {
            root._log("tablet mode state file watcher exited; code=" + exitCode)
            if (root._restartStateWatcher && !root._destroying && root.policyCurrent) {
                root._restartStateWatcher = false;
                root._syncNiriStateFileWatcher();
            } else if (!root._destroying && root.policyCurrent && root._isBackendSupported())
                niriStateWatchRestartTimer.restart()
        }
    }

    Timer {
        id: hyprEventRestartTimer
        interval: 1500
        repeat: false
        onTriggered: root._syncHyprEventListener()
    }

    Timer {
        id: niriStateWatchRestartTimer
        interval: 1500
        repeat: false
        onTriggered: root._syncNiriStateFileWatcher()
    }

    Timer {
        id: niriStateWatchDebounceTimer
        interval: 100
        repeat: false
        onTriggered: root.refreshTabletModeState()
    }

    Process {
        id: orientationProc
        stderr: StdioCollector {}
        stdout: SplitParser {
            onRead: data => {
                var line = (data || "").toString().trim()
                if (line)
                    root._log("monitor-sensor output: " + line)

                var orientation = root._extractOrientationFromText(data)
                if (!orientation)
                    return

                var target = root._orientationToTransform(orientation)
                if (!target)
                    return

                root._log("monitor-sensor orientation parsed: " + orientation + " -> " + target)
                root._setAutoRotatePendingTransform(target)
            }
        }
        onExited: (exitCode, exitStatus) => {
            var detail = orientationProc.stderr.text.trim()
            root._log("monitor-sensor exited; code=" + exitCode + (detail ? "; stderr=" + detail : ""))
            if (root._shouldAutoRotate() && root._autoRotateSessionActive)
                root._startOrientationMonitor()
        }
    }

    Process {
        id: orientationPollProc
        stdout: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            root._log("orientation poll exited; code=" + exitCode)
            if (exitCode !== 0)
                return

            var orientation = root._extractOrientationFromText(orientationPollProc.stdout.text)
            if (!orientation)
                return

            var target = root._orientationToTransform(orientation)
            if (!target)
                return

            root._log("orientation poll parsed: " + orientation + " -> " + target)
            root._setAutoRotatePendingTransform(target)
        }
    }

    onAutoRotateInTabletModeChanged: root._syncAutoRotateLifecycle()
    onAutoRotateOutsideTabletModeChanged: root._syncAutoRotateLifecycle()
    onTabletModeStateFileChanged: {
        if (root._constructed && !root._destroying) {
            root._restartStateWatcher = true;
            if (niriStateWatchProc.running) niriStateWatchProc.running = false;
            else {
                root._restartStateWatcher = false;
                root._syncNiriStateFileWatcher();
            }
            root.refreshTabletModeState();
            if (tabletModeProc.running && root._tabletModePolicy?.stateFile !== root.tabletModeStateFile) {
                root._tabletModeRefreshPending = true;
                tabletModeProc.running = false;
            }
        }
    }
    onCompositorBackendChanged: {
        root._syncTabletModeWatchers()
        root.refreshTabletModeState()
    }

    Timer {
        interval: root.compositorBackend === "unknown" ? 2000 : root.compositorBackend === "hyprland" ? 2000 : 10000
        running: root.policyCurrent && !root._destroying
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshTabletModeState()
    }

    Component.onDestruction: {
        root._destroying = true;
        backendDetectProc.running = false
        tabletModeProc.running = false
        queryProc.running = false
        applyProc.running = false
        orientationProc.running = false
        orientationPollProc.running = false
        hyprEventProc.running = false
        hyprEventRestartTimer.running = false
        hyprTouchQueryProc.running = false
        hyprTouchApplyProc.running = false
        debugLogProc.running = false
        niriStateWatchProc.running = false
        niriStateWatchRestartTimer.running = false
        niriStateWatchDebounceTimer.running = false
    }

    Component.onCompleted: {
        root._constructed = true;
        root._log("main component completed; initial backend=" + root.compositorBackend)
        backendDetectProc.running = true
        root._syncTabletModeWatchers()
    }

    onPolicyCurrentChanged: {
        if (!root.policyCurrent && root._constructed) {
            tabletModeProc.running = false;
            queryProc.running = false;
            orientationProc.running = false;
            orientationPollProc.running = false;
            hyprEventProc.running = false;
            niriStateWatchProc.running = false;
            hyprEventRestartTimer.stop();
            niriStateWatchRestartTimer.stop();
            niriStateWatchDebounceTimer.stop();
        }
    }
}
