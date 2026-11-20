import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var threshold: pluginApi?.field("minimumThreshold")
  readonly property var background: pluginApi?.field("hideBackground")
  readonly property bool settingsDirty: false
  spacing: Style.marginM

  NPluginSettingsField {
    field: root.threshold
    spacing: Style.marginS
    NLabel {
      label: root.pluginApi?.tr("settings.minimumThreshold.label")
      description: root.pluginApi?.tr("settings.minimumThreshold.description")
    }
    NSlider {
      id: thresholdSlider
      Layout.fillWidth: true
      objectName: "settings-range-valueMinimumThreshold"
      from: 5
      to: 25
      value: root.threshold?.value ?? 10
      stepSize: 1
      onMoved: root.threshold.set(value)
    }
    NText {
      text: (root.pluginApi?.tr("settings.currentThreshold") || "").replace("{value}", thresholdSlider.value)
      color: AtmoColor.mOnSurfaceVariant
      font.pointSize: Style.fontSizeS
    }
  }
  NPluginSettingsField {
    field: root.background
    NToggle {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.hideBackground.label")
      description: root.pluginApi?.tr("settings.hideBackground.description")
      checked: root.background?.value ?? false
      onToggled: function (checked) {
        root.background.set(checked);
      }
    }
  }
  function saveSettings() {
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("Catwalk", "Settings saved successfully");
    });
  }
}
