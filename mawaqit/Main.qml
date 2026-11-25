import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component { id: clientFactory; MawaqitSettingsClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {settingsContext: context, pluginApi: pluginApi, observation: root,
      retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }});
    _settingsConsumers.set(context, client); return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property var prayerTimings: settingsConsumer?.prayerTimings ?? null
  readonly property bool isRamadan: settingsConsumer?.isRamadan ?? false
  readonly property bool isLoading: settingsConsumer?.isLoading ?? false
  readonly property bool hasError: settingsConsumer?.hasError ?? false
  readonly property string errorMessage: settingsConsumer?.errorMessage ?? ""
  readonly property int secondsToNext: settingsConsumer?.secondsToNext ?? -1
  readonly property string nextPrayerName: settingsConsumer?.nextPrayerName ?? ""
  readonly property int secondsElapsed: settingsConsumer?.secondsElapsed ?? -1
  readonly property string lastPrayerName: settingsConsumer?.lastPrayerName ?? ""
  readonly property int hijriDay: settingsConsumer?.hijriDay ?? 0
  readonly property int hijriDayRaw: settingsConsumer?.hijriDayRaw ?? 0
  readonly property int hijriDayOffset: settingsConsumer?.hijriDayOffset ?? 0
  readonly property int hijriMonth: settingsConsumer?.hijriMonth ?? 0
  readonly property int hijriYear: settingsConsumer?.hijriYear ?? 0
  readonly property string hijriMonthNameAr: settingsConsumer?.hijriMonthNameAr ?? ""
  readonly property string hijriMonthNameEn: settingsConsumer?.hijriMonthNameEn ?? ""
  readonly property int hijriMonthDays: settingsConsumer?.hijriMonthDays ?? 30
  readonly property string gregorianDateStr: settingsConsumer?.gregorianDateStr ?? ""
  readonly property var prayerOrder: settingsConsumer?.prayerOrder ?? []
  readonly property bool isJumuah: settingsConsumer?.isJumuah ?? false
  function getPrayer(key) { return settingsConsumer?.getPrayer(key) ?? null; }
  function updateCountdown() { settingsConsumer?.updateCountdown(); }
  function checkPrayerTimes() { settingsConsumer?.checkPrayerTimes(); }
  function fetchPrayerTimes() { settingsConsumer?.fetchPrayerTimes(); }
  function forceRefresh() { settingsConsumer?.forceRefresh(); }

  CalendarCache { id: calendarCache; pluginApi: root.pluginApi }
  function calendarRequest(command, callback) { calendarCache.request(command, callback); }
  Component.onCompleted: calendarRequest({op: "adopt"})

  function cacheOwner(client) { return client && client.current && client === settingsConsumer && pluginApi.settingsContext.current(); }
  function cacheFor(client) {
    // The shared client publishes the week; any live matching source can read it.
    if (!client?.current || !pluginApi?.settingsContext.current()) return null;
    try {
      var cached = JSON.parse(pluginApi.pluginSettings._cacheData || "null");
      return cached?.schema === 1 && cached.source === client.sourceKey ? cached.days : null;
    } catch (error) { return null; }
  }
  function saveCache(client, days) {
    if (!cacheOwner(client)) return;
    var settings = pluginApi.pluginSettings;
    settings._cacheData = JSON.stringify({schema: 1, source: client.sourceKey, days: days});
    settings._cacheCity = client.city; settings._cacheCountry = client.country;
    settings._cacheMethod = String(client.method); settings._cacheSchool = String(client.school);
    settings._cacheSavedAt = new Date().toISOString().substring(0, 10);
    settings._cacheFajrAngle = String(client.fajrAngle ?? "null"); settings._cacheIshaAngle = String(client.ishaAngle ?? "null");
    pluginApi.saveSettings();
  }
  function clearCache(client) {
    if (!cacheOwner(client)) return;
    pluginApi.pluginSettings._cacheData = null; pluginApi.saveSettings();
  }
  property bool azanPlaying: false
  Process { id: azanPlayer; onExited: root.azanPlaying = false }
  Process { id: stopAzanProc }
  function playAzanFile(fileName) {
    if (!pluginApi?.pluginDir) return;
    const filePath = pluginApi.pluginDir + "/assets/" + fileName;
    azanPlayer.exec({command: ["bash", "-c", "if command -v paplay >/dev/null 2>&1; then paplay '" + filePath + "'; elif command -v pw-cat >/dev/null 2>&1; then pw-cat -p '" + filePath + "'; fi"]});
    azanPlaying = true;
  }
  function stopAzanFile() {
    stopAzanProc.exec({command: ["bash", "-c", "pkill -f 'paplay.*azan' 2>/dev/null; pkill -f 'pw-cat.*azan' 2>/dev/null || true"]});
    azanPlaying = false;
  }
  Process { id: notificationProcess }
  property var _notified: new Set()
  property var _played: new Set()
  function onPrayerTime(client, prayerKey) {
    if (!client.current || !client.prayerTimings) return;
    var time = client.prayerTimings[prayerKey] || "";
    var key = JSON.stringify([new Date().toISOString().substring(0, 10), client.city, client.country, prayerKey, time]);
    if (client.showNotifications && !_notified.has(key)) {
      _notified.add(key);
      var names = {Fajr: "الفجر", Dhuhr: "الظهر", Asr: "العصر", Maghrib: "المغرب", Isha: "العشاء", Imsak: "الإمساك"};
      var title = prayerKey === "Imsak" ? "🌙 Imsak — " + time : "🕌 " + prayerKey + " — " + time;
      var body = prayerKey === "Imsak" ? "حان وقت الإمساك" : "حان الآن موعد صلاة " + (names[prayerKey] || prayerKey);
      notificationProcess.command = ["notify-send", "-a", "Mawaqit", "-u", "critical", "-t", "10000", title, body]; notificationProcess.running = true;
    }
    if (prayerKey !== "Imsak" && client.playAzan && !_played.has(key)) { _played.add(key); playAzanFile(client.azanFile); }
  }
}
