import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  readonly property var mainInstance: pluginApi?.mainInstance

  property real contentPreferredWidth: 300 * Style.uiScaleRatio
  property real contentPreferredHeight: contentColumn.implicitHeight + Style.marginM * 2

  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      id: contentColumn
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: Style.marginM
      }
      spacing: Style.marginM

      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: boxContent.implicitHeight + Style.marginM * 2

        ColumnLayout {
          id: boxContent
          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Style.marginM
          }
          spacing: Style.marginS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            CloudflareIcon {
              pointSize: Style.fontSizeL
              color: (mainInstance?.warpConnected ?? false) ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
            }

            NText {
              text: pluginApi?.tr("panel.title")
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: AtmoColor.mOnSurface
              Layout.fillWidth: true
            }

            NText {
              text: (mainInstance?.warpConnected ?? false)
                ? pluginApi?.tr("panel.status.connected")
                : pluginApi?.tr("panel.status.disconnected")
              pointSize: Style.fontSizeS
              color: (mainInstance?.warpConnected ?? false) ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
            }
          }

          RowLayout {
            Layout.fillWidth: true
            visible: (mainInstance?.warpMode ?? "") !== ""
            spacing: Style.marginS

            NText {
              text: pluginApi?.tr("panel.mode") + ":"
              pointSize: Style.fontSizeS
              color: AtmoColor.mOnSurfaceVariant
            }

            NText {
              text: mainInstance?.warpMode ?? ""
              pointSize: Style.fontSizeS
              color: AtmoColor.mOnSurface
              font.family: Settings.data.ui.fontFixed
            }
          }

          Rectangle {
            Layout.fillWidth: true
            visible: !(mainInstance?.warpInstalled ?? true)
            Layout.preferredHeight: notInstalledLayout.implicitHeight + Style.marginM * 2
            color: Qt.alpha(AtmoColor.mError, 0.1)
            radius: Style.radiusM
            border.width: Style.borderS
            border.color: Qt.alpha(AtmoColor.mError, 0.3)

            RowLayout {
              id: notInstalledLayout
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: Style.marginS

              AtmoIcon {
                icon: "alert-circle"
                pointSize: Style.fontSizeM
                color: AtmoColor.mError
              }

              NText {
                text: pluginApi?.tr("panel.not-installed")
                pointSize: Style.fontSizeS
                color: AtmoColor.mError
                Layout.fillWidth: true
                wrapMode: Text.Wrap
              }
            }
          }
        }
      }

      NButton {
        Layout.fillWidth: true
        text: (mainInstance?.warpConnected ?? false)
          ? pluginApi?.tr("context.disconnect")
          : pluginApi?.tr("context.connect")
        icon: (mainInstance?.warpConnected ?? false) ? "plug-x" : "plug"
        backgroundColor: (mainInstance?.warpConnected ?? false) ? AtmoColor.mError : AtmoColor.mPrimary
        textColor: (mainInstance?.warpConnected ?? false) ? AtmoColor.mOnError : AtmoColor.mOnPrimary
        enabled: mainInstance?.warpInstalled ?? false

        onClicked: {
          mainInstance?.toggleWarp()
          pluginApi?.closePanel(pluginApi?.panelOpenScreen)
        }
      }
    }
  }
}
