import QtQuick
import Quickshell
import qs.Commons

import "../common"
import "../common/MonitorCommands.js" as Commands

Item {
    id: root
    required property var pluginApi
    property var settingsContext: pluginApi?.settingsContext
    readonly property var cfg: settingsContext?.settingsView ?? pluginApi?.pluginSettings
    property var pendingBrowse: null
    property var browseChoices: null
    onSettingsContextChanged: {
        if (pendingBrowse && pendingBrowse.context !== settingsContext) cancelBrowse();
    }


    /***************************
    * PROPERTIES
    ***************************/
    // Required properties
    required property FolderModel folderModel

    // Global properties
    readonly property bool   monitorSpecific: cfg?.monitorSpecific ?? false
    readonly property string wallpapersFolder: cfg?.wallpapersFolder ?? pluginApi?.manifest?.metadata?.defaultSettings?.wallpapersFolder ?? ""


    /***************************
    * FUNCTIONS
    ***************************/
    function random(screen, runtimeApi) {
        return browse("random", screen, runtimeApi);
    }

    function clear(screen, runtimeApi) {
        setWallpaper("", screen, runtimeApi);
    }

    function nextWallpaper(screen, runtimeApi) {
        return browse("next", screen, runtimeApi);
    }

    function cancelBrowse() {
        pendingBrowse = null;
        if (browseChoices) browseChoices.destroy();
        browseChoices = null;
    }

    function browse(mode, screen, runtimeApi) {
        runtimeApi = runtimeApi || pluginApi;
        if (!runtimeApi?.settingsContext?.current()) return false;
        cancelBrowse();
        const selected = runtimeApi.settingsContext.settingsView;
        const names = selected.monitorSpecific && typeof screen === "string" ? [screen] : Array.from(Quickshell.screens).map(value => value.name);
        const name = typeof screen === "string" ? screen : Quickshell.screens[0]?.name;
        pendingBrowse = {writer: runtimeApi, context: runtimeApi.settingsContext, folder: String(selected.wallpapersFolder ?? ""),
            screens: names, current: Commands.record(selected.monitors, name)?.currentWallpaper ?? "", mode: mode};
        if (!pendingBrowse.folder.length) { cancelBrowse(); return false; }
        browseChoices = browseChoicesComponent.createObject(root, {sourceFolder: Settings.preprocessPath(pendingBrowse.folder)});
        return true;
    }

    function finishBrowse(model) {
        const request = pendingBrowse;
        if (!request || model !== browseChoices) return;
        if (!request.context.current() || request.context !== settingsContext || request.folder !== String(request.context.settingsView.wallpapersFolder ?? "")) { cancelBrowse(); return; }
        if (!model.ready) return;
        pendingBrowse = null;
        if (model.count > 0) {
            const index = request.mode === "random" ? Math.floor(Math.random() * model.count) : (model.indexOf(request.current) + 1) % model.count;
            setWallpaper(model.get(index), undefined, request.writer, request.screens);
        }
        browseChoices = null;
        Qt.callLater(function () { model.destroy(); });
    }

    Component {
        id: browseChoicesComponent
        FolderModel {
            id: choices
            required property string sourceFolder
            folder: sourceFolder
            filters: ["*.mp4", "*.avi", "*.mov", "*.webm", "*.gif"]
            onReadyChanged: root.finishBrowse(choices)
        }
    }

    function setWallpaper(path, screen, runtimeApi, admittedScreens) {
        runtimeApi = runtimeApi || pluginApi;
        if (!runtimeApi?.settingsContext?.current()) {
            Logger.e("video-wallpaper", "Can't set the wallpaper because pluginApi is null.");
            return;
        }

        const selected = runtimeApi.settingsContext.settingsView;
        var names = admittedScreens || (selected.monitorSpecific && typeof screen === "string" ? [screen] : Array.from(Quickshell.screens).map(value => value.name));
        if (!names.length) return;
        var edits = [];
        for (var name of names) {
            edits.push({op: "set", screen: name, field: "currentWallpaper", value: path});
            edits.push({op: "set", screen: name, field: "isPlaying", value: true});
        }
        const writer = runtimeApi;
        const monitorCommand = Commands.create(function () { return writer.pluginSettings.monitors; },
            function (value) { writer.pluginSettings.monitors = value; }, function (value) { return Settings.store.copyValue(value); },
            function () { return writer.manifest?.metadata?.defaultSettings; });
        monitorCommand.submit(edits);

        writer.saveSettings();
    }
}
