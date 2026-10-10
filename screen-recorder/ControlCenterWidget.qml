
import QtQuick
import Quickshell
import qs.Widgets
import qs.Commons

AtmoIconButton {
    property ShellScreen screen
    property var pluginApi: null
    readonly property var mainInstance: pluginApi?.mainInstance

    enabled: mainInstance?.isAvailable ?? false
    icon: "camera-video"
    tooltipText: mainInstance?.buildTooltip()
    colorFg: mainInstance?.isRecording ? AtmoColor.mOnPrimary : (mainInstance?.isReplaying ? AtmoColor.mSecondary : AtmoColor.mPrimary)
    colorBg: mainInstance?.isRecording ? AtmoColor.mPrimary : (mainInstance?.isReplaying ? Qt.alpha(AtmoColor.mSecondary, 0.25) : Style.capsuleColor)
    onClicked: {
        if (pluginApi && pluginApi.mainInstance) {
            pluginApi.mainInstance.toggleRecording();
        }
    }
}
