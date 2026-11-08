import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

import "./common"
import "./settings"

ColumnLayout {
    id: root

    property var pluginApi: null

    property bool active:
        pluginApi?.initialSettings?.active ||
        false
    NSettingsBaseline {
        id: displayBaseline
        readonly property bool active: root.pluginApi?.initialSettings?.active || false
        readonly property bool isPlaying: root.pluginApi?.initialSettings?.isPlaying || false
        readonly property bool isMuted: root.pluginApi?.initialSettings?.isMuted || false
    }
    property bool isPlaying: displayBaseline.isPlaying
    property bool isMuted: displayBaseline.isMuted
    property alias wallpapersFolder: playback.wallpapersFolder
    property alias currentWallpaper: playback.currentWallpaper
    property alias volume: audio.volume
    property alias automation: automationTab.automation
    property alias automationMode: automationTab.automationMode
    property alias automationTime: automationTab.automationTime
    property alias hardwareAcceleration: advanced.hardwareAcceleration
    property alias mpvSocket: advanced.mpvSocket
    property alias profile: advanced.profile
    property alias fillMode: advanced.fillMode
    readonly property bool settingsDirty: displayBaseline.differs({active: active, isPlaying: isPlaying, isMuted: isMuted}) || playback.settingsDirty || audio.settingsDirty || automationTab.settingsDirty || advanced.settingsDirty

    spacing: Style.marginM

    // Active toggle
    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.toggle.label") || "Enable mpvpaper"
        description: pluginApi?.tr("settings.toggle.description") || "Enable the mpvpaper integration"
        checked: root.active
        onToggled: checked => root.active = checked
    }

    NDivider {}

    ToolRow {
        objectName: "mpv-settings-tools"
        pluginApi: root.pluginApi
        enabled: root.active
        isPlaying: root.isPlaying
        isMuted: root.isMuted
        playingWriter: value => root.isPlaying = value
        muteWriter: value => root.isMuted = value
    }

    NDivider {}

    NTabBar {
        id: subTabBar
        Layout.fillWidth: true
        distributeEvenly: true
        currentIndex: tabView.currentIndex

        NTabButton {
            enabled: root.active
            text: pluginApi?.tr("settings.tab_bar.playback") || "Playback"
            tabIndex: 0
            checked: subTabBar.currentIndex === 0
        }
        NTabButton {
            enabled: root.active
            text: pluginApi?.tr("settings.tab_bar.audio") || "Audio"
            tabIndex: 1
            checked: subTabBar.currentIndex === 1
        }
        NTabButton {
            enabled: root.active
            text: pluginApi?.tr("settings.tab_bar.automation") || "Automation"
            tabIndex: 2
            checked: subTabBar.currentIndex === 2
        }
        NTabButton {
            enabled: root.active
            text: pluginApi?.tr("settings.tab_bar.advanced") || "Advanced"
            tabIndex: 3
            checked: subTabBar.currentIndex === 3
        }
    }

    NTabView {
        id: tabView
        currentIndex: subTabBar.currentIndex

        PlaybackTab {
            id: playback
            pluginApi: root.pluginApi
            active: root.active
        }

        AudioTab {
            id: audio
            pluginApi: root.pluginApi
            active: root.active
        }

        AutomationTab {
            id: automationTab
            pluginApi: root.pluginApi
            active: root.active
        }

        AdvancedTab {
            id: advanced
            pluginApi: root.pluginApi
            active: root.active
        }
    }


    /********************************
     * Save settings functionality
     ********************************/
    function saveSettings() {
        if(!pluginApi) {
            Logger.e("mpvpaper", "Cannot save: pluginApi is null");
            return;
        }

        pluginApi.pluginSettings.active = active;
        pluginApi.pluginSettings.isPlaying = isPlaying;
        pluginApi.pluginSettings.isMuted = isMuted;

        playback.saveSettings();
        audio.saveSettings();
        advanced.saveSettings();
        automationTab.saveSettings();

        pluginApi.saveSettings();

    }
    Connections {
        target: root.pluginApi
        function onSettingsCompleted(result) {
            if ((result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current") Logger.d("mpvpaper", "Settings saved");
        }
    }
}
