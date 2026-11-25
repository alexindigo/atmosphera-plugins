import QtQuick

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component { id: clientFactory; PrayerSettingsClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
      pluginApi: pluginApi,
      settingsContext: context,
      retire: function(retired) {
        root._settingsConsumers.delete(context);
        retired.destroy();
      }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property var prayerTimings: settingsConsumer?.prayerTimings ?? null
  readonly property string hijriDateStr: settingsConsumer?.hijriDateStr ?? ""
  readonly property string gregorianDateStr: settingsConsumer?.gregorianDateStr ?? ""
  readonly property int hijriMonth: settingsConsumer?.hijriMonth ?? 0
  readonly property int hijriYear: settingsConsumer?.hijriYear ?? 0
  readonly property string hijriMonthName: settingsConsumer?.hijriMonthName ?? ""
  readonly property bool isRamadan: settingsConsumer?.isRamadan ?? false
  readonly property bool isLoading: settingsConsumer?.isLoading ?? false
  readonly property bool hasError: settingsConsumer?.hasError ?? false
  readonly property string errorMessage: settingsConsumer?.errorMessage ?? ""
  readonly property string lastFetchDate: settingsConsumer?.lastFetchDate ?? ""
  readonly property int secondsToIftar: settingsConsumer?.secondsToIftar ?? -1
  readonly property bool iftarPassed: settingsConsumer?.iftarPassed ?? false
  function fetchPrayerTimes() { settingsConsumer?.fetchPrayerTimes(); }
  function updateCountdown() { settingsConsumer?.updateCountdown(); }
}
