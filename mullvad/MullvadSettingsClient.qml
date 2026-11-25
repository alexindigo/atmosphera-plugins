import QtQuick
import qs.Services.Plugins

PluginSettingsPoller {
  id: root
  required property var observation
  readonly property var cfg: settingsContext.settingsView
  readonly property var defaults: observation.defaults
  sourceInterval: cfg.refreshInterval ?? defaults.refreshInterval ?? 3000
  requestRefresh: function() {
    if (!observation.installed) observation.checkInstalled();
    else observation.updateStatus();
  }
  readonly property bool showCountryFlag: cfg.showCountryFlag ?? defaults.showCountryFlag ?? true
  readonly property bool showCityName: cfg.showCityName ?? defaults.showCityName ?? false
  readonly property bool showIp: cfg.showIp ?? defaults.showIp ?? false
  readonly property bool compactMode: cfg.compactMode ?? defaults.compactMode ?? false
  readonly property string clickAction: cfg.clickAction ?? defaults.clickAction ?? "toggle"
  readonly property bool relayClickConnects: cfg.relayClickConnects ?? defaults.relayClickConnects ?? true
  readonly property bool confirmDisconnectInLockdown: cfg.confirmDisconnectInLockdown ?? defaults.confirmDisconnectInLockdown ?? true
  readonly property var favoriteCountries: cfg.favoriteCountries ?? defaults.favoriteCountries ?? []
  readonly property int expiryWarningDays: cfg.expiryWarningDays ?? defaults.expiryWarningDays ?? 7
  readonly property bool installed: observation.installed
  state: observation.state
  readonly property bool locked: observation.locked
  readonly property var currentLocation: observation.currentLocation
  readonly property var visibleLocation: observation.visibleLocation
  readonly property bool isRefreshing: observation.isRefreshing
  readonly property var relaySelection: observation.relaySelection
  readonly property bool multihop: observation.multihop
  readonly property string multihopEntry: observation.multihopEntry
  readonly property string ipVersion: observation.ipVersion
  readonly property var relayList: observation.relayList
  readonly property bool relayListReady: observation.relayListReady
  readonly property bool lockdownMode: observation.lockdownMode
  readonly property bool autoConnect: observation.autoConnect
  readonly property string lanSharing: observation.lanSharing
  readonly property string accountExpiry: observation.accountExpiry
  readonly property int accountDaysLeft: observation.accountDaysLeft

  function connectVpn() { if (current) observation.connectVpn(); }
  function disconnectVpn() { if (current) observation.disconnectVpn(); }
  function reconnectVpn() { if (current) observation.reconnectVpn(); }
  function toggleVpn() { if (current) observation.toggleVpn(); }
  function refreshRelayList() { if (current) observation.refreshRelayList(); }
  function refreshRelaySelection() { if (current) observation.refreshRelaySelection(); }
  function refreshTogglesState() { if (current) observation.refreshTogglesState(); }
  function setLocation(country, city, hostname) { if (current) observation.setLocation(country, city, hostname); }
  function setLockdown(on) { if (current) observation.setLockdown(on); }
  function setAutoConnect(on) { if (current) observation.setAutoConnect(on); }
  function setLanSharing(allow) { if (current) observation.setLanSharing(allow); }
  function setMultihop(on) { if (current) observation.setMultihop(on); }
  function setMultihopEntry(country) { if (current) observation.setMultihopEntry(country); }
  function setIpVersion(version) { if (current) observation.setIpVersion(version); }
}
