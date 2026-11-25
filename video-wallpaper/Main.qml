import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

import "./common"
import "./main"
import "./common/MonitorCommands.js" as Commands

Item {
    id: root
    property var pluginApi: null
    property var selectedContext: null
    property var runtimeOrigins: []
    readonly property var policyContext: selectedContext || pluginApi?.settingsContext
    readonly property bool policyCurrent: policyContext?.current() ?? false
    readonly property var cfg: policyContext?.settingsView ?? ({})
    readonly property var runtimeWriter: runtimeOrigins.find(api => api.settingsContext === policyContext && policyCurrent) || (policyContext === pluginApi?.settingsContext && policyCurrent ? pluginApi : null)

    function registerRuntime(runtimeApi) {
        if (!runtimeApi?.settingsContext?.current()) return false;
        runtimeOrigins = runtimeOrigins.filter(api => api?.settingsContext?.current());
        if (!runtimeOrigins.includes(runtimeApi)) runtimeOrigins = runtimeOrigins.concat([runtimeApi]);
        return true;
    }

    function activatePolicy(context) {
        context = context || pluginApi?.settingsContext;
        if (!context?.current()) return false;
        selectedContext = context;
        return true;
    }

    function admitRuntime(runtimeApi) {
        runtimeApi = runtimeApi || pluginApi;
        if (!registerRuntime(runtimeApi) || !activatePolicy(runtimeApi.settingsContext)) return null;
        return runtimeApi;
    }

    // One admitted writer owns immediate panel, bar and IPC monitor commands.
    // An empty screen targets the connected outputs, never offline records.
    function submitMonitorCommand(runtimeApi, op, field, value, screen) {
        if (!runtimeApi || runtimeApi.apiRole === "settings-editor" || typeof screen !== "string") return false;
        const writer = admitRuntime(runtimeApi);
        if (!writer) return false;
        const names = screen === "" ? Array.from(Quickshell.screens, output => output.name) : [screen];
        if (!names.length) return false;
        const commands = Commands.create(() => writer.pluginSettings.monitors,
            next => { writer.pluginSettings.monitors = next; }, value => Settings.store.copyValue(value),
            () => writer.manifest?.metadata?.defaultSettings);
        if (!commands.submit(names.map(name => ({op: op, screen: name, field: field, value: value})))) return false;
        writer.saveSettings();
        return true;
    }


    /***************************
    * PROPERTIES
    ***************************/
    readonly property string wallpapersFolder: cfg.wallpapersFolder ?? pluginApi?.manifest?.metadata?.defaultSettings?.wallpapersFolder ?? ""

    readonly property bool thumbCacheReady: thumbnails.thumbCacheReady
    readonly property bool thumbnailGenerationFailed: thumbnails.generationFailed
    readonly property bool thumbnailsSettled: thumbnails.settled
    readonly property string requestedWallpaperPaths: JSON.stringify(Quickshell.screens.map(screen => Commands.record(root.cfg.monitors, screen.name)?.currentWallpaper ?? ""))


    /***************************
    * WALLPAPER FUNCTIONALITY
    ***************************/
    function random(screen, runtimeApi) {
        const origin = admitRuntime(runtimeApi);
        if (origin) functions.random(screen, origin);
    }

    function clear(screen, runtimeApi) {
        const origin = admitRuntime(runtimeApi);
        if (origin) functions.clear(screen, origin);
    }

    function nextWallpaper(screen, runtimeApi) {
        const origin = admitRuntime(runtimeApi);
        if (origin) functions.nextWallpaper(screen, origin);
    }

    function setWallpaper(path, screen, runtimeApi) {
        const origin = admitRuntime(runtimeApi);
        if (origin) functions.setWallpaper(path, screen, origin);
    }

    function selectWallpaper(path, names, runtimeApi) {
        const origin = admitRuntime(runtimeApi);
        if (origin) functions.selectWallpaper(path, names, origin);
    }


    /***************************
    * HELPER FUNCTIONALITY
    ***************************/
    // The shared image owner's thumbnail of a video ("" until it exists).
    function getThumbPath(videoPath: string): string {
        return thumbnails.thumbnailFor(videoPath);
    }

    // The owner's failure for a video's thumbnail ({code, reason}).
    function getThumbFailure(videoPath: string): var {
        return thumbnails.failureFor(videoPath);
    }

    function thumbRegenerate() {
        thumbnails.thumbRegenerate();
        retryBaselines();
    }

    signal retryBaselines()


    /***************************
    * COMPONENTS
    ***************************/
    Variants {
        model: Quickshell.screens

        Item {
            id: screenItem
            required property var modelData

            readonly property string name:      modelData.name
            readonly property int screenWidth:  modelData.width
            readonly property int screenHeight: modelData.height

            readonly property string activeBackend: root.policyCurrent ? (root.cfg.activeBackend ?? root.pluginApi?.manifest?.metadata?.defaultSettings?.activeBackend ?? "") : ""

            /***************************
            * FUNCTIONALITY
            ***************************/
            function reloadWallpaperLoader() {
                wallpaperLoader.active = false;
                if (root.policyCurrent) wallpaperLoader.active = true;
            }


            /***************************
            * EVENTS
            ***************************/
            onActiveBackendChanged: {
                reloadWallpaperLoader();
            }


            /***************************
            * BACKEND COMPONENTS
            ***************************/
            Timer {
                id: wallpaperLoaderStartupTimer
                interval: 500
                running: true

                onTriggered: {
                    screenItem.reloadWallpaperLoader();
                }
            }

            Loader {
                id: wallpaperLoader
                active: false
                asynchronous: true

                sourceComponent: {
                    if (!root.policyCurrent) return null;
                    switch (screenItem.activeBackend) {
                        case "mpvpaper":
                            return mpvpaper;
                        case "qt6-multimedia":
                            return qtmultimedia;
                        default:
                            Logger.e("video-wallpaper", "No active backend.");
                    }
                }

                onStatusChanged: {
                    // Most likely if status is error and active backend is qt6-multimedia, is that qt6-multimedia wasn't found.
                    if (status === Loader.Error && screenItem.activeBackend === "qt6-multimedia") {
                        ToastService.showError(root.pluginApi?.tr("main.no_backend_found", {"backend": "Qt6-multimedia"}));
                    }
                }
            }

            Component {
                id: qtmultimedia

                VideoWallpaper {
                    pluginApi: root.pluginApi
                    settingsContext: root.policyContext

                    screenData:   screenItem.modelData
                    screenName:   screenItem.name
                    screenWidth:  screenItem.screenWidth
                    screenHeight: screenItem.screenHeight
                }
            }

            Component {
                id: mpvpaper

                Mpvpaper {
                    pluginApi: root.pluginApi
                    settingsContext: root.policyContext

                    screenData:   screenItem.modelData
                    screenName:   screenItem.name
                    screenWidth:  screenItem.screenWidth
                    screenHeight: screenItem.screenHeight
                }
            }


            /***************************
            * COLOR GENERATION
            ***************************/
            ColorGeneration {
                id: colorgen
                pluginApi: root.pluginApi
                settingsContext: root.policyContext
                screenName: screenItem.name
                thumbnailSource: thumbnails
                baselineSource: baselineOwner
            }


            /***************************
            * NOCTALIA WALLPAPER
            ***************************/
            InnerService {
                id: baselineOwner
                pluginApi: root.pluginApi
                settingsContext: root.policyContext
                runtimeWriter: root.runtimeWriter
                thumbCacheReady: root.thumbCacheReady
                thumbnailSource: thumbnails

                screenName: screenItem.name
            }

            Connections {
                target: root
                function onRetryBaselines() { baselineOwner.retry(); }
            }
        }
    }

    Thumbnails {
        id: thumbnails
        pluginApi: root.pluginApi
        settingsContext: root.policyContext

        folderModel:      rootFolderModel
        requestedPaths: JSON.parse(root.requestedWallpaperPaths)
    }

    Automation {
        id: automation
        pluginApi: root.pluginApi
        settingsContext: root.policyContext

        onRandom: (screen) => { if (root.runtimeWriter) root.random(screen, root.runtimeWriter); }
        onNextWallpaper: (screen) => { if (root.runtimeWriter) root.nextWallpaper(screen, root.runtimeWriter); }
    }

    Functions {
        id: functions
        pluginApi: root.pluginApi
        settingsContext: root.policyContext

        folderModel: rootFolderModel
    }

    // Folder models
    FolderModel {
        id: rootFolderModel
        folder: root.wallpapersFolder
        filters: ["*.mp4", "*.avi", "*.mov", "*.webm", "*.gif"]
    }

    // IPC Handler
    IPC {
        id: ipcHandler
        pluginApi: root.pluginApi
        admitRuntime: root.admitRuntime
        writeMonitorCommand: root.submitMonitorCommand

        random: root.random
        clear: root.clear
        selectWallpaper: root.selectWallpaper
    }
}
