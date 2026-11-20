import QtQuick
import qs.Commons
import qs.Services.Location

Item {
  id: root
  required property var settingsContext
  required property var pluginApi
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: current ? settingsContext.settingsView : ({})
  readonly property string aqiScale: cfg.aqiScale ?? "us"
  // Location is a genuine shared observation. Capture it with each generation
  // so a response for an old location cannot acquire a replacement's label.
  readonly property var _weather: LocationService.data?.weather
  readonly property string _queryIdentity: JSON.stringify([cfg.dataSource, cfg.aqicnToken, cfg.useNoctaliaLocation, cfg.customLatitude, cfg.customLongitude, cfg.aqiScale, cfg.refreshInterval, Settings.data.location?.weatherEnabled, Settings.data.location?.name, _weather?.latitude, _weather?.longitude])
  property var _worker: null
  property bool _constructed: false
  readonly property bool loading: _worker?.loading ?? false
  readonly property bool hasData: _worker?.hasData ?? false
  readonly property string errorMessage: _worker?.errorMessage ?? ""
  readonly property string lastUpdate: _worker?.lastUpdate ?? ""
  readonly property string stationName: _worker?.stationName ?? ""
  readonly property int usAqi: _worker?.usAqi ?? 0
  readonly property int europeanAqi: _worker?.europeanAqi ?? 0
  readonly property real pm25: _worker?.pm25 ?? 0
  readonly property real pm10: _worker?.pm10 ?? 0
  readonly property real ozone: _worker?.ozone ?? 0
  readonly property real no2: _worker?.no2 ?? 0
  readonly property real co: _worker?.co ?? 0
  readonly property real so2: _worker?.so2 ?? 0
  function refresh() {
    _worker?.refresh();
  }
  function getAqi() {
    return aqiScale === "eu" ? europeanAqi : usAqi;
  }
  function getAqiColor(value, scale) {
    return _worker?.getAqiColor(value, scale) ?? "transparent";
  }
  function getAqiLevel(value, scale) {
    return _worker?.getAqiLevel(value, scale) ?? "levels.unknown";
  }
  function getLocationName() {
    return _worker?.getLocationName() ?? "";
  }
  function getPollutantColor(pollutant, value) {
    return _worker?.getPollutantColor(pollutant, value) ?? "transparent";
  }
  function _retireWorker() {
    if (!_worker)
      return;
    var old = _worker;
    _worker = null;
    old.active = false;
    old.destroy();
  }
  function _replaceQuery() {
    if (!_constructed)
      return;
    _retireWorker();
    if (!current)
      return;
    _worker = workerFactory.createObject(root, {
                                           pluginApi: pluginApi,
                                           configuration: cfg,
                                           location: Object.freeze({
                                                                     enabled: Settings.data.location?.weatherEnabled ?? false,
                                                                     name: Settings.data.location?.name ?? "",
                                                                     latitude: _weather?.latitude,
                                                                     longitude: _weather?.longitude
                                                                   })
                                         });
  }
  Component {
    id: workerFactory
    AirQualityQueryWorker {}
  }
  on_QueryIdentityChanged: _replaceQuery()
  onCurrentChanged: {
    if (!current && _constructed) {
      _retireWorker();
      retire(root);
    }
  }
  Component.onCompleted: {
    _constructed = true;
    _replaceQuery();
  }
  Component.onDestruction: _retireWorker()
}
