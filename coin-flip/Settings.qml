import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var delayField: pluginApi?.field("delay") ?? null

  readonly property int delay: root.delayField?.value ?? 1

  spacing: Style.marginL

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.delay.label")
      description: pluginApi?.tr("settings.delay.description")
    }

    NPluginSettingsField {
      field: root.delayField
      NSlider {
        id: rangeDelay
        objectName: "settings-range-delay"
        onMoved: root.delayField.set(value)
        Layout.fillWidth: true
        from: 1
        to: 36
        stepSize: 5
        value: root.delay
      }
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("CoinFilp", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings();
  }
}
