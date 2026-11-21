import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.Compositor
import "overlays"
import "widgets"
import "utils/utils.js" as U
import "utils"
import "tools"
Item {
    id: root
    property var pluginApi: null
    property var pendingPolicy: null

    function capturePolicy(context) {
        context = context || pluginApi?.settingsContext
        if (!context?.current()) return null
        const settings = context.settingsView
        return { context: context, settings: settings }
    }
    function captureAction(runtimeApi) {
        const api = runtimeApi || pluginApi
        const policy = capturePolicy(api?.settingsContext)
        if (!policy) return null
        policy.api = api
        return policy
    }
    function showResult(policy) {
        if (!policy?.context.current()) return
        policy.api.withCurrentScreen(screen => {
            if (policy.context.current()) policy.api.openPanel(screen)
        })
    }
    readonly property string _scriptsDir: Qt.resolvedUrl("scripts/").toString().replace("file://", "")
    readonly property string _home: Quickshell.env("HOME")
    property bool   isRunning:              false
    property string activeTool:             ""
    property string pendingLangStr:         "eng"
    property string pendingRecordFormat:    "gif"
    property bool   pendingRecordAudioOut:  false
    property bool   pendingRecordAudioIn:   false
    property bool   pendingRecordCursor:    false
    property string pendingTool:            ""
    property var    installedLangs:         []
    property bool   transAvailable:         false
    property string detectedRecorder:       ""
    readonly property string detectedCompositor: CompositorService.isHyprland ? "hyprland"
                                                 : CompositorService.isNiri   ? "niri" : "other"
    readonly property bool isNiri:     CompositorService.isNiri
    readonly property bool isHyprland: CompositorService.isHyprland
    readonly property string resultHex:        colorPickerOverlay.resultHex
    readonly property string resultRgb:        colorPickerOverlay.resultRgb
    readonly property string resultHsv:        colorPickerOverlay.resultHsv
    readonly property string resultHsl:        colorPickerOverlay.resultHsl
    readonly property string colorCapturePath: colorPickerOverlay.colorCapturePath
    readonly property int    colorCacheBust:   colorPickerOverlay.colorCacheBust
    readonly property var    colorHistory:     colorPickerOverlay.colorHistory
    readonly property string ocrResult:        ocrOverlay.ocrResult
    readonly property string ocrCapturePath:   ocrOverlay.ocrCapturePath
    readonly property string translateResult:  ocrOverlay.translateResult
    readonly property string qrResult:         qrOverlay.qrResult
    readonly property string qrCapturePath:    qrOverlay.qrCapturePath
    readonly property var    paletteColors:    paletteOverlay.paletteColors
    readonly property string recordState:  recordOverlay?.recordState  ?? ""
    readonly property string recordFormat: recordOverlay?.format       ?? "gif"
    readonly property string recordPath:   recordOverlay?.gifPath      ?? ""
    readonly property bool   mirrorVisible: mirrorOverlay.isVisible
    readonly property bool   hasPins:       pinOverlay.hasPins
    readonly property var mainInstance: pluginApi?.mainInstance ?? null
    property int    _regionX:      0
    property int    _regionY:      0
    property int    _regionW:      0
    property int    _regionH:      0
    property var    _regionScreen: null
    property bool   _capsDetected:   false
    property bool   _sessionChecked: false
    property var    _detectedLangs:  []
    property string _grimGeometry: ""
    property int    _grimX:        0
    property int    _grimY:        0
    property int    _grimW:        0
    property int    _grimH:        0
    property int    _grimLocalX:   0
    property int    _grimLocalY:   0
    Component.onCompleted: {
        root.isRunning  = false
        root.activeTool = ""
        Logger.i("ScreenToolkit", "Scripts dir: " + root._scriptsDir)
        if (!_capsDetected) {
            detectCapabilities()
            _capsDetected = true
        }
    }
    onPluginApiChanged: {
        _checkSession()
    }
    Connections {
        target: TempPaths
        function onReadyChanged() { root._checkSession() }
    }
    ToolProcess {
        id: sessionCheckProc
        stdout: StdioCollector {}
        onExited: code => {
            if (code !== 0) {
                root._sessionChecked = false
                Logger.w("ScreenToolkit", "Could not initialize runtime session marker")
                return
            }
            var isNewBoot = sessionCheckProc.stdout.text.trim() === "new"
            if (isNewBoot) _clearStaleResults()
            else           _restoreSavedState()
        }
    }
    function _checkSession() {
        if (!pluginApi || !TempPaths.ready || root._sessionChecked) return
        root._sessionChecked = true
        sessionCheckProc.exec({ command: ["bash", "-c",
            "boot=$(cat /proc/sys/kernel/random/boot_id) || exit 1; " +
            "prior=$(cat -- \"$1\" 2>/dev/null); " +
            "[ \"$prior\" = \"$boot\" ] && echo 'exists' || echo 'new'; " +
            "printf '%s\\n' \"$boot\" > \"$1\"",
            "screen-toolkit-session", TempPaths.path("session")
        ]})
    }
    function _clearStaleResults() {
        if (!pluginApi) return
        var s = pluginApi.pluginSettings
        s.resultHex        = ""; s.resultRgb        = ""
        s.resultHsv        = ""; s.resultHsl        = ""
        s.colorCapturePath = ""; s.colorCacheBust   = 0
        s.ocrResult        = ""; s.ocrCapturePath   = ""
        s.qrResult         = ""; s.qrCapturePath    = ""
        s.paletteColors    = []; s.translateResult  = ""
        pluginApi.saveSettings()
        colorPickerOverlay.clearResults()
        ocrOverlay.clearResults()
        qrOverlay.clearResults()
        paletteOverlay.clearResults()
        colorPickerOverlay.colorHistory = pluginApi.pluginSettings.colorHistory || []
    }
    function clearColorResult() {
    colorPickerOverlay.clearResults()
    if (pluginApi) {
        pluginApi.pluginSettings.resultHex        = ""
        pluginApi.pluginSettings.resultRgb        = ""
        pluginApi.pluginSettings.resultHsv        = ""
        pluginApi.pluginSettings.resultHsl        = ""
        pluginApi.pluginSettings.colorCapturePath = ""
        pluginApi.pluginSettings.colorCacheBust   = 0
        pluginApi.saveSettings()
    }
}
function clearColorHistory() {
    colorPickerOverlay.colorHistory = []
    if (pluginApi) { pluginApi.pluginSettings.colorHistory = []; pluginApi.saveSettings() }
}
function clearOcrResult() {
    ocrOverlay.clearResults()
    if (pluginApi) {
        pluginApi.pluginSettings.ocrResult      = ""
        pluginApi.pluginSettings.ocrCapturePath = ""
        pluginApi.saveSettings()
    }
}
function clearQrResult() {
    qrOverlay.clearResults()
    if (pluginApi) {
        pluginApi.pluginSettings.qrResult      = ""
        pluginApi.pluginSettings.qrCapturePath = ""
        pluginApi.saveSettings()
    }
}
function clearPaletteResult() {
    paletteOverlay.clearResults()
    if (pluginApi) { pluginApi.pluginSettings.paletteColors = []; pluginApi.saveSettings() }
}
    function _restoreSavedState() {
        if (!pluginApi) return
        var s = pluginApi.pluginSettings
        colorPickerOverlay.loadState(s)
        ocrOverlay.loadState(s)
        qrOverlay.loadState(s)
        paletteOverlay.loadState(s)
        colorPickerOverlay.colorHistory = s.colorHistory || []
    }
    Connections {
        target: recordOverlay
        function onRecordStateChanged() {
            if (!pluginApi) return
            const policy = recordOverlay.actionPolicy
            if (!policy?.context.current()) return
            var skipConfirm = policy.settings.recordSkipConfirmation ?? false
            var toClipboard = policy.settings.recordCopyToClipboard ?? false
            if (recordOverlay.recordState === "converting" && !skipConfirm && !toClipboard) {
                var screen = recordOverlay._primaryScreen
                if (screen) policy.api.openPanel(screen)
                else showResult(policy)
            }
        }
        function onDismissed() {
            if (root.activeTool === "record") root.activeTool = ""
        }
    }
    Connections {
        target: colorPickerOverlay
        function onDone() {
            root.isRunning  = false
            if (!colorPickerOverlay.actionPolicy?.context.current()) { root.activeTool = ""; return }
            root.activeTool = "colorpicker"
            root.showResult(colorPickerOverlay.actionPolicy)
        }
        function onFailed() {
            root.isRunning  = false
            root.activeTool = ""
            ToastService.showError(pluginApi?.tr("messages.picker-cancelled"))
        }
    }
    Connections {
        target: ocrOverlay
        function onDone() {
            root.isRunning  = false
            if (!ocrOverlay.actionPolicy?.context.current()) { root.activeTool = ""; return }
            root.activeTool = "ocr"
            root.showResult(ocrOverlay.actionPolicy)
        }
        function onFailed(messageKey, messageArg) {
            root.isRunning  = false
            root.activeTool = ""
            var template = pluginApi?.tr(messageKey)
            var msg = messageArg !== "" ? template.replace("{dep}", messageArg) : template
            ToastService.showError(msg)
        }
    }
    Connections {
        target: qrOverlay
        function onDone() {
            root.isRunning  = false
            if (!qrOverlay.actionPolicy?.context.current()) { root.activeTool = ""; return }
            root.activeTool = "qr"
            root.showResult(qrOverlay.actionPolicy)
        }
        function onFailed() {
            root.isRunning  = false
            root.activeTool = ""
            ToastService.showError(pluginApi?.tr("messages.no-qr"))
        }
    }
    Connections {
        target: lensOverlay
        function onDone() {
            root.isRunning  = false
            root.activeTool = ""
        }
        function onFailed(messageKey, messageArg) {
            root.isRunning  = false
            root.activeTool = ""
            var template = pluginApi?.tr(messageKey)
            var msg = messageArg !== "" ? template.replace("{dep}", messageArg) : template
            ToastService.showError(msg)
        }
    }
    Connections {
        target: paletteOverlay
        function onDone() {
            root.isRunning  = false
            if (!paletteOverlay.actionPolicy?.context.current()) { root.activeTool = ""; return }
            root.activeTool = "palette"
            root.showResult(paletteOverlay.actionPolicy)
        }
        function onFailed() {
            root.isRunning  = false
            root.activeTool = ""
            ToastService.showError(pluginApi?.tr("messages.palette-failed"))
        }
    }
    RegionSelector {
        id: regionSelector
        pluginApi: root.pluginApi
        onRegionSelected: (x, y, w, h, screen) => {
            if (!root.pendingPolicy?.context.current()) {
                root.isRunning = false
                return
            }
            root._regionX      = x; root._regionY = y
            root._regionW      = w; root._regionH = h
            root._regionScreen = screen
            var scale          = screen?.devicePixelRatio ?? 1.0
            var sx             = screen?.x ?? 0
            var sy             = screen?.y ?? 0
            root._grimX        = sx + Math.round(x / scale)
            root._grimY        = sy + Math.round(y / scale)
            root._grimW        = Math.round(w / scale)
            root._grimH        = Math.round(h / scale)
            root._grimLocalX   = Math.round(x / scale)
            root._grimLocalY   = Math.round(y / scale)
            root._grimGeometry = root._grimX + "," + root._grimY + " " + root._grimW + "x" + root._grimH
            _dispatchPendingTool()
        }
        onCancelled: {
            root.isRunning  = false
            root.activeTool = ""
        }
    }
    Annotate      { id: annotateOverlay;      mainInstance: root }
    Measure       { id: measureOverlay;       mainInstance: root }
    Pin           { id: pinOverlay;           pluginApi: root.pluginApi }
    Record        { id: recordOverlay;        pluginApi: root.pluginApi }
    Mirror { id: mirrorOverlay; pluginApi: root.pluginApi; scriptsDir: root._scriptsDir }
    ColorPicker   { id: colorPickerOverlay;   pluginApi: root.pluginApi; scriptsDir: root._scriptsDir }
    Ocr           { id: ocrOverlay;           pluginApi: root.pluginApi; scriptsDir: root._scriptsDir }
    Qr            { id: qrOverlay;            pluginApi: root.pluginApi; scriptsDir: root._scriptsDir }
    Lens          { id: lensOverlay;          pluginApi: root.pluginApi; scriptsDir: root._scriptsDir }
    Palette       { id: paletteOverlay;       pluginApi: root.pluginApi; scriptsDir: root._scriptsDir }
    ToolProcess {
        id: detectLangsProc
        stdout: StdioCollector {}
        onExited: {
            var lines = detectLangsProc.stdout.text.trim().split("\n")
            root._detectedLangs = []
            for (var i = 0; i < lines.length; i++) {
                var lang = lines[i].trim()
                if (lang === "" || lang === "osd" || lang === "equ") continue
                if (!root._detectedLangs.includes(lang))
                    root._detectedLangs.push(lang)
            }
            if (pluginApi && root._detectedLangs.length > 0) {
                pluginApi.pluginSettings.installedLangs = root._detectedLangs.slice()
                pluginApi.saveSettings()
            }
            if (root._detectedLangs.length > 0)
                root.installedLangs = root._detectedLangs.slice()
        }
    }
    ToolProcess {
        id: detectTransProc
        stdout: StdioCollector {}
        onExited: {
            var path = detectTransProc.stdout.text.trim()
            if (pluginApi) {
                pluginApi.pluginSettings.transAvailable = path !== "" && path.startsWith("/")
                pluginApi.saveSettings()
            }
            root.transAvailable = path !== "" && path.startsWith("/")
        }
    }
    ToolProcess {
        id: detectRecorderProc
        stdout: StdioCollector {}
        onExited: {
            var path = detectRecorderProc.stdout.text.trim()
            if (pluginApi) {
                pluginApi.pluginSettings.detectedRecorder =
                    path.endsWith("wl-screenrec") ? "wl-screenrec" :
                    path.endsWith("wf-recorder")  ? "wf-recorder"  : ""
                pluginApi.saveSettings()
            }
            root.detectedRecorder =
                path.endsWith("wl-screenrec") ? "wl-screenrec" :
                path.endsWith("wf-recorder")  ? "wf-recorder"  : ""
        }
    }
    ToolProcess {
        id: annotateProc
        property var actionPolicy: null
        onExited: (code) => {
            root.isRunning = false
            const policy = actionPolicy
            if (!policy?.context.current()) return
            if (code === 0) {
                root.activeTool = ""
                var region = annotateRegionState._pendingRegion
                var screen = annotateRegionState._pendingScreen
                annotateRegionState._pendingRegion = ""
                annotateRegionState._pendingScreen = null
                policy.api.withCurrentScreen(s => {
                    if (!policy.context.current()) return
                    policy.api.closePanel(s)
                    annotateOverlay.parseAndShow(region, TempPaths.path("screen-toolkit-annotate.png"), screen, policy)
                })
            } else {
                root.activeTool = ""
                ToastService.showError(pluginApi.tr("messages.capture-failed"))
            }
        }
    }
    QtObject {
        id: annotateRegionState
        property string _pendingRegion: ""
        property var    _pendingScreen: null
    }
    ToolProcess {
        id: annotateWinProc
        property var actionPolicy: null
        stdout: StdioCollector {}
        onExited: (code) => {
            root.isRunning = false
            const policy = actionPolicy
            if (!policy?.context.current()) return
            var geomStr = annotateWinProc.stdout.text.trim()
            if (code !== 0 || geomStr === "") {
                root.activeTool = ""
                ToastService.showError(pluginApi.tr("messages.capture-failed"))
                return
            }
            var parts = geomStr.split(" ")
            if (parts.length < 2) { root.activeTool = ""; return }
            var xy = parts[0].split(",")
            var wh = parts[1].split("x")
            var gx = parseInt(xy[0]) || 0
            var gy = parseInt(xy[1]) || 0
            var gw = parseInt(wh[0]) || 400
            var gh = parseInt(wh[1]) || 300
            var screen    = root._findScreenForPoint(gx, gy)
            var regionStr = (gx - (screen?.x ?? 0)) + "," + (gy - (screen?.y ?? 0)) + " " + gw + "x" + gh
            root.activeTool = ""
            policy.api.withCurrentScreen(s => {
                if (!policy.context.current()) return
                policy.api.closePanel(s)
                annotateOverlay.parseAndShow(regionStr, TempPaths.path("screen-toolkit-annotate.png"), screen, policy)
            })
        }
    }
    ToolProcess {
        id: pinGrimProc
        property var actionPolicy: null
        stdout: StdioCollector {}
        onExited: (code) => {
            root.isRunning = false
            if (!actionPolicy?.context.current()) return
            var output = pinGrimProc.stdout.text.trim()
            if (code === 0 && output !== "") {
                var parts = output.split("|")
                if (parts.length === 2) {
                    var imgPath = parts[0]
                    var wh  = parts[1].split("x")
                    var pw  = parseInt(wh[0]) || 400
                    var ph  = parseInt(wh[1]) || 300
                    pinOverlay.addPin(imgPath, pw, ph, root._regionScreen)
                    ToastService.showNotice(pluginApi.tr("messages.pinned"))
                }
            } else if (code !== 0) {
                ToastService.showError(pluginApi.tr("messages.capture-failed"))
            }
        }
    }
    ToolProcess {
        id: pinFileProc
        property var actionPolicy: null
        stdout: StdioCollector {}
        onExited: (code) => {
            if (!actionPolicy?.context.current()) return
            var path = pinFileProc.stdout.text.trim()
            if (code === 0 && path !== "") {
                pinOverlay.addPin(path, 600, 400, root._regionScreen)
                ToastService.showNotice(pluginApi.tr("messages.pinned"))
            } else if (code === 2) {
                ToastService.showError(pluginApi.tr("messages.no-file-picker"))
            }
        }
    }
    ToolProcess { id: clipProc }
    Timer {
        id: launchColorPicker
        property var actionPolicy: null
        interval: 220; repeat: false
        onTriggered: { if (actionPolicy?.context.current()) colorPickerOverlay.run(actionPolicy); else root.isRunning = false }
    }
    Timer {
        id: launchOcr
        property var actionPolicy: null
        interval: 50; repeat: false
        onTriggered: { if (actionPolicy?.context.current()) ocrOverlay.run(root._grimX, root._grimY, root._grimW, root._grimH, root.pendingLangStr, actionPolicy); else root.isRunning = false }
    }
    Timer {
        id: launchQr
        property var actionPolicy: null
        interval: 50; repeat: false
        onTriggered: { if (actionPolicy?.context.current()) qrOverlay.run(root._grimGeometry, actionPolicy); else root.isRunning = false }
    }
    Timer {
        id: launchLens
        property var actionPolicy: null
        interval: 50; repeat: false
        onTriggered: { if (actionPolicy?.context.current()) lensOverlay.run(root._grimX, root._grimY, root._grimW, root._grimH, actionPolicy); else root.isRunning = false }
    }
    Timer {
        id: launchAnnotate
        property var actionPolicy: null
        interval: 50; repeat: false
        onTriggered: {
            if (!actionPolicy?.context.current()) { root.isRunning = false; return }
            annotateProc.actionPolicy = actionPolicy
            var regionStr = root._grimLocalX + "," + root._grimLocalY + " " + root._grimW + "x" + root._grimH
            annotateRegionState._pendingRegion = regionStr
            annotateRegionState._pendingScreen = root._regionScreen
            annotateProc.exec({ command: ["bash", "-c",
                "grim -g \"" + root._grimGeometry + "\" " + TempPaths.shellPath("screen-toolkit-annotate.png") + " 2>/dev/null"
            ]})
        }
    }
    Timer {
        id: launchAnnotateActiveWindow
        property var actionPolicy: null
        interval: 360; repeat: false
        onTriggered: {
            if (!actionPolicy?.context.current()) { root.isRunning = false; return }
            annotateWinProc.actionPolicy = actionPolicy
            annotateWinProc.exec({ command: [root._scriptsDir + "capture.sh", "annotate-window"] })
        }
    }
    Timer {
        id: launchAnnotateFullscreen
        property var actionPolicy: null
        interval: 380; repeat: false
        property var targetScreen: null
        onTriggered: {
            if (!actionPolicy?.context.current()) { root.isRunning = false; return }
            annotateProc.actionPolicy = actionPolicy
            var name = targetScreen?.name ?? ""
            annotateProc.exec({ command: name !== ""
                ? ["grim", "-o", name, TempPaths.path("screen-toolkit-annotate.png")]
                : ["grim", TempPaths.path("screen-toolkit-annotate.png")]
            })
        }
    }
    Timer {
        id: launchPin
        property var actionPolicy: null
        interval: 50; repeat: false
        onTriggered: {
            if (!actionPolicy?.context.current()) { root.isRunning = false; return }
            pinGrimProc.actionPolicy = actionPolicy
            pinGrimProc.exec({ command: [root._scriptsDir + "capture.sh", "pin", root._grimGeometry] })
        }
    }
    Timer {
        id: launchPinFile
        property var actionPolicy: null
        interval: 200; repeat: false
        onTriggered: {
            if (!actionPolicy?.context.current()) return
            pinFileProc.actionPolicy = actionPolicy
            pinFileProc.exec({ command: [root._scriptsDir + "pick-file.sh"] })
        }
    }
    Timer {
        id: launchPalette
        property var actionPolicy: null
        interval: 50; repeat: false
        onTriggered: { if (actionPolicy?.context.current()) paletteOverlay.run(root._grimGeometry, actionPolicy); else root.isRunning = false }
    }
    Timer {
        id: launchRecord
        property var actionPolicy: null
        interval: 50; repeat: false
        onTriggered: {
            if (!actionPolicy?.context.current()) { root.isRunning = false; return }
            root.isRunning  = false
            root.activeTool = "record"
            recordOverlay.startRecording(
                root._grimGeometry, root.pendingRecordFormat,
                root.pendingRecordAudioOut, root.pendingRecordAudioIn,
                root.pendingRecordCursor, root._grimLocalX, root._grimLocalY,
                root._regionScreen, actionPolicy
            )
        }
    }
    Timer {
        id: launchRecordFullscreen
        property var actionPolicy: null
        interval: 50; repeat: false
        property var targetScreen: null
        onTriggered: {
            if (!actionPolicy?.context.current()) { root.isRunning = false; return }
            var screen = targetScreen ?? Quickshell.screens[0] ?? null
            if (!screen) return
            var scale  = screen.devicePixelRatio ?? 1.0
            var region = screen.x + "," + screen.y + " " +
                         Math.round(screen.width * scale) + "x" +
                         Math.round(screen.height * scale)
            root.isRunning  = false
            root.activeTool = "record"
            recordOverlay.startRecording(
                region, root.pendingRecordFormat,
                root.pendingRecordAudioOut, root.pendingRecordAudioIn,
                root.pendingRecordCursor, 0, 0, screen, actionPolicy
            )
        }
    }
    Timer {
        id: launchRegionSelector
        property var actionPolicy: null
        interval: 220; repeat: false
        property var targetScreen: null
        onTriggered: { if (actionPolicy?.context.current()) regionSelector.show(targetScreen); else root.isRunning = false }
    }
    function _dispatchPendingTool() {
        for (const timer of [launchOcr, launchQr, launchLens, launchAnnotate, launchPin, launchPalette, launchRecord])
            timer.actionPolicy = root.pendingPolicy
        switch (root.pendingTool) {
            case "ocr":      launchOcr.start();      break
            case "qr":       launchQr.start();       break
            case "lens":     launchLens.start();     break
            case "annotate": launchAnnotate.start(); break
            case "pin":      launchPin.start();      break
            case "palette":  launchPalette.start();  break
            case "record":   launchRecord.start();   break
            default:
                Logger.w("ScreenToolkit", "unknown pendingTool: " + root.pendingTool)
                root.isRunning = false
        }
    }
    function copyToClipboard(text) {
        if (!text || text === "") return
        clipProc.exec({ command: ["bash", "-c",
            "printf '%s' " + U.shellEscape(text) + " | wl-copy 2>/dev/null"] })
    }
    function closeThenLaunch(timer, policy) {
        if (!policy?.context.current()) return
        timer.actionPolicy = policy
        policy.api.withCurrentScreen(screen => {
            if (!policy.context.current()) { root.isRunning = false; return }
            if (timer === launchRegionSelector) launchRegionSelector.targetScreen = screen
            policy.api.closePanel(screen)
            timer.start()
        })
    }
    function runTranslate(text, targetLang) {
        ocrOverlay.runTranslate(text, targetLang)
    }
    function runColorPicker(runtimeApi) {
        if (root.isRunning) return
        const policy = captureAction(runtimeApi)
        if (!policy) return
        root.isRunning  = true
        root.activeTool = ""
        colorPickerOverlay.clearResults()
        closeThenLaunch(launchColorPicker, policy)
    }
    function runOcr(langStr, runtimeApi) {
        if (root.isRunning) return
        root.pendingLangStr = (langStr && langStr !== "") ? langStr : "eng"
        _runSlurpTool("ocr", runtimeApi)
    }
    function runQr(runtimeApi)       { _runSlurpTool("qr", runtimeApi)      }
    function runLens(runtimeApi)     { _runSlurpTool("lens", runtimeApi)     }
    function runAnnotate(runtimeApi) { _runSlurpTool("annotate", runtimeApi) }
    function _findScreenForPoint(gx, gy) {
        var screens = Quickshell.screens
        for (var i = 0; i < screens.length; i++) {
            var s = screens[i]
            if (gx >= s.x && gx < s.x + s.width && gy >= s.y && gy < s.y + s.height)
                return s
        }
        return root._regionScreen ?? (screens.length > 0 ? screens[0] : null)
    }
    function runAnnotateFullscreen(runtimeApi) {
        if (root.isRunning || annotateOverlay.busy) return
        const policy = captureAction(runtimeApi)
        if (!policy) return
        root.isRunning = true
        launchAnnotateFullscreen.actionPolicy = policy
        policy.api.withCurrentScreen(screen => {
            if (!policy.context.current()) { root.isRunning = false; return }
            policy.api.closePanel(screen)
            root._regionScreen = screen
            root._regionX = 0; root._regionY = 0
            root._regionW = Math.round(screen.width  * (screen.devicePixelRatio ?? 1.0))
            root._regionH = Math.round(screen.height * (screen.devicePixelRatio ?? 1.0))
            annotateRegionState._pendingRegion = "0,0 " + screen.width + "x" + screen.height
            annotateRegionState._pendingScreen = screen
            launchAnnotateFullscreen.targetScreen = screen
            launchAnnotateFullscreen.start()
        })
    }
    function runAnnotateActiveWindow(runtimeApi) {
        if (root.isRunning || annotateOverlay.busy) return
        const policy = captureAction(runtimeApi)
        if (!policy) return
        root.isRunning = true
        launchAnnotateActiveWindow.actionPolicy = policy
        policy.api.withCurrentScreen(screen => {
            if (!policy.context.current()) { root.isRunning = false; return }
            policy.api.closePanel(screen)
            root._regionScreen = screen
            launchAnnotateActiveWindow.start()
        })
    }
    function runPalette(runtimeApi) {
        if (root.isRunning) return
        _runSlurpTool("palette", runtimeApi)
    }
    function runPin(runtimeApi) { _runSlurpTool("pin", runtimeApi) }
    function runPinFromFile(runtimeApi) {
        const policy = captureAction(runtimeApi)
        if (!policy) return
        closeThenLaunch(launchPinFile, policy)
    }
    function pinFile(path, screen) {
        if (!path || path === "") return
        pinOverlay.addPin(path, 600, 400, screen)
    }
    function runMeasure(runtimeApi) {
        if (root.isRunning) return
        const policy = captureAction(runtimeApi)
        if (!policy) return
        root.activeTool = "measure"
        policy.api.withCurrentScreen(screen => { if (policy.context.current()) policy.api.closePanel(screen) })
        measureOverlay.show(policy)
    }
    function runRecordStop()    { recordOverlay.stopRecording() }
    function runRecordSave()    { recordOverlay._saveToFile() }
    function runRecordDiscard() { recordOverlay.dismiss() }
    function runRecord(format, audioOut, audioIn, cursor, runtimeApi) {
        if (root.isRunning || recordOverlay.isRecording || recordOverlay.isConverting) return
        root.pendingRecordFormat   = format   || "gif"
        root.pendingRecordAudioOut = audioOut === true
        root.pendingRecordAudioIn  = audioIn  === true
        root.pendingRecordCursor   = cursor   === true
        _runSlurpTool("record", runtimeApi)
    }
    function runRecordFullscreen(format, audioOut, audioIn, cursor, runtimeApi) {
        if (root.isRunning || recordOverlay.isRecording || recordOverlay.isConverting) return
        const policy = captureAction(runtimeApi)
        if (!policy) return
        root.pendingRecordFormat   = format   || "gif"
        root.pendingRecordAudioOut = audioOut === true
        root.pendingRecordAudioIn  = audioIn  === true
        root.pendingRecordCursor   = cursor   === true
        launchRecordFullscreen.actionPolicy = policy
        root.isRunning = true
        policy.api.withCurrentScreen(screen => {
            if (!policy.context.current()) { root.isRunning = false; return }
            root.activeTool = "record"
            policy.api.closePanel(screen)
            launchRecordFullscreen.targetScreen = screen
            launchRecordFullscreen.start()
        })
    }
    function runMirror(runtimeApi) {
        const policy = captureAction(runtimeApi)
        if (!policy) return
        policy.api.withCurrentScreen(screen => {
            if (!policy.context.current()) return
            policy.api.closePanel(screen)
            if (!mirrorOverlay.isVisible) mirrorOverlay.show(screen, policy)
        })
    }
    function runMirrorClose() { mirrorOverlay.hide() }
    function _runSlurpTool(tool, runtimeApi) {
        if (root.isRunning || tool === "annotate" && annotateOverlay.busy) return
        const policy = captureAction(runtimeApi)
        if (!policy) return
        root.pendingPolicy = policy
        root.pendingTool = tool
        root.isRunning   = true
        closeThenLaunch(launchRegionSelector, policy)
    }
    function detectCapabilities() {
        root._detectedLangs = []
        detectLangsProc.exec({ command:    ["bash", "-c", "tesseract --list-langs 2>/dev/null | tail -n +2"] })
        detectTransProc.exec({ command:    ["bash", "-c", "which trans 2>/dev/null"] })
        detectRecorderProc.exec({ command: ["bash", "-c", "which wl-screenrec 2>/dev/null || which wf-recorder 2>/dev/null"] })
    }
    function annotateScreenshotCmd(overlayTmpFile) {
        var dir   = U.screenshotDir(root._home, annotateOverlay.actionPolicy?.settings.screenshotPath)
        var fname = U.buildFilename("annotate", ".png", annotateOverlay.actionPolicy?.settings.filenameFormat)
        var dest  = dir + "/" + fname
        return "mkdir -p " + U.shellEscape(dir) + " && " +
               "magick " + TempPaths.shellPath("screen-toolkit-annotate.png") + " " + U.shellEscape(overlayTmpFile) +
               " -composite " + U.shellEscape(dest) + " && " +
               "rm -f " + U.shellEscape(overlayTmpFile) + " && " +
               "echo " + U.shellEscape(dest)
    }
    function annotateScreenshotZoomCmd(imgPath) {
        var dir   = U.screenshotDir(root._home, annotateOverlay.actionPolicy?.settings.screenshotPath)
        var fname = U.buildFilename("annotate", ".png", annotateOverlay.actionPolicy?.settings.filenameFormat)
        var dest  = dir + "/" + fname
        return "mkdir -p " + U.shellEscape(dir) + " && " +
               "cp " + U.shellEscape(imgPath) + " " + U.shellEscape(dest) + " && " +
               "echo " + U.shellEscape(dest)
    }
    IpcHandler {
        target: "plugin:screen-toolkit"
        function toggle()              { if (pluginApi) pluginApi.withCurrentScreen(screen => pluginApi.togglePanel(screen)) }
        function mirror()              { root.runMirror() }
        function measure()             { root.runMeasure() }
        function colorPicker()         { root.runColorPicker() }
        function annotate()            { root.runAnnotate() }
        function annotateFullscreen()  { root.runAnnotateFullscreen() }
        function annotateWindow()      { if (root.isHyprland) root.runAnnotateActiveWindow() }
        function pin()                 { root.runPin() }
        function pinImage()            { root.runPinFromFile() }
        function ocr()                 { root.runOcr(pluginApi?.pluginSettings?.selectedOcrLang || "eng") }
        function qr()                  { root.runQr() }
        function palette()             { root.runPalette() }
        function lens()                { root.runLens() }
        function record()              { root.runRecord("gif") }
        function recordMp4()           { root.runRecord("mp4") }
        function recordFullscreen()    { root.runRecordFullscreen("gif") }
        function recordFullscreenMp4() { root.runRecordFullscreen("mp4") }
        function recordStop()          { if (recordOverlay.isRecording) recordOverlay.stopRecording() }
    }
}
