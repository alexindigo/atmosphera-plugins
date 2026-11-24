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
    readonly property bool policyCurrent: settingsContext?.current() ?? false
    property var _browseRequests: new Map()
    onSettingsContextChanged: cancelBrowse()
    onPolicyCurrentChanged: if (!policyCurrent) cancelBrowse()
    onWallpapersFolderChanged: cancelBrowse()


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

    function retireBrowse(model) {
        if (!_browseRequests.delete(model)) return;
        Qt.callLater(function () { model.destroy(); });
    }

    function cancelBrowse(screens) {
        for (const [model, request] of _browseRequests) {
            if (screens) request.screens = request.screens.filter(name => !screens.includes(name));
            if (!screens || request.screens.length === 0) retireBrowse(model);
        }
    }

    function affectedScreens(selected, screen) {
        return selected.monitorSpecific && typeof screen === "string" ? [screen] : Array.from(Quickshell.screens).map(value => value.name);
    }

    function browse(mode, screen, runtimeApi) {
        runtimeApi = runtimeApi || pluginApi;
        const context = runtimeApi?.settingsContext;
        if (!context?.current() || context !== settingsContext) return false;
        const selected = context.settingsView;
        const names = affectedScreens(selected, screen);
        const name = typeof screen === "string" ? screen : Quickshell.screens[0]?.name;
        const folder = String(selected.wallpapersFolder ?? "");
        if (!names.length || !folder.length) return false;
        const model = browseChoicesComponent.createObject(root, {sourceFolder: Settings.preprocessPath(folder)});
        if (!model) return false;
        cancelBrowse(names);
        _browseRequests.set(model, {writer: runtimeApi, context: context, folder: folder,
            screens: names, current: Commands.record(selected.monitors, name)?.currentWallpaper ?? "", mode: mode});
        finishBrowse(model);
        return true;
    }

    function finishBrowse(model) {
        const request = _browseRequests.get(model);
        if (!request) return;
        if (!request.context.current() || request.context !== settingsContext || request.folder !== String(request.context.settingsView.wallpapersFolder ?? "")) { retireBrowse(model); return; }
        if (!model.ready) return;
        retireBrowse(model);
        if (model.count > 0) {
            const index = request.mode === "random" ? Math.floor(Math.random() * model.count) : (model.indexOf(request.current) + 1) % model.count;
            setWallpaper(model.get(index), undefined, request.writer, request.screens);
        }
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
        if (!runtimeApi?.settingsContext?.current() || runtimeApi.settingsContext !== settingsContext) {
            Logger.e("video-wallpaper", "Can't set the wallpaper because pluginApi is null.");
            return;
        }

        const selected = runtimeApi.settingsContext.settingsView;
        const names = admittedScreens || affectedScreens(selected, screen);
        if (!names.length) return;
        if (!admittedScreens) cancelBrowse(names);
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
