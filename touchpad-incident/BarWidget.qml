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

  readonly property var marker: pluginApi?.mainInstance
  readonly property string resultState: marker ? marker.resultState : "idle"

  baseSize: Style.getCapsuleHeightForScreen(screen ? screen.name : "")
  applyUiScale: false
  customRadius: Style.radiusL
  colorBg: Style.capsuleColor
  colorFg: resultState === "error" ? Color.mError : resultState === "success" ? Color.mPrimary : Color.mOnSurface
  colorBorder: "transparent"
  colorBorderHover: "transparent"
  border.color: Style.capsuleBorderColor
  border.width: Style.capsuleBorderWidth
  enabled: !!marker && marker.canMark

  icon: resultState === "success" ? "pointer-check" : resultState === "error" ? "pointer-x" : "pointer-exclamation"
  tooltipDirection: BarService.getTooltipDirection(screen ? screen.name : "")
  tooltipText: {
    if (!pluginApi)
      return "Touchpad Incident";
    if (!marker)
      return pluginApi.tr("tooltip.unavailable");
    if (marker.busy)
      return pluginApi.tr("tooltip.busy");
    if (marker.coolingDown)
      return pluginApi.tr("tooltip.cooldown");
    return pluginApi.tr("tooltip.mark");
  }

  onClicked: {
    if (marker)
      marker.markIncident();
  }
}
