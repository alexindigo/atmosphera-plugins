import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  property var _observations: new Map()
  Component { id: observationFactory; GpuObservation {} }
  Component { id: clientFactory; GpuSettingsClient {} }

  function acquireObservation(index, client) {
    if (!_observations.has(index)) {
      var observer = observationFactory.createObject(root, {deviceIndex: index});
      _observations.set(index, {observer: observer, clients: new Set()});
    }
    var entry = _observations.get(index);
    entry.clients.add(client);
    return entry.observer;
  }
  function releaseObservation(index, client) {
    var entry = _observations.get(index);
    if (!entry) return;
    entry.clients.delete(client);
    if (entry.clients.size === 0) {
      _observations.delete(index);
      entry.observer.destroy();
    }
  }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
      settingsContext: context,
      acquireObservation: function(index, consumer) { return root.acquireObservation(index, consumer); },
      releaseObservation: function(index, consumer) { root.releaseObservation(index, consumer); },
      retire: function(retired) {
        root._settingsConsumers.delete(context);
        retired.destroy();
      }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property var observation: settingsConsumer?.observation
  readonly property int deviceIndex: settingsConsumer?.deviceIndex ?? 0
  readonly property int pollIntervalMs: observation?.pollIntervalMs ?? 1000
  readonly property int historyLength: observation?.historyLength ?? 300
  readonly property bool available: observation?.available ?? false
  readonly property string lastError: observation?.lastError ?? ""
  readonly property string productName: observation?.productName ?? ""
  readonly property string cardKey: observation?.cardKey ?? "card0"
  readonly property real tempEdge: observation?.tempEdge ?? 0
  readonly property real tempJunction: observation?.tempJunction ?? 0
  readonly property real tempMemory: observation?.tempMemory ?? 0
  readonly property real fanSpeed: observation?.fanSpeed ?? 0
  readonly property real gpuUse: observation?.gpuUse ?? 0
  readonly property real vramPercent: observation?.vramPercent ?? 0
  readonly property real vramActivity: observation?.vramActivity ?? 0
  readonly property real vramUsedGb: observation?.vramUsedGb ?? 0
  readonly property real vramTotalGb: observation?.vramTotalGb ?? 0
  readonly property real powerWatts: observation?.powerWatts ?? 0
  readonly property real sclkMhz: observation?.sclkMhz ?? 0
  readonly property real mclkMhz: observation?.mclkMhz ?? 0
  readonly property real fclkMhz: observation?.fclkMhz ?? 0
  readonly property real socclkMhz: observation?.socclkMhz ?? 0
  readonly property real dcefclkMhz: observation?.dcefclkMhz ?? 0
  readonly property var gpuUseHistory: observation?.gpuUseHistory ?? []
  readonly property var tempEdgeHistory: observation?.tempEdgeHistory ?? []
  readonly property var tempJunctionHistory: observation?.tempJunctionHistory ?? []
  readonly property var tempMemoryHistory: observation?.tempMemoryHistory ?? []
  readonly property var fanSpeedHistory: observation?.fanSpeedHistory ?? []
  readonly property var vramHistory: observation?.vramHistory ?? []
  readonly property var powerHistory: observation?.powerHistory ?? []
  readonly property var vramActivityHistory: observation?.vramActivityHistory ?? []
  readonly property var sclkHistory: observation?.sclkHistory ?? []
  readonly property var mclkHistory: observation?.mclkHistory ?? []
  readonly property var fclkHistory: observation?.fclkHistory ?? []
  readonly property var socclkHistory: observation?.socclkHistory ?? []
  readonly property var dcefclkHistory: observation?.dcefclkHistory ?? []
  readonly property int gpuWarningThreshold: observation?.gpuWarningThreshold ?? 0
  readonly property int gpuCriticalThreshold: observation?.gpuCriticalThreshold ?? 0
  readonly property bool gpuWarning: observation?.gpuWarning ?? false
  readonly property bool gpuCritical: observation?.gpuCritical ?? false
  readonly property real powerGraphMax: observation?.powerGraphMax ?? 50
  function refreshNow() { settingsConsumer?.refreshNow(); }
  function registerPoller(token) { settingsConsumer?.registerPoller(token); }
  function unregisterPoller(token) { settingsConsumer?.unregisterPoller(token); }
  function historyMax(values, floor) { return observation?.historyMax(values, floor) ?? (floor || 1); }
  IpcHandler {
    target: "plugin:amd-gpu-monitor"
    function togglePanel() {
      root.pluginApi?.withCurrentScreen(screen => root.pluginApi.togglePanel(screen));
    }
    function refresh() { root.refreshNow(); }
  }
}
