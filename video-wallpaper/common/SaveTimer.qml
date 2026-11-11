// Capture authored input now; the timer schedules one owning edit and the
// receipt, never timer fire, acknowledges it. Failed work stays available.
import QtQuick
import qs.Commons
import "MonitorCommands.js" as Commands

Item {
    id: root

    required property var pluginApi

    property alias running: timer.running

    property var screenName: undefined
    property bool busy: false
    property bool failed: false
    property var _pending: null
    signal completed(var result)
    readonly property var monitorCommand: Commands.create(function () { return root.pluginApi?.pluginSettings?.monitors; },
        function (value) { root.pluginApi.pluginSettings.monitors = value; }, function (value) { return Settings.store.copyValue(value); })

    function save(key: string, value: var) {
        if (typeof key !== "string") {
            Logger.e("video-wallpaper", "Saving with wrong type of key:", key);
            return;
        }

        if (screenName === undefined) {
            if (value !== null && typeof value === "object") throw new Error("timer-scalar-input");
            _pending = {key: key, value: value};
        } else {
            _pending = {commands: Commands.capture([{op: "set", screen: screenName, field: key, value: value}])};
        }
        failed = false;
        timer.restart();
    }

    function retry() {
        if (!_pending || busy) return false;
        failed = false;
        timer.restart();
        return true;
    }

    Timer {
        id: timer
        interval: 30
        repeat: false
        running: false
        triggeredOnStart: false

        onTriggered: {
            if (!root._pending || !root.pluginApi) return;
            if (root.busy) return; // The completion schedules any newer input.
            var body = root._pending;
            root.busy = true;
            function finish(result) {
                root.busy = false;
                var success = result.status === "saved" || result.status === "nothing_to_save";
                if (root._pending === body) {
                    root.failed = !success;
                    if (success) root._pending = null;
                } else timer.restart();
                root.completed(result);
            }
            try {
                if (body.commands) root.monitorCommand.submit(body.commands);
                else root.pluginApi.pluginSettings[body.key] = body.value;
                root.pluginApi.saveSettings(finish);
            } catch (error) {
                Qt.callLater(function () { finish({status: "failed", error: {code: "timer-edit"}}); });
            }
        }
    }
}
