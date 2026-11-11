import QtQuick
import Quickshell
import qs.Commons

import "../common"
import "../common/MonitorCommands.js" as Commands

Item {
    id: root
    required property var pluginApi
    readonly property var monitorCommand: Commands.create(function () { return root.pluginApi?.pluginSettings?.monitors; },
        function (value) { root.pluginApi.pluginSettings.monitors = value; }, function (value) { return Settings.store.copyValue(value); })


    /***************************
    * PROPERTIES
    ***************************/
    // Required properties
    required property FolderModel folderModel

    // Global properties
    readonly property bool   monitorSpecific:  pluginApi?.pluginSettings?.monitorSpecific  ?? false
    readonly property string wallpapersFolder: pluginApi?.pluginSettings?.wallpapersFolder ?? pluginApi?.manifest?.metadata?.defaultSettings?.wallpapersFolder ?? ""


    /***************************
    * FUNCTIONS
    ***************************/
    function random(screen) {
        if (wallpapersFolder === "") {
            Logger.e("video-wallpaper", "Wallpapers folder is empty!");
            return;
        }
        if (folderModel.count === 0) {
            Logger.e("video-wallpaper", "No valid video files found!");
            return;
        }

        const rand = Math.floor(Math.random() * folderModel.count);
        const url = folderModel.get(rand, "filePath");
        setWallpaper(url, screen);
    }

    function clear(screen) {
        setWallpaper("", screen);
    }

    function nextWallpaper(screen) {
        if (wallpapersFolder === "") {
            Logger.e("video-wallpaper", "Wallpapers folder is empty!");
            return;
        }
        if (folderModel.count === 0) {
            Logger.e("video-wallpaper", "No valid video files found!");
            return;
        }

        Logger.d("video-wallpaper", "Choosing next wallpaper...");

        // Even if the file is not in wallpapers folder, aka -1, it sets the nextIndex to 0 then
        const name = typeof screen === "string" ? screen : Quickshell.screens[0]?.name;
        const currentIndex = folderModel.indexOf(Commands.record(pluginApi?.pluginSettings?.monitors, name)?.currentWallpaper);
        const nextIndex = (currentIndex + 1) % folderModel.count;
        const url = folderModel.get(nextIndex);
        setWallpaper(url, screen);
    }

    function setWallpaper(path, screen) {
        if (root.pluginApi == null) {
            Logger.e("video-wallpaper", "Can't set the wallpaper because pluginApi is null.");
            return;
        }

        var names = monitorSpecific && typeof screen === "string" ? [screen] : Array.from(Quickshell.screens).map(value => value.name);
        if (!names.length) return;
        var edits = [];
        for (var name of names) {
            edits.push({op: "set", screen: name, field: "currentWallpaper", value: path});
            edits.push({op: "set", screen: name, field: "isPlaying", value: true});
        }
        monitorCommand.submit(edits);

        pluginApi.saveSettings();
    }
}
