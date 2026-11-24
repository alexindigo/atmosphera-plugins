import "Utils.js" as Utils
import QtQuick
import Quickshell
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
      if (entry.token)
        ImageCacheService.releaseSource(entry.token);
      if (entry.quantizer)
        entry.quantizer.destroy();
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
                     quantizer: null
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
                                                    if (reply.status === "unavailable" || !reply.url) {
                                                      Logger.w("Wallcards", "Thumbnail unavailable:", entry.fileName, reply.reason || "");
                                                      settle(entry);
                                                      return;
                                                    }
                                                    entry.url = reply.url;
                                                    quantize(entry);
                                                  });
  }

  function quantize(entry) {
    const quantizer = quantizerComponent.createObject(service);
    if (!quantizer) {
      settle(entry);
      return;
    }
    entry.quantizer = quantizer;
    quantizer.colorsChanged.connect(function () {
      if (!entry.alive || entry.settled || entry.quantizer !== quantizer)
        return;
      // The native completion signal also delivers an empty palette.
      if (quantizer.colors.length) {
        const color = quantizer.colors[0];
        entry.hex = [color.r, color.g, color.b].map(c => Math.round(c * 255).toString(16).padStart(2, "0")).join("");
      }
      settle(entry);
    });
    quantizer.source = entry.url;
  }

  function settle(entry) {
    entry.settled = true;
    if (entry.quantizer) {
      entry.quantizer.destroy();
      entry.quantizer = null;
    }
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
    id: quantizerComponent

    ColorQuantizer {
      depth: 0
      rescaleSize: 32
    }
  }

  Component.onDestruction: releaseEntries()
}
