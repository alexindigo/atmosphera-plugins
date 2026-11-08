import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM
    Layout.fillWidth: true

    required property var pluginApi
    required property bool active
    NSettingsBaseline {
        id: displayBaseline
        readonly property bool hardwareAcceleration: root.pluginApi?.initialSettings?.hardwareAcceleration || false
        readonly property string mpvSocket: root.pluginApi?.initialSettings?.mpvSocket || root.pluginApi?.manifest?.metadata?.defaultSettings?.mpvSocket || "/tmp/mpv-socket"
        readonly property string profile: root.pluginApi?.initialSettings?.profile || root.pluginApi?.manifest?.metadata?.defaultSettings?.profile || "default"
        readonly property string fillMode: root.pluginApi?.initialSettings?.fillMode || root.pluginApi?.manifest?.metadata?.defaultSettings?.fillMode || "fit"
    }
    readonly property bool settingsDirty: displayBaseline.differs({hardwareAcceleration: hardwareAcceleration, mpvSocket: mpvSocket, profile: profile, fillMode: fillMode})
    
    property bool hardwareAcceleration:
        pluginApi?.initialSettings?.hardwareAcceleration ||
        false

    property string mpvSocket: 
        pluginApi?.initialSettings?.mpvSocket ||
        pluginApi?.manifest?.metadata?.defaultSettings?.mpvSocket ||
        "/tmp/mpv-socket"

    property string profile:
        pluginApi?.initialSettings?.profile ||
        pluginApi?.manifest?.metadata?.defaultSettings?.profile ||
        "default"
    
    property string fillMode:
        pluginApi?.initialSettings?.fillMode ||
        pluginApi?.manifest?.metadata?.defaultSettings?.fillMode ||
        "fit"

    // Profile
    NComboBox {
        enabled: root.active
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.profile.label") || "Profile"
        description: pluginApi?.tr("settings.profile.description") || "The profile that mpv uses. Use fast for better performance.";
        defaultValue: "default"
        model: [
            {
                "key": "default",
                "name": pluginApi?.tr("settings.profile.default") || "Default"
            },
            {
                "key": "fast",
                "name": pluginApi?.tr("settings.profile.fast") || "Fast"
            },
            {
                "key": "high-quality",
                "name": pluginApi?.tr("settings.profile.high_quality") || "High Quality"
            },
            {
                "key": "low-latency",
                "name": pluginApi?.tr("settings.profile.low_latency") || "Low Latency"
            }
        ]
        currentKey: root.profile
        onSelected: key => root.profile = key
    }

    // Fill Mode
    NComboBox {
        enabled: root.active
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.fill_mode.label") || "Fill mode"
        description: pluginApi?.tr("settings.fill_mode.description") || "The fill mode that mpv uses.";
        defaultValue: "fit"
        model: [
            {
                "key": "fit",
                "name": pluginApi?.tr("settings.fill_mode.fit") || "Fit"
            },
            {
                "key": "crop",
                "name": pluginApi?.tr("settings.fill_mode.crop") || "Crop"
            },
            {
                "key": "stretch",
                "name": pluginApi?.tr("settings.fill_mode.stretch") || "Stretch"

            }
        ]
        currentKey: root.fillMode
        onSelected: key => root.fillMode = key
    }

    // Hardware Acceleration
    NToggle {
        enabled: root.active
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.hardware_acceleration.label") || "Hardware Acceleration"
        description: pluginApi?.tr("settings.hardware_acceleration.description") || "Offloads video decoding from cpu to gpu / dedicated hardware.";
        checked: root.hardwareAcceleration
        onToggled: checked => root.hardwareAcceleration = checked
        defaultValue: false
    }

    // MPV Socket path
    NTextInput {
        enabled: root.active
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.mpv_socket.title_label") || "Mpvpaper socket"
        description: pluginApi?.tr("settings.mpv_socket.title_description") || "The mpvpaper socket that noctalia connects to"
        placeholderText: pluginApi?.tr("settings.mpv_socket.input_placeholder") || "Example: /tmp/mpv-socket"
        text: root.mpvSocket
        onTextChanged: root.mpvSocket = text
    }


    /********************************
    * Save settings functionality
    ********************************/
    function saveSettings() {
        if(!pluginApi) {
            Logger.e("mpvpaper", "Cannot save: pluginApi is null");
            return;
        }

        pluginApi.pluginSettings.hardwareAcceleration = hardwareAcceleration;
        pluginApi.pluginSettings.mpvSocket = mpvSocket;
        pluginApi.pluginSettings.profile = profile;
        pluginApi.pluginSettings.fillMode = fillMode;
    }
}
