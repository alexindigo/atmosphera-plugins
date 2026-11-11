pragma ComponentBehavior: Bound
import QtQuick
import "../common/MonitorCommands.js" as Commands
import Quickshell
import Quickshell.Io

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

    required property var    getThumbPath
    required property string thumbCacheFolderPath

    required property FolderModel folderModel
    required property FolderModel thumbFolderModel

    // Screen specific properties
    readonly property string currentWallpaper: Commands.record(pluginApi?.pluginSettings?.monitors, screenName)?.currentWallpaper ?? ""

    // Global properties
    readonly property bool wallpaperEnabled: pluginApi?.pluginSettings?.enabled ?? false
    required property bool thumbCacheReady
    readonly property string wallpapersFolder: pluginApi?.pluginSettings?.wallpapersFolder ?? pluginApi?.manifest?.metadata?.defaultSettings?.wallpapersFolder ?? ""

    // Local properties
    property bool wallpaperBaselineReady: false
    property bool generationFailed: false
    property int  _thumbGenIndex: 0


    /***************************
    * FUNCTIONS
    ***************************/
    function startColorGen() {
        // If the folder model isn't ready, or we are still regenerating a thumbnail, or the old wallpapers haven't saved yet, try in a bit
        if(!thumbCacheReady || !thumbFolderModel.ready || proc.running || !wallpaperBaselineReady){
            Qt.callLater(startColorGen);
            return;
        }

        const thumbPath = root.getThumbPath(currentWallpaper);
        if (thumbFolderModel.indexOf(thumbPath) !== -1) {
            Logger.d("video-wallpaper", "Generating color scheme based on video wallpaper!");
            WallpaperService.changeWallpaper(thumbPath, screenName);
        } else {
            // Try to create the thumbnail again
            // just a fail safe if the current wallpaper isn't included in the wallpapers folder
            Logger.d("video-wallpaper", "Thumbnail not found:", thumbPath);
            proc.command = ["sh", "-c", `ffmpeg -y -i "${currentWallpaper}" -vframes:v 1 "${thumbPath}"`]
            proc.running = true;
            return;
        }

        // Reset the flag
        wallpaperBaselineReady = false;
    }


    /***************************
    * EVENTS
    ***************************/
    onCurrentWallpaperChanged: {
        if (root.wallpaperEnabled && root.currentWallpaper != "") {
            root.startColorGen();
        }
    }

    onWallpaperEnabledChanged: {
        if (root.wallpaperEnabled && root.currentWallpaper != "") {
            root.startColorGen();
        }
    }


    /***************************
    * COMPONENTS
    ***************************/

    Process {
        id: proc
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.generationFailed = true;
                Logger.e("video-wallpaper", "Color thumbnail generation failed.");
                return;
            }
            // When finished recreating the thumbnail, try to apply the colors again
            root.startColorGen();
        }
    }
}
