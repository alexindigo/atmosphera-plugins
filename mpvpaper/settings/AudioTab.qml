import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM
  Layout.fillWidth: true

  required property var pluginApi
  readonly property var volumeField: pluginApi?.field("volume") ?? null
  required property bool active
  required property bool isMuted

  readonly property real volume: root.volumeField?.value ?? 100
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  // Volume
  NPluginSettingsField {
    field: root.volumeField
    NValueSlider {
      id: volumeInput
      objectName: "settings-range-volume"
      enabled: root.active && !root.isMuted
      from: 0
      to: 100
      value: root.volume
      stepSize: Settings.data.audio.volumeStep
      label: pluginApi?.tr("settings.volume.label") || "Volume"
      description: pluginApi?.tr("settings.volume.description") || "The volume of the video wallpaper playing."
      onMoved: value => root.volumeField.set(value)
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
