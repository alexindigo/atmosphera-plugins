import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI
import "../utils"

Item {
    id: root
    property var    pluginApi:  null
    property string scriptsDir: ""

    signal done()
    signal failed()

    function run(grimX, grimY, grimW, grimH) {
        ToastService.showNotice(pluginApi?.tr("messages.lens-uploading"))
        lensProc.exec({ command: [
            root.scriptsDir + "lens-upload.sh",
            String(grimX), String(grimY), String(grimW), String(grimH)
        ]})
    }

    ToolProcess {
        id: lensProc
        onExited: (code) => {
            if (code !== 0) { root.failed(); return }
            root.done()
        }
    }
}

