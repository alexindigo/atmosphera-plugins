import QtQuick

// One typed schedule per applied context, never another physical device owner.
Item {
    id: root
    required property var settingsContext
    required property var defaults
    required property var requestRefresh
    required property var retire
    property bool available: false
    property bool busy: false
    readonly property bool current: settingsContext.current()
    readonly property var cfg: current ? settingsContext.settingsView : ({})
    readonly property var gpu: cfg.supergfxctl ?? ({})
    readonly property bool debug: cfg.debug ?? defaults.debug ?? false
    readonly property bool patchPending: gpu.patchPending ?? defaults.supergfxctl?.patchPending ?? true
    readonly property bool polling: gpu.polling ?? defaults.supergfxctl?.polling ?? false
    readonly property int pollingInterval: gpu.pollingInterval ?? defaults.supergfxctl?.pollingInterval ?? 3000
    readonly property alias pollingTimer: pollingTimer

    function refresh() { if (current) requestRefresh(); }
    Timer {
        id: pollingTimer
        interval: root.pollingInterval
        repeat: true
        running: root.current && root.available && !root.busy && root.polling
        onTriggered: root.refresh()
    }
    onCurrentChanged: { if (!current) { pollingTimer.stop(); retire(root); } }
    Component.onDestruction: pollingTimer.stop()
}
