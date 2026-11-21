import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var settingsConsumer: pluginApi?.mainInstance?.settingsConsumerFor(pluginApi.runtimeContext) ?? null
  readonly property var clientIdField: pluginApi?.field("clientId") ?? null
  readonly property var clientSecretField: pluginApi?.field("clientSecret") ?? null
  readonly property var playerIdField: pluginApi?.field("playerId") ?? null
  readonly property var callbackPortField: pluginApi?.field("callbackPort") ?? null
  readonly property bool settingsDirty: false
  spacing: Style.marginM

  AuthorizationStatus {
    Layout.fillWidth: true
    status: root.settingsConsumer?.status ?? (root.pluginApi?.pluginSettings?.accessToken ? "token-available" : "not-authorized")
    translate: key => root.pluginApi?.tr(key) || ""
  }
  NText {
    Layout.fillWidth: true
    text: root.pluginApi?.tr("authorization.settings-guidance") || ""
    wrapMode: Text.WordWrap
  }
  NPluginSettingsField {
    field: root.clientIdField
    NTextInput {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.cid") || ""
      description: root.pluginApi?.tr("settings.cid_desc") || ""
      placeholderText: root.pluginApi?.tr("settings.cid_placeholder") || ""
      text: root.clientIdField?.value || ""
      onEditCommitted: root.clientIdField.set(text)
    }
  }
  NPluginSettingsField {
    field: root.clientSecretField
    NTextInput {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.secret") || ""
      description: root.pluginApi?.tr("settings.secret_desc") || ""
      placeholderText: root.pluginApi?.tr("settings.secret_placeholder") || ""
      text: root.clientSecretField?.value || ""
      onEditCommitted: root.clientSecretField.set(text)
    }
  }
  NPluginSettingsField {
    field: root.callbackPortField
    NSpinBox {
      objectName: "settings-range-editCallbackPort"
      label: root.pluginApi?.tr("settings.callback") || ""
      description: root.pluginApi?.tr("settings.callback_warning") || ""
      from: 0; to: 65535
      value: root.callbackPortField?.value ?? 8888
      onValueModified: value => root.callbackPortField.set(value)
    }
  }
  NPluginSettingsField {
    field: root.playerIdField
    NTextInput {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.pid") || ""
      description: root.pluginApi?.tr("settings.pid_desc") || ""
      placeholderText: root.pluginApi?.tr("settings.pid_placeholder") || ""
      inputMethodHints: Qt.ImhDigitsOnly
      text: root.playerIdField?.value ?? ""
      onEditCommitted: root.playerIdField.set(text)
    }
  }
  function saveSettings() { pluginApi?.saveSettings(); }
}
