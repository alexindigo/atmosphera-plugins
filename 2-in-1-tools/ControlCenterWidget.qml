import QtQuick
import Quickshell
import qs.Widgets

AtmoIconButtonHot {
    property ShellScreen screen
    property var pluginApi: null

    readonly property string outputName: screen?.name ?? ""
    readonly property var backend: pluginApi?.mainInstance
    readonly property string currentTransform: backend?.transformForOutput(outputName) ?? "Normal"

    icon: backend?.buttonIconName(pluginApi?.settingsContext) ?? "rotate-cw"
    visible: backend?.buttonVisible(outputName, pluginApi?.settingsContext) ?? false
    enabled: backend?.buttonEnabled(outputName, pluginApi?.settingsContext) ?? false
    tooltipText: backend?.buttonTooltip(outputName, pluginApi?.settingsContext) ?? ("Rotate display · Current: " + (backend?.transformLabel(currentTransform) ?? "Normal"))

    onClicked: backend?.activatePrimaryButton(outputName, pluginApi?.settingsContext)

    Component.onCompleted: backend?.refreshTransform(outputName, pluginApi?.settingsContext)
    onScreenChanged: backend?.refreshTransform(outputName, pluginApi?.settingsContext)
}
