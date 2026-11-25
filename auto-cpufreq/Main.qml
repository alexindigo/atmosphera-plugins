import QtQuick
import Quickshell.Io

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  property string governor: "\u2014"
  property string turboState: "\u2014"
  property bool daemonRunning: false
  property string forceOverride: "default"
  property string turboOverride: "auto"
  property bool pkexecFailed: false
  property int batCapacity: -1
  property string batStatus: ""
  property real batWatts: 0
  property string batDevice: ""

  Component {
    id: clientFactory
    Item {
      id: client
      required property var settingsContext
      required property var retire
      readonly property bool current: settingsContext.current()
      readonly property int sourceInterval: settingsContext.settingsView.refreshInterval ?? root.pluginApi?.manifest?.metadata?.defaultSettings?.refreshInterval ?? 3000
      readonly property int interval: sourceInterval
      readonly property string governor: root.governor
      readonly property string turboState: root.turboState
      readonly property bool daemonRunning: root.daemonRunning
      readonly property string forceOverride: root.forceOverride
      readonly property string turboOverride: root.turboOverride
      readonly property bool pkexecFailed: root.pkexecFailed
      readonly property int batCapacity: root.batCapacity
      readonly property string batStatus: root.batStatus
      readonly property real batWatts: root.batWatts
      function refreshAll() { if (current) root.refreshAll(settingsContext); }
      function setForce(mode) { if (current) root.setForce(mode, settingsContext); }
      function setTurbo(mode) { if (current) root.setTurbo(mode, settingsContext); }
      Timer {
        interval: client.interval
        running: client.current
        repeat: true
        triggeredOnStart: true
        onTriggered: client.refreshAll()
      }
      property bool _constructed: false
      onCurrentChanged: if (!current && _constructed) retire(client)
      Component.onCompleted: _constructed = true
    }
  }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    const client = clientFactory.createObject(root, {
      settingsContext: context,
      retire: function(retired) {
        root._settingsConsumers.delete(context);
        retired.destroy();
      }
    });
    _settingsConsumers.set(context, client);
    return client;
  }

  FileView {
    id: governorFile
    path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
    printErrors: false
    onLoaded: root.governor = text().trim() || "\u2014"
  }
  FileView {
    id: noTurboFile
    path: "/sys/devices/system/cpu/intel_pstate/no_turbo"
    printErrors: false
    onLoaded: {
      const value = text().trim();
      if (value !== "") root.turboState = value === "0" ? "on" : "off";
    }
  }
  FileView {
    id: boostFile
    path: "/sys/devices/system/cpu/cpufreq/boost"
    printErrors: false
    onLoaded: {
      if (noTurboFile.text().trim() !== "") return;
      const value = text().trim();
      if (value !== "") root.turboState = value === "1" ? "on" : "off";
    }
  }
  Process {
    id: batFinder
    command: ["sh", "-c", "for d in /sys/class/power_supply/*/type; do [ \"$(cat $d 2>/dev/null)\" = 'Battery' ] && basename $(dirname $d) && exit 0; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        const device = text.trim();
        if (device !== "") { root.batDevice = device; batUevent.reload(); }
      }
    }
  }
  FileView {
    id: batUevent
    path: root.batDevice !== "" ? "/sys/class/power_supply/" + root.batDevice + "/uevent" : "/dev/null"
    printErrors: false
    onLoaded: {
      let capacity = -1, status = "", currentUa = 0, voltageUv = 0;
      for (const line of text().split("\n")) {
        if (line.startsWith("POWER_SUPPLY_CAPACITY=")) capacity = parseInt(line.split("=")[1]) || -1;
        else if (line.startsWith("POWER_SUPPLY_STATUS=")) status = line.split("=")[1]?.trim() ?? "";
        else if (line.startsWith("POWER_SUPPLY_CURRENT_NOW=")) currentUa = parseInt(line.split("=")[1]) || 0;
        else if (line.startsWith("POWER_SUPPLY_VOLTAGE_NOW=")) voltageUv = parseInt(line.split("=")[1]) || 0;
      }
      root.batCapacity = capacity;
      root.batStatus = status;
      root.batWatts = voltageUv > 0 && currentUa > 0 ? Math.round(voltageUv / 1e6 * currentUa / 1e6 * 10) / 10 : 0;
    }
  }
  Process {
    id: overrideReader
    command: ["sh", "-c", "for f in /run/override.pickle /opt/auto-cpufreq/override.pickle; do [ -f \"$f\" ] && strings \"$f\" | grep -oE '(powersave|performance)' | head -1 && exit 0; done; echo 'default'"]
    stdout: StdioCollector {
      onStreamFinished: { const value = text.trim(); root.forceOverride = value === "powersave" || value === "performance" ? value : "default"; }
    }
  }
  Process {
    id: turboOverrideReader
    command: ["sh", "-c", "for f in /run/turbo-override.pickle /opt/auto-cpufreq/turbo-override.pickle; do [ -f \"$f\" ] && strings \"$f\" | grep -oE '(never|always)' | head -1 && exit 0; done; echo 'auto'"]
    stdout: StdioCollector {
      onStreamFinished: { const value = text.trim(); root.turboOverride = value === "never" || value === "always" ? value : "auto"; }
    }
  }
  Process {
    id: daemonChecker
    command: ["systemctl", "is-active", "--quiet", "auto-cpufreq"]
    onExited: code => root.daemonRunning = code === 0
  }
  property var forceContext: null
  property var turboContext: null
  readonly property bool forceCurrent: !!forceContext && forceContext.current()
  readonly property bool turboCurrent: !!turboContext && turboContext.current()
  onForceCurrentChanged: if (!forceCurrent) forceProc.running = false
  onTurboCurrentChanged: if (!turboCurrent) turboProc.running = false
  Process {
    id: forceProc
    onExited: code => {
      if (!root.forceCurrent) return;
      if (code === 0) { root.pkexecFailed = false; root.refreshAll(root.forceContext); }
      else if (code === 126 || code === 127) root.pkexecFailed = true;
    }
  }
  Process {
    id: turboProc
    onExited: code => {
      if (!root.turboCurrent) return;
      if (code === 0) { root.pkexecFailed = false; root.refreshAll(root.turboContext); }
      else if (code === 126 || code === 127) root.pkexecFailed = true;
    }
  }
  function setForce(mode, context) {
    context = context || pluginApi?.settingsContext;
    if (!context || !context.current()) return;
    forceProc.running = false;
    forceContext = context;
    forceProc.command = ["pkexec", "auto-cpufreq", "--force=" + mode];
    forceProc.running = true;
  }
  function setTurbo(mode, context) {
    context = context || pluginApi?.settingsContext;
    if (!context || !context.current()) return;
    turboProc.running = false;
    turboContext = context;
    turboProc.command = ["pkexec", "auto-cpufreq", "--turbo=" + mode];
    turboProc.running = true;
  }
  function refreshAll(context) {
    context = context || pluginApi?.settingsContext;
    if (!context || !context.current()) return;
    governorFile.reload(); noTurboFile.reload(); boostFile.reload();
    if (!daemonChecker.running) daemonChecker.running = true;
    if (!overrideReader.running) overrideReader.running = true;
    if (!turboOverrideReader.running) turboOverrideReader.running = true;
    if (batDevice === "") { if (!batFinder.running) batFinder.running = true; }
    else batUevent.reload();
  }
}
