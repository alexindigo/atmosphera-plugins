pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.Commons
import qs.Widgets
import qs.Portals

import "../common"
import "../common/MonitorCommands.js" as Commands

ColumnLayout {
    id: root
    spacing: Style.marginM
    Layout.fillWidth: true


    /***************************
    * PROPERTIES
    ***************************/
    // Required properties
    required property var    pluginApi
    required enabled
    required property string selectedMonitor
    required property var monitorSettings
    required property var toolSettings
    NSettingsBaseline {
        id: displayBaseline
        readonly property string currentWallpaper: Commands.record(root.pluginApi?.initialSettings?.monitors, root.selectedMonitor)?.currentWallpaper ?? ""
        readonly property real volume: Commands.value(root.pluginApi?.initialSettings?.monitors, root.selectedMonitor, "volume", root.pluginApi?.manifest?.metadata?.defaultSettings)
        ranges: [NSettingsRange { field: "volume"; from: volumeInput.from; to: volumeInput.to }]
    }
    readonly property bool settingsDirty: displayBaseline.differs({currentWallpaper: currentWallpaper, volume: volume})

    // Monitor specific properties
    readonly property bool isMuted: Commands.value(pluginApi?.pluginSettings?.monitors, selectedMonitor, "isMuted", pluginApi?.manifest?.metadata?.defaultSettings)
    readonly property bool isPlaying: Commands.value(pluginApi?.pluginSettings?.monitors, selectedMonitor, "isPlaying", pluginApi?.manifest?.metadata?.defaultSettings)

    property string currentWallpaper: monitorSettings.currentWallpaper ?? ""
    property bool   monitorSpecific:  pluginApi?.pluginSettings?.monitorSpecific                     ?? false
    property double volume: displayBaseline.project("volume")

    // Global properties
    property string wallpapersFolder: pluginApi?.pluginSettings?.wallpapersFolder ?? pluginApi?.manifest?.metadata?.defaultSettings?.wallpapersFolder ?? ""

    // Signals
    signal saveMonitorProperty(key: string, value: var);


    /***************************
    * EVENTS
    ***************************/
    function loadMonitor(record) {
        // Update the local variables
        currentWallpaper = record.currentWallpaper ?? ""
        volume = Math.max(volumeInput.from, Math.min(volumeInput.to, Commands.resolve(record, "volume", pluginApi?.manifest?.metadata?.defaultSettings)))
    }


    /***************************
    * COMPONENTS
    ***************************/
    // Select Wallpaper
    RowLayout {
        spacing: Style.marginS

        NLabel {
            enabled: root.enabled
            label:       root.pluginApi?.tr("settings.general.select_wallpaper.title.label")
            description: root.pluginApi?.tr("settings.general.select_wallpaper.title.description")
        }

        AtmoIconButton {
            enabled: root.enabled
            icon: "wallpaper-selector"
            tooltipText: root.pluginApi?.tr("settings.general.select_wallpaper.icon_button.tooltip")
            onClicked: currentWallpaperPicker.openFilePicker()
        }

        PortalFilePicker {
            id: currentWallpaperPicker
            title: root.pluginApi?.tr("settings.general.select_wallpaper.file_picker.title")
            initialPath: root.wallpapersFolder
            selectionMode: "files"

            onAccepted: paths => {
                if (paths.length > 0) {
                    Logger.d("video-wallpaper", "Selected the following current wallpaper:", paths[0]);
                    root.currentWallpaper = paths[0];
                }
            }
        }
    }

    // Volume
    NValueSlider {
        id: volumeInput
        objectName: "settings-range-volume"

        enabled: root.enabled
        from: 0.0
        to: 1.0
        defaultValue: 1.0
        value: root.volume
        stepSize: (Settings.data.audio.volumeStep / 100.0)
        text: `${root.volume * 100.0}%`
        label:       root.pluginApi?.tr("settings.general.volume.label")
        description: root.pluginApi?.tr("settings.general.volume.description")
        onMoved: value => root.volume = value
    }

    NDivider {}

    // Tool row
    ToolRow {
        pluginApi: root.pluginApi
        enabled: root.enabled
        monitorSpecific: root.monitorSpecific
        screenName: root.selectedMonitor
        settingWriter: (key, value) => root.saveMonitorProperty(key, value)
        settings: root.toolSettings
    }


    /********************************
    * Save settings functionality
    ********************************/
    function saveSettings() {
        if(pluginApi == null) {
            Logger.e("video-wallpaper", "Cannot save, pluginApi is null");
            return;
        }

        saveMonitorProperty("currentWallpaper", currentWallpaper);
        saveMonitorProperty("volume", volume);
    }
}
