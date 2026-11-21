import QtQuick

Item {
  id: root
  required property var pluginApi
  required property var settingsContext
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
  readonly property string city: cfg.city ?? defaults.city ?? "London"
  readonly property string country: cfg.country ?? defaults.country ?? "UK"
  readonly property int method: cfg.method ?? defaults.method ?? 3
  readonly property string _queryIdentity: JSON.stringify([city, country, method])
  property bool _constructed: false
  property var _worker: null
  readonly property var prayerTimings: _worker?.prayerTimings ?? null
  readonly property string hijriDateStr: _worker?.hijriDateStr ?? ""
  readonly property string gregorianDateStr: _worker?.gregorianDateStr ?? ""
  readonly property int hijriMonth: _worker?.hijriMonth ?? 0
  readonly property int hijriYear: _worker?.hijriYear ?? 0
  readonly property string hijriMonthName: _worker?.hijriMonthName ?? ""
  readonly property bool isRamadan: _worker?.isRamadan ?? false
  readonly property bool isLoading: _worker?.isLoading ?? false
  readonly property bool hasError: _worker?.hasError ?? false
  readonly property string errorMessage: _worker?.errorMessage ?? ""
  readonly property string lastFetchDate: _worker?.lastFetchDate ?? ""
  readonly property int secondsToIftar: _worker?.secondsToIftar ?? -1
  readonly property bool iftarPassed: _worker?.iftarPassed ?? false
  Component { id: workerFactory; PrayerQueryWorker {} }
  function _retireWorker() {
    if (!_worker) return;
    var old = _worker;
    _worker = null;
    old.stop();
    old.destroy();
  }
  function _replaceQuery() {
    if (!_constructed) return;
    _retireWorker();
    if (!current) return;
    _worker = workerFactory.createObject(root, {pluginApi: pluginApi, city: city, country: country, method: method});
  }
  function fetchPrayerTimes() { _worker?.fetchPrayerTimes(); }
  function updateCountdown() { _worker?.updateCountdown(); }
  // Fence immediately, then capture the settled typed inputs together. A native
  // multi-field publication must not launch mixed old/new derived properties.
  function _queueQuery() {
    if (!_constructed) return;
    _retireWorker();
    replacement.restart();
  }
  Timer { id: replacement; interval: 0; onTriggered: root._replaceQuery() }
  on_QueryIdentityChanged: _queueQuery()
  onCurrentChanged: {
    if (!current && _constructed) {
      replacement.stop();
      _retireWorker();
      retire(root);
    }
  }
  Component.onCompleted: { _constructed = true; _replaceQuery(); }
  Component.onDestruction: { replacement.stop(); _retireWorker(); }
}
