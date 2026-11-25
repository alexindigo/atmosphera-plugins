import QtQuick
import "Projection.js" as Projection

Item {
    id: client
    required property var settingsContext
    required property var observation
    required property var retire
    readonly property bool current: settingsContext.current()
    readonly property var cfg: settingsContext.settingsView
    readonly property bool enableToast: cfg.enableToast ?? true
    readonly property var microphone: Projection.filteredMicrophone(observation.rawMic, cfg.micFilterRegex ?? "")
    readonly property bool micActive: microphone.active
    readonly property var micApps: microphone.apps
    readonly property var camApps: Projection.camera(observation.rawCamera, cfg.camFilterRegex ?? "")
    readonly property bool camActive: camApps.length > 0
    readonly property bool scrActive: observation.scrActive
    readonly property var scrApps: observation.scrApps
    readonly property var accessHistory: observation.accessHistory
    property bool _constructed: false
    function notify(type) {
        if (current && enableToast) observation.requestToast(type, settingsContext);
    }
    onMicActiveChanged: if (_constructed && micActive) notify("mic")
    onCamActiveChanged: if (_constructed && camActive) notify("cam")
    onScrActiveChanged: if (_constructed && scrActive) notify("screen")
    function clearHistory() { if (current) observation.clearHistory(); }
    onCurrentChanged: if (!current && _constructed) retire(client)
    Component.onCompleted: {
        _constructed = true;
        if (micActive) notify("mic");
        if (camActive) notify("cam");
        if (scrActive) notify("screen");
    }
}
