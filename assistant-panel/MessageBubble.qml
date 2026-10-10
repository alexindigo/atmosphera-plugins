import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

Item {
  id: root
  property var message
  property var pluginApi

  readonly property int bubblePadding: Style.marginM

  signal regenerateRequested
  signal copyRequested(string text)
  signal editRequested(string id, string newText)

  property bool isEditing: false
  property string editBuffer: ""

  height: mainLayout.implicitHeight
  width: parent ? parent.width : 400

  // ---------------------------------------------------------
  // User Row Hover Logic
  // ---------------------------------------------------------
  // This MouseArea covers the entire row (full width) for User messages.
  // It sits in the background (z: 0) to allow buttons/text selection on top to work.
  MouseArea {
    id: userHoverArea
    visible: message.role === "user"
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton // Pass clicks through
    z: 0
  }

  RowLayout {
    id: mainLayout
    // Ensure layout sits above the background hover detection
    z: 1

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    spacing: Style.marginS

    // ---------------------------------------------------------
    // Left Side Items (Assistant Avatar & Spacer for User)
    // ---------------------------------------------------------

    AtmoIcon {
      Layout.alignment: Qt.AlignTop
      visible: message.role === "assistant"
      icon: "sparkles"
      color: AtmoColor.mPrimary
      pointSize: Style.fontSizeL
      applyUiScale: false
    }

    Item {
      visible: message.role === "user"
      Layout.fillWidth: true
    }

    // ---------------------------------------------------------
    // Message Bubble
    // ---------------------------------------------------------
    Rectangle {
      id: bubbleRect

      Layout.maximumWidth: parent.width * 0.8
      Layout.preferredWidth: root.isEditing ? (parent.width * 0.8) : (contentCol.implicitWidth + (root.bubblePadding * 2))
      Layout.preferredHeight: contentCol.implicitHeight + (root.bubblePadding * 2)

      color: message.role === "user" ? AtmoColor.mSurfaceVariant : AtmoColor.mSurface
      radius: Style.radiusM

      // Sharp Corner Hack for User (Top Right)
      Rectangle {
        visible: message.role === "user"
        anchors.top: parent.top
        anchors.right: parent.right
        width: parent.radius
        height: parent.radius
        color: parent.color
      }

      // ---------------------------------------------------------
      // User Action Buttons (Floating Outside Left)
      // ---------------------------------------------------------
      Row {
        id: userActionButtons
        visible: message.role === "user" && !root.isEditing && (userHoverArea.containsMouse || copyBtnMouse.containsMouse || editBtnMouse.containsMouse)
        z: 2
        spacing: Style.marginXS

        anchors.right: parent.left
        anchors.top: parent.top
        anchors.rightMargin: Style.marginXS

        // Copy Button
        Rectangle {
          width: 28
          height: 28
          radius: 4
          color: copyBtnMouse.containsMouse ? AtmoColor.mSurfaceVariant : "transparent"

          AtmoIcon {
            anchors.centerIn: parent
            icon: "copy"
            pointSize: Style.fontSizeS
            applyUiScale: false
            color: copyBtnMouse.containsMouse ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
          }

          MouseArea {
            id: copyBtnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.copyRequested(message.content)

            ToolTip.visible: containsMouse
            ToolTip.text: pluginApi?.tr("chat.copy") ?? "Copy"
          }
        }

        // Edit Button
        Rectangle {
          width: 28
          height: 28
          radius: 4
          color: editBtnMouse.containsMouse ? AtmoColor.mSurfaceVariant : "transparent"

          AtmoIcon {
            anchors.centerIn: parent
            icon: "pencil"
            pointSize: Style.fontSizeS
            applyUiScale: false
            color: editBtnMouse.containsMouse ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
          }

          MouseArea {
            id: editBtnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.editBuffer = message.content;
              root.isEditing = true;
            }

            ToolTip.visible: containsMouse
            ToolTip.text: pluginApi?.tr("chat.edit") ?? "Edit"
          }
        }
      }

      // ---------------------------------------------------------
      // Bubble Content
      // ---------------------------------------------------------
      ColumnLayout {
        id: contentCol
        z: 2

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.bubblePadding

        spacing: Style.marginM

        TextEdit {
          Layout.maximumWidth: bubbleRect.Layout.maximumWidth - (root.bubblePadding * 2)
          Layout.fillWidth: true
          wrapMode: TextEdit.Wrap

          visible: !root.isEditing
          text: message.content
          textFormat: message.role === "assistant" ? Text.MarkdownText : Text.PlainText
          readOnly: true
          selectByMouse: true

          color: AtmoColor.mOnSurface
          font.family: Settings.data.ui.fontDefault
          // Replicate NText font scaling logic for consistency
          font.pointSize: Math.max(1, Style.fontSizeM * Settings.data.ui.fontDefaultScale * Style.uiScaleRatio)
          font.weight: Style.fontWeightMedium

          selectionColor: AtmoColor.mPrimary
          selectedTextColor: AtmoColor.mOnPrimary

          onLinkActivated: link => Qt.openUrlExternally(link)
        }

        // Edit Area
        ColumnLayout {
          visible: root.isEditing
          Layout.fillWidth: true
          spacing: Style.marginS

          TextArea {
            id: editArea
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(80, contentHeight + 20)
            text: root.editBuffer
            wrapMode: TextEdit.Wrap
            focus: root.isEditing

            color: AtmoColor.mOnSurface
            background: Rectangle {
              color: AtmoColor.mSurface
              radius: Style.radiusS
              border.width: 1
              border.color: editArea.activeFocus ? AtmoColor.mPrimary : "transparent"
            }
          }

          RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Style.marginS

            NButton {
              text: pluginApi?.tr("chat.save")
              backgroundColor: AtmoColor.mPrimary
              textColor: AtmoColor.mOnPrimary
              hoverColor: Qt.lighter(AtmoColor.mPrimary, 1.2)
              textHoverColor: AtmoColor.mOnPrimary
              onClicked: {
                root.isEditing = false;
                if (editArea.text !== message.content) {
                  root.editRequested(message.id, editArea.text);
                }
              }
            }

            NButton {
              text: pluginApi?.tr("chat.cancel")
              backgroundColor: AtmoColor.mSurface
              textColor: AtmoColor.mOnSurface
              hoverColor: Qt.lighter(AtmoColor.mSurface, 1.3)
              textHoverColor: AtmoColor.mOnSurface
              onClicked: root.isEditing = false
            }
          }
        }

        // Assistant Buttons (Bottom)
        RowLayout {
          visible: message.role === "assistant" && !message.isStreaming
          spacing: Style.marginS
          Layout.alignment: Qt.AlignLeft

          // Copy Button
          Rectangle {
            width: 28
            height: 28
            radius: 4
            color: copyMouse.containsMouse ? AtmoColor.mSurfaceVariant : "transparent"

            AtmoIcon {
              anchors.centerIn: parent
              icon: "copy"
              pointSize: Style.fontSizeM
              applyUiScale: false
              color: copyMouse.containsMouse ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
            }

            MouseArea {
              id: copyMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.copyRequested(message.content)
              ToolTip.visible: containsMouse
              ToolTip.text: pluginApi?.tr("chat.copy") ?? "Copy"
            }
          }

          // Regenerate Button
          Rectangle {
            width: 28
            height: 28
            radius: 4
            color: regenMouse.containsMouse ? AtmoColor.mSurfaceVariant : "transparent"

            AtmoIcon {
              anchors.centerIn: parent
              icon: "refresh"
              pointSize: Style.fontSizeM
              applyUiScale: false
              color: regenMouse.containsMouse ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
            }

            MouseArea {
              id: regenMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.regenerateRequested()
              ToolTip.visible: containsMouse
              ToolTip.text: pluginApi?.tr("chat.regenerate") ?? "Regenerate"
            }
          }
        }
      }
    }

    // ---------------------------------------------------------
    // Right Side Items (User Avatar & Spacer for Assistant)
    // ---------------------------------------------------------

    Item {
      visible: message.role === "assistant"
      Layout.fillWidth: true
    }

    AtmoIcon {
      Layout.alignment: Qt.AlignTop
      visible: message.role === "user"
      icon: "user"
      color: AtmoColor.mOnSurfaceVariant
      pointSize: Style.fontSizeL
      applyUiScale: false
    }
  }
}
