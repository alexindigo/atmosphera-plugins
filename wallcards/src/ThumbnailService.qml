import "Utils.js" as Utils
import QtQuick
import Qt.labs.folderlistmodel
import ImvQml
import qs.Commons

Item {
  id: service

  // Cards display original sources through NImage. Sampling owns only small
  // RGBA buffers, not staging files or a separate decode pipeline.
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
  property var _requests: ({})
  property int _cursor: 0

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
    retry.stop();
    for (const id of Object.keys(_requests))
      sampler.cancel(Number(id));
    _requests = ({});
    _entries = [];
    _cursor = 0;
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
                     hex: ""
                   });
    }
    _entries = entries;
    pendingProcesses = entries.length;
    loading = entries.length > 0;
    // One placeholder per wallpaper while loading: the progress total.
    files = entries.map(() => ({}));
    pump();
    if (entries.length === 0)
      ready();
  }

  function pump() {
    while (_cursor < _entries.length && Object.keys(_requests).length < 2) {
      const entry = _entries[_cursor];
      const id = sampler.sample(entry.filePath, 32, 32, 0.1);
      if (id === -2) {
        retry.restart();
        return;
      }
      ++_cursor;
      if (id > 0)
        _requests[id] = entry;
      else
        settle();
    }
  }

  function averageColor(buffer) {
    let pixels = 0;
    const sums = [0, 0, 0];
    // Count the sampled pixels equally, skipping only fully transparent ones.
    const rgba = new Uint8Array(buffer);
    for (let offset = 0; offset + 3 < rgba.length; offset += 4) {
      if (rgba[offset + 3] === 0)
        continue;
      ++pixels;
      for (let i = 0; i < 3; i++)
        sums[i] += rgba[offset + i];
    }
    return pixels ? sums.map(sum => Math.round(sum / pixels).toString(16).padStart(2, "0")).join("") : "";
  }

  function settle() {
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
                                          thumbnail: entry.filePath,
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

  Timer { id: retry; interval: 125; onTriggered: service.pump() }
  ImvImageJob {
    id: sampler
    onFinished: (id, result) => {
      const entry = service._requests[id];
      if (!entry)
        return;
      delete service._requests[id];
      if (result.stage === "complete")
        entry.hex = service.averageColor(result.rgba);
      else
        Logger.w("Wallcards", "Image sample unavailable:", entry.fileName, result.detail || result.code);
      service.settle();
      service.pump();
    }
  }

  Component.onDestruction: releaseEntries()
}
