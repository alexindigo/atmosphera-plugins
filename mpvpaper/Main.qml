import Qt.labs.folderlistmodel
import QtQuick
import Quickshell
import Quickshell.Io

import qs.Commons
import qs.Services.UI

import "./main"

Item {
    id: root
    property var pluginApi: null
    // One physical playback/automation owner, driven by the last admitted origin.
    // Main's plugin API remains the shared operational/cache owner.
    property var selectedContext: null
    property var runtimeWriter: null
    property var runtimeOrigins: []
    property var pendingBrowse: null
    property var browseChoices: null
    readonly property var policyContext: selectedContext || pluginApi?.settingsContext
    readonly property bool policyCurrent: policyContext?.current() ?? false
    readonly property var cfg: policyContext?.settingsView ?? ({})

    function activatePolicy(context) {
        context = context || pluginApi?.settingsContext;
        if (!context?.current()) return false;
        if (policyContext !== context) cancelBrowse();
        runtimeWriter = runtimeOrigins.find(api => api.settingsContext === context && context.current()) || (context === pluginApi?.settingsContext ? pluginApi : null);
        selectedContext = context;
        return true;
    }

    // Runtime views register their existing API, never a writer on the page API.
    // Several views of one context still share this single physical owner.
    function registerRuntime(runtimeApi) {
        if (!runtimeApi?.settingsContext?.current()) return false;
        runtimeOrigins = runtimeOrigins.filter(api => api?.settingsContext?.current());
        if (!runtimeOrigins.includes(runtimeApi)) runtimeOrigins = runtimeOrigins.concat([runtimeApi]);
        if (policyContext === runtimeApi.settingsContext) runtimeWriter = runtimeApi;
        return true;
    }

    function setPreference(key, value, runtimeApi) {
        runtimeApi = runtimeApi || pluginApi;
        if (!["active", "isPlaying", "isMuted", "wallpapersFolder", "volume", "hardwareAcceleration"].includes(key) || !runtimeApi?.settingsContext?.current()) return false;
        registerRuntime(runtimeApi);
        runtimeApi.pluginSettings[key] = value;
        runtimeApi.saveSettings();
        activatePolicy(runtimeApi.settingsContext);
        runtimeWriter = runtimeApi;
        return true;
    }

    readonly property bool active: 
        policyCurrent && cfg.active ||
        false

    readonly property bool automation:
        policyCurrent && cfg.automation ||
        false

    readonly property string automationMode:
        cfg.automationMode ||
        "random"

    readonly property real automationTime:
        cfg.automationTime ||
        5 * 60

    readonly property string currentWallpaper: 
        cfg.currentWallpaper ||
        ""

    readonly property bool hardwareAcceleration:
        cfg.hardwareAcceleration ||
        false

    readonly property bool isMuted:
        cfg.isMuted ||
        false

    readonly property bool isPlaying:
        cfg.isPlaying ||
        false

    readonly property string mpvSocket: 
        cfg.mpvSocket ||
        pluginApi.manifest.metadata.defaultSettings.mpvSocket || 
        "/tmp/mpv-socket"

    readonly property var oldWallpapers:
        pluginApi.pluginSettings.oldWallpapers || 
        ({})

    readonly property string profile:
        cfg.profile ||
        pluginApi.manifest.metadata.defaultSettings.profile ||
        "default"

    readonly property string fillMode:
        cfg.fillMode ||
        pluginApi.manifest.metadata.defaultSettings.fillMode ||
        "fit"
    

    readonly property bool thumbCacheReady:
        pluginApi.pluginSettings.thumbCacheReady ||
        false

    readonly property real volume:
        cfg.volume ||
        100

    readonly property string wallpapersFolder: 
        cfg.wallpapersFolder ||
        pluginApi.manifest.metadata.defaultSettings.wallpapersFolder || 
        "~/Pictures/Wallpapers"


    /***************************
    * WALLPAPER FUNCTIONALITY
    ***************************/
    function random(runtimeApi) { return browse("random", runtimeApi); }

    function clear(runtimeApi) {
        setWallpaper("", runtimeApi);
    }

    function nextWallpaper(runtimeApi) { return browse("next", runtimeApi); }

    function browse(mode, runtimeApi) {
        runtimeApi = runtimeApi || pluginApi;
        if (!registerRuntime(runtimeApi) || !activatePolicy(runtimeApi.settingsContext)) return false;
        cancelBrowse();
        const settings = runtimeApi.settingsContext.settingsView;
        pendingBrowse = {writer: runtimeApi, context: runtimeApi.settingsContext,
            folder: String(settings.wallpapersFolder ?? ""), current: String(settings.currentWallpaper ?? ""), mode: mode};
        if (!pendingBrowse.folder.length) { cancelBrowse(); return false; }
        browseChoices = browseChoicesComponent.createObject(root, {sourceFolder: Settings.preprocessPath(pendingBrowse.folder)});
        return true;
    }

    function cancelBrowse() {
        pendingBrowse = null;
        if (browseChoices) browseChoices.destroy();
        browseChoices = null;
    }

    function pumpBrowse(model) {
        const request = pendingBrowse;
        if (!request || model !== browseChoices) return;
        if (!request.context.current() || request.context !== policyContext || request.folder !== String(request.context.settingsView.wallpapersFolder ?? "")) {
            cancelBrowse();
            return;
        }
        if (model.status !== FolderListModel.Ready || String(model.folder) !== String(Qt.resolvedUrl("file://" + Settings.preprocessPath(request.folder)))) return;
        // Release ownership before forwarding the choice to the common writer.
        pendingBrowse = null;
        browseChoices = null;
        Qt.callLater(function () { model.destroy(); });
        if (model.count > 0) {
            const index = request.mode === "random" ? Math.floor(Math.random() * model.count) : (model.indexOf(request.current) + 1) % model.count;
            setWallpaper(model.get(index, "filePath"), request.writer);
        } else Logger.e("mpvpaper", "Empty wallpapers folder or no files found!");
    }

    Component {
        id: browseChoicesComponent
        FolderListModel {
            id: choices
            required property string sourceFolder
            folder: "file://" + sourceFolder
            nameFilters: ["*.mp4", "*.avi", "*.mov"]
            showDirs: false
            onStatusChanged: root.pumpBrowse(choices)
        }
    }

    function setWallpaper(path, runtimeApi) {
        runtimeApi = runtimeApi || pluginApi;
        if (!runtimeApi?.settingsContext?.current()) {
            Logger.e("mpvpaper", "Can't set the wallpaper because pluginApi is null.");
            return;
        }

        cancelBrowse();
        registerRuntime(runtimeApi);
        runtimeApi.pluginSettings.currentWallpaper = path;
        runtimeApi.pluginSettings.isPlaying = true;
        runtimeApi.saveSettings();
        activatePolicy(runtimeApi.settingsContext);
        runtimeWriter = runtimeApi;
    }


    /***************************
    * HELPER FUNCTIONALITY
    ***************************/
    function getThumbPath(videoPath: string): string {
        return thumbnails.getThumbPath(videoPath);
    }

    // Get thumbnail url based on video name
    function getThumbUrl(videoPath: string): string {
        return thumbnails.getThumbUrl(videoPath);
    }

    function thumbRegenerate() {
        thumbnails.thumbRegenerate();
    }


    /***************************
    * COMPONENTS
    ***************************/
    Mpvpaper {
        // Contains all the mpvpaper specific functionality
        id: mpvpaper
        pluginApi: root.pluginApi
        settingsContext: root.policyContext
        runtimeWriter: root.runtimeWriter

        active: root.active
        currentWallpaper: root.currentWallpaper
        hardwareAcceleration: root.hardwareAcceleration
        isMuted: root.isMuted
        isPlaying: root.isPlaying
        mpvSocket: root.mpvSocket
        profile: root.profile
        fillMode: root.fillMode
        volume: root.volume

        thumbnails: thumbnails
        innerService: innerService
    }

    Thumbnails {
        // Contains all the thumbnail specific functionality
        id: thumbnails
        pluginApi: root.pluginApi

        active: root.active
        settingsContext: root.policyContext
        currentWallpaper: root.currentWallpaper
        thumbCacheReady: root.thumbCacheReady

        folderModel: folderModel
    }

    InnerService {
        // Contains all the save / load functionality for this to work with noctalia
        id: innerService
        pluginApi: root.pluginApi

        currentWallpaper: root.currentWallpaper
        oldWallpapers: root.oldWallpapers

        thumbnails: thumbnails
    }

    Automation {
        id: automation
        pluginApi: root.pluginApi

        automation: root.automation
        automationMode: root.automationMode
        automationTime: root.automationTime

        random: function () { const writer = root.runtimeWriterForPolicy(); if (writer) root.random(writer); }
        nextWallpaper: function () { const writer = root.runtimeWriterForPolicy(); if (writer) root.nextWallpaper(writer); }
    }

    // A read-only Settings completion does not grant a native runtime writer.
    // Automatic wallpaper actions must be admitted by a runtime origin first.
    function runtimeWriterForPolicy() {
        if (runtimeWriter?.settingsContext === policyContext && policyCurrent) return runtimeWriter;
        return policyContext === pluginApi?.settingsContext ? pluginApi : null;
    }


    FolderListModel {
        id: folderModel
        folder: root.pluginApi == null ? "" : "file://" + root.wallpapersFolder
        nameFilters: ["*.mp4", "*.avi", "*.mov"]
        showDirs: false

        onStatusChanged: {
            if (folderModel.status == FolderListModel.Ready) {
                // Generate all the thumbnails for the folder
                thumbnails.thumbGeneration();
            }
        }
    }

    // IPC Handler
    IpcHandler {
        target: "plugin:mpvpaper"

        function random() {
            root.random();
        }

        function clear() {
            root.clear();
        }

        // Current wallpaper
        function setWallpaper(path: string) {
            root.setWallpaper(path);
        }

        function getWallpaper(): string {
            return root.pluginApi?.pluginSettings.currentWallpaper || "";
        }

        // Active
        function setActive(isActive: bool) {
            if (root.pluginApi == null) return;

            root.setPreference("active", isActive, root.pluginApi);
        }

        function getActive(): bool {
            return root.pluginApi?.pluginSettings.active || false;
        }

        function toggleActive() {
            setActive(!getActive());
        }

        // Is playing
        function resume() {
            if (root.pluginApi == null) return;

            root.setPreference("isPlaying", true, root.pluginApi);
        }

        function pause() {
            if (root.pluginApi == null) return;

            root.setPreference("isPlaying", false, root.pluginApi);
        }

        function togglePlaying() {
            if (root.pluginApi == null) return;

            root.setPreference("isPlaying", !(root.pluginApi.pluginSettings.isPlaying || false), root.pluginApi);
        }

        // Mute / unmute
        function mute() {
            if (root.pluginApi == null) return;

            root.setPreference("isMuted", true, root.pluginApi);
        }

        function unmute() {
            if (root.pluginApi == null) return;

            root.setPreference("isMuted", false, root.pluginApi);
        }

        function toggleMute() {
            if (root.pluginApi == null) return;

            root.setPreference("isMuted", !(root.pluginApi.pluginSettings.isMuted || false), root.pluginApi);
        }

        // Volume
        function setVolume(volume: real) {
            if (root.pluginApi == null) return;

            root.setPreference("volume", volume, root.pluginApi);
        }

        function increaseVolume() {
            setVolume((root.pluginApi.pluginSettings.volume || 100) + Settings.data.audio.volumeStep);
        }

        function decreaseVolume() {
            setVolume((root.pluginApi.pluginSettings.volume || 100) - Settings.data.audio.volumeStep);
        }

        // Hardware acceleration
        function setHardwareAcceleration(active: bool) {
            if (root.pluginApi == null) return;

            root.setPreference("hardwareAcceleration", active, root.pluginApi);
        }

        function toggleHardwareAcceleration() {
            setHardwareAcceleration(!(root.pluginApi.pluginSettings.hardwareAcceleration || false));
        }
    }
}
