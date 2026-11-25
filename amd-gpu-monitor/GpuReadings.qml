import QtQuick
import qs.Commons

// A typed presentation only. It owns no query, timer or device registration.
Item {
  readonly property int pollIntervalMs: 1000
  readonly property int historyLength: 300
  property bool available: false
  property string lastError: ""
  property string productName: ""
  property string cardKey: "card0"
  property real tempEdge: 0
  property real tempJunction: 0
  property real tempMemory: 0
  property real fanSpeed: 0
  property real gpuUse: 0
  property real vramPercent: 0
  property real vramActivity: 0
  property real vramUsedGb: 0
  property real vramTotalGb: 0
  property real powerWatts: 0
  property real sclkMhz: 0
  property real mclkMhz: 0
  property real fclkMhz: 0
  property real socclkMhz: 0
  property real dcefclkMhz: 0
  property var gpuUseHistory: new Array(historyLength).fill(0)
  property var tempEdgeHistory: new Array(historyLength).fill(40)
  property var tempJunctionHistory: new Array(historyLength).fill(40)
  property var tempMemoryHistory: new Array(historyLength).fill(40)
  property var fanSpeedHistory: new Array(historyLength).fill(0)
  property var vramHistory: new Array(historyLength).fill(0)
  property var powerHistory: new Array(historyLength).fill(0)
  property var vramActivityHistory: new Array(historyLength).fill(0)
  property var sclkHistory: new Array(historyLength).fill(0)
  property var mclkHistory: new Array(historyLength).fill(0)
  property var fclkHistory: new Array(historyLength).fill(0)
  property var socclkHistory: new Array(historyLength).fill(0)
  property var dcefclkHistory: new Array(historyLength).fill(0)
  readonly property int gpuWarningThreshold: Settings.data.systemMonitor.gpuWarningThreshold
  readonly property int gpuCriticalThreshold: Settings.data.systemMonitor.gpuCriticalThreshold
  readonly property bool gpuWarning: available && tempJunction >= gpuWarningThreshold
  readonly property bool gpuCritical: available && tempJunction >= gpuCriticalThreshold
  readonly property real powerGraphMax: {
    let max = 0;
    for (let i = 0; i < powerHistory.length; i++) max = Math.max(max, powerHistory[i]);
    return Math.max(50, max * 1.2);
  }
  function historyMax(values, floorValue) {
    let max = floorValue || 0;
    for (let i = 0; i < values.length; i++) max = Math.max(max, values[i]);
    return Math.max(floorValue || 1, max * 1.1);
  }
}
