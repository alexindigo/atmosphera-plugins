import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property string levelAuto: "auto"
  readonly property string levelOff: "0"
  readonly property string levelUnknown: "unknown"
  property int fanRpm: 0
  property string fanLevel: levelAuto
  property int currentTemp: 0
  property bool isInitialized: false

  Component {
    id: clientFactory
    Item {
      id: client
      required property var settingsContext
      required property var retire
      readonly property bool current: settingsContext.current()
      readonly property var cfg: settingsContext.settingsView
      readonly property var defaults: root.pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
      readonly property bool colorizeByStatus: cfg.colorizeByStatus ?? defaults.colorizeByStatus ?? true
      readonly property bool allowPopupOpening: cfg.allowPopupOpening ?? defaults.allowPopupOpening ?? true
      readonly property var rawColorLevel0: cfg.colorLevel0 ?? defaults.colorLevel0 ?? AtmoColor.mError
      readonly property var rawColorActive: cfg.colorActive ?? defaults.colorActive ?? AtmoColor.mPrimary
      readonly property var rawColorAuto: cfg.colorAuto ?? defaults.colorAuto ?? ""
      readonly property bool level0IsNeutral: String(rawColorLevel0).length === 0
      readonly property bool activeIsNeutral: String(rawColorActive).length === 0
      readonly property bool autoIsNeutral: String(rawColorAuto).length === 0
      readonly property string colorLevel0: level0IsNeutral ? Style.capsuleColor : rawColorLevel0
      readonly property string colorActive: activeIsNeutral ? Style.capsuleColor : rawColorActive
      readonly property string colorAuto: autoIsNeutral ? Style.capsuleColor : rawColorAuto
      readonly property string levelAuto: root.levelAuto
      readonly property string levelOff: root.levelOff
      readonly property int fanRpm: root.fanRpm
      readonly property string fanLevel: root.fanLevel
      readonly property int currentTemp: root.currentTemp
      readonly property bool isInitialized: root.isInitialized
      function setFanSpeed(level) { if (current) root.setFanSpeed(level, settingsContext); }
      property bool _constructed: false
      onCurrentChanged: if (!current && _constructed) retire(client)
      Component.onCompleted: _constructed = true
    }
  }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    const client = clientFactory.createObject(root, {
      settingsContext: context,
      retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  FileView {
    id: fanLoader
    path: "/proc/acpi/ibm/fan"
    printErrors: false
    onLoaded: {
      const content = text();
      if (!content) return;
      let rpm = 0, level = root.levelAuto;
      for (const line of content.split("\n")) {
        if (line.trim().startsWith("speed:")) rpm = parseInt(line.split(":")[1].trim()) || 0;
        else if (line.trim().startsWith("level:")) level = line.split(":")[1].replace(/[\r\n\t]/g, "").trim().toLowerCase();
      }
      root.fanRpm = rpm; root.fanLevel = level; root.isInitialized = true;
    }
  }
  FileView {
    id: tempLoader
    path: "/sys/class/thermal/thermal_zone0/temp"
    printErrors: false
    onLoaded: {
      const value = parseInt(text().trim());
      if (!isNaN(value)) root.currentTemp = Math.round(value / 1000);
    }
  }
  property var actionContext: null
  readonly property bool actionCurrent: !!actionContext && actionContext.current()
  onActionCurrentChanged: if (!actionCurrent) { fanProcess.running = false; refreshTimer.stop(); }
  Process {
    id: fanProcess
    onExited: if (root.actionCurrent) refreshTimer.restart()
  }
  function setFanSpeed(targetLevel, context) {
    context = context || pluginApi?.settingsContext;
    if (!isInitialized || !context || !context.current()) return;
    const level = String(targetLevel).replace(/[\r\n\t]/g, "").trim().toLowerCase();
    if (!level || level === levelUnknown) return;
    fanProcess.running = false;
    refreshTimer.stop();
    actionContext = context;
    fanLevel = level;
    fanProcess.command = ["sh", "-c", "echo level " + level + " > /proc/acpi/ibm/fan"];
    fanProcess.running = true;
  }
  Timer {
    id: refreshTimer
    interval: 300
    onTriggered: if (root.actionCurrent) { fanLoader.reload(); tempLoader.reload(); }
  }
  Timer {
    interval: 2000
    running: root.pluginApi !== null
    repeat: true
    triggeredOnStart: true
    onTriggered: { fanLoader.reload(); tempLoader.reload(); }
  }
}
