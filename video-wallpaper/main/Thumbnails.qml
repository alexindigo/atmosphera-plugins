pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Services.UI
import "../common"

Item {
    id: root
    required property var pluginApi
    property var settingsContext: pluginApi?.settingsContext
    required property FolderModel folderModel
    // Selected files can live outside the browsed directory. They use this
    // producer too, never a second request owned by a color consumer.
    property var requestedPaths: []

    // Export only frames the wallpaper/palette integration needs as files.
    // Cache readiness belongs to this generation, never to preference files.
    readonly property bool thumbCacheReady: internal.ready
    readonly property bool generationFailed: internal.failed
    // Every current video has its thumbnail or a labelled failure.
    readonly property bool settled: internal.settled
    readonly property int generation: internal.generation
    readonly property string wallpapersFolder: settingsContext?.settingsView?.wallpapersFolder ?? pluginApi?.manifest?.metadata?.defaultSettings?.wallpapersFolder ?? ""

    QtObject {
        id: internal
        property bool ready: false
        property bool failed: false
        property bool settled: false
        property bool pending: true
        property bool retry: false
        property int generation: 0
        property var paths: []
        // video path -> {request, state: "loading" | "ready" | "unavailable", path}
        property var entries: ({})
    }

    function invalidate(retry) {
        internal.generation++;
        internal.ready = false;
        internal.failed = false;
        internal.settled = false;
        internal.pending = true;
        internal.retry = internal.retry || retry;
        Qt.callLater(pump);
    }

    // Refresh: ask the owner again for every video, including failed ones.
    function thumbRegenerate() {
        invalidate(true);
        folderModel.forceReload();
    }

    // A thumbnail is the owner's output, never a user's own wallpaper.
    function ownsPath(path) {
        return ImageCacheService.isGeneratedImage(path);
    }

    // The owner's thumbnail of a video once it exists, "" before or without one.
    function thumbnailFor(videoPath) {
        const entry = internal.entries[videoPath];
        return entry && entry.state === "ready" ? entry.path : "";
    }

    // The owner's failure for a video's thumbnail ({code, reason}, empty when none).
    function failureFor(videoPath) {
        const entry = internal.entries[videoPath];
        return entry && entry.state === "unavailable" ? { code: entry.code, reason: entry.reason } : { code: "", reason: "" };
    }

    function pathFor(videoPath) {
        if (!thumbCacheReady || internal.paths.indexOf(videoPath) === -1) return "";
        return thumbnailFor(videoPath);
    }

    function request(videoPath) {
        const entry = { request: null, state: "loading", path: "", code: "", reason: "" };
        entry.request = ImageCacheService.exportVideoFrame(videoPath, function (path, ready, reply) {
            if (internal.entries[videoPath] !== entry) return;
            entry.request = null;
            if (!ready) Logger.w("video-wallpaper", "Thumbnail unavailable:", videoPath, reply.reason || "");
            entry.state = ready ? "ready" : "unavailable";
            entry.path = ready ? path : "";
            entry.code = ready ? "" : (reply.code || "decode-unavailable");
            entry.reason = ready ? "" : (reply.reason || "");
            internal.entries = Object.assign({}, internal.entries);
            root.settle();
        });
        return entry;
    }

    function release(entries) {
        for (const path in entries)
            entries[path].request?.cancel();
    }

    function pump() {
        if (!internal.pending || !folderModel.ready) return;
        internal.pending = false;
        const retry = internal.retry;
        internal.retry = false;
        const paths = Array.from(new Set(requestedPaths.filter(path => path !== "")));
        const previous = internal.entries;
        const entries = {};
        for (const path of paths)
            entries[path] = previous[path] && !retry ? previous[path] : request(path);
        const retired = {};
        for (const path in previous)
            if (entries[path] !== previous[path]) retired[path] = previous[path];
        internal.paths = paths;
        internal.entries = entries;
        release(retired);
        settle();
    }

    function settle() {
        if (internal.pending) return;
        const states = internal.paths.map(path => internal.entries[path].state);
        const failed = states.indexOf("unavailable") !== -1;
        internal.ready = !failed && states.every(state => state === "ready");
        internal.settled = states.indexOf("loading") === -1;
        if (failed && !internal.failed) Logger.e("video-wallpaper", "Thumbnail generation failed; cache remains unready.");
        internal.failed = failed;
    }

    onWallpapersFolderChanged: invalidate(false)
    onRequestedPathsChanged: invalidate(false)
    Connections {
        target: root.folderModel
        function onReadyChanged() {
            if (!root.folderModel.ready) root.invalidate(false);
            else Qt.callLater(root.pump);
        }
    }
    Component.onCompleted: Qt.callLater(pump)
    Component.onDestruction: release(internal.entries)
}
