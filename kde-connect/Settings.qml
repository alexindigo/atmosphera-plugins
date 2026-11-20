import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var hideIfNoDeviceConnectedField: pluginApi?.field("hideIfNoDeviceConnected") ?? null

  readonly property bool hideIfNoDeviceConnected: root.hideIfNoDeviceConnectedField?.value ?? false
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NPluginSettingsField {
      field: root.hideIfNoDeviceConnectedField
      NToggle {
        label: pluginApi?.tr("settings.no-device-connected-hide.label")
        description: pluginApi?.tr("settings.no-device-connected-hide.description")

        checked: root.hideIfNoDeviceConnected
        onToggled: function (checked) {
          root.hideIfNoDeviceConnectedField.set(checked);
        }
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("KDEConnect", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("KDEConnect", "Settings saved successfully");
    });
  }
}
