import QtQuick
import qs.Commons
import qs.Services.Media

Item {
    id: root

    required property var settingsContext
    required property var observation
    required property var retire
    readonly property bool current: settingsContext.current()
    readonly property var cfg: settingsContext.settingsView
    property bool _constructed: false

    // === CORE STATE ===
    property int catState: 0  // 0 = idle (both paws up), 1 = left slap, 2 = right slap, 3 = both slap
    property bool leftWasLast: false  // Track which paw slapped last to alternate
    readonly property bool paused: observation.paused
    property bool waiting: false
    property bool blinking: false
    property int pendingCatState: 0  // State to transition to after reset delay

    // === INPUT DEVICES (from settings) ===
    readonly property var inputDevices: {
        const saved = cfg.inputDevices;
        if (saved && saved.length > 0) return saved;
        return [];
    }

    onInputDevicesChanged: if (_constructed && current) observation.synchronizeDevices()
    onCurrentChanged: if (_constructed && !current) {
        stop();
        retire(root);
    }
    Component.onCompleted: _constructed = true
    function stop() {
        for (var timer of [beatCooldownTimer, flashTimer, stateResetTimer, idleTimer,
                           waitingTimer, blinkIntervalTimer, blinkDurationTimer, flutterTimer]) timer.stop();
    }

    // === SETTINGS ===
    readonly property int idleTimeout: cfg.idleTimeout ?? 250
    readonly property int waitingTimeout: cfg.waitingTimeout ?? 5000
    readonly property string catColor: cfg.catColor ?? "default"
    readonly property real catSize: cfg.catSize ?? 1.0
    readonly property real catOffsetY: cfg.catOffsetY ?? 0.0
    readonly property bool raveMode: cfg.raveMode ?? false
    readonly property bool tappyMode: cfg.tappyMode ?? false
    readonly property bool useMprisFilter: cfg.useMprisFilter ?? false

    // === AUDIO REACTIVE STATE ===
    readonly property bool anyMusicPlaying: !SpectrumService.isIdle
    property int rainbowIndex: 0
    readonly property var rainbowColors: ['#aa0000', '#b65c02', '#bb9c14', '#00a100', '#01019b', '#37005c', '#6a0196']
    property real audioIntensity: 0
    property real smoothedIntensity: 0
    property real previousIntensity: 0
    property real bassIntensity: 0
    readonly property real beatThreshold: 0.07
    readonly property real bigBeatThreshold: 0.67
    readonly property real beatDeltaThreshold: 0.014  // Minimum sudden increase to count as beat
    property bool isFlashing: false

    // === COMPUTED MODE FLAGS ===
    readonly property bool mprisAllowed: !useMprisFilter || MediaService.isPlaying
    readonly property bool useTappyMode: tappyMode && anyMusicPlaying && mprisAllowed
    readonly property string currentRainbowColor: rainbowColors[rainbowIndex]
    readonly property bool useRaveColors: raveMode && anyMusicPlaying && mprisAllowed
    readonly property bool showRainbowColor: useRaveColors && isFlashing

    // === AUDIO REACTIVE CONNECTIONS ===
    Connections {
        target: SpectrumService
        function onValuesChanged() {
            if (!root.current || root.paused) return;
            if (!root.useRaveColors && !root.useTappyMode) return;

            if (!SpectrumService.values || SpectrumService.values.length === 0) {
                root.audioIntensity = 0;
                return;
            }

            const subBassCount = Math.min(4, SpectrumService.values.length);
            const bassCount = Math.min(8, SpectrumService.values.length);
            const midCount = Math.min(16, SpectrumService.values.length);

            let subBassSum = 0;
            for (let i = 0; i < subBassCount; i++) {
                subBassSum += SpectrumService.values[i] || 0;
            }

            let bassSum = 0;
            for (let i = 0; i < bassCount; i++) {
                bassSum += SpectrumService.values[i] || 0;
            }

            let midSum = 0;
            for (let i = 8; i < midCount; i++) {
                midSum += SpectrumService.values[i] || 0;
            }

            const subBassAvg = subBassSum / subBassCount;
            const bassAvg = bassSum / bassCount;
            const midAvg = midSum / Math.max(1, midCount - 8);

            root.bassIntensity = subBassAvg;
            root.audioIntensity = (bassAvg * 0.8) + (midAvg * 0.6);

            const alpha = 0.75;
            root.previousIntensity = root.smoothedIntensity;
            root.smoothedIntensity = alpha * root.audioIntensity + (1 - alpha) * root.smoothedIntensity;

            const intensityDelta = root.smoothedIntensity - root.previousIntensity;
            const isBeat = (intensityDelta > root.beatDeltaThreshold && root.smoothedIntensity > root.beatThreshold * 0.5)
                        || (root.smoothedIntensity > root.beatThreshold && intensityDelta > 0);

            if (isBeat && !beatCooldownTimer.running) {
                if (root.useRaveColors) {
                    root.rainbowIndex = (root.rainbowIndex + 1) % root.rainbowColors.length;
                    root.isFlashing = true;
                    flashTimer.restart();
                }

                if (root.useTappyMode) {
                    root.musicEvent(root.bassIntensity > root.bigBeatThreshold);
                }

                beatCooldownTimer.restart();
            }
        }
    }

    // === TIMERS ===
    Timer {
        id: beatCooldownTimer
        interval: 70
        repeat: false
    }

    Timer {
        id: flashTimer
        interval: 100
        repeat: false
        onTriggered: if (root.current) root.isFlashing = false
    }

    Timer {
        id: stateResetTimer
        interval: 40
        repeat: false
        onTriggered: if (root.current) root.catState = root.pendingCatState
    }

    // === MUSIC HANDLER ===
    function musicEvent(isBigHit = false) {
        if (!root.current || root.paused) return;
        root.waiting = false;

        let targetState;
        if (isBigHit) {
            targetState = 3;
        } else {
            root.leftWasLast = !root.leftWasLast;
            targetState = root.leftWasLast ? 1 : 2;
        }

        const needsReset = root.catState !== 0 && ((isBigHit && root.catState !== 3) || (!isBigHit && root.catState === 3));

        if (needsReset) {
            root.catState = 0;
            root.pendingCatState = targetState;
            stateResetTimer.restart();
        } else {
            root.catState = targetState;
        }

        idleTimer.restart();
        waitingTimer.restart();
    }

    // === KEY PRESS HANDLER ===
    function onKeyPress(isBigHit = false) {
        if (!root.current || root.paused) return;
        root.waiting = false;

        let targetState;
        if (isBigHit) {
            targetState = 3;
        } else {
            if (root.catState !== 0){
                targetState = 3;
            } else {
                root.leftWasLast = !root.leftWasLast;
                targetState = root.leftWasLast ? 1 : 2;
            }
        }

        root.catState = targetState;
        waitingTimer.restart();
    }

    function onKeyRelease(isBigHit = false) {
        if (!root.current || root.paused) return;
        root.waiting = false;

        let targetState;
        if (isBigHit) {
            targetState = 0;
        } else {
            if (root.catState === 3){
                targetState = root.leftWasLast ? 1 : 2;
            } else {
                targetState = 0;
            }
        }

        root.catState = targetState;
        waitingTimer.restart();
    }

    function onKeyRepeat(isBigHit = false){
        if (!root.current || root.paused) return;
        root.waiting = false;

        let targetState;
        if (root.catState !== 0) {
            targetState = root.catState;
        } else {
            if (isBigHit){
                targetState = 3;
            } else {
                targetState = root.leftWasLast ? 1 : 2;
            }
        }

        root.catState = targetState;
        waitingTimer.restart();
    }

    // === STATE CHANGE HANDLERS ===
    onPausedChanged: {
        if (root.paused) {
            idleTimer.stop();
            waitingTimer.stop();
            root.waiting = false;
            root.blinking = false;
            root.catState = 0;
        } else if (root.current) {
            waitingTimer.restart();
        }
    }

    onWaitingChanged: {
        if (root.waiting) {
            root.blinking = false;
        }
    }

    // === IDLE & WAITING TIMERS ===
    Timer {
        id: idleTimer
        interval: root.idleTimeout
        repeat: false
        onTriggered: if (root.current) root.catState = 0
    }

    Timer {
        id: waitingTimer
        interval: root.waitingTimeout
        repeat: false
        onTriggered: if (root.current) root.waiting = true
    }

    // === BLINK ANIMATION ===
    Timer {
        id: blinkIntervalTimer
        interval: 6000 + Math.random() * 8000
        repeat: true
        running: root.current && !root.paused && !root.waiting
        onTriggered: {
            interval = 6000 + Math.random() * 8000;
            if (Math.random() < 0.5) {
                root.blinking = true;
                blinkDurationTimer.start();
            } else {
                root.blinkFlutterCount = 0;
                root.blinking = true;
                flutterTimer.start();
            }
        }
    }

    property int blinkFlutterCount: 0

    Timer {
        id: blinkDurationTimer
        interval: 450
        repeat: false
        onTriggered: root.blinking = false
    }

    Timer {
        id: flutterTimer
        interval: 120
        repeat: false
        onTriggered: {
            root.blinkFlutterCount++;
            root.blinking = !root.blinking;
            if (root.blinkFlutterCount < 4) {
                flutterTimer.start();
            } else {
                root.blinking = false;
            }
        }
    }

}
