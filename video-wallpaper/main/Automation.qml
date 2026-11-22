import QtQuick
import Quickshell
import Quickshell.Io

import qs.Commons
import qs.Services.UI
import "../common/MonitorCommands.js" as Commands

Item {
    id: root
    required property var pluginApi
    property var settingsContext: pluginApi?.settingsContext
    readonly property bool policyCurrent: settingsContext?.current() ?? false
    readonly property var cfg: settingsContext?.settingsView ?? ({})


    /***************************
    * PROPERTIES
    ***************************/
    readonly property var globalSettings: Commands.automationSettings(cfg, null, pluginApi?.manifest?.metadata?.defaultSettings)
    readonly property bool   automation: policyCurrent && globalSettings.automation
    readonly property string automationMode:  globalSettings.automationMode
    readonly property real   automationTime:  globalSettings.automationTime
    readonly property bool   monitorSpecific: cfg.monitorSpecific ?? false

    signal random(screenName: var)
    signal nextWallpaper(screenName: var)

    /***************************
    * EVENTS
    ***************************/
    onAutomationChanged: {
        if(automation) {
            Logger.d("video-wallpaper", "Starting automation timer...");

            if (!monitorSpecific) timer.restart();
        } else {
            Logger.d("video-wallpaper", "Stop automation timer...");

            timer.stop();
        }
    }
    
    onAutomationTimeChanged: {
        if(automation && !monitorSpecific) {
            timer.restart();
        }
    }


    /***************************
    * COMPONENTS
    ***************************/
    Timer {
        id: timer
        interval: root.automationTime * 1000
        repeat: true
        running: root.automation && !root.monitorSpecific

        onTriggered: {
            switch(root.automationMode) {
                case "random":
                    if(root.monitorSpecific) {
                        for(const screen of Quickshell.screens) {
                            root.random(screen.name);
                        }
                    } else {
                        root.random(undefined);
                    }
                    break;
                case "alphabetically":
                    if(root.monitorSpecific) {
                        for(const screen of Quickshell.screens) {
                            root.nextWallpaper(screen.name);
                        }
                    } else {
                        root.nextWallpaper(undefined);
                    }
                    break;
            }
        }
    }

    Variants {
        model: Quickshell.screens
        Timer {
            required property var modelData
            readonly property var selectedSettings: Commands.automationSettings(root.globalSettings, Commands.record(root.cfg.monitors, modelData.name))
            readonly property bool selectedAutomation: selectedSettings.automation
            readonly property string selectedMode: selectedSettings.automationMode
            readonly property real selectedTime: selectedSettings.automationTime
            interval: selectedTime * 1000
            repeat: true
            running: root.policyCurrent && root.monitorSpecific && selectedAutomation
            onTriggered: {
                var name = modelData.name;
                if (selectedMode === "random") root.random(name);
                else if (selectedMode === "alphabetically") root.nextWallpaper(name);
            }
        }
    }
}
