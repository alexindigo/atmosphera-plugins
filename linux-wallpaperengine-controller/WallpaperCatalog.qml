import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

// Source-dependent browse state belongs to a captured runtime context, not to
// the single physical engine. Several views of that context share this client.
Item {
  id: root
  required property var pluginApi
  required property var settingsContext
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView ?? ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
  readonly property string folderPath: Settings.preprocessPath(String(cfg.wallpapersFolder ?? defaults.wallpapersFolder ?? "")).trim()
  readonly property int cacheMinutes: {
    const value = Number(cfg.wallpaperScanCacheMinutes ?? defaults.wallpaperScanCacheMinutes ?? 10);
    return isNaN(value) ? 10 : Math.max(0, Math.floor(value));
  }
  property bool scanningWallpapers: false
  property bool wallpapersFolderAccessible: true
  property var cachedWallpaperItems: []
  property double lastWallpaperScanAt: 0
  property bool notify: false
  property string requestFolder: ""
  property int generation: 0
  property int requestGeneration: -1
  property bool activated: false

  function refresh(force = false, showToast = false) {
    if (!current) return false;
    activated = true;
    if (folderPath.length === 0) {
      cachedWallpaperItems = [];
      wallpapersFolderAccessible = false;
      lastWallpaperScanAt = 0;
      return false;
    }
    if (scanner.running) return false;
    if (!force && cacheMinutes > 0 && cachedWallpaperItems.length > 0 && lastWallpaperScanAt > 0 && Date.now() - lastWallpaperScanAt < cacheMinutes * 60000) return true;
    requestFolder = folderPath;
    requestGeneration = generation;
    scanningWallpapers = true;
    notify = showToast;
    scanner.command = ["bash", pluginApi.pluginDir + "/scripts/scan-wallpapers.sh", requestFolder];
    scanner.running = true;
    return true;
  }

  onFolderPathChanged: {
    generation++;
    cachedWallpaperItems = [];
    lastWallpaperScanAt = 0;
    wallpapersFolderAccessible = true;
    if (scanner.running) scanner.running = false;
    if (activated) Qt.callLater(function () { root.refresh(true, false); });
  }
  onCurrentChanged: {
    if (!current) {
      generation++;
      scanner.running = false;
      scanningWallpapers = false;
      cachedWallpaperItems = [];
      Qt.callLater(function () { root.retire(root); });
    }
  }
  Component.onDestruction: scanner.running = false
  Process {
    id: scanner
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: exitCode => {
      root.scanningWallpapers = false;
      if (!root.current) return;
      if (root.requestGeneration !== root.generation || root.requestFolder !== root.folderPath) {
        if (root.activated) Qt.callLater(function () { root.refresh(true, false); });
        return;
      }
      const parsed = [];
      for (const raw of String(stdout.text || "").split("\n")) {
        const line = raw.trim();
        if (!line) continue;
        const parts = line.split("\t");
        const path = parts[0] || "";
        if (!path) continue;
        const size = String(parts[10] || "0:0").split(":");
        parsed.push({
          path: path, name: parts[1] || path.split("/").pop(), thumb: parts[2] || "",
          motionPreview: parts[3] || "", dynamic: parts[4] === "1",
          id: parts[5] || path.split("/").pop(), type: parts[6] || "unknown",
          resolution: parts[7] || "unknown", hasEmbeddedAudio: parts[8] === "1",
          hasAudioReactive: parts[9] === "1", bytes: Number(size[0] || 0),
          mtime: Number(size[1] || 0), approved: parts[11] === "1", description: parts[12] || ""
        });
      }
      root.cachedWallpaperItems = parsed;
      root.wallpapersFolderAccessible = exitCode === 0;
      root.lastWallpaperScanAt = exitCode === 0 ? Date.now() : 0;
      if (root.notify && exitCode === 0) ToastService.showNotice(root.pluginApi.tr("panel.title"),root.pluginApi.tr("toast.refreshedWallpapers",{count:parsed.length}),"refresh");
      root.notify = false;
      if (exitCode !== 0) Logger.e("LWEController", "Wallpaper scan failed", "exitCode=", exitCode, "stderr=", String(stderr.text || "").trim());
    }
  }
}
