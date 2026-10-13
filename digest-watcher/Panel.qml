import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen

  // SmartPanel contract (PluginPanelSlot reads these)
  readonly property real contentPreferredWidth: 460
  readonly property real contentPreferredHeight: Math.min(600, column.implicitHeight + Style.margin2L)

  property var index: ({ "maxMtime": 0, "count": 0, "entries": [] })

  function markSeen() {
    if (pluginApi && pluginApi.pluginSettings && index.maxMtime > 0) {
      pluginApi.pluginSettings.seenMtime = index.maxMtime;
      pluginApi.saveSettings();
    }
  }

  Component.onCompleted: markSeen()
  onVisibleChanged: if (visible) markSeen()

  FileView {
    id: indexFile
    path: Quickshell.env("HOME") + "/Digest/.index.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root._parse()
  }

  function _parse() {
    try { root.index = JSON.parse(indexFile.text()); }
    catch (e) { /* half-written index; keep last good */ }
  }

  ColumnLayout {
    id: column
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginM

    NText {
      text: "Model digests — " + root.index.count + " finds"
      pointSize: Style.fontSizeL
      font.weight: Font.Bold
      color: AtmoColor.mOnSurface
    }
    NText {
      text: "click = copy path · shift+click = open"
      pointSize: Style.fontSizeS
      color: AtmoColor.mOnSurfaceVariant
    }

    ListView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      spacing: Style.marginS
      model: root.index.entries

      delegate: Rectangle {
        required property var modelData
        width: ListView.view.width
        implicitHeight: delegateColumn.implicitHeight + Style.marginM
        radius: Style.radiusM
        color: mouseArea.containsMouse ? AtmoColor.mSurfaceVariant : AtmoColor.mSurface

        ColumnLayout {
          id: delegateColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.marginS
          spacing: 2

          NText {
            text: modelData.title || modelData.rel
            pointSize: Style.fontSizeM
            font.weight: Font.DemiBold
            color: AtmoColor.mOnSurface
            wrapMode: Text.Wrap
            Layout.fillWidth: true
          }
          NText {
            text: modelData.summary || ""
            pointSize: Style.fontSizeS
            color: AtmoColor.mOnSurfaceVariant
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            visible: (modelData.summary || "") !== ""
          }
          NText {
            text: (modelData.week || "") + " · " + (modelData.date || "") +
                  (modelData.fit ? " · fits: " + modelData.fit : "")
            pointSize: Style.fontSizeS
            color: AtmoColor.mPrimary
            wrapMode: Text.NoWrap
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
        }

        MouseArea {
          id: mouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: function (mouse) {
            if (mouse.modifiers & Qt.ShiftModifier) {
              Quickshell.execDetached(["xdg-open", modelData.path]);
            } else {
              Quickshell.execDetached(["wl-copy", modelData.path]);
              ToastService.showNotice("Digest", "Path copied:\n" + modelData.path, "", 2500);
            }
          }
        }
      }

      NText {
        anchors.centerIn: parent
        visible: root.index.count === 0
        text: "No digests yet — the scout runs Fridays 18:00"
        pointSize: Style.fontSizeM
        color: AtmoColor.mOnSurfaceVariant
      }
    }
  }
}
