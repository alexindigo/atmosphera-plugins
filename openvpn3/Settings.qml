import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null
  readonly property var displayModeField: pluginApi?.field("displayMode") ?? null
  readonly property var connectedColorField: pluginApi?.field("connectedColor") ?? null
  readonly property var disconnectedColorField: pluginApi?.field("disconnectedColor") ?? null
  readonly property var pollIntervalField: pluginApi?.field("pollInterval") ?? null
  readonly property var showNotificationsField: pluginApi?.field("showNotifications") ?? null
  readonly property var defaultPersistentField: pluginApi?.field("defaultPersistent") ?? null
  readonly property var hideWhenInactiveField: pluginApi?.field("hideWhenInactive") ?? null

  readonly property string editDisplayMode: root.displayModeField?.value ?? "onhover"
  readonly property string editConnectedColor: root.connectedColorField?.value ?? "primary"
  readonly property string editDisconnectedColor: root.disconnectedColorField?.value ?? "none"
  readonly property int editPollInterval: root.pollIntervalField?.value ?? 5
  readonly property bool editShowNotifications: root.showNotificationsField?.value ?? true
  readonly property bool editDefaultPersistent: root.defaultPersistentField?.value ?? true
  readonly property bool editHideWhenInactive: root.hideWhenInactiveField?.value ?? false

  readonly property var displayModeModel: [
    {
      "key": "onhover",
      "name": pluginApi?.tr("settings.displayMode.onhover")
    },
    {
      "key": "alwaysShow",
      "name": pluginApi?.tr("settings.displayMode.alwaysShow")
    },
    {
      "key": "alwaysHide",
      "name": pluginApi?.tr("settings.displayMode.alwaysHide")
    }
  ]

  readonly property var pollIntervalModel: [
    {
      "key": "2",
      "name": pluginApi?.tr("settings.pollInterval.2s")
    },
    {
      "key": "5",
      "name": pluginApi?.tr("settings.pollInterval.5s")
    },
    {
      "key": "10",
      "name": pluginApi?.tr("settings.pollInterval.10s")
    },
    {
      "key": "30",
      "name": pluginApi?.tr("settings.pollInterval.30s")
    }
  ]

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("OpenVPN3", "Settings saved");
    });
  }

  NLabel {
    label: pluginApi?.tr("settings.bar.label")
    description: pluginApi?.tr("settings.bar.description")
    Layout.fillWidth: true
  }

  NPluginSettingsField {
    field: root.displayModeField
    NComboBox {
      label: pluginApi?.tr("settings.displayMode.label")
      description: pluginApi?.tr("settings.displayMode.description")
      minimumWidth: 200
      model: root.displayModeModel
      currentKey: root.editDisplayMode
      onSelected: key => root.displayModeField.set(key)
    }
  }

  NLabel {
    label: pluginApi?.tr("settings.colors.label")
    description: pluginApi?.tr("settings.colors.description")
    Layout.fillWidth: true
  }

  NPluginSettingsField {
    field: root.connectedColorField
    NColorChoice {
      label: pluginApi?.tr("settings.colors.connected.label")
      description: pluginApi?.tr("settings.colors.connected.description")
      currentKey: root.editConnectedColor
      onSelected: key => root.connectedColorField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.disconnectedColorField
    NColorChoice {
      label: pluginApi?.tr("settings.colors.disconnected.label")
      description: pluginApi?.tr("settings.colors.disconnected.description")
      currentKey: root.editDisconnectedColor
      onSelected: key => root.disconnectedColorField.set(key)
    }
  }

  NLabel {
    label: pluginApi?.tr("settings.behavior.label")
    description: pluginApi?.tr("settings.behavior.description")
    Layout.fillWidth: true
  }

  NPluginSettingsField {
    field: root.pollIntervalField
    NComboBox {
      label: pluginApi?.tr("settings.pollInterval.label")
      description: pluginApi?.tr("settings.pollInterval.description")
      minimumWidth: 200
      model: root.pollIntervalModel
      currentKey: String(root.editPollInterval)
      defaultValue: "5"
      onSelected: key => root.pollIntervalField.set(parseInt(key))
    }
  }

  NPluginSettingsField {
    field: root.showNotificationsField
    NToggle {
      label: pluginApi?.tr("settings.showNotifications.label")
      description: pluginApi?.tr("settings.showNotifications.description")
      checked: root.editShowNotifications
      onToggled: checked => root.showNotificationsField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.defaultPersistentField
    NToggle {
      label: pluginApi?.tr("settings.defaultPersistent.label")
      description: pluginApi?.tr("settings.defaultPersistent.description")
      checked: root.editDefaultPersistent
      onToggled: checked => root.defaultPersistentField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.hideWhenInactiveField
    NToggle {
      label: pluginApi?.tr("settings.hideWhenInactive.label")
      description: pluginApi?.tr("settings.hideWhenInactive.description")
      checked: root.editHideWhenInactive
      onToggled: checked => root.hideWhenInactiveField.set(checked)
    }
  }
}
