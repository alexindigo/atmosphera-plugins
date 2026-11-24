import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  property var pluginApi: null
  readonly property var serverUrlField: pluginApi?.field("serverUrl") ?? null
  readonly property var topicsField: pluginApi?.field("topics") ?? null
  readonly property var authMethodField: pluginApi?.field("authMethod") ?? null
  readonly property var authTokenField: pluginApi?.field("authToken") ?? null
  readonly property var authUsernameField: pluginApi?.field("authUsername") ?? null
  readonly property var authPasswordField: pluginApi?.field("authPassword") ?? null
  readonly property var pollIntervalField: pluginApi?.field("pollInterval") ?? null
  readonly property var enableToastsField: pluginApi?.field("enableToasts") ?? null
  readonly property var maxMessagesField: pluginApi?.field("maxMessages") ?? null

  // Edit copies
  readonly property string editServerUrl: root.serverUrlField?.value ?? "https://ntfy.sh"
  readonly property string editTopics: root.topicsField?.value ?? ""
  readonly property string editAuthMethod: root.authMethodField?.value ?? "none"
  readonly property string editAuthToken: root.authTokenField?.value ?? ""
  readonly property string editAuthUsername: root.authUsernameField?.value ?? ""
  readonly property string editAuthPassword: root.authPasswordField?.value ?? ""
  readonly property int editPollInterval: root.pollIntervalField?.value ?? 30
  readonly property bool editEnableToasts: root.enableToastsField?.value ?? true
  readonly property int editMaxMessages: root.maxMessagesField?.value ?? 100
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  NLabel {
    visible: root.pluginApi?.scopeKind === "instance"
    label: root.pluginApi?.tr("settings.shared-effect-label")
    description: root.pluginApi?.tr("settings.shared-effect")
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }

  // --- Server URL ---
  NPluginSettingsField {
    field: root.serverUrlField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.server.label")
      description: pluginApi?.tr("settings.server.desc")
      text: root.editServerUrl
      onEditCommitted: {
        root.serverUrlField.set(text);
      }
    }
  }

  // --- Topics ---
  NPluginSettingsField {
    field: root.topicsField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.topics.label")
      description: pluginApi?.tr("settings.topics.desc")
      text: root.editTopics
      onEditCommitted: {
        root.topicsField.set(text);
      }
    }
  }

  // --- Auth Method ---
  NPluginSettingsField {
    field: root.authMethodField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.auth.label")
      description: pluginApi?.tr("settings.auth.desc")
      minimumWidth: 200
      model: [
        {
          "key": "none",
          "name": pluginApi?.tr("settings.auth.none")
        },
        {
          "key": "token",
          "name": pluginApi?.tr("settings.auth.token")
        },
        {
          "key": "basic",
          "name": pluginApi?.tr("settings.auth.basic")
        }
      ]
      currentKey: root.editAuthMethod
      onSelected: key => {
        root.authMethodField.set(key);
      }
    }
  }

  // --- Token (visible when auth = token) ---
  NPluginSettingsField {
    field: root.authTokenField
    visible: root.editAuthMethod === "token"
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.token.label")
      description: pluginApi?.tr("settings.token.desc")
      text: root.editAuthToken
      onEditCommitted: {
        root.authTokenField.set(text);
      }
    }
  }

  // --- Username (visible when auth = basic) ---
  NPluginSettingsField {
    field: root.authUsernameField
    visible: root.editAuthMethod === "basic"
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.username.label")
      description: pluginApi?.tr("settings.username.desc")
      text: root.editAuthUsername
      onEditCommitted: {
        root.authUsernameField.set(text);
      }
    }
  }

  // --- Password (visible when auth = basic) ---
  NPluginSettingsField {
    field: root.authPasswordField
    visible: root.editAuthMethod === "basic"
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.password.label")
      description: pluginApi?.tr("settings.password.desc")
      text: root.editAuthPassword
      onEditCommitted: {
        root.authPasswordField.set(text);
      }
    }
  }

  // --- Poll Interval ---
  NPluginSettingsField {
    field: root.pollIntervalField
    NSpinBox {
      label: pluginApi?.tr("settings.pollInterval.label")
      description: pluginApi?.tr("settings.pollInterval.desc")
      from: 15
      to: 3600
      stepSize: 15
      value: root.editPollInterval
      requestValue: value => {
        root.pollIntervalField.set(value);
      }
    }
  }

  // --- Enable Toasts ---
  NPluginSettingsField {
    field: root.enableToastsField
    NToggle {
      label: pluginApi?.tr("settings.enableToasts.label")
      description: pluginApi?.tr("settings.enableToasts.desc")
      checked: root.editEnableToasts
      onToggled: checked => {
        root.enableToastsField.set(checked);
      }
    }
  }

  // --- Max Messages ---
  NPluginSettingsField {
    field: root.maxMessagesField
    NSpinBox {
      label: pluginApi?.tr("settings.maxMessages.label")
      description: pluginApi?.tr("settings.maxMessages.desc")
      from: 10
      to: 500
      stepSize: 10
      value: root.editMaxMessages
      requestValue: value => {
        root.maxMessagesField.set(value);
      }
    }
  }
}
