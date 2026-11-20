import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null
  readonly property var statusStateField: pluginApi?.field("statusState") ?? null
  readonly property var activeColorField: pluginApi?.field("activeColor") ?? null
  readonly property var inactiveColorField: pluginApi?.field("inactiveColor") ?? null

  readonly property int valueRefreshInterval: root.refreshIntervalField?.value ?? 5000
  readonly property string iconColor: root.iconColorField?.value ?? "none"
  readonly property string statusState: root.statusStateField?.value ?? "all"
  readonly property string activeColor: root.activeColorField?.value ?? "success"
  readonly property string inactiveColor: root.inactiveColorField?.value ?? "error"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("MiniDocker", "Cannot save settings: pluginApi is null");
      return;
    }
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("MiniDocker", "Settings saved successfully");
    });
  }

  spacing: Style.marginM
  Component.onCompleted: {
    Logger.i("MiniDocker", "Settings UI loaded");
  }

  ListModel {
    id: intervalModel

    ListElement {
      name: "1 Second"
      key: "1000"
    }

    ListElement {
      name: "5 Seconds"
      key: "5000"
    }

    ListElement {
      name: "10 Seconds"
      key: "10000"
    }

    ListElement {
      name: "30 Seconds"
      key: "30000"
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: (pluginApi && pluginApi.tr) ? pluginApi.tr("settings.refresh_interval_label") : "Refresh Interval"
      description: (pluginApi && pluginApi.tr) ? pluginApi.tr("settings.refresh_interval_description") : "How often the plugin checks for container status changes"
    }

    NPluginSettingsField {
      field: root.refreshIntervalField
      NComboBox {
        Layout.fillWidth: true
        model: intervalModel
        currentKey: root.valueRefreshInterval.toString()
        onSelected: key => {
          root.refreshIntervalField.set(parseInt(key));
        }
      }
    }

    Text {
      text: ((pluginApi && pluginApi.tr) ? pluginApi.tr("settings.current_value") : "Selected: {value} ms").replace("{value}", root.valueRefreshInterval)
      color: AtmoColor.mOnSurfaceVariant
      font.pointSize: Style.fontSizeS
    }
  }

  NPluginSettingsField {
    field: root.iconColorField
    NColorChoice {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.icon_color_label")
      description: pluginApi?.tr("settings.icon_color_description")
      currentKey: root.iconColor
      onSelected: key => root.iconColorField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.activeColorField
    NColorChoice {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.active_color_label")
      description: pluginApi?.tr("settings.active_color_description")
      currentKey: root.activeColor
      onSelected: key => root.activeColorField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.inactiveColorField
    NColorChoice {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.inactive_color_label")
      description: pluginApi?.tr("settings.inactive_color_description")
      currentKey: root.inactiveColor
      onSelected: key => root.inactiveColorField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.statusStateField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.status_state_label")
      description: pluginApi?.tr("settings.status_state_description")
      model: [
        {
          "key": "all",
          "name": pluginApi?.tr("settings.status_state_always")
        },
        {
          "key": "running-only",
          "name": pluginApi?.tr("settings.status_state_running_only")
        },
        {
          "key": "hidden",
          "name": pluginApi?.tr("settings.status_state_hidden")
        }
      ]
      currentKey: root.statusState
      onSelected: key => root.statusStateField.set(key)
    }
  }
}
