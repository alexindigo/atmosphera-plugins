import QtQuick
import Quickshell.Io
import qs.Services.UI
import QtQml.Models
import Quickshell
import qs.Commons
import qs.Services.Compositor

Item {
    id: root
    property var pluginApi: null
    property bool active: false
    property bool recordingActive: false
    property string target: ""
    property string recordingCheckTarget: ""
    property var recordingCheckPolicy: null
    property var selectorPolicy: null

    function capturePolicy(context) {
        context = context || pluginApi?.settingsContext
        if (!context?.current()) return null
        const settings = context.settingsView
        return { context: context, settings: settings }
    }

    Process {
        id: recordingCheckProc
        command: ["pidof", "wf-recorder"]
        running: false
        onExited: (exitCode) => {
            const requestedTarget = root.recordingCheckTarget
            const policy = root.recordingCheckPolicy
            root.recordingCheckTarget = ""
            root.recordingCheckPolicy = null

            if (requestedTarget === "" || !policy?.context.current()) {
                return
            }

            if (exitCode === 0) {
                root.stopRecording(policy.context, policy)
                return
            }

            root.openSelector(requestedTarget, policy)
        }
    }

    function stopRecording(context, admitted) {
        const policy = admitted || capturePolicy(context)
        if (!policy?.context.current()) return false
        if (!pluginApi?.pluginDir) {
            return
        }

        const recordingNotificationsEnabled = policy.settings.recordingNotifications
                                           ?? pluginApi?.manifest?.metadata?.defaultSettings?.recordingNotifications
                                           ?? true

        recordingActive = false
        const stopArgs = ["bash", pluginApi.pluginDir + "/record.sh"]
        if (recordingNotificationsEnabled) {
            stopArgs.push("--notify")
        }
        stopArgs.push(...buildRecordingNotifyArgs())
        Quickshell.execDetached(stopArgs)
    }

    function buildRecordingNotifyArgs() {
        return [
            "--notify-app", pluginApi?.tr("notify.app.recorder"),
            "--notify-cancelled-title", pluginApi?.tr("notify.recording.cancelledTitle"),
            "--notify-no-region-body", pluginApi?.tr("notify.recording.noRegionBody"),
            "--notify-no-dir-body", pluginApi?.tr("notify.recording.noDirBody"),
            "--notify-stopped-title", pluginApi?.tr("notify.recording.stoppedTitle"),
            "--notify-stopped-body", pluginApi?.tr("notify.recording.stoppedBody"),
            "--notify-starting-title", pluginApi?.tr("notify.recording.startingTitle")
        ]
    }

    function openSelector(target, policy) {
        if (active || !policy?.context.current()) {
            return
        }

        if (CompositorService.isNiri) {
           // Show a notification that Niri is not supported (i18n only)
            pluginApi?.mainInstance?.showToast?.(pluginApi?.tr("notify.screenshot.niriNotSupported"));
           Logger.w("ScreenShot", "Niri is not supported for screenshots.");
           return;
        }

        root.target = target
        root.selectorPolicy = policy
        active = true
    }

    // 存储当前所有屏幕
    property var screens: Quickshell.screens
    readonly property string selectorSource: CompositorService.isSway ? "ScreenShotSway.qml"
                                           : CompositorService.isHyprland ? "ScreenShotHypr.qml"
                                           : "ScreenShot.qml"

    // 使用 Instantiator 管理选择框
    Instantiator {
        id: selectorInstantiator
        active: root.active
        model: Quickshell.screens
        delegate: Loader {
            required property int index
            source: root.selectorSource
            onLoaded: {
                item.pluginApi = root.pluginApi
                item.actionPolicy = root.selectorPolicy
                item.screen = Quickshell.screens[index]
                Logger.d("ScreenShot", (root.target))
                item.target = root.target
                item.closed.connect(() => root.close())
                item.startCapture()
            }
        }
        onObjectAdded: (index, object) => Logger.d("ScreenShot", ("Selector added for screen", index))
        onObjectRemoved: (index, object) => Logger.d("ScreenShot", ("Selector removed for screen", index))
    }

    function open(target, context) {
        return openAdmitted(target, capturePolicy(context))
    }

    // A Panel captures before requesting its own destruction. The subsequent
    // teardown/preflight uses that operation, never a newer effective view.
    function openAdmitted(target, policy) {
        if (!policy?.context.current()) return false
        if (target === "record" || target === "recordsound") {
            if (root.recordingCheckTarget !== "") {
                return
            }

            root.recordingCheckTarget = target
            root.recordingCheckPolicy = policy
            recordingCheckProc.running = true
            return
        }

        root.openSelector(target, policy)
    }

    function close() {
        active = false
        root.target = ""
        root.selectorPolicy = null
    }

    IpcHandler {
        target: "plugin:screen-shot-and-record"
        function screenshot() {
            open("screenshot")
        }

        function search() {
            open("search")
        }

        function ocr() {
            open("ocr")
        }

        function record() {
            open("record")
        }

        function recordsound() {
            open("recordsound")
        }

        function stoprecord() {
            root.stopRecording()
        }
    }
}
