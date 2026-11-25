import QtQuick
import qs.Services.Plugins

PluginSettingsPoller {
  id: root
  required property var defaults
  required property var acquireObservation
  required property var releaseObservation
  readonly property var cfg: settingsContext.settingsView
  readonly property int refreshIntervalSeconds: Math.max(1, cfg.refreshIntervalSeconds ?? defaults.refreshIntervalSeconds ?? 5)
  readonly property string deviceNativePath: cfg.deviceNativePath ?? defaults.deviceNativePath ?? "__default__"
  sourceInterval: refreshIntervalSeconds
  intervalScale: 1000
  requestRefresh: function() { observation?.scanSysfs(); }
  property var observation: null
  property string _capturedPath: ""
  property bool _ready: false
  function releaseObservationLease() {
    if (!observation) return;
    observation = null;
    releaseObservation(_capturedPath, root);
  }
  function selectObservation() {
    if (!_ready) return;
    releaseObservationLease();
    if (!current) return;
    _capturedPath = deviceNativePath;
    observation = acquireObservation(_capturedPath, root);
  }
  onDeviceNativePathChanged: selectObservation()
  Component.onCompleted: { _ready = true; selectObservation(); }
  Component.onDestruction: releaseObservationLease()
}
