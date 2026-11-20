import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var showTempValueField: pluginApi?.field("showTempValue") ?? null
  readonly property var showConditionIconField: pluginApi?.field("showConditionIcon") ?? null
  readonly property var showTempUnitField: pluginApi?.field("showTempUnit") ?? null
  readonly property var tooltipOptionField: pluginApi?.field("tooltipOption") ?? null
  readonly property var customColorField: pluginApi?.field("customColor") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property bool showTempValue: root.showTempValueField?.value ?? defaults.showTempValue
  readonly property bool showConditionIcon: root.showConditionIconField?.value ?? defaults.showConditionIcon
  readonly property bool showTempUnit: root.showTempUnitField?.value ?? defaults.showTempUnit
  readonly property string tooltipOption: root.tooltipOptionField?.value ?? defaults.tooltipOption
  readonly property string customColor: root.customColorField?.value ?? defaults.customColor
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _applyEffectPending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._applyEffectPending = false;
      Logger.i("WeatherIndicator", "Settings saved successfully");
      root.pluginApi.withCurrentScreen(s => root.pluginApi.closePanel(s));
    }
  }
  spacing: Style.marginL

  Component.onCompleted: {
    Logger.i("WeatherIndicator", "Settings UI loaded");
  }

  NPluginSettingsField {
    field: root.customColorField
    NColorChoice {
      label: pluginApi?.tr("settings.customColor.label")
      description: pluginApi?.tr("settings.customColor.desc")
      currentKey: root.customColor
      onSelected: key => {
        root.customColorField.set(key);
      }
    }
  }

  NPluginSettingsField {
    field: root.showConditionIconField
    NToggle {
      id: toggleIcon
      label: pluginApi?.tr("settings.showConditionIcon.label")
      description: pluginApi?.tr("settings.showConditionIcon.desc")
      checked: root.showConditionIcon
      onToggled: checked => {
        root.showConditionIconField.set(checked);
        root.showTempValueField.set(true);
      }
      defaultValue: true
    }
  }

  NPluginSettingsField {
    field: root.showTempValueField
    NToggle {
      id: toggleTempText
      label: pluginApi?.tr("settings.showTempValue.label")
      description: pluginApi?.tr("settings.showTempValue.desc")
      checked: root.showTempValue
      onToggled: checked => {
        root.showTempValueField.set(checked);
        root.showConditionIconField.set(true);
      }
      defaultValue: true
    }
  }

  NPluginSettingsField {
    field: root.showTempUnitField
    visible: root.showTempValue
    NToggle {
      id: toggleTempLetter
      label: pluginApi?.tr("settings.showTempUnit.label")
      description: pluginApi?.tr("settings.showTempUnit.desc")
      checked: root.showTempUnit
      onToggled: checked => {
        root.showTempUnitField.set(checked);
      }
      defaultValue: true
    }
  }

  NPluginSettingsField {
    field: root.tooltipOptionField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.tooltipOption.label")
      description: pluginApi?.tr("settings.tooltipOption.desc")
      model: [
        {
          "key": "disable",
          "name": pluginApi?.tr("settings.mode.disable")
        },
        {
          "key": "highlow",
          "name": pluginApi?.tr("settings.mode.highlow")
        },
        {
          "key": "sunrise",
          "name": pluginApi?.tr("settings.mode.sunrise")
        },
        {
          "key": "everything",
          "name": pluginApi?.tr("settings.mode.everything")
        }
      ]
      currentKey: root.tooltipOption
      onSelected: function (key) {
        root.tooltipOptionField.set(key);
      }
      defaultValue: "everything"
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("WeatherIndicator", "Cannot save settings: pluginApi is null");
      return;
    }

    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true;
  }
}
