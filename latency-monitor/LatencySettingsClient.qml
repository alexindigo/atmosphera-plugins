import QtQuick
import qs.Commons
import "ThresholdPolicy.js" as ThresholdPolicy

Item {
  id: root
  required property var pluginApi
  required property var settingsContext
  required property var retire
  readonly property bool current: settingsContext.current()
  property bool _constructed: false

  readonly property var cfg: settingsContext.settingsView
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property int intervalSeconds: cfg.intervalSeconds ?? defaults.intervalSeconds ?? 5
  readonly property int thresholdGood: cfg.thresholdGood ?? defaults.thresholdGood ?? 20
  readonly property int thresholdWarning: ThresholdPolicy.effectiveWarning(thresholdGood, cfg.thresholdWarning ?? defaults.thresholdWarning ?? 70)
  readonly property bool showHostName: cfg.showHostName ?? defaults.showHostName ?? true
  readonly property string barHost: cfg.barHost ?? defaults.barHost ?? "worst"
  readonly property string colorGood: cfg.colorGood ?? defaults.colorGood ?? "#00ff7f"
  readonly property string colorWarning: cfg.colorWarning ?? defaults.colorWarning ?? "#f1fa8c"
  readonly property string colorCritical: cfg.colorCritical ?? defaults.colorCritical ?? "#ff5555"
  readonly property bool animations: cfg.animations ?? defaults.animations ?? true

  readonly property var hostsCfg: cfg.hosts ?? defaults.hosts ?? [
    {
      name: "Cloudflare",
      address: "1.1.1.1"
    },
    {
      name: "Google",
      address: "8.8.8.8"
    }
  ]

  property var hosts: []

  readonly property var worstHost: {
    const order = {
      "critical": 3,
      "warning": 2,
      "good": 1,
      "unknown": 0
    };
    let worst = null;
    for (const h of hosts) {
      if (!worst || (order[h.status] ?? 0) > (order[worst.status] ?? 0))
        worst = h;
    }
    return worst;
  }

  readonly property var displayHost: {
    if (barHost === "worst" || !barHost)
      return worstHost;
    return hosts.find(h => h.name === barHost) ?? worstHost;
  }

  readonly property string status: displayHost?.status ?? "unknown"

  Component {
    id: hostComp
    Host {}
  }

  function _retireHosts() {
    for (const h of hosts)
      h.stop();
    for (const h of hosts)
      h.destroy();
    hosts = [];
  }

  function _rebuildHosts() {
    _retireHosts();
    const built = [];
    if (!current) {
      hosts = built;
      return;
    }
    for (const hcfg of hostsCfg) {
      const h = hostComp.createObject(root, {
        name: hcfg.name ?? "Host",
        address: hcfg.address ?? "1.1.1.1",
        intervalMs: intervalSeconds * 1000,
        thresholdGood: thresholdGood,
        thresholdWarning: thresholdWarning
      });
      built.push(h);
    }
    hosts = built;
    Logger.d("LatencyMonitor", "Rebuilt", built.length, "host(s)");
  }

  onThresholdGoodChanged: {
    for (const h of hosts)
      h.thresholdGood = thresholdGood;
  }
  onThresholdWarningChanged: {
    for (const h of hosts)
      h.thresholdWarning = thresholdWarning;
  }

  function _queueHosts() {
    if (!_constructed) return;
    // Fence the old generation at handoff, not at the deferred constructor.
    _retireHosts();
    replacement.restart();
  }
  Timer { id: replacement; interval: 0; onTriggered: root._rebuildHosts() }
  onHostsCfgChanged: _queueHosts()
  onIntervalSecondsChanged: _queueHosts()

  onCurrentChanged: {
    if (!current && _constructed) {
      replacement.stop();
      _retireHosts();
      retire(root);
    }
  }
  Component.onCompleted: { _constructed = true; _rebuildHosts(); }
  Component.onDestruction: {
    replacement.stop();
    _retireHosts();
  }
}
