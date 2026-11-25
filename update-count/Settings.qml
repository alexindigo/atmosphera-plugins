import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  NText {
    Layout.fillWidth: true
    visible: root.pluginApi?.scopeKind === "instance"
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
    wrapMode: Text.WordWrap
    color: AtmoColor.mOnSurfaceVariant
    pointSize: Style.fontSizeS
  }
  readonly property var updateIntervalMinutesField: pluginApi?.field("updateIntervalMinutes") ?? null
  readonly property var updateTerminalCommandField: pluginApi?.field("updateTerminalCommand") ?? null
  readonly property var currentIconNameField: pluginApi?.field("currentIconName") ?? null
  readonly property var hideOnZeroField: pluginApi?.field("hideOnZero") ?? null
  readonly property var customCmdGetNumUpdatesField: pluginApi?.field("customCmdGetNumUpdates") ?? null
  readonly property var customCmdDoSystemUpdateField: pluginApi?.field("customCmdDoSystemUpdate") ?? null

  readonly property int updateIntervalMinutes: root.updateIntervalMinutesField?.value
  readonly property string updateTerminalCommand: root.updateTerminalCommandField?.value
  readonly property string currentIconName: root.currentIconNameField?.value
  readonly property bool hideOnZero: root.hideOnZeroField?.value

  readonly property string customCmdGetNumUpdates: root.customCmdGetNumUpdatesField?.value || ""
  readonly property string customCmdDoSystemUpdate: root.customCmdDoSystemUpdateField?.value || ""
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _applyEffectPending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._applyEffectPending = false;
      root.pluginApi.mainInstance?.settingsConsumerFor(root.pluginApi.runtimeContext)?.startGetNumUpdates();
      Logger.i("UpdateCount", "Settings saved successfully");
      root.pluginApi.withCurrentScreen(s => root.pluginApi.closePanel(s));
    }
  }

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.i("UpdateCount", "Settings UI loaded");
  }

  //
  // ------ General ------
  //
  NPluginSettingsField {
    field: root.hideOnZeroField
    NToggle {
      id: widgetSwitch
      label: pluginApi?.tr("settings.hideWidget.label")
      description: pluginApi?.tr("settings.hideWidget.desc")
      checked: root.hideOnZero
      onToggled: function (checked) {
        root.hideOnZeroField.set(checked);
      }
    }
  }

  RowLayout {
    spacing: Style.marginL

    NLabel {
      label: pluginApi?.tr("settings.currentIconName.label")
      description: pluginApi?.tr("settings.currentIconName.desc")
    }

    NText {
      text: root.currentIconName
      color: Settings.data.colorSchemes.darkMode ? AtmoColor.mPrimary : AtmoColor.mOnPrimary
    }

    AtmoIcon {
      icon: root.currentIconName
      color: Settings.data.colorSchemes.darkMode ? AtmoColor.mPrimary : AtmoColor.mOnPrimary
    }

    NPluginSettingsField {
      field: root.currentIconNameField
      NButton {
        text: pluginApi?.tr("settings.changeIcon.label")
        onClicked: {
          Logger.i("UpdateCount", "Icon selector button clicked.");
          changeIcon.open();
        }
      }
    }

    AtmoIconPicker {
      id: changeIcon
      onIconSelected: function (icon) {
        root.currentIconNameField.set(icon);
      }
    }
  }

  ColumnLayout {
    spacing: Style.marginM

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NLabel {
        label: pluginApi?.tr("settings.updateInterval.label")
        description: pluginApi?.tr("settings.updateInterval.desc")
      }

      NText {
        text: root.updateIntervalMinutes.toString().padStart(3, " ") + " minutes"
        color: Settings.data.colorSchemes.darkMode ? AtmoColor.mOnSurface : AtmoColor.mOnPrimary
      }
    }

    NPluginSettingsField {
      field: root.updateIntervalMinutesField
      NSlider {
        id: rangeUpdateIntervalMinutes
        objectName: "settings-range-updateIntervalMinutes"
        Layout.fillWidth: true
        from: 5
        to: 300
        value: root.updateIntervalMinutes
        stepSize: 5
        onMoved: {
          root.updateIntervalMinutesField.set(value);
        }
      }
    }
  }

  NDivider {
    visible: true
    Layout.fillWidth: true
    Layout.topMargin: Style.marginL
    Layout.bottomMargin: Style.marginL
  }

  //
  // ------ Custom commands ------
  //
  NPluginSettingsField {
    field: root.customCmdGetNumUpdatesField
    NTextInput {
      label: pluginApi?.tr("settings.customCmdGetNumUpdates.label")
      description: pluginApi?.tr("settings.customCmdGetNumUpdates.desc")
      placeholderText: pluginApi?.tr("settings.customCmdGetNumUpdates.placeholder")
      text: root.customCmdGetNumUpdates
      onEditCommitted: root.customCmdGetNumUpdatesField.set(text)
    }
  }

  NPluginSettingsField {
    field: root.customCmdDoSystemUpdateField
    NTextInput {
      label: pluginApi?.tr("settings.customCmdDoSystemUpdate.label")
      description: pluginApi?.tr("settings.customCmdDoSystemUpdate.desc")
      placeholderText: pluginApi?.tr("settings.customCmdDoSystemUpdate.placeholder")
      text: root.customCmdDoSystemUpdate
      onEditCommitted: root.customCmdDoSystemUpdateField.set(text)
    }
  }

  NPluginSettingsField {
    field: root.updateTerminalCommandField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.terminal.label")
      description: pluginApi?.tr("settings.terminal.desc")
      placeholderText: pluginApi?.tr("settings.terminal.placeholder")
      text: root.updateTerminalCommand
      onEditCommitted: root.updateTerminalCommandField.set(text || pluginApi?.manifest?.metadata?.defaultSettings?.updateTerminalCommand || "")
    }
  }

  NDivider {
    visible: true
    Layout.fillWidth: true
    Layout.topMargin: Style.marginL
    Layout.bottomMargin: Style.marginL
  }

  //
  // ------ Information ------
  //
  NLabel {
    label: pluginApi?.tr("settings.currentCommands.label")
  }

  ColumnLayout {
    NText {
      text: pluginApi?.tr("settings.currentNumUpdatesCmd.label")
      color: Settings.data.colorSchemes.darkMode ? AtmoColor.mSecondary : AtmoColor.mOnSecondary
    }
    NLabel {
      description: `> ${root.customCmdGetNumUpdates || pluginApi?.mainInstance?.updater?.cmdGetNumUpdates || "NA"}`
    }
  }

  ColumnLayout {
    NText {
      text: pluginApi?.tr("settings.currentUpdateCmd.label")
      color: Settings.data.colorSchemes.darkMode ? AtmoColor.mSecondary : AtmoColor.mOnSecondary
    }

    NLabel {
      description: `> ${root.customCmdDoSystemUpdate || pluginApi?.mainInstance?.updater?.cmdDoSystemUpdate || "NA"}`
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("UpdateCount", "Cannot save settings: pluginApi is null");
      return;
    }

    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true;
  }
}
