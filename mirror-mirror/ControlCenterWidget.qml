import QtQuick
import Quickshell
import qs.Widgets

AtmoIconButtonHot {
    property ShellScreen screen
    property var pluginApi: null

    icon: "screen-share"
    tooltipText: pluginApi?.tr("widget.tooltip")
    onClicked: {
        if (pluginApi) pluginApi.togglePanel(screen, this);
    }
}
