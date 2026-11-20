import QtQuick
import Quickshell.Io

// Main owns clients by captured runtime identity, not view or equal settings.
Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component {
    id: clientFactory
    AirQualitySettingsClient {}
  }
  function settingsConsumerFor(context) {
    if (!context || !context.current())
      return null;
    if (_settingsConsumers.has(context))
      return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
                                              settingsContext: context,
                                              pluginApi: pluginApi,
                                              retire: function (retired) {
                                                root._settingsConsumers.delete(context);
                                                retired.destroy();
                                              }
                                            });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property int usAqi: settingsConsumer?.usAqi ?? 0
  readonly property int europeanAqi: settingsConsumer?.europeanAqi ?? 0
  readonly property real pm25: settingsConsumer?.pm25 ?? 0
  readonly property real pm10: settingsConsumer?.pm10 ?? 0
  readonly property real ozone: settingsConsumer?.ozone ?? 0
  readonly property real no2: settingsConsumer?.no2 ?? 0
  readonly property real co: settingsConsumer?.co ?? 0
  readonly property real so2: settingsConsumer?.so2 ?? 0
  readonly property string aqiScale: settingsConsumer?.aqiScale ?? "us"
  readonly property string lastUpdate: settingsConsumer?.lastUpdate ?? ""
  readonly property string stationName: settingsConsumer?.stationName ?? ""
  readonly property string errorMessage: settingsConsumer?.errorMessage ?? ""
  readonly property bool hasData: settingsConsumer?.hasData ?? false
  readonly property bool loading: settingsConsumer?.loading ?? false
  function refresh() {
    settingsConsumer?.refresh();
  }
  function getAqi() {
    return settingsConsumer?.getAqi() ?? 0;
  }
  function getAqiColor(value, scale) {
    return settingsConsumer?.getAqiColor(value, scale) ?? "transparent";
  }
  function getAqiLevel(value, scale) {
    return settingsConsumer?.getAqiLevel(value, scale) ?? "levels.unknown";
  }
  function getLocationName() {
    return settingsConsumer?.getLocationName() ?? "";
  }
  function getPollutantColor(pollutant, value) {
    return settingsConsumer?.getPollutantColor(pollutant, value) ?? "transparent";
  }
  IpcHandler {
    target: "plugin:air-quality"
    function refresh() {
      root.refresh();
    }
    function toggle() {
      if (root.pluginApi)
        root.pluginApi.withCurrentScreen(screen => root.pluginApi.togglePanel(screen));
    }
  }
}
