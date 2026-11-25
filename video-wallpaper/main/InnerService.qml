import QtQuick
import "../common/MonitorCommands.js" as Commands

import qs.Commons
import qs.Services.UI

import "../common"

Item {
    id: root
    required property var pluginApi
    property var settingsContext: pluginApi?.settingsContext
    property var runtimeWriter: pluginApi
    readonly property bool policyCurrent: settingsContext?.current() ?? false
    readonly property var cfg: settingsContext?.settingsView ?? ({})


    /***************************
    * PROPERTIES
    ***************************/
    // Required properties
    required property string screenName

    // Monitor specific properties
    readonly property string currentWallpaper: Commands.record(cfg.monitors, screenName)?.currentWallpaper ?? ""
    readonly property string noctaliaWallpaper: Commands.record(cfg.monitors, screenName)?.noctaliaWallpaper ?? ""

    // Global properties
    readonly property bool wallpaperEnabled: policyCurrent && (cfg.enabled ?? false)
    required property bool thumbCacheReady
    required property var thumbnailSource
    property bool _initialized: false
    property string _runtimeWallpaper: ""
    property bool baselineReady: false
    property int revision: 0
    readonly property bool failed: saveTimer.failed

    // Signals
    signal oldWallpapersSaved
    signal wallpaperBaselineReady


    /***************************
    * FUNCTIONS
    ***************************/
    function saveOldWallpapers() {
        if (!_initialized || pluginApi == null || saveTimer.running || saveTimer.busy || saveTimer.failed || !wallpaperEnabled || currentWallpaper === "") return;

        const noctaliaWallpaper = WallpaperService.getWallpaper(screenName);

        // A thumbnail shown for color generation (including the retired
        // ".extension.bmp" ones) is never saved as the user's own wallpaper.
        if (!thumbnailSource.ownsPath(noctaliaWallpaper)) {
            _runtimeWallpaper = noctaliaWallpaper;
            if (runtimeWriter?.settingsContext === settingsContext && policyCurrent) {
                saveTimer.save("noctaliaWallpaper", noctaliaWallpaper, revision);
                return;
            }
        }

        baselineReady = true;
        wallpaperBaselineReady();
    }

    function retry() { return failed && wallpaperEnabled && currentWallpaper !== "" && saveTimer.retry(); }

    function requestBaseline() {
        if (!_initialized || pluginApi == null) return;
        revision++;
        baselineReady = false;
        saveTimer.cancelPending();
        if (wallpaperEnabled && currentWallpaper !== "") Qt.callLater(saveOldWallpapers);
        else applyOldWallpapers();
    }

    function applyOldWallpapers() {
        WallpaperService.changeWallpaper(_runtimeWallpaper || noctaliaWallpaper, screenName);
        Logger.d("video-wallpaper", "Applying the old wallpapers...");
    }


    /***************************
    * EVENTS
    ***************************/
    onCurrentWallpaperChanged: requestBaseline()
    onWallpaperEnabledChanged: requestBaseline()
    onSettingsContextChanged: requestBaseline()

    Component.onCompleted: {
        // Attaching an enabled plugin is not a preference action. Capture the
        // current wallpaper for this runtime before color generation, without
        // overwriting historical restoration preferences.
        _runtimeWallpaper = WallpaperService.getWallpaper(screenName);
        if (thumbnailSource.ownsPath(_runtimeWallpaper)) _runtimeWallpaper = noctaliaWallpaper;
        _initialized = true;
        baselineReady = true;
        Qt.callLater(function () { if (root.baselineReady) root.wallpaperBaselineReady(); });
    }
    Component.onDestruction: {
        applyOldWallpapers();
    }

    /***************************
    * COMPONENTS
    ***************************/
    SaveTimer {
        id: saveTimer
        pluginApi: root.runtimeWriter
        screenName: root.screenName
        onCompleted: (result, context) => {
            if (context !== root.revision || !root.wallpaperEnabled || root.currentWallpaper === "") {
                Qt.callLater(root.saveOldWallpapers);
                return;
            }
            if (result.status === "saved" || result.status === "nothing_to_save") {
                root.baselineReady = true;
                root.oldWallpapersSaved();
                root.wallpaperBaselineReady();
            }
        }
    }
}
