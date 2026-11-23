import Qt.labs.folderlistmodel
import QtQuick
import Quickshell
import Quickshell.Io

import qs.Commons
import qs.Services.UI

Item {
    id: root
    required property var pluginApi


    /***************************
    * PROPERTIES
    ***************************/
    required property bool active
    required property var settingsContext
    required property string currentWallpaper 
    required property bool thumbCacheReady
    required property FolderListModel folderModel

    readonly property string thumbCacheFolder: ImageCacheService.wpThumbDir + "mpvpaper"
    property int _thumbGenIndex: 0
    property var colorRequest: null


    /***************************
    * FUNCTIONS
    ***************************/
    function clearThumbCacheReady() {
        if(pluginApi != null && thumbCacheReady) {
            pluginApi.pluginSettings.thumbCacheReady = false;
            pluginApi.saveSettings();
        }
    }

    function setThumbCacheReady() {
        if(pluginApi != null && !thumbCacheReady) {
            pluginApi.pluginSettings.thumbCacheReady = true;
            pluginApi.saveSettings();
        }
    }


    function getThumbPath(videoPath: string): string {
        const file = videoPath.split('/').pop();

        return `${thumbCacheFolder}/${file}.bmp`
    }

    // Get thumbnail url based on video name
    function getThumbUrl(videoPath: string): string {
        return `file://${getThumbPath(videoPath)}`;
    }


    function startColorGen(context, path) {
        const request = {context: context, path: String(path)};
        if (!ownsWallpaper(request)) return;
        colorRequest = request;
        thumbColorGenTimer.restart();
    }

    function cancelColorGen() {
        colorRequest = null;
        thumbColorGenTimer.stop();
    }

    function ownsWallpaper(request) {
        return !!request && root.active && request.path !== "" && request.path === root.currentWallpaper
            && request.context === root.settingsContext && request.context?.current();
    }

    function thumbnailCommand(videoPath) {
        return ["ffmpeg", "-y", "-i", videoPath, "-frames:v", "1", root.getThumbPath(videoPath)];
    }

    function thumbGeneration() {
        if(pluginApi == null) return;

        // Reset the state of thumbCacheReady
        clearThumbCacheReady();

        while(root._thumbGenIndex < folderModel.count) {
            const videoPath = folderModel.get(root._thumbGenIndex, "filePath");
            const thumbUrl = root.getThumbUrl(videoPath);
            root._thumbGenIndex++;
            // Check if file already exists, otherwise create it with ffmpeg
            if (thumbFolderModel.indexOf(thumbUrl) === -1) {
                Logger.d("mpvpaper", `Creating thumbnail for video: ${videoPath}`);
                thumbProc.command = root.thumbnailCommand(videoPath);
                thumbProc.running = true;
                return;
            }
        }

        // The thumbnail generation has looped over every video and finished the generation.
        root._thumbGenIndex = 0;
        setThumbCacheReady();
    }

    function thumbRegenerate() {
        if(pluginApi == null) return;

        pluginApi.pluginSettings.thumbCacheReady = false;
        pluginApi.saveSettings();

        thumbProc.command = ["sh", "-c", 'rm -rf -- "$1" && mkdir -p -- "$1"', "mpvpaper-cache", thumbCacheFolder];
        thumbProc.running = true;
    }


    /***************************
    * COMPONENTS
    ***************************/
    Process {
        id: thumbProc
        onRunningChanged: {
            if (thumbProc.running)
                return;

            // Try to create the thumbnails if they don't exist.
            root.thumbGeneration();
        }
    }

    FolderListModel {
        id: thumbFolderModel
        folder: "file://" + root.thumbCacheFolder
        nameFilters: ["*.bmp"]
        showDirs: false
    }

    Timer {
        id: thumbColorGenTimer
        interval: 50
        repeat: false
        running: false
        triggeredOnStart: false

        onTriggered: {
            const request = root.colorRequest;
            if (!root.ownsWallpaper(request)) return;
            if(thumbFolderModel.status == FolderListModel.Ready) {
                root.pluginApi.withCurrentScreen(screen => {
                    if (root.colorRequest !== request || !root.ownsWallpaper(request)) return;
                    const thumbPath = root.getThumbPath(request.path);
                    if(thumbFolderModel.indexOf("file://" + thumbPath) !== -1) {
                        Logger.d("mpvpaper", "Generating color scheme based on video wallpaper!");
                        WallpaperService.changeWallpaper(thumbPath);
                        root.cancelColorGen();
                    } else if (!thumbColorGenTimerProc.running) {
                        // Try to create the thumbnail again
                        // just a fail safe if the current wallpaper isn't included in the wallpapers folder
                        Logger.d("mpvpaper", "Thumbnail not found:", thumbPath);
                        thumbColorGenTimerProc.command = root.thumbnailCommand(request.path);
                        thumbColorGenTimerProc.request = request;
                        thumbColorGenTimerProc.running = true;
                    }
                });
            } else {
                thumbColorGenTimer.restart();
            }
        }
    }

    Process {
        id: thumbColorGenTimerProc
        property var request: null
        onExited: exitCode => {
            if (!root.ownsWallpaper(root.colorRequest)) return;
            if (request !== root.colorRequest || exitCode === 0) thumbColorGenTimer.restart();
            else root.cancelColorGen();
        }
    }

    // Process to create the thumbnail folder
    Process {
        id: thumbInit
        command: ["mkdir", "-p", "--", root.thumbCacheFolder]
        running: true
    }
}
