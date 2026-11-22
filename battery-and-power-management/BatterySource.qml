import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root
  required property string devicePath
  property int subscribers: 0
  property bool active: true
  property int batPercent: 0
  property real wattNum: 0
  property string statusKey: "battery.status-unknown"
  property string timeRemaining: "..."
  property int batteryThreshold: 80
  property var actionContext: null
  readonly property bool actionCurrent: active && !!actionContext && actionContext.current()
  onActionCurrentChanged: if (!actionCurrent) thresholdSetter.running = false
  onActiveChanged: if (!active) { etaGetter.running = false; thresholdSetter.running = false; }
  function formatUpowerTime(value) {
    const parts = value.split(/\s+/), number = parseFloat(parts[0]), unit = parts.length > 1 ? parts[1] : "";
    if (isNaN(number)) return "...";
    let minutes;
    if (unit.indexOf("hour") === 0) minutes = number * 60;
    else if (unit.indexOf("minute") === 0) minutes = number;
    else if (unit.indexOf("second") === 0) minutes = number / 60;
    else if (unit.indexOf("day") === 0) minutes = number * 1440;
    else return value;
    const total = Math.round(minutes), hours = Math.floor(total / 60), rest = total % 60;
    return hours > 0 ? hours + "h " + rest + "m" : rest + "m";
  }
  function parseEta(out) {
    for (const source of out.split("\n")) {
      const line = source.trim();
      if (line.indexOf("time to empty:") === 0 || line.indexOf("time to full:") === 0)
        return formatUpowerTime(line.substring(line.indexOf(":") + 1).trim());
    }
    return "...";
  }
  function setBatteryThreshold(value, context) {
    if (!active || !context || !context.current()) return;
    thresholdSetter.running = false;
    actionContext = context;
    batteryThreshold = value;
    thresholdSetter.command = ["sh", "-c", "echo " + value + " > " + devicePath + "/charge_control_end_threshold"];
    thresholdSetter.running = true;
  }
  Process {
    id: thresholdSetter
    onExited: code => { if (root.actionCurrent && code !== 0) Logger.e("BatteryAndPowerManagement", "Error writing battery threshold."); }
  }
  Process {
    id: etaGetter
    command: ["upower", "-i", "/org/freedesktop/UPower/devices/battery_" + (root.devicePath.split("/").pop() || "BAT0")]
    stdout: StdioCollector { onStreamFinished: if (root.active) root.timeRemaining = root.parseEta(text) }
    onExited: code => { if (root.active && code !== 0) root.timeRemaining = "..."; }
  }
  function refresh() {
    if (!active) return;
    batLoader.reload(); thresholdLoader.reload();
    if (!etaGetter.running) etaGetter.running = true;
  }
  Timer { interval: 2000; running: root.active && root.subscribers > 0; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
  FileView {
    id: thresholdLoader
    path: root.devicePath + "/charge_control_end_threshold"
    printErrors: false
    onLoaded: {
      if (!root.active) return;
      const parsed = parseInt(text().trim());
      if (!isNaN(parsed) && parsed >= 50 && parsed <= 100) root.batteryThreshold = parsed;
    }
  }
  FileView {
    id: batLoader
    // Preserve the original basename-selected sysfs observation semantics.
    path: "/sys/class/power_supply/" + (root.devicePath.split("/").pop() || "BAT0") + "/uevent"
    printErrors: false
    onLoaded: {
      if (!root.active || !text()) return;
      let capacity = 0, rate = 0, status = "Unknown";
      for (const source of text().split("\n")) {
        const line = source.trim();
        if (line.indexOf("POWER_SUPPLY_CAPACITY=") === 0) capacity = parseInt(line.split("=")[1]) || 0;
        else if (line.indexOf("POWER_SUPPLY_POWER_NOW=") === 0) rate = parseInt(line.split("=")[1]) || 0;
        else if (line.indexOf("POWER_SUPPLY_STATUS=") === 0) status = line.split("=")[1] || "Unknown";
      }
      root.batPercent = capacity;
      root.wattNum = rate / 1000000;
      root.statusKey = status === "Charging" ? "battery.status-charging" : status === "Full" ? "battery.status-full" : status === "Discharging" ? "battery.status-discharging" : status === "Not charging" ? "battery.status-not-charging" : "battery.status-unknown";
    }
  }
}
