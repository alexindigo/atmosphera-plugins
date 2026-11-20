import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var outputDirField: pluginApi?.field("outputDir") ?? null
  readonly property var fpsField: pluginApi?.field("fps") ?? null
  readonly property var maxRecordingSecondsField: pluginApi?.field("maxRecordingSeconds") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string valueOutputDir: root.outputDirField?.value ?? defaults.outputDir
  readonly property int valueFps: root.fpsField?.value ?? defaults.fps
  readonly property int valueMaxRecordingSeconds: root.maxRecordingSecondsField?.value ?? defaults.maxRecordingSeconds
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  NPluginSettingsField {
    field: root.outputDirField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.outputDir.label")
      description: pluginApi?.tr("settings.outputDir.description")
      text: root.valueOutputDir
      onEditCommitted: root.outputDirField.set(text)
    }
  }

  NPluginSettingsField {
    field: root.fpsField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.fps.label")
      description: pluginApi?.tr("settings.fps.description")
      text: String(root.valueFps)
      onEditCommitted: root.fpsField.set(parseInt(text) || 20)
    }
  }

  NPluginSettingsField {
    field: root.maxRecordingSecondsField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.maxRecordingSeconds.label")
      description: pluginApi?.tr("settings.maxRecordingSeconds.description")
      text: String(root.valueMaxRecordingSeconds)
      onEditCommitted: root.maxRecordingSecondsField.set(parseInt(text) || 0)
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }
}
