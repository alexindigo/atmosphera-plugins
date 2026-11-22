import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property ShellScreen screen
  property var pluginApi: null
  readonly property var mainInstance: pluginApi?.mainInstance ?? null
  readonly property var settingsConsumer: pluginApi?.settingsContext?.current() ? mainInstance?.settingsConsumerFor(pluginApi.settingsContext) : null
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)
  readonly property bool showBarText: settingsConsumer?.setting("showBarText", true) ?? true
  readonly property color stateColor: settingsConsumer?.connected ? AtmoColor.mPrimary : (settingsConsumer?.connecting ? AtmoColor.mSecondary : AtmoColor.mOnSurfaceVariant)

  implicitWidth: isVertical ? capsuleHeight : Math.round(contentRow.implicitWidth + Style.margin2M)
  implicitHeight: isVertical ? Math.round(contentRow.implicitHeight + Style.margin2M) : capsuleHeight

  onSettingsConsumerChanged: settingsConsumer?.activate(pluginApi)
  Component.onCompleted: settingsConsumer?.activate(pluginApi)

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": pluginApi?.tr("menu.settings"),
        "action": "settings",
        "icon": "settings"
      },
    ]

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "settings" && pluginApi?.manifest)
        BarService.openPluginSettings(screen, pluginApi.manifest);
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusM
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: contentRow
      anchors.centerIn: parent
      spacing: Style.marginXS

      Image {
        property real iconSize: Style.toOdd(root.capsuleHeight * 0.42)

        Layout.preferredWidth: iconSize
        Layout.preferredHeight: iconSize
        source: Qt.resolvedUrl("assets/hermesagent.svg")
        sourceSize.width: iconSize
        sourceSize.height: iconSize
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        opacity: root.settingsConsumer?.sessionActive ? 1.0 : 0.72
      }

      NText {
        visible: root.showBarText && !root.isVertical
        text: root.settingsConsumer?.connecting ? pluginApi?.tr("widget.connecting") : pluginApi?.tr("widget.label")
        pointSize: root.barFontSize
        applyUiScale: false
        color: root.stateColor
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
          pluginApi?.togglePanel(screen, root);
        } else if (mouse.button === Qt.RightButton) {
          PanelService.showContextMenu(contextMenu, root, screen);
        }
      }
      onEntered: TooltipService.show(root, root.settingsConsumer?.statusText ?? "")
      onExited: TooltipService.hide()
    }
  }
}
