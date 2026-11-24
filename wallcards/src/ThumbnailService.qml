import "Utils.js" as Utils
import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import qs.Commons
import qs.Services.UI

Item {
  id: service

  // Thumbnails come from the shared image owner (validated PNGs, fallback
  // decoding, video frames); the dominant color is read from those.
  required property string cacheDir
  required property var imageFilter
  required property var videoFilter
  required property string wallpaperDir
  property var colorOrder: ["Red", "Orange", "Green", "Teal", "Blue", "Purple", "Pink", "Monochrome"]
  property var colorOrderColors: ["#FF4500", "#FFA500", "#32CD32", "#2EC4B6", "#1E90FF", "#8A2BE2", "#FF69B4", "#A9A9A9"]
  property int fileCount: files.length
  property var files: []
  property bool loading: true
  property int pendingProcesses: 0
  property int thumbnailRevision: 0
  property var _entries: []

  signal ready

  function toLocalPath(urlStr) {
    return String(urlStr).replace(/^file:\/\//, "");
  }

  FolderListModel {
    id: thumbnailModel

    folder: service.wallpaperDir ? Qt.resolvedUrl("file://" + service.wallpaperDir) : ""
    nameFilters: Utils.nameFilters(service.imageFilter, service.videoFilter)
    showDirs: false
    sortField: FolderListModel.Name

    onStatusChanged: {
      if (status === FolderListModel.Ready) {
        service.createThumbnails();
      }
    }
  }

  function releaseEntries() {
    for (const entry of _entries) {
      entry.alive = false;
      if (entry.sampler) {
        entry.sampler.destroy();
        entry.sampler = null;
      }
      if (entry.token)
        ImageCacheService.releaseSource(entry.token);
    }
    _entries = [];
  }

  function createThumbnails() {
    releaseEntries();
    var entries = [];
    for (var i = 0; i < thumbnailModel.count; i++) {
      var fileName = thumbnailModel.get(i, "fileName");
      entries.push({
                     fileName: fileName,
                     filePath: toLocalPath(thumbnailModel.get(i, "filePath")),
                     isVideo: Utils.isVideo(fileName, service.videoFilter),
                     url: "",
                     hex: "",
                     settled: false,
                     alive: true,
                     token: "",
                      sampler: null
                   });
    }
    _entries = entries;
    pendingProcesses = entries.length;
    loading = entries.length > 0;
    // One placeholder per wallpaper while loading: the progress total.
    files = entries.map(() => ({}));
    for (const entry of entries)
      request(entry);
    if (entries.length === 0)
      ready();
  }

  function request(entry) {
    entry.token = ImageCacheService.acquireSource({
                                                    source: entry.filePath,
                                                    width: entry.isVideo ? 1024 : 1000,
                                                    height: entry.isVideo ? 1024 : 500,
                                                    fit: "contain",
                                                    animationIntent: "still",
                                                    operation: entry.isVideo ? "video-thumbnail" : "render"
                                                  }, function (reply) {
                                                    if (!entry.alive || entry.settled)
                                                      return;
                                                    if (!["hit", "generated"].includes(reply.status) || !reply.url) {
                                                      Logger.w("Wallcards", "Thumbnail unavailable:", entry.fileName, reply.reason || "");
                                                      settle(entry);
                                                      return;
                                                    }
                                                    entry.url = reply.url;
                                                    sampleColor(entry, reply.url);
                                                  });
  }

  function sampleColor(entry, thumbnailUrl) {
    // This is a normalized owner artifact, never the original wallpaper.
    const url = String(thumbnailUrl);
    if (!url.startsWith("file:///")) {
      settle(entry);
      return;
    }
    const path = decodeURIComponent(url.slice(7));
    const cache = ImageCacheService.thumbnailDir;
    const filename = entry.isVideo ? /^xx-large\/[a-f0-9]{32}\.png$/ : /^atmosphera-representations-v1\/still\/[a-f0-9]{64}\.png$/;
    if (!cache.startsWith("/") || !path.startsWith(cache) || !filename.test(path.slice(cache.length))) {
      settle(entry);
      return;
    }
    const sampler = samplerComponent.createObject(service, { thumbnailPath: path });
    if (!sampler) {
      settle(entry);
      return;
    }
    entry.sampler = sampler;
    sampler.completed.connect(function (hex) {
      if (!entry.alive || entry.settled || entry.sampler !== sampler)
        return;
      entry.sampler = null;
      sampler.destroy();
      entry.hex = hex;
      settle(entry);
    });
    sampler.running = true;
  }

  function averageColor(histogram) {
    let pixels = 0;
    const sums = [0, 0, 0];
    // Count the sampled pixels equally, skipping only fully transparent ones.
    const rows = /^\s*(\d+):[^\n]*?\s#([0-9a-f]{8})(?=\s|$)/gim;
    let row;
    while ((row = rows.exec(histogram)) !== null) {
      if (row[2].slice(6) === "00")
        continue;
      const count = Number(row[1]);
      pixels += count;
      for (let i = 0; i < 3; i++)
        sums[i] += count * parseInt(row[2].slice(i * 2, i * 2 + 2), 16);
    }
    return pixels ? sums.map(sum => Math.round(sum / pixels).toString(16).padStart(2, "0")).join("") : "";
  }

  function settle(entry) {
    entry.settled = true;
    pendingProcesses = Math.max(0, pendingProcesses - 1);
    thumbnailRevision++;
    if (pendingProcesses === 0)
      buildFileList();
  }

  function buildFileList() {
    var items = _entries.map(entry => ({
                                         fileName: entry.fileName,
                                         filePath: entry.filePath,
                                         // A failed thumbnail shows the original through the owner,
                                         // which labels the failure.
                                         thumbnail: entry.url || entry.filePath,
                                         hexCode: entry.hex,
                                         filterColor: getFilterColor(entry.hex),
                                         isVideo: entry.isVideo
                                       }));

    items.sort((a, b) => colorOrder.indexOf(a.filterColor) - colorOrder.indexOf(b.filterColor));

    files = items;
    service.loading = false;
    service.ready();
  }

  function getFilterColor(hexColor) {
    if (!hexColor)
      return "Monochrome";

    const cleaned = String(hexColor).trim().replace(/x/g, '').substring(0, 6);
    if (cleaned.length !== 6)
      return "Monochrome";

    const r = parseInt(cleaned.substring(0, 2), 16) / 255;
    const g = parseInt(cleaned.substring(2, 4), 16) / 255;
    const b = parseInt(cleaned.substring(4, 6), 16) / 255;
    if ([r, g, b].some(isNaN))
      return "Monochrome";

    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    const d = max - min;

    let h = 0;
    let s = max === 0 ? 0 : d / max;
    let v = max;

    if (d !== 0) {
      if (max === r)
        h = (g - b) / d + (g < b ? 6 : 0);
      else if (max === g)
        h = (b - r) / d + 2;
      else
        h = (r - g) / d + 4;
      h = (h / 6) * 360;
    }

    if (s < 0.15 || v < 0.10)
      return "Monochrome";
    if (h >= 345 || h < 15)
      return "Red";
    if (h < 50)
      return "Orange";
    if (h < 160)
      return "Green";
    if (h < 200)
      return "Teal";
    if (h < 260)
      return "Blue";
    if (h < 315)
      return "Purple";
    if (h < 345)
      return "Pink";

    return "Monochrome";
  }

  Component {
    id: samplerComponent

    Process {
      required property string thumbnailPath
      signal completed(string hex)

      // Only read a histogram on stdout; never decode an original or write an image.
      command: ["magick", "-limit", "thread", "1", thumbnailPath, "-scale", "32x32>", "-type", "TrueColorAlpha", "-depth", "8", "-format", "%c", "histogram:info:-"]
      stdout: StdioCollector { id: histogram }
      onExited: (code, status) => completed(code === 0 && status === 0 ? service.averageColor(histogram.text) : "")
      // FailedToStart does not deliver exited. A normal exit was already handled.
      onRunningChanged: if (!running) completed("")
    }
  }

  Component.onDestruction: releaseEntries()
}
