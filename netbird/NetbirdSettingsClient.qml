import QtQuick
import qs.Services.Plugins

PluginSettingsPoller {
  id: root
  required property var observation
  readonly property var cfg: settingsContext.settingsView
  sourceInterval: cfg.refreshInterval ?? 5000
  requestRefresh: function() {
    if (!observation.netbirdInstalled) observation.checkNetbirdInstalled();
    else observation.updateNetbirdStatus();
  }
  readonly property int refreshInterval: sourceInterval
  readonly property bool compactMode: cfg.compactMode ?? false
  readonly property bool showIpAddress: cfg.showIpAddress ?? true
  readonly property bool showPing: cfg.showPing ?? false
  readonly property string adminConsoleUrl: {
    var configured = observation.normalizeManagementUrl(cfg.managementUrl ?? "");
    if (configured !== "") return configured;
    if (observation.managementUrlDetected !== "") return observation.managementUrlDetected;
    return observation.normalizeManagementUrl(observation.pluginApi?.manifest?.metadata?.defaultSettings?.managementUrl || "https://app.netbird.io/");
  }
  readonly property string detectedTerminal: observation.detectedTerminal
  readonly property bool terminalDetected: detectedTerminal !== ""
  readonly property bool netbirdInstalled: observation.netbirdInstalled
  readonly property bool netbirdRunning: observation.netbirdRunning
  readonly property string netbirdIp: observation.netbirdIp
  readonly property string netbirdFqdn: observation.netbirdFqdn
  readonly property string netbirdStatus: observation.netbirdStatus
  readonly property int peerCount: observation.peerCount
  readonly property int peerConnected: observation.peerConnected
  readonly property bool isRefreshing: observation.isRefreshing
  readonly property var peerList: observation.peerList
  readonly property bool managementConnected: observation.managementConnected
  readonly property bool signalConnected: observation.signalConnected
  readonly property var peerPings: observation.peerPings

  onShowPingChanged: observation.updatePingDemand()
  function updateNetbirdStatus() { if (current) observation.updateNetbirdStatus(); }
  function toggleNetbird() { if (current) observation.toggleNetbird(); }
}
