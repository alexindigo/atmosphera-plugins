import QtQuick

// One Main-owned configuration client, shared by all renderings of its API.
Item {
    id: root
    visible: false
    required property var settingsContext
    required property var inventory
    required property var deviceFor
    required property var retire
    readonly property bool current: settingsContext.current()
    readonly property var cfg: current ? settingsContext.settingsView : ({})
    readonly property var batteries: inventory.batteries
    readonly property string batteryDevice: current ? (cfg.batteryDevice || batteries[0] || "") : ""
    readonly property string thresholdFile: batteryDevice ? batteryDevice + "/charge_control_end_threshold" : ""
    readonly property var device: batteryDevice ? deviceFor(batteryDevice) : null
    readonly property int currentThreshold: device?.currentThreshold ?? 0
    readonly property bool isAvailable: device?.isAvailable ?? false
    readonly property bool isWritable: device?.isWritable ?? false
    readonly property int batteryMinThresh: 40
    readonly property int batteryMaxThresh: 100
    readonly property bool busy: device?.busy ?? false
    property string actionError: ""
    property string _restoredPolicy: ""
    property bool _restoreRequested: true
    property string _expectedRestoreDevice: ""
    readonly property string policy: current ? JSON.stringify([batteryDevice, cfg.chargeThreshold]) : ""
    property var _lifetime: ({alive: true})

    function refresh(expectedDevice) {
        _expectedRestoreDevice = expectedDevice || batteryDevice;
        _restoreRequested = true;
        device?.refresh();
        Qt.callLater(restoreSavedThreshold);
    }

    function restoreSavedThreshold() {
        if (!_restoreRequested || !current || !device || !device.ready || !isWritable || busy || (_expectedRestoreDevice && batteryDevice !== _expectedRestoreDevice))
            return;
        const saved = cfg.chargeThreshold;
        if (typeof saved !== "number" || saved < batteryMinThresh || saved > batteryMaxThresh)
            return;
        // Restore once per effective configuration, never on each redraw or
        // physical observation. Another client may change this shared device.
        const capturedPolicy = policy;
        if (Math.round(saved) === currentThreshold) {
            _restoredPolicy = capturedPolicy;
            _restoreRequested = false;
            return;
        }
        const lifetime = _lifetime;
        device.setThreshold(saved, function(ok) {
            if (lifetime.alive && root.current && root.policy === capturedPolicy) {
                root._restoredPolicy = capturedPolicy;
                root._restoreRequested = false;
                if (!ok)
                    root.actionError = "device-write";
            }
        });
    }

    function setThreshold(value, runtimeApi) {
        const v = Math.round(value);
        if (!current || !runtimeApi || runtimeApi.settingsContext !== settingsContext || !isWritable || busy || v < batteryMinThresh || v > batteryMaxThresh) {
            actionError = "action-unavailable";
            return false;
        }
        const capturedDevice = device;
        const capturedPolicy = policy;
        const lifetime = _lifetime;
        actionError = "";
        return capturedDevice.setThreshold(v, function(ok) {
            if (!lifetime.alive || !root.current || root.device !== capturedDevice || root.policy !== capturedPolicy)
                return;
            if (!ok) {
                root.actionError = "device-write";
                return;
            }
            // Physical success and preference persistence are distinct. The
            // existing runtime writer stays scoped to the originating API.
            runtimeApi.pluginSettings.chargeThreshold = v;
            runtimeApi.saveSettings(function(result) {
                if (lifetime.alive && root.current && (!result || (result.status !== "saved" && result.status !== "nothing_to_save") || (result.refreshState !== undefined && result.refreshState !== "current")))
                    root.actionError = "preference-save";
            });
        });
    }

    onPolicyChanged: Qt.callLater(restoreSavedThreshold)
    Connections {
        target: root.device
        function onReadyChanged() { Qt.callLater(root.restoreSavedThreshold); }
        function onBusyChanged() { Qt.callLater(root.restoreSavedThreshold); }
    }
    onCurrentChanged: {
        if (!current)
            retire(root);
    }
    Component.onCompleted: Qt.callLater(restoreSavedThreshold)
    Component.onDestruction: _lifetime.alive = false
}
