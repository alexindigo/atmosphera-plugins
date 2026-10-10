import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

RowLayout {
  id: root
  property string label: ""
  property string value: ""

  spacing: Style.marginM

  NText {
    text: root.label
    pointSize: Style.fontSizeS; color: AtmoColor.mOnSurfaceVariant
    Layout.preferredWidth: 120 * Style.uiScaleRatio
  }
  NText {
    text: root.value
    pointSize: Style.fontSizeS; color: AtmoColor.mOnSurface
    Layout.fillWidth: true
  }
}
