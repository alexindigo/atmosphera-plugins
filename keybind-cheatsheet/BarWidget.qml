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

  baseSize: Style.getCapsuleHeightForScreen(screen?.name)
  applyUiScale: false
  icon: "keyboard"
  tooltipText: pluginApi?.tr("barwidget.tooltip")
  tooltipDirection: BarService.getTooltipDirection(screen?.name)
  customRadius: Style.radiusL

  colorBg: Style.capsuleColor
  colorFg: AtmoColor.mOnSurface
  colorBgHover: AtmoColor.mHover
  colorFgHover: AtmoColor.mOnHover
  colorBorder: "transparent"
  colorBorderHover: "transparent"

  border.color: Style.capsuleBorderColor
  border.width: Style.capsuleBorderWidth

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": root.pluginApi?.tr("barwidget.open"),
        "action": "open-panel",
        "icon": "keyboard"
      },
      {
        "label": root.pluginApi?.tr("barwidget.settings"),
        "action": "plugin-settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);

      if (action === "open-panel") {
        if (root.pluginApi) {
          root.pluginApi.openPanel(root.screen);
        }
      } else if (action === "plugin-settings") {
        if (root.pluginApi) {
          BarService.openPluginSettings(root.screen, root.pluginApi.manifest);
        }
      }
    }
  }

  onClicked: {
    if (pluginApi) {
      pluginApi.openPanel(screen);
    }
  }

  onRightClicked: {
    PanelService.showContextMenu(contextMenu, root, screen);
  }
}
