import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var connectedColorField: pluginApi?.field("connectedColor") ?? null
  readonly property var disconnectedColorField: pluginApi?.field("disconnectedColor") ?? null

  readonly property int editRefreshInterval: root.refreshIntervalField?.value || 5000
  readonly property string editConnectedColor: root.connectedColorField?.value || "primary"
  readonly property string editDisconnectedColor: root.disconnectedColorField?.value || "none"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  NText {
    text: pluginApi?.tr("settings.title")
    font.pointSize: Style.fontSizeXL
    font.bold: true
  }

  NText {
    text: pluginApi?.tr("settings.description")
    color: AtmoColor.mSecondary
    Layout.fillWidth: true
    wrapMode: Text.Wrap
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NPluginSettingsField {
    field: root.connectedColorField
    NColorChoice {
      label: pluginApi?.tr("settings.connected-color")
      description: pluginApi?.tr("settings.connected-color-desc")
      currentKey: root.editConnectedColor
      onSelected: key => root.connectedColorField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.disconnectedColorField
    NColorChoice {
      label: pluginApi?.tr("settings.disconnected-color")
      description: pluginApi?.tr("settings.disconnected-color-desc")
      currentKey: root.editDisconnectedColor
      onSelected: key => root.disconnectedColorField.set(key)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.refresh-interval")
    description: pluginApi?.tr("settings.refresh-interval-desc") + " (" + root.editRefreshInterval + " ms)"
  }

  NPluginSettingsField {
    field: root.refreshIntervalField
    NSlider {
      id: rangeEditRefreshInterval
      objectName: "settings-range-editRefreshInterval"
      Layout.fillWidth: true
      from: 1000
      to: 60000
      stepSize: 1000
      value: root.editRefreshInterval
      onMoved: root.refreshIntervalField.set(value)
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("CloudflareWarp", "Settings saved");
    });
  }
}
