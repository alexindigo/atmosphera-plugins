import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    // Edit copies
    property string editServerUrl: displayBaseline.editServerUrl
    property string editTopics: displayBaseline.editTopics
    property string editAuthMethod: displayBaseline.editAuthMethod
    property string editAuthToken: displayBaseline.editAuthToken
    property string editAuthUsername: displayBaseline.editAuthUsername
    property string editAuthPassword: displayBaseline.editAuthPassword
    property int editPollInterval: displayBaseline.editPollInterval
    property bool editEnableToasts: displayBaseline.editEnableToasts
    property int editMaxMessages: displayBaseline.editMaxMessages
    NSettingsBaseline {
        id: displayBaseline
        readonly property string editServerUrl: cfg.serverUrl ?? defaults.serverUrl ?? "https://ntfy.sh"
        readonly property string editTopics: cfg.topics ?? defaults.topics ?? ""
        readonly property string editAuthMethod: cfg.authMethod ?? defaults.authMethod ?? "none"
        readonly property string editAuthToken: cfg.authToken ?? defaults.authToken ?? ""
        readonly property string editAuthUsername: cfg.authUsername ?? defaults.authUsername ?? ""
        readonly property string editAuthPassword: cfg.authPassword ?? defaults.authPassword ?? ""
        readonly property int editPollInterval: cfg.pollInterval ?? defaults.pollInterval ?? 30
        readonly property bool editEnableToasts: cfg.enableToasts ?? defaults.enableToasts ?? true
        readonly property int editMaxMessages: cfg.maxMessages ?? defaults.maxMessages ?? 100
    }
    readonly property bool settingsDirty: displayBaseline.differs({editServerUrl: root.editServerUrl, editTopics: root.editTopics, editAuthMethod: root.editAuthMethod, editAuthToken: root.editAuthToken, editAuthUsername: root.editAuthUsername, editAuthPassword: root.editAuthPassword, editPollInterval: root.editPollInterval, editEnableToasts: root.editEnableToasts, editMaxMessages: root.editMaxMessages})

    function saveSettings() {
        if (!pluginApi) return;
        pluginApi.pluginSettings.serverUrl = editServerUrl;
        pluginApi.pluginSettings.topics = editTopics;
        pluginApi.pluginSettings.authMethod = editAuthMethod;
        pluginApi.pluginSettings.authToken = editAuthToken;
        pluginApi.pluginSettings.authUsername = editAuthUsername;
        pluginApi.pluginSettings.authPassword = editAuthPassword;
        pluginApi.pluginSettings.pollInterval = editPollInterval;
        pluginApi.pluginSettings.enableToasts = editEnableToasts;
        pluginApi.pluginSettings.maxMessages = editMaxMessages;
        pluginApi.saveSettings();
    }

    // --- Server URL ---
    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.server.label")
        description: pluginApi?.tr("settings.server.desc")
        text: root.editServerUrl
        onEditingFinished: {
            root.editServerUrl = text;
            root.saveSettings();
        }
    }

    // --- Topics ---
    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.topics.label")
        description: pluginApi?.tr("settings.topics.desc")
        text: root.editTopics
        onEditingFinished: {
            root.editTopics = text;
            root.saveSettings();
        }
    }

    // --- Auth Method ---
    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.auth.label")
        description: pluginApi?.tr("settings.auth.desc")
        minimumWidth: 200
        model: [
            { "key": "none", "name": pluginApi?.tr("settings.auth.none") },
            { "key": "token", "name": pluginApi?.tr("settings.auth.token") },
            { "key": "basic", "name": pluginApi?.tr("settings.auth.basic") }
        ]
        currentKey: root.editAuthMethod
        onSelected: key => {
            root.editAuthMethod = key;
            root.saveSettings();
        }
    }

    // --- Token (visible when auth = token) ---
    NTextInput {
        Layout.fillWidth: true
        visible: root.editAuthMethod === "token"
        label: pluginApi?.tr("settings.token.label")
        description: pluginApi?.tr("settings.token.desc")
        text: root.editAuthToken
        onEditingFinished: {
            root.editAuthToken = text;
            root.saveSettings();
        }
    }

    // --- Username (visible when auth = basic) ---
    NTextInput {
        Layout.fillWidth: true
        visible: root.editAuthMethod === "basic"
        label: pluginApi?.tr("settings.username.label")
        description: pluginApi?.tr("settings.username.desc")
        text: root.editAuthUsername
        onEditingFinished: {
            root.editAuthUsername = text;
            root.saveSettings();
        }
    }

    // --- Password (visible when auth = basic) ---
    NTextInput {
        Layout.fillWidth: true
        visible: root.editAuthMethod === "basic"
        label: pluginApi?.tr("settings.password.label")
        description: pluginApi?.tr("settings.password.desc")
        text: root.editAuthPassword
        onEditingFinished: {
            root.editAuthPassword = text;
            root.saveSettings();
        }
    }

    // --- Poll Interval ---
    NSpinBox {
        label: pluginApi?.tr("settings.pollInterval.label")
        description: pluginApi?.tr("settings.pollInterval.desc")
        from: 15
        to: 3600
        stepSize: 15
        value: root.editPollInterval
        onValueModified: {
            root.editPollInterval = value;
            root.saveSettings();
        }
    }

    // --- Enable Toasts ---
    NToggle {
        label: pluginApi?.tr("settings.enableToasts.label")
        description: pluginApi?.tr("settings.enableToasts.desc")
        checked: root.editEnableToasts
        onToggled: checked => {
            root.editEnableToasts = checked;
            root.saveSettings();
        }
    }

    // --- Max Messages ---
    NSpinBox {
        label: pluginApi?.tr("settings.maxMessages.label")
        description: pluginApi?.tr("settings.maxMessages.desc")
        from: 10
        to: 500
        stepSize: 10
        value: root.editMaxMessages
        onValueModified: {
            root.editMaxMessages = value;
            root.saveSettings();
        }
    }
}
