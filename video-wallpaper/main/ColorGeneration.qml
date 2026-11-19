pragma ComponentBehavior: Bound
import QtQuick
import "../common/MonitorCommands.js" as Commands
import qs.Commons
import qs.Services.UI

Item {
    id: root
    required property var pluginApi
    required property string screenName
    required property var thumbnailSource
    required property var baselineSource

    readonly property string currentWallpaper: Commands.record(pluginApi?.pluginSettings?.monitors, screenName)?.currentWallpaper ?? ""
    readonly property bool wallpaperEnabled: pluginApi?.pluginSettings?.enabled ?? false
    readonly property bool generationFailed: wallpaperEnabled && currentWallpaper !== "" && (thumbnailSource.generationFailed || baselineSource.failed)
    property bool _initialized: false
    property string _appliedWallpaper: ""
    property int _appliedGeneration: -1
    property int _appliedBaseline: -1

    // Every dependency owns its readiness and emits changes. Waiting does not
    // queue another attempt; only a real dependency transition can wake us.
    function startColorGen() {
        if (!_initialized || !wallpaperEnabled || currentWallpaper === "" || generationFailed) return;
        if (!baselineSource.baselineReady || baselineSource.currentWallpaper !== currentWallpaper) return;
        const path = thumbnailSource.pathFor(currentWallpaper);
        if (path === "") return;
        if (_appliedWallpaper === currentWallpaper && _appliedGeneration === thumbnailSource.generation && _appliedBaseline === baselineSource.revision) return;
        _appliedWallpaper = currentWallpaper;
        _appliedGeneration = thumbnailSource.generation;
        _appliedBaseline = baselineSource.revision;
        Logger.d("video-wallpaper", "Generating color scheme based on video wallpaper!");
        WallpaperService.changeWallpaper(path, screenName);
    }

    function schedule() { Qt.callLater(startColorGen); }
    onCurrentWallpaperChanged: schedule()
    onWallpaperEnabledChanged: {
        if (!wallpaperEnabled) _appliedWallpaper = "";
        schedule();
    }
    Connections {
        target: root.thumbnailSource
        function onThumbCacheReadyChanged() { root.schedule(); }
        function onGenerationFailedChanged() { root.schedule(); }
        function onGenerationChanged() { root.schedule(); }
    }
    Connections {
        target: root.baselineSource
        function onBaselineReadyChanged() { root.schedule(); }
        function onFailedChanged() { root.schedule(); }
        function onRevisionChanged() { root.schedule(); }
    }
    Component.onCompleted: { _initialized = true; schedule(); }
}
