import QtQuick

Item {
    id: client
    required property var settingsContext
    required property var observation
    required property var retire
    readonly property bool current: settingsContext.current()
    readonly property var cfg: settingsContext.settingsView
    readonly property string deviceId: cfg.mainDeviceId || ""
    readonly property bool hideIfNoDeviceConnected: cfg.hideIfNoDeviceConnected ?? false
    property var mainDevice: null
    property var _configuredDevice: null
    property bool _constructed: false
    function update(checkReachable) {
        if (!current) return;
        mainDevice = observation.selectDevice(deviceId, checkReachable);
        _configuredDevice = observation.devices.find(device => device.id === deviceId);
    }
    onDeviceIdChanged: if (_constructed) update(false)
    Connections {
        target: client.observation
        function onDevicesChanged() {
            var previous = client._configuredDevice;
            var next = client.observation.devices.find(device => device.id === client.deviceId);
            var lost = !previous || (previous.reachable && !next?.reachable) || (previous.paired && !next?.paired);
            client.update(lost);
        }
    }
    function selectDevice(id, api) {
        if (!current || !api || api.settingsContext !== settingsContext || !observation.devices.some(device => device.id === id)) return false;
        api.pluginSettings.mainDeviceId = id;
        return api.saveSettings();
    }
    function triggerFindMyPhone() { if (current && mainDevice) observation.triggerFindMyPhone(mainDevice.id); }
    function browseFiles() { if (current && mainDevice) observation.browseFiles(mainDevice.id); }
    function wakeUpDevice() { if (current && mainDevice) observation.wakeUpDevice(mainDevice.id); }
    function unpairDevice() { if (current && mainDevice) observation.unpairDevice(mainDevice.id); }
    function requestPairing() {
        if (!current || !mainDevice) return;
        observation.requestPairing(mainDevice.id);
        mainDevice.pairRequested = true;
        observation.refreshDevices();
    }
    function shareFile(id, path) {
        if (current && id && observation.devices.some(device => device.id === id && device.paired && device.reachable))
            observation.shareFile(id, path);
    }
    onCurrentChanged: if (!current && _constructed) retire(client)
    Component.onCompleted: { _constructed = true; update(false); }
}
