import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets
import "./common/MonitorCommands.js" as Commands

Item {
    id: root
    property var pluginApi: null
    readonly property var monitorCommand: Commands.create(function () { return root.pluginApi?.pluginSettings?.monitors; },
        function (value) { root.pluginApi.pluginSettings.monitors = value; }, function (value) { return Settings.store.copyValue(value); },
        function () { return root.pluginApi?.manifest?.metadata?.defaultSettings; })

    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    implicitWidth: pill.width
    implicitHeight: pill.height


    /***************************
    * PROPERTIES
    ***************************/
    // Monitor specific properties
    readonly property bool isPlaying: Commands.value(pluginApi?.pluginSettings?.monitors, screen?.name, "isPlaying", pluginApi?.manifest?.metadata?.defaultSettings)
    readonly property bool isMuted: Commands.value(pluginApi?.pluginSettings?.monitors, screen?.name, "isMuted", pluginApi?.manifest?.metadata?.defaultSettings)

    // Global properties
    readonly property bool wallpaperEnabled: pluginApi?.pluginSettings?.enabled ?? false
    readonly property bool monitorSpecific: pluginApi?.pluginSettings?.monitorSpecific ?? false

    /***************************
    * FUNCTIONS
    ***************************/
    function saveMonitorProperty(key: string, value: var): void {
        if(pluginApi == null) {
            Logger.e("video-wallpaper", "PluginAPI is null.");
            return;
        }

        var names = monitorSpecific ? [screen.name] : Array.from(Quickshell.screens).map(screen => screen.name);
        if (names.length) monitorCommand.submit(names.map(name => ({op: "set", screen: name, field: key, value: value})));
    }

    /***************************
    * COMPONENTS
    ***************************/
    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": root.pluginApi?.tr("barWidget.contextMenu.panel"),
                "action": "panel",
                "icon": "rectangle"
            },
            {
                "label": root.wallpaperEnabled ?
                    root.pluginApi?.tr("barWidget.contextMenu.disable") :
                    root.pluginApi?.tr("barWidget.contextMenu.enable"),
                "action": root.wallpaperEnabled ? "disable" : "enable",
                "icon": "power"
            },
            {
                "label": root.isPlaying ? 
                    root.pluginApi?.tr("barWidget.contextMenu.pause") :
                    root.pluginApi?.tr("barWidget.contextMenu.play"),
                "action": root.isPlaying ? "pause" : "play",
                "icon": root.isPlaying ? "media-pause" : "media-play"
            },
            {
                "label": root.isMuted ? 
                    root.pluginApi?.tr("barWidget.contextMenu.unmute") :
                    root.pluginApi?.tr("barWidget.contextMenu.mute"),
                "action": root.isMuted ? "unmute" : "mute",
                "icon": root.isMuted ? "volume-high" : "volume-mute"
            },
            {
                "label": I18n.tr("actions.widget-settings"),
                "action": "settings",
                "icon": "settings"
            }
        ]

        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(root.screen);

            switch(action) {
                case "panel":
                    root.pluginApi?.openPanel(root.screen, root);
                    break;
                case "enable":
                    root.pluginApi.pluginSettings.enabled = true;
                    root.pluginApi.saveSettings();
                    break;
                case "disable":
                    root.pluginApi.pluginSettings.enabled = false;
                    root.pluginApi.saveSettings();
                    break;
                case "play":
                    root.saveMonitorProperty("isPlaying", true);
                    root.pluginApi.saveSettings();
                    break;
                case "pause":
                    root.saveMonitorProperty("isPlaying", false);
                    root.pluginApi.saveSettings();
                    break;
                case "mute":
                    root.saveMonitorProperty("isMuted", true);
                    root.pluginApi.saveSettings();
                    break;
                case "unmute":
                    root.saveMonitorProperty("isMuted", false);
                    root.pluginApi.saveSettings();
                    break;
                case "settings":
                    BarService.openPluginSettings(root.screen, root.pluginApi.manifest);
                    break;
                default:
                    Logger.e("video-wallpaper", "Error, action not found:", action);
            }
        }
    }

    BarPill {
        id: pill

        screen: root.screen
        tooltipText: root.pluginApi?.tr("barWidget.tooltip")

        icon: "wallpaper-selector"

        onClicked: {
            root.pluginApi?.openPanel(root.screen, root);
        }

        onRightClicked: {
            PanelService.showContextMenu(contextMenu, root, root.screen);
        }
    }
}
