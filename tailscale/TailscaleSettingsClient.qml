import QtQuick
import qs.Services.Plugins

PluginSettingsPoller {
  id: root
  required property var observation
  readonly property var cfg: settingsContext.settingsView
  readonly property var defaults: observation.pluginApi?.manifest?.metadata?.defaultSettings || ({})
  sourceInterval: cfg.refreshInterval ?? 5000
  requestRefresh: function() {
    if (!observation.tailscaleInstalled) observation.checkTailscaleInstalled();
    else observation.updateTailscaleStatus();
  }
  readonly property int refreshInterval: sourceInterval
  readonly property bool compactMode: cfg.compactMode ?? false
  readonly property bool showIpAddress: cfg.showIpAddress ?? true
  readonly property bool showPeerCount: cfg.showPeerCount ?? true
  readonly property bool taildropEnabled: cfg.taildropEnabled ?? defaults.taildropEnabled ?? true
  readonly property string taildropDownloadDir: observation._expandPath(cfg.taildropDownloadDir || defaults.taildropDownloadDir || "~/Downloads")
  readonly property string taildropReceiveMode: cfg.taildropReceiveMode || defaults.taildropReceiveMode || "operator"
  readonly property bool tailscaleInstalled: observation.tailscaleInstalled
  readonly property bool tailscaleRunning: observation.tailscaleRunning
  readonly property string tailscaleIp: observation.tailscaleIp
  readonly property string tailscaleStatus: observation.tailscaleStatus
  readonly property bool needsLogin: observation.needsLogin
  readonly property string authUrl: observation.authUrl
  readonly property int peerCount: observation.peerCount
  readonly property bool isRefreshing: observation.isRefreshing
  readonly property var peerList: observation.peerList
  readonly property var exitNodeStatus: observation.exitNodeStatus
  readonly property var accounts: observation.accounts
  readonly property string currentAccountId: observation.currentAccountId
  readonly property bool accountSwitchInProgress: observation.accountSwitchInProgress
  readonly property string taildropState: observation.taildropState
  readonly property string taildropMessage: observation.taildropMessage

  function filterIPv4(ips) { return observation.filterIPv4(ips); }
  function resolveHostName(host, dns) { return observation.resolveHostName(host, dns); }
  function tailscaleName(dns) { return observation.tailscaleName(dns); }
  function updateTailscaleStatus() { if (current) observation.updateTailscaleStatus(); }
  function toggleTailscale() { if (current) observation.toggleTailscale(); }
  function setExitNode(ip) { if (current) observation.setExitNode(ip); }
  function clearExitNode() { if (current) observation.clearExitNode(); }
  function switchAccount(id) { if (current) observation.switchAccount(id); }
  function loginTailscale() {
    if (current) observation.loginTailscale(cfg.loginServer || "");
  }
  function startTaildropReceive() {
    if (!current) return;
    var context = settingsContext;
    observation.startTaildropReceive({
      context: context,
      enabled: taildropEnabled,
      directory: taildropDownloadDir,
      mode: taildropReceiveMode,
      current: function() { return context.current(); }
    });
  }
  function sendFilesViaTaildrop(files, peerTarget) {
    if (current) observation.sendFilesViaTaildrop(files, peerTarget, taildropEnabled);
  }
}
