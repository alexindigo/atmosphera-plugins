import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    property var pluginApi: null

    // Local state
    property string editUrl: displayBaseline.editUrl
    property string editToken: displayBaseline.editToken
    property bool _applyEffectPending: false
    NSettingsBaseline {
        id: displayBaseline
        readonly property string editUrl: pluginApi?.pluginSettings?.haUrl ?? ""
        readonly property string editToken: pluginApi?.pluginSettings?.haToken ?? ""
    }
    readonly property bool settingsDirty: displayBaseline.differs({editUrl: root.editUrl, editToken: root.editToken})
    Connections {
        target: root.pluginApi
        function onSettingsCompleted(result) {
            if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current") return;
            root._applyEffectPending = false;
            root.pluginApi.mainInstance?.reloadSettings();
        }
    }

    spacing: Style.marginM

    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.url_label")
        placeholderText: pluginApi?.tr("settings.url_placeholder")
        text: root.editUrl
        onTextChanged: root.editUrl = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.token_label")
        placeholderText: pluginApi?.tr("settings.token_placeholder")
        text: root.editToken
        onTextChanged: root.editToken = text
    }

    function saveSettings() {
        pluginApi.pluginSettings.haUrl = root.editUrl;
        pluginApi.pluginSettings.haToken = root.editToken;
        if (pluginApi.saveSettings() !== false)
            root._applyEffectPending = true;
    }
}
