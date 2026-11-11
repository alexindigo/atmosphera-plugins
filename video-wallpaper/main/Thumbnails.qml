pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.Commons
import "../common"

Item {
    id: root
    required property var pluginApi
    required property var getThumbPath
    required property string thumbCacheFolderPath
    required property FolderModel folderModel
    required property FolderModel thumbFolderModel

    // Cache readiness belongs to this generation, never to preference files.
    readonly property bool thumbCacheReady: internal.ready
    readonly property bool generationFailed: internal.failed
    readonly property string wallpapersFolder: pluginApi?.pluginSettings?.wallpapersFolder ?? pluginApi?.manifest?.metadata?.defaultSettings?.wallpapersFolder ?? ""

    QtObject {
        id: internal
        property bool ready: false
        property bool failed: false
        property bool initialized: false
        property bool pending: true
        property bool rebuild: false
        property bool awaitingCache: false
        property int generation: 0
        property int runningGeneration: -1
        property int index: 0
        property var paths: []
    }

    function invalidate(rebuild) {
        internal.generation++;
        internal.ready = false;
        internal.failed = false;
        internal.pending = true;
        internal.rebuild = internal.rebuild || rebuild;
        internal.awaitingCache = false;
        Qt.callLater(pump);
    }

    function thumbRegenerate() { invalidate(true); }

    function fail() {
        internal.ready = false;
        internal.failed = true;
        internal.awaitingCache = false;
        Logger.e("video-wallpaper", "Thumbnail generation failed; cache remains unready.");
    }

    function pump() {
        if (thumbGenerationProc.running || thumbRegenerationProc.running || !internal.initialized || !folderModel.ready || !thumbFolderModel.ready) return;
        if (internal.pending) {
            internal.runningGeneration = internal.generation;
            if (internal.rebuild) {
                internal.rebuild = false;
                thumbRegenerationProc.running = true;
                return;
            }
            internal.pending = false;
            internal.paths = Array.from(folderModel.files);
            internal.index = 0;
            advance();
        } else if (internal.awaitingCache) {
            internal.awaitingCache = false;
            if (internal.runningGeneration !== internal.generation) return;
            if (!internal.paths.every(path => thumbFolderModel.indexOf(root.getThumbPath(path)) !== -1)) { fail(); return; }
            internal.ready = true;
        }
    }

    function advance() {
        if (internal.runningGeneration !== internal.generation) { pump(); return; }
        while (internal.index < internal.paths.length) {
            const videoPath = internal.paths[internal.index++];
            const thumbPath = getThumbPath(videoPath);
            if (thumbFolderModel.indexOf(thumbPath) !== -1) continue;
            thumbGenerationProc.command = ["ffmpeg", "-nostdin", "-y", "-i", videoPath, "-vf", "scale=iw/2:-1, format=rgb24", "-vframes:v", "1", thumbPath];
            thumbGenerationProc.running = true;
            return;
        }
        internal.awaitingCache = true;
        thumbFolderModel.forceReload();
    }

    onWallpapersFolderChanged: invalidate(false)
    Connections {
        target: root.folderModel
        function onReadyChanged() {
            if (!root.folderModel.ready) root.invalidate(false);
            else Qt.callLater(root.pump);
        }
    }
    Connections {
        target: root.thumbFolderModel
        function onReadyChanged() { if (root.thumbFolderModel.ready) Qt.callLater(root.pump); }
    }

    Process {
        id: thumbInit
        command: ["mkdir", "-p", "--", root.thumbCacheFolderPath]
        running: true
        onExited: exitCode => {
            if (exitCode !== 0) { root.fail(); return; }
            internal.initialized = true;
            root.thumbFolderModel.forceReload();
        }
    }
    Process {
        id: thumbGenerationProc
        onExited: exitCode => {
            if (internal.runningGeneration !== internal.generation) { root.pump(); return; }
            if (exitCode !== 0) { root.fail(); return; }
            root.advance();
        }
    }
    Process {
        id: thumbRegenerationProc
        command: ["sh", "-c", "rm -rf -- \"$1\" && mkdir -p -- \"$1\"", "thumbnail-cache", root.thumbCacheFolderPath]
        onExited: exitCode => {
            if (exitCode !== 0 && internal.runningGeneration === internal.generation) { root.fail(); internal.pending = false; return; }
            root.thumbFolderModel.forceReload();
        }
    }
}
