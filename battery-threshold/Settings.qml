import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var batteryDeviceField: pluginApi?.field("batteryDevice") ?? null
  property var service: pluginApi?.mainInstance?.service ?? null

  readonly property string editBatteryDevice: root.batteryDeviceField?.value || root.service?.batteries[0] || "/sys/class/power_supply/BAT0"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _applyEffectPending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._applyEffectPending = false;
      root.service?.refresh();
      Logger.i("BatteryThreshold", "Current battery: " + root.pluginApi.pluginSettings.batteryDevice);
    }
  }

  spacing: Style.marginL

  NText {
    visible: !service?.isAvailable
    text: pluginApi?.tr("settings.no-battery-device")
    pointSize: Style.fontSizeM
    color: AtmoColor.mOnSurfaceVariant
  }

  NPluginSettingsField {
    field: root.batteryDeviceField
    visible: service?.isAvailable ?? false
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.battery-device")
      description: pluginApi?.tr("settings.battery-device-desc")

      model: (service?.batteries ?? []).map(path => ({
        key: path,
        name: `${modelNameOf(path)} (${path.split("/").slice(-1)})`
      }))

      currentKey: root.editBatteryDevice
      onSelected: key => root.batteryDeviceField.set(key)
    }
  }

  function modelNameOf(battery) {
    modelNameView.path = `${battery}/model_name`;
    modelNameView.reload();
    modelNameView.waitForJob();
    return modelNameView.text().trim();
  }

  FileView {
    id: modelNameView
    path: `${root.editBatteryDevice}/model_name`
    printErrors: false
  }

  function saveSettings() {
    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true;
  }
}
