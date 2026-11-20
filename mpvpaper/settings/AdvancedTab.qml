import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM
  Layout.fillWidth: true

  required property var pluginApi
  readonly property var hardwareAccelerationField: pluginApi?.field("hardwareAcceleration") ?? null
  readonly property var mpvSocketField: pluginApi?.field("mpvSocket") ?? null
  readonly property var profileField: pluginApi?.field("profile") ?? null
  readonly property var fillModeField: pluginApi?.field("fillMode") ?? null
  required property bool active
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  readonly property bool hardwareAcceleration: root.hardwareAccelerationField?.value || false

  readonly property string mpvSocket: root.mpvSocketField?.value || "/tmp/mpv-socket"

  readonly property string profile: root.profileField?.value || "default"

  readonly property string fillMode: root.fillModeField?.value || "fit"

  // Profile
  NPluginSettingsField {
    field: root.profileField
    NComboBox {
      enabled: root.active
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.profile.label") || "Profile"
      description: pluginApi?.tr("settings.profile.description") || "The profile that mpv uses. Use fast for better performance."
      defaultValue: "default"
      model: [
        {
          "key": "default",
          "name": pluginApi?.tr("settings.profile.default") || "Default"
        },
        {
          "key": "fast",
          "name": pluginApi?.tr("settings.profile.fast") || "Fast"
        },
        {
          "key": "high-quality",
          "name": pluginApi?.tr("settings.profile.high_quality") || "High Quality"
        },
        {
          "key": "low-latency",
          "name": pluginApi?.tr("settings.profile.low_latency") || "Low Latency"
        }
      ]
      currentKey: root.profile
      onSelected: key => root.profileField.set(key)
    }
  }

  // Fill Mode
  NPluginSettingsField {
    field: root.fillModeField
    NComboBox {
      enabled: root.active
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.fill_mode.label") || "Fill mode"
      description: pluginApi?.tr("settings.fill_mode.description") || "The fill mode that mpv uses."
      defaultValue: "fit"
      model: [
        {
          "key": "fit",
          "name": pluginApi?.tr("settings.fill_mode.fit") || "Fit"
        },
        {
          "key": "crop",
          "name": pluginApi?.tr("settings.fill_mode.crop") || "Crop"
        },
        {
          "key": "stretch",
          "name": pluginApi?.tr("settings.fill_mode.stretch") || "Stretch"
        }
      ]
      currentKey: root.fillMode
      onSelected: key => root.fillModeField.set(key)
    }
  }

  // Hardware Acceleration
  NPluginSettingsField {
    field: root.hardwareAccelerationField
    NToggle {
      enabled: root.active
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.hardware_acceleration.label") || "Hardware Acceleration"
      description: pluginApi?.tr("settings.hardware_acceleration.description") || "Offloads video decoding from cpu to gpu / dedicated hardware."
      checked: root.hardwareAcceleration
      onToggled: checked => root.hardwareAccelerationField.set(checked)
      defaultValue: false
    }
  }

  // MPV Socket path
  NPluginSettingsField {
    field: root.mpvSocketField
    NTextInput {
      enabled: root.active
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.mpv_socket.title_label") || "Mpvpaper socket"
      description: pluginApi?.tr("settings.mpv_socket.title_description") || "The mpvpaper socket that noctalia connects to"
      placeholderText: pluginApi?.tr("settings.mpv_socket.input_placeholder") || "Example: /tmp/mpv-socket"
      text: root.mpvSocket
      onEditCommitted: root.mpvSocketField.set(text)
    }
  }

  /********************************
  * Save settings functionality
  ********************************/
  function saveSettings() {
    if (!pluginApi) {
      Logger.e("mpvpaper", "Cannot save: pluginApi is null");
      return;
    }
  }
}
