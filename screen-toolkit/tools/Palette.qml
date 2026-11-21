import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI
import "../utils"

Item {
    id: root
    property var    pluginApi:  null
    property var actionPolicy: null
    property string scriptsDir: ""

    property var paletteColors: []

    signal done()
    signal failed()

    function run(grimGeometry, policy) {
        if (!policy?.context.current() || paletteProc.running) return false
        actionPolicy = policy
        if (root.pluginApi) {
            root.pluginApi.pluginSettings.paletteColors = []
            root.pluginApi.saveSettings()
        }
        root.paletteColors = []
        paletteProc.exec({ command: [root.scriptsDir + "capture.sh", "palette", grimGeometry] })
    }

    function clearResults() {
        root.paletteColors = []
    }

    function loadState(s) {
        var pal = s.paletteColors ?? []
        if (pal.length > 0) root.paletteColors = pal
    }

    ToolProcess {
        id: paletteProc
        stdout: StdioCollector {}
        onExited: (code) => {
            if (!root.actionPolicy?.context.current()) { root.done(); return }
            var raw = paletteProc.stdout.text.trim()
            if (code !== 0 || raw === "") { root.failed(); return }

            var colors = raw.split("\n")
                .map(function(c) { return c.trim() })
                .filter(function(c) { return /^#[0-9a-fA-F]{6}$/.test(c) })
                .filter(function(c, i, arr) { return arr.indexOf(c) === i })
                .slice(0, 8)

            if (colors.length === 0) { root.failed(); return }

            root.paletteColors = colors

            if (root.pluginApi) {
                root.pluginApi.pluginSettings.paletteColors = colors
                root.pluginApi.saveSettings()
            }

            root.done()
        }
    }
}
