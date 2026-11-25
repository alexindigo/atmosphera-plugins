import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var leftButtonField: pluginApi?.field("leftButton") ?? null
  readonly property var rightButtonField: pluginApi?.field("rightButton") ?? null
  readonly property var middleButtonField: pluginApi?.field("middleButton") ?? null
  readonly property var shuffleStopsPlaybackField: pluginApi?.field("shuffleStopsPlayback") ?? null

  readonly property string editLeftButton: root.leftButtonField?.value ?? "next"
  readonly property string editRightButton: root.rightButtonField?.value ?? "toggle"
  readonly property string editMiddleButton: root.middleButtonField?.value ?? "shuffle"
  readonly property bool editShuffleStopsPlayback: root.shuffleStopsPlaybackField?.value ?? true
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  readonly property var actionModel: [
    {
      key: "next",
      name: "Next track"
    },
    {
      key: "prev",
      name: "Previous track"
    },
    {
      key: "toggle",
      name: "Play / Pause"
    },
    {
      key: "stop",
      name: "Stop"
    },
    {
      key: "shuffle",
      name: "Toggle ashuffle"
    },
    {
      key: "none",
      name: "Do nothing"
    },
  ]

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }

  // Mouse button actions
  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NPluginSettingsField {
      field: root.leftButtonField
      NComboBox {
        label: "Left click"
        description: "Action when left-clicking the widget"
        model: root.actionModel
        currentKey: root.editLeftButton
        onSelected: key => root.leftButtonField.set(key)
      }
    }

    NPluginSettingsField {
      field: root.rightButtonField
      NComboBox {
        label: "Right click"
        description: "Action when right-clicking the widget"
        model: root.actionModel
        currentKey: root.editRightButton
        onSelected: key => root.rightButtonField.set(key)
      }
    }

    NPluginSettingsField {
      field: root.middleButtonField
      NComboBox {
        label: "Middle click"
        description: "Action when middle-clicking the widget"
        model: root.actionModel
        currentKey: root.editMiddleButton
        onSelected: key => root.middleButtonField.set(key)
      }
    }

    NPluginSettingsField {
      field: root.shuffleStopsPlaybackField
      NToggle {
        label: "Stop playback when disabling shuffle"
        description: "When toggling ashuffle off, also send mpc stop. Only applies to the \"Toggle ashuffle\" action."
        checked: root.editShuffleStopsPlayback
        onToggled: checked => root.shuffleStopsPlaybackField.set(checked)
      }
    }
  }
}
