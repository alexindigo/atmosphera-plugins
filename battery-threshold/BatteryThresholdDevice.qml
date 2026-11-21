import QtQuick
import Quickshell.Io

// Main owns one observer/action serializer per physical battery. It knows no
// preference owner; callers capture their own completion and native writer.
Item {
    id: root
    visible: false
    required property string batteryDevice
    readonly property string thresholdFile: batteryDevice + "/charge_control_end_threshold"
    property int currentThreshold: 0
    property bool isAvailable: false
    property bool isWritable: false
    property bool ready: false
    property bool _loaded: false
    readonly property bool busy: writer.running

    function refresh() {
        if (!probe.running)
            probe.running = true;
        thresholdView.reload();
    }
    function setThreshold(value, callback) {
        if (busy || !ready || !isWritable)
            return false;
        writer.completion = callback;
        writer.command = ["sh", "-c", 'printf "%s\\n" "$1" > "$2"', "battery-threshold", String(Math.round(value)), thresholdFile];
        writer.running = true;
        return true;
    }
    Process {
        id: probe
        command: ["test", "-w", root.thresholdFile]
        onExited: function(exitCode) {
            root.isWritable = exitCode === 0;
            root.ready = root._loaded;
        }
    }
    FileView {
        id: thresholdView
        path: root.thresholdFile
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const value = parseInt(text().trim());
            root.isAvailable = !isNaN(value) && value >= 0 && value <= 100;
            if (root.isAvailable)
                root.currentThreshold = value;
            root._loaded = root.isAvailable;
            if (!probe.running)
                probe.running = true;
        }
        onLoadFailed: {
            root.isAvailable = false;
            root.isWritable = false;
            root.ready = false;
            root._loaded = false;
        }
    }
    Process {
        id: writer
        property var completion: null
        onExited: function(exitCode) {
            const callback = completion;
            completion = null;
            // Refresh physical state before notifying the configuration owner.
            thresholdView.reload();
            thresholdView.waitForJob();
            if (typeof callback === "function")
                callback(exitCode === 0);
        }
    }
    Component.onCompleted: refresh()
}
