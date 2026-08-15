import QtQuick
import Quickshell
import qs.Widgets

AtmoIconButtonHot {
    property ShellScreen screen
    property var pluginApi: null

    icon: "arrow-big-down-lines"
    tooltipText: pluginApi.tr("ccw.tooltip")

    onClicked: pluginApi.togglePanel(screen, this)
}