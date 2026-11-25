import QtQuick

Item {
  id: root
  required property var owner
  required property var settingsContext
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property string devicePath: settingsContext.settingsView.batteryDevice ?? "/sys/class/power_supply/BAT0"
  property var observation: null
  readonly property int batPercent: observation?.batPercent ?? 0
  readonly property real wattNum: observation?.wattNum ?? 0
  readonly property string batStatus: owner.pluginApi?.tr(observation?.statusKey ?? "battery.status-unknown") ?? ""
  readonly property string timeRemaining: observation?.timeRemaining ?? "..."
  readonly property int batteryThreshold: observation?.batteryThreshold ?? 80
  readonly property string currentProfile: owner.currentProfile
  property bool _constructed: false
  function replaceSource() {
    const previous = observation;
    observation = current ? owner.acquireBattery(devicePath) : null;
    owner.releaseBattery(previous);
  }
  function refreshAll() { if (current) { observation?.refresh(); owner.updatePowerProfile(); } }
  function updatePowerProfile() { if (current) owner.updatePowerProfile(); }
  function setPowerProfile(profile) { if (current) owner.setPowerProfile(profile, settingsContext); }
  function setBatteryThreshold(value) { if (current) observation?.setBatteryThreshold(value, settingsContext); }
  function getBatteryIcon() {
    if (observation?.statusKey === "battery.status-charging") return "battery-charging";
    if (observation?.statusKey === "battery.status-full") return "battery-charging-2";
    if (batPercent >= 86) return "battery-4";
    if (batPercent >= 56) return "battery-3";
    if (batPercent >= 31) return "battery-2";
    if (batPercent >= 11) return "battery-1";
    return "battery";
  }
  onDevicePathChanged: if (_constructed) replaceSource()
  onCurrentChanged: if (!current && _constructed) { replaceSource(); retire(root); }
  Component.onCompleted: { _constructed = true; replaceSource(); }
  Component.onDestruction: owner.releaseBattery(observation)
}
