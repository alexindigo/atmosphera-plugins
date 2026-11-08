import QtQuick
import qs.Commons
import qs.Widgets

Rectangle {
  id: root
  property string label: ""
  property color bg: "#888888"
  property color fg: "#FFFFFF"
  width: badgeText.implicitWidth + Style.marginM * 2
  height: badgeText.implicitHeight + Style.marginS * 2
  radius: Style.radiusS
  color: bg
  border.color: Qt.darker(bg, 1.4)
  border.width: Math.max(1, Style.borderS)

  NText {
    id: badgeText
    anchors.centerIn: parent
    text: root.label
    color: root.fg
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
  }
}
