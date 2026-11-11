import QtQuick
import "../common/MonitorCommands.js" as Commands
import QtQuick.Layouts

import Quickshell

import qs.Commons
import qs.Widgets

import "./advanced"

ColumnLayout {
    id: root
    spacing: Style.marginM
    Layout.fillWidth: true


    /***************************
    * PROPERTIES
    ***************************/
    // Required properties
    required property var pluginApi

    required property string activeBackend
    required enabled
    required property string selectedMonitor
    required property var monitorSettings
    property alias hardwareAcceleration: mpvpaper.hardwareAcceleration
    property alias profile: mpvpaper.profile
    property alias mpvSocket: mpvpaper.mpvSocket
    NSettingsBaseline {
        id: displayBaseline
        readonly property string fillMode: Commands.record(root.pluginApi?.initialSettings?.monitors, root.selectedMonitor)?.fillMode ?? root.pluginApi?.manifest?.metadata?.defaultSettings?.fillMode ?? ""
        readonly property int orientation: Commands.record(root.pluginApi?.initialSettings?.monitors, root.selectedMonitor)?.orientation ?? 0
        ranges: [NSettingsRange { field: "orientation"; from: orientationInput.from; to: orientationInput.to }]
    }
    readonly property bool settingsDirty: displayBaseline.differs({fillMode: fillMode, orientation: orientation}) || mpvpaper.settingsDirty

    // Monitor specific properties
    property string fillMode: monitorSettings.fillMode ?? pluginApi?.manifest?.metadata?.defaultSettings?.fillMode ?? ""
    property int orientation: displayBaseline.project("orientation")
    function loadMonitor(record) {
        fillMode = record.fillMode ?? pluginApi?.manifest?.metadata?.defaultSettings?.fillMode ?? "";
        orientation = Math.max(orientationInput.from, Math.min(orientationInput.to, record.orientation ?? 0));
        mpvpaper.loadMonitor(record);
    }

    // Constants
    readonly property list<string> backends: ["qt6-multimedia", "mpvpaper"]

    // Signals
    signal saveMonitorProperty(key: string, value: var);


    /***************************
    * COMPONENTS
    ***************************/
    // Fill Mode
    NComboBox {
        enabled: root.enabled
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("settings.advanced.fill_mode.label")
        description: root.pluginApi?.tr("settings.advanced.fill_mode.description")
        defaultValue: "fit"
        model: [
            {
                "key": "fit",
                "name": root.pluginApi?.tr("settings.advanced.fill_mode.fit")
            },
            {
                "key": "crop",
                "name": root.pluginApi?.tr("settings.advanced.fill_mode.crop")
            },
            {
                "key": "stretch",
                "name": root.pluginApi?.tr("settings.advanced.fill_mode.stretch")
            }
        ]
        currentKey: root.fillMode
        onSelected: key => root.fillMode = key
    }

    // Orientation
    NValueSlider {
        id: orientationInput
        objectName: "settings-range-orientation"

        enabled: root.enabled
        from: 0
        to: 270
        value: root.orientation
        defaultValue: 0
        stepSize: 90
        text: root.orientation
        label:       root.pluginApi?.tr("settings.advanced.orientation.label")
        description: root.pluginApi?.tr("settings.advanced.orientation.description")
        onMoved: value => root.orientation = value
    }

    NTabView {
        currentIndex: root.backends.indexOf(root.activeBackend)

        VideoWallpaper {
            id: videoWallpaper
            pluginApi: root.pluginApi
            enabled: root.enabled
        }

        Mpvpaper {
            id: mpvpaper
            pluginApi: root.pluginApi
            enabled: root.enabled
            selectedMonitor: root.selectedMonitor
            monitorSettings: root.monitorSettings

            onSaveMonitorProperty: (key, value) => root.saveMonitorProperty(key, value);
        }

        NoBackend {
            pluginApi: root.pluginApi
            enabled: root.enabled
        }
    }


    /********************************
    * Save settings functionality
    ********************************/
    function saveSettings() {
        if(pluginApi == null) {
            Logger.e("mpvpaper", "Cannot save: pluginApi is null");
            return;
        }

        videoWallpaper.saveSettings();
        mpvpaper.saveSettings();

        saveMonitorProperty("fillMode", fillMode);
        saveMonitorProperty("orientation", orientation);
    }
}
