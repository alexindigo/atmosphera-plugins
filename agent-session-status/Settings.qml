import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var bindAddressField: pluginApi?.field("bindAddress") ?? null
  readonly property var portField: pluginApi?.field("port") ?? null
  readonly property var tokenField: pluginApi?.field("token") ?? null
  readonly property var pollIntervalSecField: pluginApi?.field("pollIntervalSec") ?? null
  readonly property var hideWhenEmptyField: pluginApi?.field("hideWhenEmpty") ?? null

  readonly property string editBindAddress: root.bindAddressField?.value ?? "127.0.0.1"
  readonly property int editPort: Number(root.portField?.value ?? 55854)
  readonly property string editToken: root.tokenField?.value ?? ""
  readonly property int editPollIntervalSec: Number(root.pollIntervalSecField?.value ?? 2)
  readonly property bool editHideWhenEmpty: root.hideWhenEmptyField?.value ?? false
  property bool _applyEffectPending: false
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._applyEffectPending = false;
      root.pluginApi.mainInstance?.restartService(root.pluginApi.runtimeContext);
    }
  }

  spacing: Style.marginL

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    text: root.pluginApi?.tr("settings.shared-effect")
    wrapMode: Text.WordWrap
  }

  NPluginSettingsField {
    field: root.bindAddressField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.bindAddress.label")
      description: pluginApi?.tr("settings.bindAddress.desc")
      text: root.editBindAddress
      onEditCommitted: root.bindAddressField.set(text.trim() || "127.0.0.1")
    }
  }

  NPluginSettingsField {
    field: root.portField
    NSpinBox {
      label: pluginApi?.tr("settings.port.label")
      description: pluginApi?.tr("settings.port.desc")
      from: 1
      to: 65535
      value: root.editPort
      onValueModified: value => root.portField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.tokenField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.token.label")
      description: pluginApi?.tr("settings.token.desc")
      text: root.editToken
      onEditCommitted: root.tokenField.set(text.trim())
    }
  }

  NPluginSettingsField {
    field: root.pollIntervalSecField
    NSpinBox {
      label: pluginApi?.tr("settings.pollInterval.label")
      description: pluginApi?.tr("settings.pollInterval.desc")
      from: 1
      to: 30
      value: root.editPollIntervalSec
      onValueModified: value => root.pollIntervalSecField.set(value)
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: hideToggle.implicitHeight

    NPluginSettingsField {
      field: root.hideWhenEmptyField
      NToggle {
        id: hideToggle
        anchors.fill: parent
        label: pluginApi?.tr("settings.hideWhenEmpty.label")
        description: pluginApi?.tr("settings.hideWhenEmpty.desc")
        checked: root.editHideWhenEmpty
        onToggled: checked => root.hideWhenEmptyField.set(checked)
      }
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true;
  }
}
