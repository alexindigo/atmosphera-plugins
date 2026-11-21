import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

// News Bar Widget Component
Item {
  id: root

  property var pluginApi: null

  // Required properties for bar widgets
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  // Bar positioning properties
  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real barHeight: Style.getBarHeightForScreen(screenName)
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // Configuration
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Get settings from configuration
  readonly property int rollingSpeed: cfg.rollingSpeed || defaults.rollingSpeed || 50
  readonly property int widgetWidth: cfg.widgetWidth || defaults.widgetWidth || 300

  readonly property var settingsConsumer: pluginApi?.mainInstance?.settingsConsumerFor(pluginApi.settingsContext) ?? null
  readonly property var main: settingsConsumer
  readonly property string allNewsText: (main?.newsData ?? []).map((article, index) => "[" + (index + 1) + "] " + (article?.title || "No headline")).join("  \u2022  ")

  readonly property real visualContentWidth: {
    if (isVertical) return root.capsuleHeight;
    return widgetWidth;
  }

  readonly property real visualContentHeight: {
    if (!isVertical) return root.capsuleHeight;
    return root.capsuleHeight * 2;
  }

  readonly property real contentWidth: isVertical ? root.capsuleHeight : visualContentWidth
  readonly property real contentHeight: isVertical ? visualContentHeight : root.capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  function fetchNews() { settingsConsumer?.fetchNews(); }

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    radius: Style.radiusM
    color: mouseArea.containsMouse ? AtmoColor.mHover : Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    // Mouse interaction for main area (not refresh button)
    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      propagateComposedEvents: true

      onClicked: (mouse) => {
        if (mouse.button === Qt.LeftButton) {
          // Open panel
          if (pluginApi) {
            pluginApi.openPanel(root.screen, root);
          }
        } else if (mouse.button === Qt.RightButton) {
          // Open settings on right click
          if (pluginApi) {
            BarService.openPluginSettings(root.screen, pluginApi.manifest);
          }
        }
      }

      onEntered: {
        var tooltip = (main && main.newsData && main.newsData.length > 0)
          ? main.newsData.length + " headlines\nLeft-click to view • Right-click for settings"
          : "Left-click to view • Right-click for settings";
        TooltipService.show(root, tooltip, BarService.getTooltipDirection());
      }

      onExited: {
        TooltipService.hide();
      }
    }

    // Horizontal layout
    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Style.marginS
      anchors.rightMargin: Style.marginS
      spacing: Style.marginXS
      visible: !isVertical

      // News icon
      Text {
        text: "📰"
        font.family: "Noto Color Emoji, sans-serif"
        font.pointSize: root.barFontSize * 1.2
        color: mouseArea.containsMouse ? AtmoColor.mOnHover : AtmoColor.mOnSurface
        Layout.alignment: Qt.AlignVCenter
      }

      // News content with scrolling
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        property string displayText: {
          if (!main) return "Loading..."
          if (main.errorMessage !== "") return main.errorMessage
          if (main.isLoading) return "Loading news..."
          if (!main.newsData || main.newsData.length === 0) return "No news available"
          return allNewsText
        }

        NText {
          id: newsText
          y: (parent.height - height) / 2
          text: parent.displayText
          color: {
            if (main && main.errorMessage !== "") return AtmoColor.mError
            return mouseArea.containsMouse ? AtmoColor.mOnHover : AtmoColor.mOnSurface
          }
          pointSize: root.barFontSize
          applyUiScale: false
          
          x: textAnimation.running ? 0 : (contentWidth > parent.width ? parent.width - contentWidth : 0)
          
          SequentialAnimation {
            id: textAnimation
            running: main && newsText.contentWidth > newsText.parent.width && !main.isLoading && main.errorMessage === ""
            loops: Animation.Infinite
            
            PauseAnimation { duration: 2000 }
            NumberAnimation {
              target: newsText
              property: "x"
              from: 0
              to: -(newsText.contentWidth - newsText.parent.width + 20)
              duration: newsText.contentWidth * rollingSpeed
              easing.type: Easing.Linear
            }
            PauseAnimation { duration: 1000 }
            NumberAnimation {
              target: newsText
              property: "x"
              to: 0
              duration: 500
            }
          }
        }
      }
    }

    // Vertical layout (simplified)
    ColumnLayout {
      anchors.centerIn: parent
      spacing: Style.marginXS
      visible: isVertical

      Text {
        text: "📰"
        font.family: "Noto Color Emoji, sans-serif"
        font.pointSize: root.barFontSize * 1.2
        color: mouseArea.containsMouse ? AtmoColor.mOnHover : AtmoColor.mOnSurface
        Layout.alignment: Qt.AlignHCenter
      }

      NText {
        text: (main && main.newsData && main.newsData.length > 0) ? main.newsData.length.toString() : "?"
        color: mouseArea.containsMouse ? AtmoColor.mOnHover : AtmoColor.mOnSurface
        pointSize: root.barFontSize * 0.65
        applyUiScale: false
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }

}
