import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root
    required property string device
    required property var observation
    property bool active: true
    property int retryCount: 0
    property bool hasNotified: false
    readonly property var retryIntervals: [30000, 90000, 300000]
    function stop() {
        active = false;
        restartTimer.stop();
        evtestProc.running = false;
        deviceCheckProc.running = false;
    }
    Process {
        id: evtestProc
        command: ["evtest", root.device]
        running: root.active
        stdout: SplitParser {
            onRead: data => {
                if (!root.active || !data.includes("EV_KEY")) return;
                const bigHit = data.includes("KEY_SPACE") || data.includes("KEY_ENTER");
                if (data.includes("value 1") && !data.includes("BTN_TOOL_")) observation.inputEvent(root.device, "press", bigHit);
                else if (data.includes("value 0")) observation.inputEvent(root.device, "release", bigHit);
                else if (data.includes("value 2")) observation.inputEvent(root.device, "repeat", bigHit);
            }
        }
        stderr: StdioCollector {}
        onRunningChanged: if (running && root.active) {
            root.retryCount = 0;
            root.hasNotified = false;
        }
        onExited: exitCode => {
            if (!root.active) return;
            if (exitCode !== 0) {
                root.retryCount++;
                if (!root.hasNotified) {
                    ToastService.showWarning(observation.pluginApi?.tr("toast.evtest-error") ?? "SlowBongo",
                        observation.pluginApi?.tr("toast.device-disconnected") ?? ("Device disconnected: " + root.device));
                    root.hasNotified = true;
                }
                if (root.retryCount > root.retryIntervals.length) {
                    ToastService.showNotice(observation.pluginApi?.tr("toast.device-gave-up") ?? "SlowBongo",
                        observation.pluginApi?.tr("toast.device-gave-up-desc") ?? ("Stopped trying to reconnect to: " + root.device));
                    return;
                }
                restartTimer.interval = root.retryIntervals[root.retryCount - 1];
            } else restartTimer.interval = root.retryIntervals[0];
            restartTimer.start();
        }
    }
    Timer {
        id: restartTimer
        repeat: false
        onTriggered: if (root.active) deviceCheckProc.running = true
    }
    Process {
        id: deviceCheckProc
        command: ["test", "-e", root.device]
        onExited: exitCode => {
            if (!root.active) return;
            if (exitCode === 0) evtestProc.running = true;
            else if (root.retryCount < root.retryIntervals.length) {
                root.retryCount++;
                restartTimer.interval = root.retryIntervals[root.retryCount - 1];
                restartTimer.start();
            }
        }
    }
}
