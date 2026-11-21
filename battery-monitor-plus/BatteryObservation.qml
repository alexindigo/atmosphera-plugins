import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons
import qs.Services.Hardware

Item {
  id: root

  required property var pluginApi
  required property string deviceNativePath

  // Hardware fallbacks belong to the same immutable source as the helper.
  readonly property var selectedDevice: {
    const device = BatteryService.findDevice(deviceNativePath);
    return BatteryService.isDevicePresent(device) ? device : null;
  }
  readonly property bool aggregateSelection: !deviceNativePath || deviceNativePath === "__default__" || deviceNativePath === "DisplayDevice"
  readonly property var healthDevice: selectedDevice?.healthSupported ? selectedDevice : (aggregateSelection ? (BatteryService.laptopBatteries[0] || null) : null)

  property bool sysfsOk: false
  property string sysfsStatus: ""
  property real sysfsPowerWatts: -1
  property int sysfsTimeToEmpty: 0
  property int sysfsTimeToFull: 0
  property int sysfsCapacity: -1
  property string sysfsSource: ""
  property string sysfsError: ""
  property int refreshNonce: 0

  readonly property bool isChargingHardware: sysfsStatus === "Charging"
  readonly property bool isDischargingHardware: sysfsStatus === "Discharging"

  Component.onCompleted: scanSysfs()

  Process {
    id: sysfsScanProcess
    running: false
    stdout: StdioCollector {
      id: sysfsStdout
    }
    stderr: StdioCollector {
      id: sysfsStderr
    }

    onExited: function (exitCode, exitStatus) {
      root.applySysfsSnapshot(sysfsStdout.text || "", sysfsStderr.text || "");
    }
  }

  function scanSysfs() {
    if (!pluginApi || !pluginApi.pluginDir || sysfsScanProcess.running) {
      return;
    }

    sysfsScanProcess.command = ["sh", `${pluginApi.pluginDir}/scripts/read_battery_sysfs.sh`, root.deviceNativePath];
    sysfsScanProcess.running = true;
  }

  function applySysfsSnapshot(stdoutText, stderrText) {
    let parsed = null;
    try {
      parsed = JSON.parse((stdoutText || "").trim());
    } catch (e) {
      root.sysfsOk = false;
      root.sysfsError = stderrText || String(e);
      root.refreshNonce++;
      Logger.w("BatteryMonitorPlus", "Failed to parse sysfs battery data:", root.sysfsError);
      return;
    }

    root.sysfsOk = parsed.ok === true;
    root.sysfsStatus = parsed.status || "";
    root.sysfsPowerWatts = numberOr(parsed.powerWatts, -1);
    root.sysfsTimeToEmpty = Math.round(numberOr(parsed.timeToEmpty, 0));
    root.sysfsTimeToFull = Math.round(numberOr(parsed.timeToFull, 0));
    root.sysfsCapacity = Math.round(numberOr(parsed.capacity, -1));
    root.sysfsSource = parsed.source || "";
    root.sysfsError = parsed.error || "";
    root.refreshNonce++;
  }

  function numberOr(value, fallback) {
    const parsed = Number(value);
    return isNaN(parsed) ? fallback : parsed;
  }

  function statusText() {
    if (!sysfsOk) {
      if (!BatteryService.isDeviceReady(selectedDevice)) return pluginApi?.tr("status.noBattery");
      if (BatteryService.isCharging(selectedDevice)) return pluginApi?.tr("status.charging");
      if (selectedDevice.state === UPowerDeviceState.FullyCharged) return pluginApi?.tr("status.fullyCharged");
      return pluginApi?.tr(BatteryService.isPluggedIn(selectedDevice) ? "status.pluggedIn" : "status.discharging");
    }

    if (sysfsStatus === "Charging") {
      return pluginApi?.tr("status.charging");
    }
    if (sysfsStatus === "Discharging") {
      return pluginApi?.tr("status.discharging");
    }
    if (sysfsStatus === "Full") {
      return pluginApi?.tr("status.fullyCharged");
    }
    if (sysfsStatus === "Not charging" || sysfsStatus === "Unknown") {
      return pluginApi?.tr("status.pluggedIn");
    }

    return sysfsStatus || pluginApi?.tr("status.noBattery");
  }

  function formatPower(compact, showUnavailable) {
    const watts = sysfsOk ? sysfsPowerWatts : fallbackPowerWatts();
    if (watts <= 0) {
      return showUnavailable ? pluginApi?.tr("common.unavailable") : "";
    }

    return `${watts.toFixed(1)}${compact ? "W" : " W"}`;
  }

  function formatRelevantTime(showUnavailable) {
    const seconds = sysfsOk ? (sysfsStatus === "Charging" ? sysfsTimeToFull : sysfsTimeToEmpty) : fallbackRemainingSeconds();
    const text = formatDurationCompact(seconds);
    return text || (showUnavailable ? pluginApi?.tr("common.unavailable") : "");
  }

  function readDeviceRate(device) {
    if (!device || device.changeRate === undefined || device.changeRate === null) return -1;
    const rate = Math.abs(Number(device.changeRate));
    return isNaN(rate) ? -1 : rate;
  }

  function fallbackPowerWatts() {
    const direct = readDeviceRate(selectedDevice);
    if (direct > 0 || !aggregateSelection) return direct;
    let total = 0;
    let found = false;
    for (const device of BatteryService.laptopBatteries || []) {
      if (!device || device.nativePath?.includes("DisplayDevice")) continue;
      const rate = readDeviceRate(device);
      if (rate > 0) { total += rate; found = true; }
    }
    return found ? total : direct;
  }

  function readRemainingSeconds(device) {
    if (!BatteryService.isDeviceReady(device)) return 0;
    if (BatteryService.isCharging(device) && device.timeToFull > 0) return device.timeToFull;
    if (!BatteryService.isCharging(device) && !BatteryService.isPluggedIn(device) && device.timeToEmpty > 0) return device.timeToEmpty;
    if (device.timeToFull > 0) return device.timeToFull;
    return device.timeToEmpty > 0 ? device.timeToEmpty : 0;
  }

  function fallbackRemainingSeconds() {
    if (!BatteryService.isDeviceReady(selectedDevice)) return 0;
    const direct = readRemainingSeconds(selectedDevice);
    if (direct > 0 || !aggregateSelection) return direct;
    for (const device of BatteryService.laptopBatteries || []) {
      if (!device || device.nativePath?.includes("DisplayDevice")) continue;
      const seconds = readRemainingSeconds(device);
      if (seconds > 0) return seconds;
    }
    return 0;
  }

  function healthText() {
    return healthDevice?.healthSupported ? `${Math.round(healthDevice.healthPercentage)}%` : pluginApi?.tr("common.unavailable");
  }

  function formatDurationCompact(seconds) {
    if (seconds <= 0) {
      return "";
    }

    const totalMinutes = Math.max(1, Math.round(seconds / 60));
    const hours = Math.floor(totalMinutes / 60);
    const minutes = totalMinutes % 60;

    if (hours > 0) {
      return minutes > 0 ? `${hours}h${minutes}m` : `${hours}h`;
    }

    return `${minutes}m`;
  }
}
