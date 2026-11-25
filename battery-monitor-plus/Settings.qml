import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.Hardware
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var displayModeField: pluginApi?.field("displayMode") ?? null
  readonly property var deviceNativePathField: pluginApi?.field("deviceNativePath") ?? null
  readonly property var showPowerProfilesField: pluginApi?.field("showPowerProfiles") ?? null
  readonly property var showNoctaliaPerformanceField: pluginApi?.field("showNoctaliaPerformance") ?? null
  readonly property var hideIfNotDetectedField: pluginApi?.field("hideIfNotDetected") ?? null
  readonly property var hideIfIdleField: pluginApi?.field("hideIfIdle") ?? null
  readonly property var refreshIntervalSecondsField: pluginApi?.field("refreshIntervalSeconds") ?? null
  readonly property var showPowerInBarField: pluginApi?.field("showPowerInBar") ?? null
  readonly property var showTimeInBarField: pluginApi?.field("showTimeInBar") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string valueDisplayMode: root.displayModeField?.value ?? "graphic-clean"
  readonly property string valueDeviceNativePath: root.deviceNativePathField?.value ?? "__default__"
  readonly property bool valueShowPowerProfiles: root.showPowerProfilesField?.value ?? false
  readonly property bool valueShowNoctaliaPerformance: root.showNoctaliaPerformanceField?.value ?? false
  readonly property bool valueHideIfNotDetected: root.hideIfNotDetectedField?.value ?? true
  readonly property bool valueHideIfIdle: root.hideIfIdleField?.value ?? false
  readonly property int valueRefreshIntervalSeconds: root.refreshIntervalSecondsField?.value ?? 5
  readonly property bool valueShowPowerInBar: root.showPowerInBarField?.value ?? true
  readonly property bool valueShowTimeInBar: root.showTimeInBarField?.value ?? true

  spacing: Style.marginM

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    text: root.pluginApi?.tr("settings.shared-effect") || ""
    wrapMode: Text.WordWrap
    color: AtmoColor.mOnSurfaceVariant
  }

  Component.onCompleted: {
    Logger.d("BatteryMonitorPlus", "Settings UI loaded");
  }

  NPluginSettingsField {
    field: root.deviceNativePathField
    NComboBox {
      id: deviceComboBox
      Layout.fillWidth: true
      label: I18n.tr("bar.battery.device-label")
      description: I18n.tr("bar.battery.device-description")
      minimumWidth: 240
      model: BatteryService.deviceModel
      currentKey: root.valueDeviceNativePath
      defaultValue: defaults.deviceNativePath ?? "__default__"
      onSelected: key => root.deviceNativePathField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.displayModeField
    NComboBox {
      Layout.fillWidth: true
      label: I18n.tr("common.display-mode")
      description: I18n.tr("bar.battery.display-mode-description")
      minimumWidth: 240
      model: [
        {
          "key": "graphic",
          "name": I18n.tr("bar.battery.display-mode-graphic")
        },
        {
          "key": "graphic-clean",
          "name": I18n.tr("bar.battery.display-mode-graphic-clean")
        },
        {
          "key": "icon-hover",
          "name": I18n.tr("bar.battery.display-mode-icon-hover")
        },
        {
          "key": "icon-always",
          "name": I18n.tr("bar.battery.display-mode-icon-always")
        },
        {
          "key": "icon-only",
          "name": I18n.tr("bar.battery.display-mode-icon-only")
        }
      ]
      currentKey: root.valueDisplayMode
      defaultValue: defaults.displayMode ?? "graphic-clean"
      onSelected: key => root.displayModeField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.hideIfNotDetectedField
    NToggle {
      label: I18n.tr("bar.battery.hide-if-not-detected-label")
      description: I18n.tr("bar.battery.hide-if-not-detected-description")
      checked: root.valueHideIfNotDetected
      defaultValue: defaults.hideIfNotDetected ?? true
      onToggled: checked => root.hideIfNotDetectedField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.hideIfIdleField
    NToggle {
      label: I18n.tr("bar.battery.hide-if-idle-label")
      description: I18n.tr("bar.battery.hide-if-idle-description")
      checked: root.valueHideIfIdle
      defaultValue: defaults.hideIfIdle ?? false
      onToggled: checked => root.hideIfIdleField.set(checked)
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NPluginSettingsField {
    field: root.showPowerProfilesField
    NToggle {
      label: I18n.tr("bar.battery.show-power-profile-label")
      description: I18n.tr("bar.battery.show-power-profile-description")
      checked: root.valueShowPowerProfiles
      defaultValue: defaults.showPowerProfiles ?? false
      onToggled: checked => root.showPowerProfilesField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.showNoctaliaPerformanceField
    NToggle {
      label: I18n.tr("bar.battery.show-noctalia-performance-label")
      description: I18n.tr("bar.battery.show-noctalia-performance-description")
      checked: root.valueShowNoctaliaPerformance
      defaultValue: defaults.showNoctaliaPerformance ?? false
      onToggled: checked => root.showNoctaliaPerformanceField.set(checked)
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      label: pluginApi?.tr("settings.refreshInterval.label")
      description: pluginApi?.tr("settings.refreshInterval.desc")
    }

    NPluginSettingsField {
      field: root.refreshIntervalSecondsField
      NValueSlider {
        id: rangeValueRefreshIntervalSeconds
        objectName: "settings-range-valueRefreshIntervalSeconds"
        Layout.fillWidth: true
        from: 1
        to: 60
        stepSize: 1
        snapAlways: true
        value: root.valueRefreshIntervalSeconds
        text: `${root.valueRefreshIntervalSeconds}s`
        onMoved: value => root.refreshIntervalSecondsField.set(Math.round(value))
      }
    }
  }

  NPluginSettingsField {
    field: root.showPowerInBarField
    NToggle {
      label: pluginApi?.tr("settings.showPowerInBar.label")
      description: pluginApi?.tr("settings.showPowerInBar.desc")
      checked: root.valueShowPowerInBar
      defaultValue: defaults.showPowerInBar ?? true
      onToggled: checked => root.showPowerInBarField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.showTimeInBarField
    NToggle {
      label: pluginApi?.tr("settings.showTimeInBar.label")
      description: pluginApi?.tr("settings.showTimeInBar.desc")
      checked: root.valueShowTimeInBar
      defaultValue: defaults.showTimeInBar ?? true
      onToggled: checked => root.showTimeInBarField.set(checked)
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("BatteryMonitorPlus", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("BatteryMonitorPlus", "Settings saved successfully");
    });
  }
}
