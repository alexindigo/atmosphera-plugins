import QtQuick
import Quickshell.Io

// Availability is a selected observation. It never constructs a keyboard backend.
Item {
    id: root
    required property var settingsContext
    required property var requestToggle
    required property var requestRecheck
    required property var retire
    property bool keyboardActive: false
    property bool activePolicy: false
    property bool physicalAvailable: false
    property string physicalTooltip: "tooltip.detecting"
    readonly property bool current: settingsContext.current()
    readonly property var cfg: current ? settingsContext.settingsView : ({})
    readonly property string backend: cfg.backend ?? "auto"
    readonly property string binary: cfg.wvkbdBin ?? "wvkbd-mobintl"
    property bool binaryOk: false
    property bool busOk: false
    property bool gsettingsOk: false
    property string _binaryTarget: ""
    property bool _binaryAgain: false
    property bool _constructed: false
    readonly property string resolvedBackend: backend === "auto" ? (busOk ? "squeekboard" : "wvkbd") : backend
    readonly property bool available: current && (activePolicy ? physicalAvailable : (resolvedBackend === "squeekboard" ? busOk && gsettingsOk : resolvedBackend === "wvkbd" && binaryOk))
    readonly property string unavailableTooltipKey: activePolicy ? physicalTooltip : (resolvedBackend === "squeekboard" ? (!gsettingsOk ? "tooltip.noGsettings" : "tooltip.noSqueekboard") : "tooltip.noWvkbd")

    function _checkBinary() {
        if (!current || !_constructed) return;
        if (binaryCheck.running) {
            _binaryAgain = true;
            binaryCheck.running = false;
            return;
        }
        _binaryAgain = false;
        _binaryTarget = binary;
        binaryCheck.command = ["which", binary.trim().split(/\s+/)[0]];
        binaryCheck.running = true;
    }
    function refresh() {
        if (!current || !_constructed) return;
        _checkBinary();
        busCheck.exec(["busctl", "--user", "call", "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "GetNameOwner", "s", "sm.puri.OSK0"]);
        gsettingsCheck.exec(["gsettings", "get", "org.gnome.desktop.a11y.applications", "screen-keyboard-enabled"]);
    }
    function toggleKeyboard() { if (current && available) requestToggle(); }
    function recheckState() { if (current) requestRecheck(); }
    function stop() {
        binaryCheck.running = false;
        busCheck.running = false;
        gsettingsCheck.running = false;
    }
    Process {
        id: binaryCheck
        onExited: code => {
            if (!root.current) return;
            if (root._binaryAgain || root._binaryTarget !== root.binary) root._checkBinary();
            else root.binaryOk = code === 0;
        }
    }
    Process { id: busCheck; onExited: code => { if (root.current) root.busOk = code === 0; } }
    Process { id: gsettingsCheck; onExited: code => { if (root.current) root.gsettingsOk = code === 0; } }
    onBinaryChanged: { binaryOk = false; _checkBinary(); }
    onBackendChanged: refresh()
    onCurrentChanged: { if (!current && _constructed) { stop(); retire(root); } }
    Component.onCompleted: { _constructed = true; refresh(); }
    Component.onDestruction: stop()
}
