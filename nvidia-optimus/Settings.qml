import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Settings view for the NVIDIA Optimus plugin.
Item {
  id: root

  property var pluginApi: null

  implicitHeight: col.implicitHeight

  ColumnLayout {
    id: col
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: Style.marginM

    NText {
      text: root.pluginApi?.tr("settings.title")
      font.weight: Style.fontWeightBold
      pointSize: Style.fontSizeL
      color: AtmoColor.mOnSurface
    }

    NText {
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      pointSize: Style.fontSizeS
      color: AtmoColor.mOnSurfaceVariant
      text: root.pluginApi?.tr("settings.description")
    }

    NText {
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      pointSize: Style.fontSizeXS
      color: AtmoColor.mOnSurfaceVariant
      text: root.pluginApi?.tr("settings.requirements")
    }
  }
}
