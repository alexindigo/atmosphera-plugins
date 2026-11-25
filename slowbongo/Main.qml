import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Media

Item {
    id: root
    property var pluginApi: null
    // Pause is the original common action, not configuration or persisted content.
    property bool paused: false
    readonly property string spectrumInstanceId: "plugin:slowbongo:" + Date.now() + Math.random()
    property bool _spectrumRegistered: false
    property var _settingsConsumers: new Map()
    property var _deviceMonitors: new Map()
    Component { id: clientFactory; BongoSettingsClient {} }
    Component { id: deviceFactory; BongoDeviceMonitor {} }

    function settingsConsumerFor(context) {
        if (!context || !context.current()) return null;
        if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
        var client = clientFactory.createObject(root, {
            settingsContext: context, observation: root,
            retire: function(retired) {
                root._settingsConsumers.delete(context);
                root.synchronizeDevices();
                retired.destroy();
            }
        });
        _settingsConsumers.set(context, client);
        synchronizeDevices();
        return client;
    }
    readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null

    function synchronizeDevices() {
        var wanted = new Set();
        for (var client of _settingsConsumers.values()) {
            if (!client.current) continue;
            for (var device of client.inputDevices) wanted.add(device);
        }
        for (var [device, monitor] of _deviceMonitors) {
            if (wanted.has(device)) continue;
            _deviceMonitors.delete(device);
            monitor.stop();
            monitor.destroy();
        }
        for (var device of wanted) {
            if (_deviceMonitors.has(device)) continue;
            var monitor = deviceFactory.createObject(root, {
                device: device, observation: root
            });
            _deviceMonitors.set(device, monitor);
        }
    }
    function inputEvent(device, kind, bigHit) {
        for (var client of _settingsConsumers.values()) {
            if (!client.current || client.inputDevices.indexOf(device) < 0) continue;
            if (kind === "press") client.onKeyPress(bigHit);
            else if (kind === "release") client.onKeyRelease(bigHit);
            else if (kind === "repeat") client.onKeyRepeat(bigHit);
        }
    }
    onPluginApiChanged: {
        if (pluginApi && !_spectrumRegistered) {
            SpectrumService.registerComponent(spectrumInstanceId);
            _spectrumRegistered = true;
        }
    }
    Component.onDestruction: {
        if (_spectrumRegistered) SpectrumService.unregisterComponent(spectrumInstanceId);
    }
    IpcHandler {
        target: "plugin:slowbongo"
        function pause() { root.paused = true; }
        function resume() { root.paused = false; }
        function toggle() { root.paused = !root.paused; }
    }
}
