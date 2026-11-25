import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

GpuReadings {
  id: root

  required property int deviceIndex

  function refreshNow() {
    if (!rocmProcess.running)
      rocmProcess.running = true;
  }

  function registerPoller(consumerId) {
    if (!_consumers[consumerId]) {
      _consumers[consumerId] = true;
      _consumers = Object.assign({}, _consumers);
    }
  }

  function unregisterPoller(consumerId) {
    delete _consumers[consumerId];
    _consumers = Object.assign({}, _consumers);
  }

  property var _consumers: ({})

  readonly property bool shouldPoll: Object.keys(_consumers).length > 0

  function intOrDefault(value, fallback) {
    return (typeof value === "number") ? Math.floor(value) : fallback;
  }

  function parseNumber(value) {
    if (value === undefined || value === null)
      return 0;
    const n = parseFloat(String(value).replace(/[^0-9.-]/g, ""));
    return isNaN(n) ? 0 : n;
  }

  function parseMhz(value) {
    if (!value)
      return 0;
    const m = String(value).match(/(\d+(?:\.\d+)?)\s*Mhz/i);
    return m ? parseFloat(m[1]) : 0;
  }

  function readMhz(card, key, current) {
    if (!card || card[key] === undefined || card[key] === null)
      return current;
    const text = String(card[key]).trim();
    if (text === "" || text === "N/A")
      return current;
    const mhz = parseMhz(text);
    if (mhz <= 0 && !/Mhz/i.test(text))
      return current;
    return mhz;
  }

  function bytesToGb(bytes) {
    return bytes / (1024 * 1024 * 1024);
  }

  function pushHistory(array, value, length) {
    const h = array.slice();
    h.push(value);
    while (h.length > length)
      h.shift();
    return h;
  }

  function updateHistories() {
    gpuUseHistory = pushHistory(gpuUseHistory, gpuUse, historyLength);
    tempEdgeHistory = pushHistory(tempEdgeHistory, tempEdge, historyLength);
    tempJunctionHistory = pushHistory(tempJunctionHistory, tempJunction, historyLength);
    tempMemoryHistory = pushHistory(tempMemoryHistory, tempMemory, historyLength);
    fanSpeedHistory = pushHistory(fanSpeedHistory, fanSpeed, historyLength);
    vramHistory = pushHistory(vramHistory, vramPercent, historyLength);
    powerHistory = pushHistory(powerHistory, powerWatts, historyLength);
    vramActivityHistory = pushHistory(vramActivityHistory, vramActivity, historyLength);
    sclkHistory = pushHistory(sclkHistory, sclkMhz, historyLength);
    mclkHistory = pushHistory(mclkHistory, mclkMhz, historyLength);
    fclkHistory = pushHistory(fclkHistory, fclkMhz, historyLength);
    socclkHistory = pushHistory(socclkHistory, socclkMhz, historyLength);
    dcefclkHistory = pushHistory(dcefclkHistory, dcefclkMhz, historyLength);
  }

  function applyCardData(card) {
    if (!card)
      return;

    tempEdge = parseNumber(card["Temperature (Sensor edge) (C)"]);
    tempJunction = parseNumber(card["Temperature (Sensor junction) (C)"]);
    tempMemory = parseNumber(card["Temperature (Sensor memory) (C)"]);
    fanSpeed = parseNumber(card["Fan speed (%)"]);
    gpuUse = parseNumber(card["GPU use (%)"]);
    vramPercent = parseNumber(card["GPU Memory Allocated (VRAM%)"]);
    vramActivity = parseNumber(card["GPU Memory Read/Write Activity (%)"]);
    powerWatts = parseNumber(card["Average Graphics Package Power (W)"]);

    const vramTotalB = parseNumber(card["VRAM Total Memory (B)"]);
    const vramUsedB = parseNumber(card["VRAM Total Used Memory (B)"]);
    if (vramTotalB > 0) {
      vramTotalGb = bytesToGb(vramTotalB);
      vramUsedGb = bytesToGb(vramUsedB);
      if (!vramPercent)
        vramPercent = (vramUsedB / vramTotalB) * 100;
    }

    sclkMhz = readMhz(card, "sclk clock speed:", sclkMhz);
    mclkMhz = readMhz(card, "mclk clock speed:", mclkMhz);
    fclkMhz = readMhz(card, "fclk clock speed:", fclkMhz);
    socclkMhz = readMhz(card, "socclk clock speed:", socclkMhz);
    dcefclkMhz = readMhz(card, "dcefclk clock speed:", dcefclkMhz);

    const series = card["Card Series"];
    if (series)
      productName = series;

    available = true;
    lastError = "";
    updateHistories();
  }

  function parseRocmOutput(data) {
    const text = String(data || "").trim();
    if (!text) {
      lastError = "empty output";
      available = false;
      return;
    }

    try {
      const parsed = JSON.parse(text);
      const keys = Object.keys(parsed);
      if (keys.length === 0) {
        lastError = "no GPU data";
        available = false;
        return;
      }
      cardKey = keys[0];
      applyCardData(parsed[cardKey]);
    } catch (e) {
      lastError = String(e);
      available = false;
      Logger.e("AmdGpuMonitor", "Failed to parse rocm-smi JSON:", e, text.substring(0, 200));
    }
  }

  readonly property var rocmCommand: [
    "rocm-smi",
    "--json",
    "-d",
    String(deviceIndex),
    "--showuse",
    "--showtemp",
    "--showfan",
    "--showmemuse",
    "--showpower",
    "--showclocks",
    "--showmeminfo",
    "vram",
    "--showproductname"
  ]

  Process {
    id: rocmProcess
    running: false
    command: root.rocmCommand

    stdout: StdioCollector {
      onStreamFinished: root.parseRocmOutput(text)
    }

    onExited: function (exitCode) {
      rocmProcess.running = false;
      if (exitCode !== 0 && !root.available)
        root.lastError = "rocm-smi exited with code " + exitCode;
    }
  }

  Timer {
    id: pollTimer
    interval: root.pollIntervalMs
    repeat: true
    running: root.shouldPoll
    triggeredOnStart: true
    onTriggered: root.refreshNow()
  }

}
