import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var hostField: pluginApi?.field("host") ?? null
  readonly property var portField: pluginApi?.field("port") ?? null
  readonly property var userField: pluginApi?.field("user") ?? null
  readonly property var rememberLastTargetField: pluginApi?.field("rememberLastTarget") ?? null
  readonly property var autoConnectOnStartupField: pluginApi?.field("autoConnectOnStartup") ?? null
  readonly property var panelWidthField: pluginApi?.field("panelWidth") ?? null
  readonly property var panelHeightField: pluginApi?.field("panelHeight") ?? null
  readonly property var terminalColsField: pluginApi?.field("terminalCols") ?? null
  readonly property var terminalRowsField: pluginApi?.field("terminalRows") ?? null
  readonly property var terminalFontSizeField: pluginApi?.field("terminalFontSize") ?? null
  readonly property var showBarTextField: pluginApi?.field("showBarText") ?? null
  readonly property var toggleShortcutNameField: pluginApi?.field("toggleShortcutName") ?? null
  readonly property string valueHost: root.hostField?.value ?? ""
  readonly property int valuePort: root.portField?.value ?? 22
  readonly property string valueUser: root.userField?.value ?? ""
  readonly property bool valueRememberLastTarget: root.rememberLastTargetField?.value ?? true
  readonly property bool valueAutoConnectOnStartup: root.autoConnectOnStartupField?.value ?? false
  readonly property int valuePanelWidth: root.panelWidthField?.value ?? 1200
  readonly property int valuePanelHeight: root.panelHeightField?.value ?? 760
  readonly property int valueTerminalCols: root.terminalColsField?.value ?? 180
  readonly property int valueTerminalRows: root.terminalRowsField?.value ?? 32
  readonly property int valueTerminalFontSize: root.terminalFontSizeField?.value ?? 11
  readonly property bool valueShowBarText: root.showBarTextField?.value ?? true
  readonly property string valueToggleShortcutName: root.toggleShortcutNameField?.value ?? "hermes-toggle"

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi)
      return;

    pluginApi.saveSettings();
  }

  spacing: Style.marginL

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
    color: AtmoColor.mOnSurfaceVariant
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
  }

  NPluginSettingsField {
    field: root.hostField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.host.label")
      description: pluginApi?.tr("settings.host.desc")
      placeholderText: pluginApi?.tr("settings.host.placeholder")
      text: root.valueHost
      onEditCommitted: root.hostField.set(text)
    }
  }

  NPluginSettingsField {
    field: root.userField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.user.label")
      placeholderText: pluginApi?.tr("settings.user.placeholder")
      text: root.valueUser
      onEditCommitted: root.userField.set(text)
    }
  }

  NPluginSettingsField {
    field: root.portField
    NSpinBox {
      label: pluginApi?.tr("settings.port.label")
      from: 1
      to: 65535
      stepSize: 1
      value: root.valuePort
      onValueModified: value => root.portField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.panelWidthField
    NSpinBox {
      label: pluginApi?.tr("settings.panelWidth.label")
      description: pluginApi?.tr("settings.panelWidth.desc")
      from: 720
      to: 1800
      stepSize: 20
      value: root.valuePanelWidth
      onValueModified: value => root.panelWidthField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.panelHeightField
    NSpinBox {
      label: pluginApi?.tr("settings.panelHeight.label")
      description: pluginApi?.tr("settings.panelHeight.desc")
      from: 560
      to: 1200
      stepSize: 20
      value: root.valuePanelHeight
      onValueModified: value => root.panelHeightField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.terminalColsField
    NSpinBox {
      label: pluginApi?.tr("settings.terminalCols.label")
      from: 80
      to: 240
      stepSize: 5
      value: root.valueTerminalCols
      onValueModified: value => root.terminalColsField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.terminalRowsField
    NSpinBox {
      label: pluginApi?.tr("settings.terminalRows.label")
      from: 20
      to: 80
      stepSize: 1
      value: root.valueTerminalRows
      onValueModified: value => root.terminalRowsField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.terminalFontSizeField
    NSpinBox {
      label: pluginApi?.tr("settings.terminalFontSize.label")
      from: 8
      to: 20
      stepSize: 1
      value: root.valueTerminalFontSize
      onValueModified: value => root.terminalFontSizeField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.autoConnectOnStartupField
    NToggle {
      label: pluginApi?.tr("settings.autoConnectOnStartup.label")
      checked: root.valueAutoConnectOnStartup
      onToggled: checked => root.autoConnectOnStartupField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.rememberLastTargetField
    NToggle {
      label: pluginApi?.tr("settings.rememberLastTarget.label")
      checked: root.valueRememberLastTarget
      onToggled: checked => root.rememberLastTargetField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.showBarTextField
    NToggle {
      label: pluginApi?.tr("settings.showBarText.label")
      checked: root.valueShowBarText
      onToggled: checked => root.showBarTextField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.toggleShortcutNameField
    visible: root.pluginApi?.scopeKind !== "instance"
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.toggleShortcut.label")
      description: pluginApi?.tr("settings.toggleShortcut.desc", {
                                   name: root.valueToggleShortcutName
                                 })
      placeholderText: "hermes-toggle"
      text: root.valueToggleShortcutName
      onEditCommitted: root.toggleShortcutNameField.set(text)
    }
  }
}
