import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var sourceField: pluginApi?.field("dataSource")
  readonly property var tokenField: pluginApi?.field("aqicnToken")
  readonly property var scaleField: pluginApi?.field("aqiScale")
  readonly property var locationField: pluginApi?.field("useNoctaliaLocation")
  readonly property var latitudeField: pluginApi?.field("customLatitude")
  readonly property var longitudeField: pluginApi?.field("customLongitude")
  readonly property var intervalField: pluginApi?.field("refreshInterval")
  readonly property var boldField: pluginApi?.field("boldText")
  readonly property bool settingsDirty: false
  spacing: Style.marginM
  NPluginSettingsField {
    field: root.sourceField
    NComboBox {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.dataSource")
      description: root.pluginApi?.tr("settings.dataSourceDesc")
      model: [
        {
          key: "open-meteo",
          name: root.pluginApi?.tr("settings.dataSourceOpenMeteo")
        },
        {
          key: "aqicn",
          name: root.pluginApi?.tr("settings.dataSourceAqicn")
        }
      ]
      currentKey: root.sourceField?.value ?? "open-meteo"
      onSelected: key => {
        if (root.sourceField.set(key) && key === "aqicn")
          root.scaleField.set("us");
      }
    }
  }
  NPluginSettingsField {
    field: root.tokenField
    visible: root.sourceField?.value === "aqicn"
    NTextInput {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.aqicnToken")
      description: root.pluginApi?.tr("settings.aqicnTokenDesc")
      placeholderText: root.pluginApi?.tr("settings.aqicnTokenPlaceholder")
      text: root.tokenField?.value ?? ""
      onEditCommitted: root.tokenField.set(text)
    }
  }
  NPluginSettingsField {
    field: root.scaleField
    NComboBox {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.aqiScale")
      description: root.pluginApi?.tr("settings.aqiScaleDesc")
      enabled: root.sourceField?.value !== "aqicn"
      model: [
        {
          key: "us",
          name: root.pluginApi?.tr("settings.aqiScaleUs")
        },
        {
          key: "eu",
          name: root.pluginApi?.tr("settings.aqiScaleEu")
        }
      ]
      currentKey: root.scaleField?.value ?? "us"
      onSelected: key => root.scaleField.set(key)
    }
  }
  NPluginSettingsField {
    field: root.locationField
    NToggle {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.useNoctaliaLocation")
      description: root.pluginApi?.tr("settings.useNoctaliaLocationDesc")
      checked: root.locationField?.value ?? true
      onToggled: checked => root.locationField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.latitudeField
    visible: root.locationField?.value === false
    NTextInput {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.customLatitude")
      description: root.pluginApi?.tr("settings.customLocationDesc")
      placeholderText: "41.3851"
      text: root.latitudeField?.value ?? ""
      onEditCommitted: root.latitudeField.set(text)
    }
  }
  NPluginSettingsField {
    field: root.longitudeField
    visible: root.locationField?.value === false
    NTextInput {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.customLongitude")
      placeholderText: "2.1734"
      text: root.longitudeField?.value ?? ""
      onEditCommitted: root.longitudeField.set(text)
    }
  }
  NPluginSettingsField {
    field: root.intervalField
    NLabel {
      label: root.pluginApi?.tr("settings.refreshInterval")
      description: root.pluginApi?.tr("settings.refreshIntervalDesc") + (root.intervalField?.value ?? 30)
    }
    NSlider {
      Layout.fillWidth: true
      from: 5
      to: 120
      stepSize: 5
      value: root.intervalField?.value ?? 30
      onMoved: root.intervalField.set(value)
    }
  }
  NPluginSettingsField {
    field: root.boldField
    NToggle {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.boldText")
      description: root.pluginApi?.tr("settings.boldTextDesc")
      checked: root.boldField?.value ?? true
      onToggled: checked => root.boldField.set(checked)
    }
  }
  function saveSettings() {
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        root.pluginApi.mainInstance?.settingsConsumerFor(root.pluginApi.runtimeContext)?.refresh();
    });
  }
}
