import QtQuick
import qs.Widgets

NText {
  required property string status
  required property var translate
  objectName: "spotify-authorization-status"
  text: translate("authorization." + status)
  wrapMode: Text.WordWrap
}
