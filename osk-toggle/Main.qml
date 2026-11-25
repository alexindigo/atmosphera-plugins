import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var pluginApi: null

    property var selectedContext: null
    readonly property var policyContext: selectedContext || pluginApi?.settingsContext
    readonly property bool policyCurrent: policyContext?.current() ?? false
    readonly property var cfg: policyCurrent ? policyContext.settingsView : ({})
    readonly property string backendSetting: cfg.backend ?? "auto"
    readonly property string wvkbdBin: cfg.wvkbdBin ?? "wvkbd-mobintl"
    property string resolvedBackend: ""
    readonly property var _backend: backendLoader.item
    property var _request: null
    property var _loadedRequest: null
    property var _detectRequest: null
    property var _pendingToggle: null
    property bool _constructed: false
    property bool _retired: false
    property var _settingsConsumers: new Map()
    property bool _observeSqueekboard: false

    // Compatibility observations remain the one physical keyboard's state.
    property bool keyboardActive: _backend?.keyboardActive ?? false
    property bool available: _backend?.available ?? false
    readonly property string unavailableTooltipKey: _backend?.unavailableTooltipKey ?? "tooltip.detecting"

    onBackendSettingChanged: _resolveBackend()
    onWvkbdBinChanged: _resolveBackend()
    onPolicyCurrentChanged: _resolveBackend()
    Component.onCompleted: { _constructed = true; _resolveBackend(); }
    Component.onDestruction: { _retired = true; _observeSqueekboard = false; autoDetect.running = false; _backend?.retire(); }

    // Read-only capability sampling is shared by inactive consumers. It never
    // selects a policy, creates a backend, or changes keyboard state.
    readonly property bool _sampleSqueekboard: _observeSqueekboard && resolvedBackend !== "squeekboard"
    property bool _sampledBusOk: false
    property bool _sampledGsettingsOk: false
    readonly property bool _squeekboardBusOk: resolvedBackend === "squeekboard" ? (_backend?.squeekboardOk ?? false) : _sampledBusOk
    readonly property bool _squeekboardGsettingsOk: resolvedBackend === "squeekboard" ? (_backend?.gsettingsOk ?? false) : _sampledGsettingsOk

    function _updateSqueekboardInterest() {
        _observeSqueekboard = !_retired && Array.from(_settingsConsumers.values()).some(client => client.observesSqueekboard);
    }

    on_SampleSqueekboardChanged: {
        if (_sampleSqueekboard) return;
        passiveBus.running = false;
        passiveGsettings.running = false;
        _sampledBusOk = false;
        _sampledGsettingsOk = false;
    }
    Timer {
        running: root._sampleSqueekboard
        repeat: true
        triggeredOnStart: true
        interval: 2000
        onTriggered: {
            if (!passiveBus.running) passiveBus.running = true;
            if (!passiveGsettings.running) passiveGsettings.running = true;
        }
    }
    Process {
        id: passiveBus
        command: ["busctl", "--user", "call", "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "GetNameOwner", "s", "sm.puri.OSK0"]
        onExited: code => { if (root._sampleSqueekboard) root._sampledBusOk = code === 0; }
    }
    Process {
        id: passiveGsettings
        command: ["gsettings", "get", "org.gnome.desktop.a11y.applications", "screen-keyboard-enabled"]
        onExited: code => { if (root._sampleSqueekboard) root._sampledGsettingsOk = code === 0; }
    }

    Component { id: clientFactory; OskSettingsClient {} }
    function settingsConsumerFor(context) {
        if (!context?.current()) return null;
        if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
        const client = clientFactory.createObject(root, {
            settingsContext: context,
            keyboardActive: Qt.binding(function () { return root.keyboardActive; }),
            activePolicy: Qt.binding(function () { return root._loadedRequest === root._request && root._request?.context === context; }),
            physicalAvailable: Qt.binding(function () { return root.available; }),
            physicalTooltip: Qt.binding(function () { return root.unavailableTooltipKey; }),
            busOk: Qt.binding(function () { return root._squeekboardBusOk; }),
            gsettingsOk: Qt.binding(function () { return root._squeekboardGsettingsOk; }),
            requestToggle: function () { root.toggleKeyboard(context); },
            requestRecheck: function () { root.recheckState(context); },
            retire: function (retired) { root._settingsConsumers.delete(context); root._updateSqueekboardInterest(); retired.destroy(); }
        });
        _settingsConsumers.set(context, client);
        client.observesSqueekboardChanged.connect(root._updateSqueekboardInterest);
        _updateSqueekboardInterest();
        return client;
    }

    Process {
        id: autoDetect
        command: ["busctl", "--user", "call",
                  "org.freedesktop.DBus", "/org/freedesktop/DBus",
                  "org.freedesktop.DBus", "GetNameOwner",
                  "s", "sm.puri.OSK0"]
        onExited: (exitCode, exitStatus) => {
            const request = root._detectRequest;
            root._detectRequest = null;
            if (!root._retired && request === root._request && request?.context?.current())
                root._loadBackend(request, exitCode === 0 ? "squeekboard" : "wvkbd");
            else root._pumpBackend();
        }
    }

    Loader {
        id: backendLoader
        active: false
        onLoaded: root._runPendingToggle()
    }

    Connections {
        target: root._backend
        function onQuiescentChanged() { root._pumpBackend(); }
        function onAvailableChanged() { root._runPendingToggle(); }
    }

    function activatePolicy(context) {
        context = context || pluginApi?.settingsContext;
        if (!context?.current() || _retired) return false;
        selectedContext = context;
        _resolveBackend();
        return true;
    }

    function _resolveBackend() {
        if (!_constructed || _retired) return;
        if (!policyCurrent) {
            _request = null;
            _pendingToggle = null;
        } else {
            const context = policyContext, values = context.settingsView;
            const backend = values.backend ?? "auto", binary = values.wvkbdBin ?? "wvkbd-mobintl";
            if (_request?.context === context && _request.backend === backend && _request.binary === binary) return;
            _request = {context: context, backend: backend, binary: binary};
            _pendingToggle = null;
        }
        autoDetect.running = false;
        _pumpBackend();
    }

    function _pumpBackend() {
        if (_retired || _loadedRequest === _request && _backend) return;
        if (_backend) {
            _backend.retire();
            if (!_backend.quiescent) return;
            backendLoader.active = false;
            backendLoader.source = "";
            _loadedRequest = null;
            resolvedBackend = "";
        }
        if (autoDetect.running || !_request?.context?.current()) return;
        if (_request.backend === "auto") {
            _detectRequest = _request;
            autoDetect.running = true;
        } else _loadBackend(_request, _request.backend);
    }

    function _loadBackend(request, backend) {
        if (_retired || request !== _request || !request.context.current()) return;
        const source = backend === "squeekboard" ? "SqueekboardBackend.qml" : backend === "wvkbd" ? "WvkbdBackend.qml" : "";
        resolvedBackend = backend;
        _loadedRequest = request;
        if (!source) return;
        backendLoader.setSource(source, {settingsContext: request.context, wvkbdBin: request.binary});
        backendLoader.active = true;
    }

    function recheckState(context) {
        if (!activatePolicy(context)) return;
        settingsConsumerFor(policyContext)?.refresh();
        if (_loadedRequest === _request) _backend?.recheckState();
    }

    function toggleKeyboard(context) {
        if (!activatePolicy(context)) return;
        _pendingToggle = _request;
        _runPendingToggle();
    }

    function _runPendingToggle() {
        if (!_retired && _pendingToggle === _request && _request?.context?.current() && _loadedRequest === _request && _backend?.available) {
            _pendingToggle = null;
            _backend.toggleKeyboard();
        }
    }
}
