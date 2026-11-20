import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  property var pluginApi: null
  readonly property var volumeField: pluginApi?.field("volume") ?? null
  readonly property var difficultyField: pluginApi?.field("difficulty") ?? null
  readonly property var showDebugField: pluginApi?.field("showDebug") ?? null
  readonly property var showPercentageField: pluginApi?.field("showPercentage") ?? null
  readonly property real editVolume: root.volumeField?.value ?? 0.5
  readonly property real editDifficulty: root.difficultyField?.value ?? 50
  readonly property bool editShowDebug: root.showDebugField?.value ?? false
  readonly property bool showPercentage: root.showPercentageField?.value ?? false
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    pluginApi.saveSettings();
  }

  NLabel {
    label: pluginApi?.tr("settings.volume")
    description: pluginApi?.tr("settings.volume-desc")
  }

  NPluginSettingsField {
    field: root.volumeField
    NSlider {
      id: rangeEditVolume
      objectName: "settings-range-editVolume"
      Layout.fillWidth: true
      from: 0
      to: 1
      value: root.editVolume
      onMoved: root.volumeField.set(value)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NLabel {
    label: pluginApi?.tr("settings.difficulty")
    description: pluginApi?.tr("settings.difficulty-desc")
  }

  NPluginSettingsField {
    field: root.difficultyField
    NSlider {
      id: rangeEditDifficulty
      objectName: "settings-range-editDifficulty"
      Layout.fillWidth: true
      from: 0
      to: 100
      value: root.editDifficulty
      onMoved: root.difficultyField.set(value)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NPluginSettingsField {
    field: root.showDebugField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.debug")
      description: pluginApi?.tr("settings.debug-desc")
      checked: root.editShowDebug
      onToggled: checked => root.showDebugField.set(checked)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NPluginSettingsField {
    field: root.showPercentageField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.percentage")
      description: pluginApi?.tr("settings.percentage-desc")
      checked: root.showPercentage ?? false
      onToggled: checked => root.showPercentageField.set(checked)
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
