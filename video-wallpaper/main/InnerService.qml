import QtQuick
import "../common/MonitorCommands.js" as Commands

import qs.Commons
import qs.Services.UI

import "../common"

Item {
    id: root
    required property var pluginApi


    /***************************
    * PROPERTIES
    ***************************/
    // Required properties
    required property string screenName

    required property var         getThumbPath
    required property FolderModel thumbFolderModel

    // Monitor specific properties
    readonly property string currentWallpaper:  Commands.record(pluginApi?.pluginSettings?.monitors, screenName)?.currentWallpaper ?? ""
    readonly property string noctaliaWallpaper: Commands.record(pluginApi?.pluginSettings?.monitors, screenName)?.noctaliaWallpaper ?? ""

    // Global properties
    readonly property bool wallpaperEnabled: pluginApi?.pluginSettings?.enabled ?? false
    required property bool thumbCacheReady
    property bool _initialized: false
    property string _runtimeWallpaper: ""

    // Signals
    signal oldWallpapersSaved
    signal wallpaperBaselineReady


    /***************************
    * FUNCTIONS
    ***************************/
    function saveOldWallpapers() {
        if (!_initialized || pluginApi == null || saveTimer.running || !wallpaperEnabled || currentWallpaper === "") return;

        if (!thumbCacheReady || !thumbFolderModel.ready) {
            Qt.callLater(saveOldWallpapers);
            return;
        }

        const noctaliaWallpaper = WallpaperService.getWallpaper(screenName);

        // Check if the wallpaper name is VERY similar to how the thumbnail generation works,
        // aka if the last characters are ".extension.bmp", in that case just don't do anything, just as a fail safe.
        const videoExtension = currentWallpaper.split(".").pop();
        const isSimilarToThumbnailGen = noctaliaWallpaper.slice(-8) === `.${videoExtension}.bmp`;

        if (thumbFolderModel.indexOf(noctaliaWallpaper) === -1 && !isSimilarToThumbnailGen) {
            _runtimeWallpaper = noctaliaWallpaper;
            saveTimer.save("noctaliaWallpaper", noctaliaWallpaper);
            return;
        }

        wallpaperBaselineReady();
    }

    function applyOldWallpapers() {
        WallpaperService.changeWallpaper(_runtimeWallpaper || noctaliaWallpaper, screenName);
        Logger.d("video-wallpaper", "Applying the old wallpapers...");
    }


    /***************************
    * EVENTS
    ***************************/
    onCurrentWallpaperChanged: {
        if (!_initialized || pluginApi == null) return;

        if (root.wallpaperEnabled && root.currentWallpaper != "") {
            root.saveOldWallpapers();
        } else {
            root.applyOldWallpapers();
        }
    }

    onWallpaperEnabledChanged: {
        if (!_initialized || pluginApi == null) return;

        if (root.wallpaperEnabled && root.currentWallpaper != "") {
            root.saveOldWallpapers();
        } else {
            root.applyOldWallpapers();
        }
    }

    Component.onCompleted: {
        // Attaching an enabled plugin is not a preference action. Capture the
        // current wallpaper for this runtime before color generation, without
        // overwriting historical restoration preferences.
        _runtimeWallpaper = WallpaperService.getWallpaper(screenName);
        _initialized = true;
        Qt.callLater(function () { root.wallpaperBaselineReady(); });
    }
    Component.onDestruction: {
        applyOldWallpapers();
    }

    /***************************
    * COMPONENTS
    ***************************/
    SaveTimer {
        id: saveTimer
        pluginApi: root.pluginApi
        screenName: root.screenName
        onCompleted: result => {
            if (result.status === "saved" || result.status === "nothing_to_save") {
                root.oldWallpapersSaved();
                root.wallpaperBaselineReady();
            }
        }
    }
}
