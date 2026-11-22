import QtQuick
import "lib/Ui.js" as Ui

QtObject {
  id: client
  required property var owner
  required property var settingsContext
  required property var retire
  readonly property bool current: !owner.retired && settingsContext.current()
  readonly property var settings: settingsContext.settingsView
  readonly property var defaults: owner.defaults
  readonly property int pollIntervalMs: Math.max(owner.minimumPollIntervalMs, Number(settings.pollIntervalMs ?? defaults.pollIntervalMs ?? owner.defaultPollIntervalMs))
  readonly property string leftClickAction: settings.leftClickAction ?? defaults.leftClickAction ?? "panel"
  readonly property string launchBehavior: settings.launchBehavior ?? defaults.launchBehavior ?? "minimized-to-tray"
  readonly property string barLabelMode: settings.barLabelMode ?? defaults.barLabelMode ?? "short-label"
  readonly property bool showBarWhenRecording: settings.showBarWhenRecording ?? defaults.showBarWhenRecording ?? true
  readonly property bool showBarWhenReplay: settings.showBarWhenReplay ?? defaults.showBarWhenReplay ?? false
  readonly property bool showBarWhenStreaming: settings.showBarWhenStreaming ?? defaults.showBarWhenStreaming ?? true
  readonly property bool alwaysShowInBar: settings.showBarWhenReady ?? defaults.showBarWhenReady ?? true
  readonly property bool showControlCenterWhenRecording: settings.showControlCenterWhenRecording ?? defaults.showControlCenterWhenRecording ?? true
  readonly property bool showControlCenterWhenReplay: settings.showControlCenterWhenReplay ?? defaults.showControlCenterWhenReplay ?? true
  readonly property bool showControlCenterWhenStreaming: settings.showControlCenterWhenStreaming ?? defaults.showControlCenterWhenStreaming ?? true
  readonly property bool showControlCenterWhenReady: settings.showControlCenterWhenReady ?? defaults.showControlCenterWhenReady ?? false
  readonly property bool autoCloseManagedObs: settings.autoCloseManagedObs ?? defaults.autoCloseManagedObs ?? true
  readonly property bool openVideosAfterStop: settings.openVideosAfterStop ?? defaults.openVideosAfterStop ?? true
  readonly property bool showElapsedInBar: settings.showElapsedInBar ?? defaults.showElapsedInBar ?? false
  readonly property string configuredVideosPath: (settings.videosPath ?? defaults.videosPath ?? "").trim()
  readonly property string videosOpener: (settings.videosOpener ?? defaults.videosOpener ?? "xdg-open").trim()
  readonly property string videosPath: configuredVideosPath === "" ? owner.defaultVideosPath
                                     : configuredVideosPath === "~" ? owner.homeDir
                                     : configuredVideosPath.startsWith("~/") ? owner.homeDir + "/" + configuredVideosPath.slice(2) : configuredVideosPath
  readonly property bool canOpenVideos: videosPath !== "" && videosOpener !== ""
  readonly property bool actionBusy: owner.actionBusy
  readonly property bool obsRunning: owner.obsRunning
  readonly property bool websocket: owner.websocket
  readonly property bool connected: owner.connected
  readonly property bool recording: owner.recording
  readonly property bool replayBuffer: owner.replayBuffer
  readonly property bool streaming: owner.streaming
  readonly property int displayRecordDurationMs: owner.displayRecordDurationMs
  readonly property int displayStreamDurationMs: owner.displayStreamDurationMs
  readonly property bool websocketSupportMissing: owner.websocketSupportMissing
  readonly property bool websocketConfigMissing: owner.websocketConfigMissing
  readonly property var visibilitySettings: ({showBarWhenRecording:showBarWhenRecording,showBarWhenReplay:showBarWhenReplay,showBarWhenStreaming:showBarWhenStreaming,alwaysShowInBar:alwaysShowInBar,showControlCenterWhenRecording:showControlCenterWhenRecording,showControlCenterWhenReplay:showControlCenterWhenReplay,showControlCenterWhenStreaming:showControlCenterWhenStreaming,showControlCenterWhenReady:showControlCenterWhenReady})
  readonly property bool showInBar: current && Ui.shouldShowInBar(owner.outputState, visibilitySettings)
  readonly property bool showInControlCenter: current && Ui.shouldShowInControlCenter(owner.outputState, visibilitySettings, connected)
  readonly property string primaryActionText: Ui.primaryActionText(owner.pluginApi, leftClickAction)
  property Timer pollTimer: Timer {
    interval: client.pollIntervalMs
    running: client.current
    repeat: true
    onTriggered: if (!client.owner.actionBusy) client.owner.refresh()
  }
  onCurrentChanged: if (!current) Qt.callLater(function() { if (client && !client.current) client.retire(client); })
  function refresh() { if (current) owner.refresh(); }
  function launchObs() { return current && owner.launchObs(settingsContext); }
  function toggleRecord() { return current && owner.toggleRecord(settingsContext); }
  function toggleReplay() { return current && owner.toggleReplay(settingsContext); }
  function toggleStream() { return current && owner.toggleStream(settingsContext); }
  function saveReplay() { return current && owner.saveReplay(settingsContext); }
  function openVideos() { return current && owner.openVideos(settingsContext); }
  function openSettingsForCurrentContext() { if (current) owner.openSettingsForCurrentContext(); }
  function runPrimaryAction(screen, anchorItem, runtimeApi) { if (current) owner.runPrimaryAction(screen, anchorItem, settingsContext, runtimeApi); }
  function runSecondaryAction() { if (current) owner.runSecondaryAction(settingsContext); }
  function runMiddleAction() { if (current) owner.runMiddleAction(settingsContext); }
}
