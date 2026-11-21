import QtQuick
import qs.Services.Plugins

// Selected policy over Main's one unfiltered host observation/action owner.
PluginSettingsPoller {
  id: root
  required property var observation
  readonly property var cfg: settingsContext.settingsView
  readonly property var defaults: observation.defaults
  sourceInterval: (cfg.refreshInterval ?? defaults.refreshInterval ?? 5) * 1000
  requestRefresh: function() { observation.refresh(); }
  readonly property bool hideSystemPorts: cfg.hideSystemPorts ?? defaults.hideSystemPorts ?? false
  readonly property var portList: observation.projectPorts(observation.rawPorts, hideSystemPorts)
  readonly property var sortedPorts: portList
  readonly property int portCount: portList.length
  readonly property string detectedTerminal: observation.detectedTerminal

  function killProcess(pid) {
    if (current) observation.killProcess(pid);
  }
  function killPortElevated(port, proto) {
    if (current) observation.killPortElevated(port, proto);
  }
}
