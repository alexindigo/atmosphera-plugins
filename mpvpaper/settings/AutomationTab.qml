pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM
  Layout.fillWidth: true

  required property var pluginApi
  readonly property var automationField: pluginApi?.field("automation") ?? null
  readonly property var automationModeField: pluginApi?.field("automationMode") ?? null
  readonly property var automationTimeField: pluginApi?.field("automationTime") ?? null
  required property bool active
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  readonly property bool automation: root.automationField?.value || false

  readonly property string automationMode: root.automationModeField?.value || "random"

  readonly property real automationTime: root.automationTimeField?.value || 5 * 60

  // Automation Toggle
  NPluginSettingsField {
    field: root.automationField
    NToggle {
      enabled: root.active
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.automation.label") || "Automation"
      description: pluginApi?.tr("settings.automation.description") || "Schedule automatic wallpaper change."
      checked: root.automation
      onToggled: checked => root.automationField.set(checked)
    }
  }

  // Automation Mode
  NPluginSettingsField {
    field: root.automationModeField
    NComboBox {
      enabled: root.active && root.automation
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.automation_mode.label") || "Change mode"
      description: pluginApi?.tr("settings.automation_mode.description") || "The mode to select the new wallpaper."
      defaultValue: "random"
      model: [
        {
          "key": "random",
          "name": pluginApi?.tr("settings.automation_mode.random") || "Random"
        },
        {
          "key": "alphabetically",
          "name": pluginApi?.tr("settings.automation_mode.alphabetically") || "Alphabetically"
        }
      ]
      currentKey: root.automationMode
      onSelected: key => root.automationModeField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.automationTimeField
    ColumnLayout {
      NLabel {
        enabled: root.active && root.automation
        label: pluginApi?.tr("settings.automation_time.label") || "Time"
        description: pluginApi?.tr("settings.automation_time.description") || "How long it should take to switch the wallpaper."
      }

      RowLayout {
        spacing: Style.marginS

        Repeater {
          model: [
            {
              "text": root.pluginApi?.tr("settings.automation_time.5m") || "5m",
              "time": 5 * 60
            },
            {
              "text": root.pluginApi?.tr("settings.automation_time.10m") || "10m",
              "time": 10 * 60
            },
            {
              "text": root.pluginApi?.tr("settings.automation_time.30m") || "30m",
              "time": 30 * 60
            },
            {
              "text": root.pluginApi?.tr("settings.automation_time.1h") || "1h",
              "time": 60 * 60
            },
            {
              "text": root.pluginApi?.tr("settings.automation_time.1h30m") || "1h 30m",
              "time": 90 * 60
            },
            {
              "text": root.pluginApi?.tr("settings.automation_time.2h") || "2h",
              "time": 120 * 60
            },
          ]

          NButton {
            required property var modelData
            enabled: root.active && root.automation

            text: modelData.text
            onClicked: root.automationTimeField.set(modelData.time)
            outlined: root.automationTime === modelData.time
          }
        }
      }
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
