import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM
    Layout.fillWidth: true


    /***************************
    * PROPERTIES
    ***************************/
    // Required properties
    required property var    pluginApi
    required property bool   enabled
    required property string selectedMonitor
    required property var monitorSettings
    NSettingsBaseline {
        id: displayBaseline
        readonly property bool hardwareAcceleration: root.pluginApi?.initialSettings?.[root.selectedMonitor]?.hardwareAcceleration ?? false
        readonly property string profile: root.pluginApi?.initialSettings?.[root.selectedMonitor]?.profile ?? root.pluginApi?.manifest?.metadata?.defaultSettings?.profile ?? ""
        readonly property string mpvSocket: root.pluginApi?.initialSettings?.mpvSocket ?? root.pluginApi?.manifest?.metadata?.defaultSettings?.mpvSocket ?? ""
    }
    readonly property bool settingsDirty: displayBaseline.differs({hardwareAcceleration: hardwareAcceleration, profile: profile, mpvSocket: mpvSocket})

    // Monitor specific properties
    property bool hardwareAcceleration: monitorSettings.hardwareAcceleration ?? false
    property string profile: monitorSettings.profile ?? pluginApi?.manifest?.metadata?.defaultSettings?.profile ?? ""

    // Global properties
    property string mpvSocket: displayBaseline.mpvSocket

    // Signals
    signal saveMonitorProperty(key: string, value: var);


    /***************************
    * EVENTS
    ***************************/
    function loadMonitor(record) {
        hardwareAcceleration = record.hardwareAcceleration ?? false
        profile = record.profile ?? pluginApi?.manifest?.metadata?.defaultSettings?.profile ?? ""
    }


    /***************************
    * COMPONENTS
    ***************************/
    // Profile
    NComboBox {
        enabled: root.enabled
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("settings.advanced.profile.label")
        description: root.pluginApi?.tr("settings.advanced.profile.description")
        defaultValue: "default"
        model: [
            {
                "key": "default",
                "name": root.pluginApi?.tr("settings.advanced.profile.default")
            },
            {
                "key": "fast",
                "name": root.pluginApi?.tr("settings.advanced.profile.fast")
            },
            {
                "key": "high-quality",
                "name": root.pluginApi?.tr("settings.advanced.profile.high_quality")
            },
            {
                "key": "low-latency",
                "name": root.pluginApi?.tr("settings.advanced.profile.low_latency")
            }
        ]
        currentKey: root.profile
        onSelected: key => root.profile = key
    }

    // Hardware Acceleration
    NToggle {
        enabled: root.enabled
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("settings.advanced.hardware_acceleration.label")
        description: root.pluginApi?.tr("settings.advanced.hardware_acceleration.description")
        checked: root.hardwareAcceleration
        onToggled: checked => root.hardwareAcceleration = checked
        defaultValue: false
    }

    // MPV Socket path
    NTextInput {
        enabled: root.enabled
        Layout.fillWidth: true
        label:           root.pluginApi?.tr("settings.advanced.mpv_socket.label")
        description:     root.pluginApi?.tr("settings.advanced.mpv_socket.description")
        placeholderText: root.pluginApi?.tr("settings.advanced.mpv_socket.input_placeholder")
        text: root.mpvSocket
        onTextChanged: root.mpvSocket = text
    }


    /********************************
    * Save settings functionality
    ********************************/
    function saveSettings() {
        if(pluginApi == null) {
            Logger.e("video-wallpaper", "Cannot save: pluginApi is null");
            return;
        }

        root.saveMonitorProperty("hardwareAcceleration", hardwareAcceleration);
        root.saveMonitorProperty("profile", profile);

    }
}
