import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    onPluginApiChanged: pluginApi?.mainInstance?.registerRuntime(pluginApi)
    Component.onCompleted: pluginApi?.mainInstance?.registerRuntime(pluginApi)
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property bool active: 
        pluginApi.pluginSettings.active || 
        false

    readonly property bool isPlaying:
        pluginApi.pluginSettings.isPlaying ||
        false

    readonly property bool isMuted:
        pluginApi.pluginSettings.isMuted ||
        false

    implicitWidth: pill.width
    implicitHeight: pill.height

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": root.pluginApi?.tr("barWidget.contextMenu.panel") || "Panel",
                "action": "panel",
                "icon": "rectangle"
            },
            {
                "label": root.pluginApi?.tr("barWidget.contextMenu.toggle") || "Toggle",
                "action": "toggle",
                "icon": "power"
            },
            {
                "label": root.isPlaying ? 
                    root.pluginApi?.tr("barWidget.contextMenu.pause") || "Pause" : 
                    root.pluginApi?.tr("barWidget.contextMenu.play") || "Play",
                "action": root.isPlaying ? "pause" : "play",
                "icon": root.isPlaying ? "media-pause" : "media-play"
            },
            {
                "label": root.isMuted ? 
                    root.pluginApi?.tr("barWidget.contextMenu.unmute") || "Unmute" : 
                    root.pluginApi?.tr("barWidget.contextMenu.mute") || "Mute",
                "action": root.isMuted ? "unmute" : "mute",
                "icon": root.isMuted ? "volume-high" : "volume-mute"
            },
            {
                "label": I18n.tr("actions.widget-settings"),
                "action": "widget-settings",
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
                case "toggle":
                    root.pluginApi.mainInstance.setPreference("active", !root.active, root.pluginApi);
                    break;
                case "play":
                    root.pluginApi.mainInstance.setPreference("isPlaying", true, root.pluginApi);
                    break;
                case "pause":
                    root.pluginApi.mainInstance.setPreference("isPlaying", false, root.pluginApi);
                    break;
                case "mute":
                    root.pluginApi.mainInstance.setPreference("isMuted", true, root.pluginApi);
                    break;
                case "unmute":
                    root.pluginApi.mainInstance.setPreference("isMuted", false, root.pluginApi);
                    break;
                case "widget-settings":
                    BarService.openPluginSettings(root.screen, pluginApi.manifest);
                    break;
                default:
                    Logger.e("mpvpaper", "Error, action not found:", action);
            }
        }
    }

    BarPill {
        id: pill

        screen: root.screen
        tooltipText: "Open mpvpaper manager"

        icon: "wallpaper-selector"

        onClicked: {
            pluginApi?.openPanel(root.screen, root);
        }

        onRightClicked: {
            PanelService.showContextMenu(contextMenu, root, screen);
        }
    }
}
