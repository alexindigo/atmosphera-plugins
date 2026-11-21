import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var settingsContext: null
    property bool _retired: false
    property bool _constructed: false
    property bool _ready: false
    property bool _starting: false
    readonly property bool current: !root._retired && (settingsContext?.current() ?? false)
    readonly property bool quiescent: !availabilityChecker.running && !preemptChecker.running && !preemptKill.running && !wvkbd.running

    property bool _visible: false
    // Inverted so BarWidget's direct mapping matches wvkbd-toggle's icon convention.
    readonly property bool keyboardActive: !_visible
    property bool wvkbdOk: false
    property bool available: wvkbdOk && _ready

    readonly property string unavailableTooltipKey: "tooltip.noWvkbd"
    property string wvkbdBin: "wvkbd-mobintl"
    readonly property list<string> wvkbdBinParts: wvkbdBin.trim().split(/\s+/)

    // True when wvkbd should be made visible as soon as it finishes starting up.
    // Used both at startup (restoring a pre-existing visible instance) and after
    // an unexpected exit (relaunch-then-show).
    property bool _pendingShow: false

    // True when wvkbd is being killed in order to relaunch under a new binary name.
    property bool _pendingRestart: false

    onWvkbdBinChanged: {
        if (!root._constructed || !root.current) return;
        root._ready = false;
        if (!wvkbd.running) {
            availabilityChecker.running = true
            return
        }
        root._pendingShow = root._visible
        root._pendingRestart = true
        wvkbd.running = false
    }

    // --- 1. Availability: check binary exists on PATH ---
    Process {
        id: availabilityChecker
        command: ["which", root.wvkbdBinParts[0]]
        onExited: (exitCode, exitStatus) => {
            if (!root.current) return;
            root.wvkbdOk = exitCode === 0
            if (root.wvkbdOk && !wvkbd.running && !preemptChecker.running && !preemptKill.running) preemptChecker.running = true
        }
        Component.onCompleted: running = root.current
    }

    // --- 2. Detect any pre-existing wvkbd instance ---
    Process {
        id: preemptChecker
        command: ["pgrep", "-x", root.wvkbdBinParts[0]]
        onExited: (exitCode, exitStatus) => {
            if (!root.current) return;
            root._pendingShow = root._pendingShow || exitCode === 0  // preserve an admitted show while checking external ownership
            if (exitCode === 0) {
                preemptKill.running = true
            } else {
                wvkbd.running = true
            }
        }
    }

    // --- 3. Kill pre-existing instance so we can take ownership ---
    Process {
        id: preemptKill
        command: ["pkill", "-x", root.wvkbdBinParts[0]]
        onExited: (exitCode, exitStatus) => {
            if (!root.current) return;
            wvkbd.running = true
        }
    }

    // --- 4. Our owned wvkbd process — always running, starts hidden ---
    Process {
        id: wvkbd
        command: [...wvkbdBinParts, "--hidden"]
        onRunningChanged: {
            if (root.current && running) {
                root._starting = true;
                showTimer.restart()
                root._ready = true;
            }
        }
        onExited: (exitCode, exitStatus) => {
            root._visible = false
            if (!root.current) return;
            if (root._pendingRestart) {
                root._pendingRestart = false
                availabilityChecker.running = true
            }
        }
    }

    // --- Brief delay after launch before signalling (wvkbd needs to init) ---
    Timer {
        id: showTimer
        interval: 300
        onTriggered: {
            if (!root.current) return;
            root._starting = false;
            if (root._pendingShow && wvkbd.running) {
                root._pendingShow = false;
                wvkbd.signal(10)  // SIGUSR1 = show
                root._visible = true;
            }
        }
    }

    function retire() {
        root._retired = true;
        root._pendingRestart = false;
        root._pendingShow = false;
        root._starting = false;
        showTimer.stop();
        availabilityChecker.running = false;
        preemptChecker.running = false;
        preemptKill.running = false;
        wvkbd.running = false;
    }
    onCurrentChanged: { if (_constructed && !current) retire(); }
    Component.onCompleted: { _constructed = true; if (!current) retire(); }
    Component.onDestruction: retire()

    function recheckState() {
        if (!root.current) return;
        availabilityChecker.running = true
    }

    function toggleKeyboard() {
        if (!root.current) return;
        if (root._starting) {
            root._pendingShow = !root._pendingShow;
            return;
        }
        if (!wvkbd.running) {
            root._pendingShow = true
            wvkbd.running = true
            return
        }
        if (root._visible) {
            wvkbd.signal(12)  // SIGUSR2 = hide
            root._visible = false
        } else {
            wvkbd.signal(10)  // SIGUSR1 = show
            root._visible = true
        }
    }
}
