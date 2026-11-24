import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  spacing: Style.marginL
  width: 560

  required property var pluginApi
  readonly property var pollIntervalMsField: pluginApi?.field("pollIntervalMs") ?? null
  readonly property var leftClickActionField: pluginApi?.field("leftClickAction") ?? null
  readonly property var launchBehaviorField: pluginApi?.field("launchBehavior") ?? null
  readonly property var barLabelModeField: pluginApi?.field("barLabelMode") ?? null
  readonly property var videosPathField: pluginApi?.field("videosPath") ?? null
  readonly property var videosOpenerField: pluginApi?.field("videosOpener") ?? null
  readonly property var autoCloseManagedObsField: pluginApi?.field("autoCloseManagedObs") ?? null
  readonly property var openVideosAfterStopField: pluginApi?.field("openVideosAfterStop") ?? null
  readonly property var showBarWhenRecordingField: pluginApi?.field("showBarWhenRecording") ?? null
  readonly property var showBarWhenReplayField: pluginApi?.field("showBarWhenReplay") ?? null
  readonly property var showBarWhenStreamingField: pluginApi?.field("showBarWhenStreaming") ?? null
  readonly property var showBarWhenReadyField: pluginApi?.field("showBarWhenReady") ?? null
  readonly property var showControlCenterWhenRecordingField: pluginApi?.field("showControlCenterWhenRecording") ?? null
  readonly property var showControlCenterWhenReplayField: pluginApi?.field("showControlCenterWhenReplay") ?? null
  readonly property var showControlCenterWhenStreamingField: pluginApi?.field("showControlCenterWhenStreaming") ?? null
  readonly property var showControlCenterWhenReadyField: pluginApi?.field("showControlCenterWhenReady") ?? null
  readonly property var showElapsedInBarField: pluginApi?.field("showElapsedInBar") ?? null

  readonly property var settings: root.pluginApi.pluginSettings ?? ({})
  readonly property var service: root.pluginApi.mainInstance
  readonly property bool durationLabelsSelected: root.valueBarLabelMode === "duration"

  readonly property int valuePollIntervalMs: root.pollIntervalMsField?.value ?? 2500
  readonly property string valueLeftClickAction: root.leftClickActionField?.value ?? "panel"
  readonly property string valueLaunchBehavior: root.launchBehaviorField?.value ?? "minimized-to-tray"
  readonly property string valueBarLabelMode: root.barLabelModeField?.value ?? "short-label"
  readonly property string valueVideosPath: root.videosPathField?.value ?? ""
  readonly property string valueVideosOpener: root.videosOpenerField?.value ?? "xdg-open"
  readonly property bool valueAutoCloseManagedObs: root.autoCloseManagedObsField?.value ?? true
  readonly property bool valueOpenVideosAfterStop: root.openVideosAfterStopField?.value ?? true
  readonly property bool valueShowBarWhenRecording: root.showBarWhenRecordingField?.value ?? true
  readonly property bool valueShowBarWhenReplay: root.showBarWhenReplayField?.value ?? false
  readonly property bool valueShowBarWhenStreaming: root.showBarWhenStreamingField?.value ?? true
  // Stored under the legacy showBarWhenReady key for settings compatibility.
  readonly property bool valueAlwaysShowInBar: root.showBarWhenReadyField?.value ?? true
  readonly property bool valueShowControlCenterWhenRecording: root.showControlCenterWhenRecordingField?.value ?? true
  readonly property bool valueShowControlCenterWhenReplay: root.showControlCenterWhenReplayField?.value ?? true
  readonly property bool valueShowControlCenterWhenStreaming: root.showControlCenterWhenStreamingField?.value ?? true
  readonly property bool valueShowControlCenterWhenReady: root.showControlCenterWhenReadyField?.value ?? false
  readonly property bool valueShowElapsedInBar: root.showElapsedInBarField?.value ?? false

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    root.pluginApi.saveSettings();
  }

  NHeader {
    label: root.pluginApi.tr("settings.header.label")
    description: root.pluginApi.tr("settings.header.description")
  }

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
    color: AtmoColor.mOnSurfaceVariant
    text: root.pluginApi.tr("settings.shared-effect")
  }

  NBox {
    visible: root.service?.websocketSupportMissing || root.service?.websocketConfigMissing
    Layout.fillWidth: true
    implicitHeight: warningColumn.implicitHeight + Style.marginXL

    ColumnLayout {
      id: warningColumn

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginM
      spacing: Style.marginXS

      NText {
        text: root.service?.websocketSupportMissing ? root.pluginApi.tr("settings.runtime.qt_websockets_missing_title") : root.pluginApi.tr("settings.runtime.websocket_config_missing_title")
        font.weight: Style.fontWeightSemiBold
        color: AtmoColor.mPrimary
      }

      NText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: AtmoColor.mOnSurfaceVariant
        text: root.service?.websocketSupportMissing ? root.pluginApi.tr("settings.runtime.qt_websockets_missing") : root.pluginApi.tr("settings.runtime.websocket_config_missing")
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: behaviorSection.implicitHeight + Style.marginXL

    ColumnLayout {
      id: behaviorSection

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        text: root.pluginApi.tr("settings.sections.behavior.label")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightSemiBold
        color: AtmoColor.mPrimary
      }

      NText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: AtmoColor.mOnSurfaceVariant
        text: root.pluginApi.tr("settings.sections.behavior.description")
      }

      NPluginSettingsField {
        field: root.leftClickActionField
        NComboBox {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.left_click_action.label")
          description: root.pluginApi.tr("settings.left_click_action.description")
          model: [
            {
              key: "panel",
              name: root.pluginApi.tr("settings.left_click_action.options.open_controls")
            },
            {
              key: "toggle-record",
              name: root.pluginApi.tr("settings.left_click_action.options.toggle_recording")
            },
            {
              key: "toggle-stream",
              name: root.pluginApi.tr("settings.left_click_action.options.toggle_streaming")
            },
          ]
          currentKey: root.valueLeftClickAction
          minimumWidth: 220
          onSelected: key => root.leftClickActionField.set(key)
        }
      }

      NPluginSettingsField {
        field: root.launchBehaviorField
        NComboBox {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.launch_behavior.label")
          description: root.pluginApi.tr("settings.launch_behavior.description")
          model: [
            {
              key: "normal",
              name: root.pluginApi.tr("settings.launch_behavior.options.normal")
            },
            {
              key: "minimized-to-tray",
              name: root.pluginApi.tr("settings.launch_behavior.options.minimized_to_tray")
            },
          ]
          currentKey: root.valueLaunchBehavior
          minimumWidth: 220
          onSelected: key => root.launchBehaviorField.set(key)
        }
      }

      NPluginSettingsField {
        field: root.pollIntervalMsField
        NSpinBox {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.poll_interval.label")
          description: root.pluginApi.tr("settings.poll_interval.description")
          from: 750
          to: 10000
          stepSize: 250
          value: root.valuePollIntervalMs
          requestValue: value => root.pollIntervalMsField.set(value)
        }
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: barSection.implicitHeight + Style.marginXL

    ColumnLayout {
      id: barSection

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        text: root.pluginApi.tr("settings.sections.bar.label")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightSemiBold
        color: AtmoColor.mPrimary
      }

      NText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: AtmoColor.mOnSurfaceVariant
        text: root.pluginApi.tr("settings.sections.bar.description")
      }

      NPluginSettingsField {
        field: root.barLabelModeField
        NComboBox {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.bar_label_mode.label")
          description: root.pluginApi.tr("settings.bar_label_mode.description")
          model: [
            {
              key: "icon-only",
              name: root.pluginApi.tr("settings.bar_label_mode.options.icon_only")
            },
            {
              key: "short-label",
              name: root.pluginApi.tr("settings.bar_label_mode.options.short_label")
            },
            {
              key: "duration",
              name: root.pluginApi.tr("settings.bar_label_mode.options.duration")
            },
          ]
          currentKey: root.valueBarLabelMode
          minimumWidth: 220
          onSelected: key => root.barLabelModeField.set(key)
        }
      }

      NPluginSettingsField {
        field: root.showElapsedInBarField
        visible: root.durationLabelsSelected
        NToggle {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.show_elapsed_in_bar.label")
          description: root.pluginApi.tr("settings.show_elapsed_in_bar.description")
          checked: root.valueShowElapsedInBar
          onToggled: checked => root.showElapsedInBarField.set(checked)
        }
      }

      NPluginSettingsField {
        field: root.showBarWhenReadyField
        NToggle {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.always_show_in_bar.label")
          description: root.pluginApi.tr("settings.always_show_in_bar.description")
          checked: root.valueAlwaysShowInBar
          onToggled: checked => root.showBarWhenReadyField.set(checked)
        }
      }

      NPluginSettingsField {
        field: root.showBarWhenRecordingField
        NToggle {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.show_bar_recording.label")
          description: root.pluginApi.tr("settings.show_bar_recording.description")
          checked: root.valueShowBarWhenRecording
          onToggled: checked => root.showBarWhenRecordingField.set(checked)
        }
      }

      NPluginSettingsField {
        field: root.showBarWhenStreamingField
        NToggle {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.show_bar_streaming.label")
          description: root.pluginApi.tr("settings.show_bar_streaming.description")
          checked: root.valueShowBarWhenStreaming
          onToggled: checked => root.showBarWhenStreamingField.set(checked)
        }
      }

      NPluginSettingsField {
        field: root.showBarWhenReplayField
        NToggle {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.show_bar_replay.label")
          description: root.pluginApi.tr("settings.show_bar_replay.description")
          checked: root.valueShowBarWhenReplay
          onToggled: checked => root.showBarWhenReplayField.set(checked)
        }
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: controlCenterSection.implicitHeight + Style.marginXL

    ColumnLayout {
      id: controlCenterSection

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        text: root.pluginApi.tr("settings.sections.control_center.label")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightSemiBold
        color: AtmoColor.mPrimary
      }

      NText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: AtmoColor.mOnSurfaceVariant
        text: root.pluginApi.tr("settings.sections.control_center.description")
      }

      NPluginSettingsField {
        field: root.showControlCenterWhenReadyField
        NToggle {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.show_control_center_ready.label")
          description: root.pluginApi.tr("settings.show_control_center_ready.description")
          checked: root.valueShowControlCenterWhenReady
          onToggled: checked => root.showControlCenterWhenReadyField.set(checked)
        }
      }

      NPluginSettingsField {
        field: root.showControlCenterWhenRecordingField
        NToggle {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.show_control_center_recording.label")
          description: root.pluginApi.tr("settings.show_control_center_recording.description")
          checked: root.valueShowControlCenterWhenRecording
          onToggled: checked => root.showControlCenterWhenRecordingField.set(checked)
        }
      }

      NPluginSettingsField {
        field: root.showControlCenterWhenStreamingField
        NToggle {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.show_control_center_streaming.label")
          description: root.pluginApi.tr("settings.show_control_center_streaming.description")
          checked: root.valueShowControlCenterWhenStreaming
          onToggled: checked => root.showControlCenterWhenStreamingField.set(checked)
        }
      }

      NPluginSettingsField {
        field: root.showControlCenterWhenReplayField
        NToggle {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.show_control_center_replay.label")
          description: root.pluginApi.tr("settings.show_control_center_replay.description")
          checked: root.valueShowControlCenterWhenReplay
          onToggled: checked => root.showControlCenterWhenReplayField.set(checked)
        }
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: videosSection.implicitHeight + Style.marginXL

    ColumnLayout {
      id: videosSection

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        text: root.pluginApi.tr("settings.sections.videos.label")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightSemiBold
        color: AtmoColor.mPrimary
      }

      NText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: AtmoColor.mOnSurfaceVariant
        text: root.pluginApi.tr("settings.sections.videos.description")
      }

      NPluginSettingsField {
        field: root.videosPathField
        NTextInput {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.videos_path.label")
          description: root.pluginApi.tr("settings.videos_path.description")
          placeholderText: "~/Videos"
          text: root.valueVideosPath
          onEditCommitted: root.videosPathField.set(text.trim())
        }
      }

      NPluginSettingsField {
        field: root.videosOpenerField
        NTextInput {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.videos_opener.label")
          description: root.pluginApi.tr("settings.videos_opener.description")
          placeholderText: "xdg-open"
          text: root.valueVideosOpener
          onEditCommitted: root.videosOpenerField.set(text.trim())
        }
      }

      NPluginSettingsField {
        field: root.openVideosAfterStopField
        NToggle {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.open_videos_after_stop.label")
          description: root.pluginApi.tr("settings.open_videos_after_stop.description")
          checked: root.valueOpenVideosAfterStop
          onToggled: checked => root.openVideosAfterStopField.set(checked)
        }
      }

      NPluginSettingsField {
        field: root.autoCloseManagedObsField
        NToggle {
          Layout.fillWidth: true
          label: root.pluginApi.tr("settings.auto_close_managed.label")
          description: root.pluginApi.tr("settings.auto_close_managed.description")
          checked: root.valueAutoCloseManagedObs
          onToggled: checked => root.autoCloseManagedObsField.set(checked)
        }
      }
    }
  }
}
