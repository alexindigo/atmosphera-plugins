import QtQuick

// Selected presentation/schedule only. The shared chat/connection lives in Main.
QtObject {
  id: client
  required property var settingsContext
  required property var defaults
  required property var poll
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView
  readonly property int pollSeconds: cfg.statusPollIntervalSec ?? defaults.statusPollIntervalSec ?? 30
  readonly property bool remote: cfg.clientOnlyMode ?? defaults.clientOnlyMode ?? false
  readonly property int bridgePort: remote ? (cfg.bridgePort ?? defaults.bridgePort ?? 19777) : (defaults.bridgePort ?? 19777)
  readonly property bool hideWhenIdle: cfg.hideWhenIdle ?? defaults.hideWhenIdle ?? false
  readonly property bool panelPinned: cfg.panelPinned ?? defaults.panelPinned ?? false
  readonly property bool showToolActivity: cfg.showToolActivity ?? defaults.showToolActivity ?? false
  readonly property string launcherPrefix: cfg.launcherPrefix ?? defaults.launcherPrefix ?? ">hermes"
  property Timer pollTimer: Timer {
    interval: client.pollSeconds * 1000
    running: client.current
    repeat: true
    onTriggered: client.poll()
  }
  onCurrentChanged: if (!current) Qt.callLater(function() { if (client && !client.current) client.retire(client); })
}
