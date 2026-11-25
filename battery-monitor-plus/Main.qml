import QtQuick

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  property var _observations: new Map()
  Component { id: observationFactory; BatteryObservation {} }
  Component { id: clientFactory; BatterySettingsClient {} }
  function acquireObservation(path, client) {
    if (!_observations.has(path)) {
      var observer = observationFactory.createObject(root, {pluginApi: pluginApi, deviceNativePath: path});
      _observations.set(path, {observer: observer, clients: new Set()});
    }
    var entry = _observations.get(path);
    entry.clients.add(client);
    return entry.observer;
  }
  function releaseObservation(path, client) {
    var entry = _observations.get(path);
    if (!entry) return;
    entry.clients.delete(client);
    if (entry.clients.size === 0) {
      _observations.delete(path);
      entry.observer.destroy();
    }
  }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
      settingsContext: context,
      defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({}),
      acquireObservation: function(path, consumer) { return root.acquireObservation(path, consumer); },
      releaseObservation: function(path, consumer) { root.releaseObservation(path, consumer); },
      retire: function(retired) {
        root._settingsConsumers.delete(context);
        retired.releaseObservationLease();
        retired.destroy();
      }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property var observation: settingsConsumer?.observation
  readonly property bool sysfsOk: observation?.sysfsOk ?? false
  readonly property string sysfsStatus: observation?.sysfsStatus ?? ""
  readonly property real sysfsPowerWatts: observation?.sysfsPowerWatts ?? -1
  readonly property int sysfsTimeToEmpty: observation?.sysfsTimeToEmpty ?? 0
  readonly property int sysfsTimeToFull: observation?.sysfsTimeToFull ?? 0
  readonly property int sysfsCapacity: observation?.sysfsCapacity ?? -1
  readonly property string sysfsSource: observation?.sysfsSource ?? ""
  readonly property string sysfsError: observation?.sysfsError ?? ""
  readonly property int refreshNonce: observation?.refreshNonce ?? 0
  readonly property int refreshIntervalSeconds: settingsConsumer?.refreshIntervalSeconds ?? 5
  readonly property string deviceNativePath: settingsConsumer?.deviceNativePath ?? "__default__"
  readonly property bool isChargingHardware: observation?.isChargingHardware ?? false
  readonly property bool isDischargingHardware: observation?.isDischargingHardware ?? false
  function scanSysfs() { settingsConsumer?.refresh(); }
  function statusText() { return observation?.statusText() ?? ""; }
  function formatPower(compact, unavailable) { return observation?.formatPower(compact, unavailable) ?? ""; }
  function formatRelevantTime(unavailable) { return observation?.formatRelevantTime(unavailable) ?? ""; }
  function formatDurationCompact(seconds) { return observation?.formatDurationCompact(seconds) ?? ""; }
}
