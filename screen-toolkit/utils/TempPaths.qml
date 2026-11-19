pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
    id: root
    readonly property string directory: {
        const runtime = Quickshell.env("XDG_RUNTIME_DIR");
        const base = runtime || (Settings.cacheDir + "plugins");
        return base.replace(/\/+$/, "") + "/screen-toolkit";
    }
    readonly property var environment: ({
        SCREEN_TOOLKIT_TMPDIR: root.directory,
        TMPDIR: root.directory
    })
    property bool ready: false
    function path(name) {
        return directory + "/" + name;
    }
    function shellPath(name) {
        return "'" + path(name).replace(/'/g, "'\\''") + "'";
    }
    Process {
        command: ["mkdir", "-p", "-m", "700", "--", root.directory]
        environment: root.environment
        running: true
        onExited: function(code) { root.ready = code === 0; }
    }
}
