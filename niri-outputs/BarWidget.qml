import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

AtmoIconButton {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property string screenName: screen ? screen.name : ""

    baseSize: Style.getCapsuleHeightForScreen(screenName)
    applyUiScale: false
    icon: "device-desktop"
    tooltipText: pluginApi ? pluginApi.tr("panel.display-configuration") : "Display Configuration"
    tooltipDirection: BarService.getTooltipDirection(screenName)

    colorBg: Style.capsuleColor
    colorFg: AtmoColor.mOnSurface
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth
    colorBorder: "transparent"
    colorBorderHover: "transparent"

    onClicked: pluginApi.openPanel(root.screen, this)
}
