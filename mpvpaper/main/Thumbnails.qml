import Qt.labs.folderlistmodel
import QtQuick
import Quickshell

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

    // Only the selected video's palette needs an exported file.
    // path -> {request, state, path,
    // code, reason}. Reassigned on every change so bindings follow it.
    property var _entries: ({})
    property var colorRequest: null
    property bool colorScheduled: false

    onActiveChanged: if (!active) cancelColorGen()
    onSettingsContextChanged: cancelColorGen()
    onCurrentWallpaperChanged: if (!ownsWallpaper(colorRequest)) cancelColorGen()

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
        const entry = root._entries[videoPath];
        return entry && entry.state === "ready" ? entry.path : "";
    }

    // Get thumbnail url of a video ("" until the owner produced it)
    function getThumbUrl(videoPath: string): string {
        return getThumbPath(videoPath);
    }

    // The owner's failure for a video's thumbnail ({code, reason}, empty when none)
    function getThumbFailure(videoPath: string): var {
        const entry = root._entries[videoPath];
        return entry && entry.state === "unavailable" ? { code: entry.code, reason: entry.reason } : { code: "", reason: "" };
    }

    // A thumbnail is the owner's output, never a user's own wallpaper.
    function isThumbnail(path: string): bool {
        return ImageCacheService.isGeneratedImage(path);
    }


    function ownsWallpaper(request) {
        return !!request && root.active && request.path !== "" && request.path === root.currentWallpaper
            && request.context === root.settingsContext && request.context?.current();
    }

    function startColorGen(context, path) {
        const request = {context: context, path: String(path)};
        if (!ownsWallpaper(request)) return;
        colorRequest = request;
        colorScheduled = false;
        root.applyColorGen();
    }

    function cancelColorGen() {
        colorRequest = null;
        colorScheduled = false;
    }

    function applyColorGen() {
        const request = root.colorRequest;
        if (!ownsWallpaper(request) || colorScheduled) return;
        const wallpaper = request.path;
        const entry = root._entries[wallpaper];
        if (!entry) {
            // The current wallpaper isn't in the wallpapers folder.
            root.acquire([wallpaper], false);
            return;
        }
        if (entry.state === "loading") return;
        if (entry.state !== "ready") {
            root.cancelColorGen();
            Logger.w("mpvpaper", "No thumbnail for color generation:", wallpaper, entry.reason);
            return;
        }
        root.colorScheduled = true;
        root.pluginApi.withCurrentScreen(screen => {
            if (root.colorRequest !== request || !ownsWallpaper(request) || root._entries[wallpaper] !== entry) return;
            root.cancelColorGen();
            Logger.d("mpvpaper", "Generating color scheme based on video wallpaper!");
            WallpaperService.changeWallpaper(entry.path);
        });
    }

    function request(videoPath: string): var {
        const entry = { request: null, state: "loading", path: "", code: "", reason: "" };
        entry.request = ImageCacheService.exportVideoFrame(videoPath, function (path, ready, reply) {
            if (root._entries[videoPath] !== entry) return;
            entry.request = null;
            if (!ready) Logger.w("mpvpaper", "Thumbnail unavailable:", videoPath, reply.reason || "");
            entry.state = ready ? "ready" : "unavailable";
            entry.path = ready ? path : "";
            entry.code = ready ? "" : (reply.code || "decode-unavailable");
            entry.reason = ready ? "" : (reply.reason || "");
            root._entries = Object.assign({}, root._entries);
            root.settle();
            root.applyColorGen();
        });
        return entry;
    }

    // Hold interests for exactly these videos; retry asks again for all of them.
    function acquire(paths, retry) {
        const previous = root._entries;
        const entries = {};
        for (const path of paths)
            entries[path] = previous[path] && !retry ? previous[path] : root.request(path);
        root._entries = entries;
        for (const path in previous)
            if (entries[path] !== previous[path]) previous[path].request?.cancel();
    }

    function settle() {
        for (const path in root._entries)
            if (root._entries[path].state === "loading") return;
        // The generation has settled every video; failures stay labelled.
        root.setThumbCacheReady();
    }

    function thumbGeneration(retry) {
        if(pluginApi == null) return;

        // Reset the state of thumbCacheReady
        clearThumbCacheReady();

        root.acquire(root.active && root.currentWallpaper !== "" ? [root.currentWallpaper] : [], retry === true);
        root.settle();
    }

    function thumbRegenerate() {
        // Arm before the new request, without applying the old thumbnail.
        cancelColorGen();
        const request = {context: root.settingsContext, path: root.currentWallpaper};
        if (ownsWallpaper(request))
            colorRequest = request;
        root.thumbGeneration(true);
        root.applyColorGen();
    }

    Component.onDestruction: {
        for (const path in root._entries)
            root._entries[path].request?.cancel();
    }
}
