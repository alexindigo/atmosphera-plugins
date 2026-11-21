pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel

import Quickshell
import "../common/MonitorCommands.js" as Commands

import "../common"

import qs.Commons
import qs.Portals
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM
  Layout.fillWidth: true

  /***************************
  * PROPERTIES
  ***************************/
  // Required properties
  required property var pluginApi
  required enabled
  required property string selectedMonitor
  required property var monitorSettings
  required property var toolSettings
  NSettingsBaseline {
    id: displayBaseline
    readonly property string currentWallpaper: Commands.record(root.pluginApi?.initialSettings?.monitors, root.selectedMonitor)?.currentWallpaper ?? ""
    readonly property real volume: Commands.value(root.pluginApi?.initialSettings?.monitors, root.selectedMonitor, "volume", root.pluginApi?.manifest?.metadata?.defaultSettings)
    ranges: [
      NSettingsRange {
        field: "volume"
        from: volumeInput.from
        to: volumeInput.to
      }
    ]
  }
  readonly property bool settingsDirty: edits.hasIntent || displayBaseline.differs({
                                                                                     currentWallpaper: currentWallpaper,
                                                                                     volume: volume
                                                                                   })
  MonitorEdits {
    id: edits
    values: ({
               currentWallpaper: root.currentWallpaper,
               volume: root.volume
             })
  }

  // Monitor specific properties
  readonly property bool isMuted: Commands.value(pluginApi?.pluginSettings?.monitors, selectedMonitor, "isMuted", pluginApi?.manifest?.metadata?.defaultSettings)
  readonly property bool isPlaying: Commands.value(pluginApi?.pluginSettings?.monitors, selectedMonitor, "isPlaying", pluginApi?.manifest?.metadata?.defaultSettings)

  property string currentWallpaper: monitorSettings.currentWallpaper ?? ""
  property bool monitorSpecific: pluginApi?.pluginSettings?.monitorSpecific ?? false
  property double volume: displayBaseline.project("volume")

  // Global properties
  property string wallpapersFolder: pluginApi?.pluginSettings?.wallpapersFolder ?? pluginApi?.manifest?.metadata?.defaultSettings?.wallpapersFolder ?? ""

  // Signals
  signal saveMonitorProperty(key: string, value: var)
  signal saveWallpaperChoice(path: string, screens: var)
  readonly property string randomFolderPath: Settings.preprocessPath(root.wallpapersFolder)
  property var pendingRandom: null
  property var randomChoices: null
  onRandomFolderPathChanged: {
    if (pendingRandom && pendingRandom.folder !== randomFolderPath) cancelRandomWallpaper();
  }

  function wallpaperScreens() {
    return monitorSpecific ? [selectedMonitor] : Array.from(Quickshell.screens).map(screen => screen.name);
  }

  function stageWallpaper(path, screens) {
    screens = screens || wallpaperScreens();
    saveWallpaperChoice(path, screens);
    if (screens.includes(selectedMonitor)) currentWallpaper = path;
  }

  function stageRandomWallpaper() {
    cancelRandomWallpaper();
    if (!Settings.preprocessPath(root.wallpapersFolder).length) return;
    pendingRandom = {folder: Settings.preprocessPath(root.wallpapersFolder), screens: wallpaperScreens()};
    randomChoices = wallpaperChoicesComponent.createObject(root, {sourceFolder: pendingRandom.folder});
  }

  function cancelRandomWallpaper() {
    pendingRandom = null;
    if (randomChoices) randomChoices.destroy();
    randomChoices = null;
  }

  function finishRandomWallpaper(model) {
    const request = pendingRandom;
    if (!request || model !== randomChoices || request.folder !== randomFolderPath || model.status !== FolderListModel.Ready || String(model.folder) !== String(Qt.resolvedUrl("file://" + request.folder))) return;
    pendingRandom = null;
    if (model.count > 0) stageWallpaper(model.get(Math.floor(Math.random() * model.count), "filePath"), request.screens);
    randomChoices = null;
    Qt.callLater(function () { model.destroy(); });
  }

  function stageClearWallpaper() {
    cancelRandomWallpaper();
    stageWallpaper("");
  }

  Component {
    id: wallpaperChoicesComponent
    FolderListModel {
      id: choices
      required property string sourceFolder
      folder: sourceFolder.length ? "file://" + sourceFolder : ""
      nameFilters: ["*.mp4", "*.avi", "*.mov", "*.webm", "*.gif"]
      showDirs: false
      onStatusChanged: root.finishRandomWallpaper(choices)
    }
  }

  /***************************
  * EVENTS
  ***************************/
  function loadMonitor(record) {
    // Update the local variables
    currentWallpaper = record.currentWallpaper ?? "";
    volume = Math.max(volumeInput.from, Math.min(volumeInput.to, Commands.resolve(record, "volume", pluginApi?.manifest?.metadata?.defaultSettings)));
    edits.reset();
  }
  Component.onCompleted: loadMonitor(monitorSettings)

  /***************************
  * COMPONENTS
  ***************************/
  // Select Wallpaper
  RowLayout {
    spacing: Style.marginS

    NLabel {
      enabled: root.enabled
      label: root.pluginApi?.tr("settings.general.select_wallpaper.title.label")
      description: root.pluginApi?.tr("settings.general.select_wallpaper.title.description")
    }

    AtmoIconButton {
      enabled: root.enabled
      icon: "wallpaper-selector"
      tooltipText: root.pluginApi?.tr("settings.general.select_wallpaper.icon_button.tooltip")
      onClicked: currentWallpaperPicker.openFilePicker()
    }

    PortalFilePicker {
      id: currentWallpaperPicker
      title: root.pluginApi?.tr("settings.general.select_wallpaper.file_picker.title")
      initialPath: root.wallpapersFolder
      selectionMode: "files"

      onAccepted: paths => {
        if (paths.length > 0) {
          Logger.d("video-wallpaper", "Selected the following current wallpaper:", paths[0]);
          root.stageWallpaper(paths[0]);
        }
      }
    }
  }

  // Volume
  NValueSlider {
    id: volumeInput
    objectName: "settings-range-volume"

    enabled: root.enabled
    from: 0.0
    to: 1.0
    defaultValue: 1.0
    value: root.volume
    stepSize: (Settings.data.audio.volumeStep / 100.0)
    text: `${root.volume * 100.0}%`
    label: root.pluginApi?.tr("settings.general.volume.label")
    description: root.pluginApi?.tr("settings.general.volume.description")
    onMoved: value => {
      root.volume = value;
      edits.mark("volume");
    }
  }

  NDivider {}

  // Tool row
  ToolRow {
    pluginApi: root.pluginApi
    enabled: root.enabled
    monitorSpecific: root.monitorSpecific
    screenName: root.selectedMonitor
    settingWriter: (key, value) => root.saveMonitorProperty(key, value)
    randomAction: root.stageRandomWallpaper
    clearAction: root.stageClearWallpaper
    settings: root.toolSettings
  }

  /********************************
  * Save settings functionality
  ********************************/
  function saveSettings() {
    if (pluginApi == null) {
      Logger.e("video-wallpaper", "Cannot save, pluginApi is null");
      return;
    }

    return edits.submit((key, value) => root.saveMonitorProperty(key, value));
  }
  function acknowledgeSettings(captured) {
    edits.acknowledge(captured);
  }
}
