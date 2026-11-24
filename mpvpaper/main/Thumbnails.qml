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
    required property string currentWallpaper 
    required property bool thumbCacheReady
    required property FolderListModel folderModel

    // Video frames come from the shell's image owner (validated PNG
    // thumbnails). One interest per video: path -> {token, state, url, path,
    // code, reason}. Reassigned on every change so bindings follow it.
    property var _entries: ({})
    property bool _colorGenPending: false
    readonly property string _retryOwner: "mpvpaper:" + Date.now() + ":" + Math.random()
    property int _retrySequence: 0


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
        const entry = root._entries[videoPath];
        return entry && entry.state === "ready" ? entry.url : "";
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


    function startColorGen() {
        root._colorGenPending = true;
        root.applyColorGen();
    }

    function applyColorGen() {
        if (!root._colorGenPending || pluginApi == null || root.currentWallpaper === "") return;
        const entry = root._entries[root.currentWallpaper];
        if (!entry) {
            // The current wallpaper isn't in the wallpapers folder.
            root._entries = Object.assign({}, root._entries, { [root.currentWallpaper]: root.request(root.currentWallpaper, "") });
            return;
        }
        if (entry.state === "loading") return;
        root._colorGenPending = false;
        if (entry.state !== "ready") {
            Logger.w("mpvpaper", "No thumbnail for color generation:", root.currentWallpaper, entry.reason);
            return;
        }
        root.pluginApi.withCurrentScreen(screen => {
            Logger.d("mpvpaper", "Generating color scheme based on video wallpaper!");
            WallpaperService.changeWallpaper(entry.path);
        });
    }

    function request(videoPath: string, retryRevision: string): var {
        const entry = { token: "", state: "loading", url: "", path: "", code: "", reason: "" };
        entry.token = ImageCacheService.acquireSource({
            source: videoPath,
            width: 1024,
            height: 1024,
            fit: "contain",
            animationIntent: "still",
            operation: "video-thumbnail",
            retry: retryRevision !== "",
            revision: retryRevision
        }, function (reply) {
            if (root._entries[videoPath] !== entry) return;
            const ready = (reply.status === "hit" || reply.status === "generated") && reply.url !== "";
            if (!ready) Logger.w("mpvpaper", "Thumbnail unavailable:", videoPath, reply.reason || "");
            entry.state = ready ? "ready" : "unavailable";
            entry.url = ready ? reply.url : "";
            entry.path = ready ? decodeURIComponent(String(reply.url).replace(/^file:\/\//, "")) : "";
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
        // A different producer can still hold the last retry's result.
        // Only refreshes need a private revision; normal requests still share.
        const revision = retry ? root._retryOwner + ":" + (++root._retrySequence) : "";
        for (const path of paths)
            entries[path] = previous[path] && !retry ? previous[path] : root.request(path, revision);
        root._entries = entries;
        for (const path in previous)
            if (entries[path] !== previous[path]) ImageCacheService.releaseSource(previous[path].token);
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

        const paths = [];
        for (let i = 0; i < folderModel.count; i++)
            paths.push(folderModel.get(i, "filePath"));
        if (root.currentWallpaper !== "" && paths.indexOf(root.currentWallpaper) === -1)
            paths.push(root.currentWallpaper);
        root.acquire(paths, retry === true);
        root.settle();
    }

    function thumbRegenerate() {
        // Arm before the new request, without applying the old thumbnail.
        if (pluginApi?.pluginSettings?.active)
            root._colorGenPending = true;
        root.thumbGeneration(true);
    }

    Component.onDestruction: {
        for (const path in root._entries)
            ImageCacheService.releaseSource(root._entries[path].token);
    }
}
