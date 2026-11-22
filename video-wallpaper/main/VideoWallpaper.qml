
import Qt.labs.folderlistmodel
import QtQuick
import "../common/MonitorCommands.js" as Commands
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import QtMultimedia

import qs.Commons
import qs.Services.UI

PanelWindow {
    id: root
    required property var pluginApi
    property var settingsContext: pluginApi?.settingsContext
    readonly property bool policyCurrent: settingsContext?.current() ?? false
    readonly property var cfg: settingsContext?.settingsView ?? ({})


    /***************************
    * REQUIRED PROPERTIES
    ***************************/
    // Required properties
    required property var    screenData
    required property string screenName
    required property int    screenWidth
    required property int    screenHeight

    // Monitor specific properties
    readonly property string currentWallpaper: Commands.record(cfg.monitors, screenName)?.currentWallpaper ?? ""
    readonly property string fillMode: Commands.record(cfg.monitors, screenName)?.fillMode ?? pluginApi?.manifest?.metadata?.defaultSettings?.fillMode ?? ""
    readonly property bool isMuted: Commands.value(cfg.monitors, screenName, "isMuted", pluginApi?.manifest?.metadata?.defaultSettings)
    readonly property bool isPlaying: Commands.value(cfg.monitors, screenName, "isPlaying", pluginApi?.manifest?.metadata?.defaultSettings)
    readonly property int orientation: Commands.value(cfg.monitors, screenName, "orientation", pluginApi?.manifest?.metadata?.defaultSettings)
    readonly property double volume: Commands.value(cfg.monitors, screenName, "volume", pluginApi?.manifest?.metadata?.defaultSettings)

    // Global properties
    readonly property bool enabled: policyCurrent && (cfg.enabled ?? false)


    /***************************
    * PROPERTIES
    ***************************/
    screen: screenData
    exclusionMode: ExclusionMode.Ignore

    implicitWidth: screenWidth
    implicitHeight: screenHeight
    visible: enabled && currentWallpaper != ""

    WlrLayershell.namespace: `noctalia-wallpaper-video-${screenName}`
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        right: true
        left: true
    }

    color: "transparent"


    /***************************
    * COMPONENTS
    ***************************/
    Rectangle {
        anchors.fill: parent
        color: "black"

        Video {
            id: videoWallpaper
            anchors.fill: parent
            autoPlay: true
            fillMode: {
                if      (root.fillMode == "fit")     return VideoOutput.PreserveAspectFit;
                else if (root.fillMode == "crop")    return VideoOutput.PreserveAspectCrop;
                else if (root.fillMode == "stretch") return VideoOutput.Stretch;
                else {
                    Logger.e("video-wallpaper", "Unsupported fill mode detected:", root.fillMode);
                }
            }
            loops: MediaPlayer.Infinite
            muted: root.isMuted
            orientation: root.orientation
            playbackRate: {
                if(root.isPlaying) return 1.0
                // Pausing is the same as putting the speed to veryyyyyyy tiny amount
                else return 0.00000001
            }
            source: Qt.resolvedUrl(root.currentWallpaper)
            volume: root.volume

            onErrorOccurred: (error, errorString) => {
                Logger.e("video-wallpaper", errorString);
            }
        }
    }
}
