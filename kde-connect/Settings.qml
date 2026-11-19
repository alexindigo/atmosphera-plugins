import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property bool hideIfNoDeviceConnected: displayBaseline.hideIfNoDeviceConnected
  NSettingsBaseline {
    id: displayBaseline
    readonly property bool hideIfNoDeviceConnected: cfg.hideIfNoDeviceConnected ?? defaults.hideIfNoDeviceConnected ?? false
  }
  readonly property bool settingsDirty: displayBaseline.differs({hideIfNoDeviceConnected: root.hideIfNoDeviceConnected})

  spacing: Style.marginL

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NToggle {
        label: pluginApi?.tr("settings.no-device-connected-hide.label")
        description: pluginApi?.tr("settings.no-device-connected-hide.description")

        checked: root.hideIfNoDeviceConnected
        onToggled: function(checked) {
            root.hideIfNoDeviceConnected = checked
        }
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("KDEConnect", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.pluginSettings.hideIfNoDeviceConnected = root.hideIfNoDeviceConnected;
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("KDEConnect", "Settings saved successfully");
    });
  }
}
