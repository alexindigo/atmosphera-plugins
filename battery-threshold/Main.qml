import QtQuick
import Quickshell.Io
import qs.Commons

// Start the BatteryThresholdService to restore a previously set charge
// threshold when the plugin is loaded. This is needed as FW may reset
// the charge threshold when the device is fully powered off.
Item {
    id: root
    property var pluginApi: null
    property var batteries: []
    property var _devices: new Map()
    property var _settingsConsumers: new Map()
    Component { id: deviceFactory; BatteryThresholdDevice {} }
    Component { id: clientFactory; BatteryThresholdService {} }
    function deviceFor(path) {
        if (!_devices.has(path))
            _devices.set(path, deviceFactory.createObject(root, {batteryDevice: path}));
        return _devices.get(path);
    }
    function settingsConsumerFor(context) {
        if (!context || !context.current())
            return null;
        if (!_settingsConsumers.has(context)) {
            const client = clientFactory.createObject(root, {
                settingsContext: context,
                inventory: root,
                deviceFor: function(path) { return root.deviceFor(path); },
                retire: function(retired) {
                    root._settingsConsumers.delete(context);
                    retired.destroy();
                }
            });
            _settingsConsumers.set(context, client);
        }
        return _settingsConsumers.get(context);
    }
    // Main/IPC have no placement and remain explicitly plugin-scoped.
    readonly property var service: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
    Process {
        id: batteryList
        command: ["sh", "-c", "find /sys/class/power_supply -exec find {}/ ';' | grep charge_control_end_threshold"]
        stdout: StdioCollector {
            onStreamFinished: root.batteries = text.trim().split("\n").filter(path => path !== "").map(path => path.split("/").slice(0, -1).join("/"))
        }
    }
    Component.onCompleted: batteryList.running = true

    IpcHandler {
        target: "plugin:battery-threshold"
        function togglePanel() {
            pluginApi?.withCurrentScreen(s => pluginApi.togglePanel(s));
        }
        function set(value: string) {
            var numValue = parseInt(value);
            if (service && numValue >= service.batteryMinThresh && numValue <= service.batteryMaxThresh) {
                service.setThreshold(numValue, root.pluginApi);
            }
        }
    }
}
