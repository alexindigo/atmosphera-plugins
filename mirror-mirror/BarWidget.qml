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

  readonly property bool mirroring: pluginApi?.mainInstance?.mirroringActive ?? false
  readonly property string screenName: screen?.name ?? ""

  baseSize: Style.getCapsuleHeightForScreen(screenName)
  applyUiScale: false
  customRadius: Style.radiusL
  icon: "screen-share"
  tooltipText: mirroring
    ? pluginApi?.tr("bar.tooltip.active")
    : pluginApi?.tr("bar.tooltip.inactive")
  tooltipDirection: BarService.getTooltipDirection(screenName)

  colorBg: mirroring ? AtmoColor.mError : Style.capsuleColor
  colorFg: mirroring ? AtmoColor.mOnError : AtmoColor.mOnSurface
  colorBgHover: mirroring ? AtmoColor.mError : AtmoColor.mHover
  colorFgHover: mirroring ? AtmoColor.mOnError : AtmoColor.mOnHover
  colorBorder: mirroring ? AtmoColor.mError : Style.capsuleBorderColor
  colorBorderHover: mirroring ? AtmoColor.mError : Style.capsuleBorderColor

  onClicked: {
    pluginApi?.openPanel(root.screen, root);
  }
}
