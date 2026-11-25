import QtQuick

// An observation is shared by configured device, not by a rendering or draft.
Item {
  id: root
  required property var settingsContext
  required property var acquireObservation
  required property var releaseObservation
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView
  readonly property int deviceIndex: typeof cfg.deviceIndex === "number" ? Math.floor(cfg.deviceIndex) : 0
  property var observation: null
  property int _capturedIndex: 0
  property var _pollers: new Set()
  readonly property string _consumerId: "selected-gpu:" + Math.random()
  property bool _constructed: false

  function release() {
    if (!observation) return;
    var old = observation;
    observation = null;
    old.unregisterPoller(_consumerId);
    releaseObservation(_capturedIndex, root);
  }
  function selectObservation() {
    if (!_constructed) return;
    release();
    if (!current) return;
    _capturedIndex = deviceIndex;
    observation = acquireObservation(_capturedIndex, root);
    if (_pollers.size > 0) observation.registerPoller(_consumerId);
  }
  function registerPoller(token) {
    if (!current) return;
    _pollers.add(token);
    observation?.registerPoller(_consumerId);
  }
  function unregisterPoller(token) {
    _pollers.delete(token);
    if (_pollers.size === 0) observation?.unregisterPoller(_consumerId);
  }
  function refreshNow() { if (current) observation?.refreshNow(); }
  onDeviceIndexChanged: selectObservation()
  onCurrentChanged: {
    if (!current && _constructed) {
      release();
      retire(root);
    }
  }
  Component.onCompleted: { _constructed = true; selectObservation(); }
  Component.onDestruction: release()
}
