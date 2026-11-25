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
    // Required properties
    required property var    screenData
    required property string screenName
    required property int    screenWidth
    required property int    screenHeight

    // Monitor specific properties
    readonly property string currentWallpaper: Commands.record(cfg.monitors, screenName)?.currentWallpaper ?? ""
    readonly property bool hardwareAcceleration: Commands.value(cfg.monitors, screenName, "hardwareAcceleration", pluginApi?.manifest?.metadata?.defaultSettings)
    readonly property string fillMode: Commands.record(cfg.monitors, screenName)?.fillMode ?? pluginApi?.manifest?.metadata?.defaultSettings?.fillMode ?? ""
    readonly property bool isMuted: Commands.value(cfg.monitors, screenName, "isMuted", pluginApi?.manifest?.metadata?.defaultSettings)
    readonly property bool isPlaying: Commands.value(cfg.monitors, screenName, "isPlaying", pluginApi?.manifest?.metadata?.defaultSettings)
    readonly property int orientation: Commands.value(cfg.monitors, screenName, "orientation", pluginApi?.manifest?.metadata?.defaultSettings)
    readonly property string profile: Commands.record(cfg.monitors, screenName)?.profile ?? pluginApi?.manifest?.metadata?.defaultSettings?.profile ?? ""
    readonly property double volume: Math.max(0, Math.min(1, Commands.value(cfg.monitors, screenName, "volume", pluginApi?.manifest?.metadata?.defaultSettings)))

    // Global properties
    readonly property bool wallpaperEnabled: policyCurrent && (cfg.enabled ?? false)
    readonly property string mpvSocket: cfg.mpvSocket ?? pluginApi?.manifest?.metadata?.defaultSettings?.mpvSocket ?? ""

    // Constants
    readonly property string mpvSocketScreen: `${mpvSocket}-${screenName}`

    // Local properties
    property bool mpvpaperExists: false
    property var admittedContext: null
    property int policyGeneration: 0

    function replacePolicy() {
        const generation = ++policyGeneration;
        admittedContext = null;
        deactivateMpvpaper();
        Qt.callLater(function () {
            if (generation === root.policyGeneration && root.policyCurrent) root.activateMpvpaper();
        });
    }
    onSettingsContextChanged: replacePolicy()
    onMpvSocketScreenChanged: replacePolicy()


    /***************************
    * FUNCTIONS
    ***************************/
    function buildMpvCommand() {
        let options = [
            `input-ipc-server='${root.mpvSocketScreen}'`,
            `profile='${root.profile}'`,
            `panscan=${root.fillMode === "crop" ? 1 : 0}`,
            `keepaspect='${root.fillMode === "stretch" ? "no" : "yes"}'`,
            "loop"
        ];

        if (root.hardwareAcceleration) {
            options.push("hwdec=auto");
        }

        if (root.isMuted) {
            options.push("no-audio"); }

        const optionsString = options.join(" ");
        const command = `mpvpaper -o "${optionsString}" ${root.screenName} "${root.currentWallpaper}"`;

        return ["sh", "-c", command];
    }

    function activateMpvpaper() {
        if (!root.wallpaperEnabled || root.currentWallpaper == "") return;

        // Just call this again if we are still checking
        if (mpvCheck.running) {
            Qt.callLater(activateMpvpaper);
            return;
        }

        if (!mpvpaperExists) return;

        Logger.d("video-wallpaper", "Activating mpvpaper...");

        admittedContext = settingsContext;
        mpvProc.command = buildMpvCommand();
        mpvProc.running = true;

        // Loading a backend is not a preference edit. Explicit wallpaper/play
        // actions record isPlaying through the shared monitor command.
    }

    function deactivateMpvpaper() {
        Logger.d("video-wallpaper", "Deactivating mpvpaper...");

        socket.connected = false;
        mpvProc.running = false;
    }

    function sendCommandToMPV(command: string) {
        if (!policyCurrent || admittedContext !== settingsContext) return;
        socket.connected = true;
        socket.path = mpvSocketScreen;
        socket.write(`${command}\n`);
        socket.flush();
    }


    /***************************
    * EVENTS
    ***************************/
    Component.onDestruction: {
        // Clean up mpvpaper
        deactivateMpvpaper();
    }

    Component.onCompleted: {
        activateMpvpaper();
    }


    onCurrentWallpaperChanged: {
        if (!root.wallpaperEnabled) return;

        Logger.d("video-wallpaper", "Current wallpaper changed from mpvpaper");

        if (root.currentWallpaper != "") {
            Logger.d("video-wallpaper", "Changing current wallpaper:", root.currentWallpaper);

            if(mpvProc.running) {
                // If mpvpaper is already running
                sendCommandToMPV(`loadfile "${root.currentWallpaper}"`);
            } else {
                // Start mpvpaper
                activateMpvpaper();
            }
        } else if(mpvProc.running) {
            Logger.d("video-wallpaper", "Current wallpaper is empty, turning mpvpaper off.");

            deactivateMpvpaper();
        }
    }

    onWallpaperEnabledChanged: {
        if(root.wallpaperEnabled && !mpvProc.running && root.currentWallpaper != "") {
            Logger.d("video-wallpaper", "Turning mpvpaper on.");

            activateMpvpaper();
        } else if(!root.wallpaperEnabled) {
            Logger.d("video-wallpaper", "Turning mpvpaper off.");

            deactivateMpvpaper();
        }
    }

    onHardwareAccelerationChanged: {
        if(!root.wallpaperEnabled || !mpvProc.running) return;

        Logger.d("video-wallpaper", "Changing hardware acceleration");

        if(hardwareAcceleration) {
            sendCommandToMPV("set hwdec auto");
        } else {
            sendCommandToMPV("set hwdec no");
        }
    }

    onFillModeChanged: {
        if (!root.wallpaperEnabled || !mpvProc.running) return;

        Logger.d("video-wallpaper", "Changing current fill mode");

        switch(fillMode){
            case "fit": // Fit
                sendCommandToMPV(`no-osd set panscan 0; no-osd set keepaspect yes`);
                break;
            case "crop": // Crop
                sendCommandToMPV(`no-osd set panscan 1; no-osd set keepaspect yes`);
                break;
            case "stretch": // Stretch
                sendCommandToMPV(`no-osd set keepaspect no; no-osd set panscan 0`);
                break;
            default:
                Logger.e("video-wallpaper", "Error, fill mode not found:", fillMode);
        }
    }

    onIsMutedChanged: {
        if (!root.wallpaperEnabled || !mpvProc.running) return;

        // This sets the audio id to null or to auto
        if (isMuted) {
            sendCommandToMPV("no-osd set aid no");
        } else {
            sendCommandToMPV("no-osd set aid auto");
        }
    }

    onIsPlayingChanged: {
        if (!root.wallpaperEnabled || !mpvProc.running) return;

        // Pause or unpause the video
        if(isPlaying) {
            sendCommandToMPV("set pause no");
        } else {
            sendCommandToMPV("set pause yes");
        }
    }

    onOrientationChanged: {
        if (!root.wallpaperEnabled || !mpvProc.running) return;

        Logger.d("video-wallpaper", "Changing orientation");

        sendCommandToMPV(`set video-rotate ${orientation}`);
    }

    onProfileChanged: {
        if (!root.wallpaperEnabled || !mpvProc.running) return;

        Logger.d("video-wallpaper", "Changing current profile");

        sendCommandToMPV(`set profile ${profile}`);
    }


    onVolumeChanged: {
        if (!root.wallpaperEnabled || !mpvProc.running) return;

        const clampedVolume = Math.min(Math.max(volume, 0), 1);
        const mpvVolume = clampedVolume * 100;

        // Mpv has volume from 0 to 100 instead of 0 to 1
        sendCommandToMPV(`no-osd set volume ${mpvVolume}`)

    }

    /***************************
    * COMPONENTS
    ***************************/
    Process {
        id: mpvCheck
        running: true
        command: ["sh", "-c", "mpvpaper --help"]

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.mpvpaperExists = true;
            } else {
                ToastService.showError(root.pluginApi?.tr("main.no_backend_found", {"backend": "Mpvpaper"}));
            }
        }
    }

    Process {
        id: mpvProc
    }

    Socket {
        id: socket
        path: root.mpvSocketScreen
    }
}
