import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

// Main component: fetches prayer times and exposes data to BarWidget and Panel.
Item {
  id: root
  required property var pluginApi
  required property string city
  required property string country
  required property int method
  property bool active: true
  function stop() {
    active = false;
    updateTimer.stop();
    fetchProcess.running = false;
  }

  // Prayer data
  property var prayerTimings: null
  property string hijriDateStr: ""
  property string gregorianDateStr: ""
  property int hijriMonth: 0
  property int hijriYear: 0
  property string hijriMonthName: ""
  property bool isRamadan: hijriMonth === 9

  // Fetch state
  property bool isLoading: false
  property bool hasError: false
  property string errorMessage: ""
  property string lastFetchDate: ""

  // Countdown to Iftar (Maghrib) in seconds; -1 if past or no data
  property int secondsToIftar: -1
  property bool iftarPassed: false

  Process {
    id: fetchProcess
    running: false
    stdout: StdioCollector {}
    stderr: StdioCollector {}

    onExited: exitCode => {
      if (!root.active) return;
      isLoading = false;
      if (stderr.text.trim()) Logger.w("RamadanIftar", "curl stderr:", stderr.text.trim());
      if (exitCode === 0 && stdout.text.trim()) {
        parseResponse(stdout.text);
      } else {
        hasError = true;
        errorMessage = pluginApi?.tr("error.network") || "Network request failed";
        Logger.w("RamadanIftar", "Fetch failed, exit code:", exitCode, "stdout:", stdout.text.substring(0, 100));
      }
    }
  }

  // Update countdown every minute; re-fetch at midnight
  Timer {
    id: updateTimer
    interval: 60000
    running: root.active && prayerTimings !== null
    repeat: true
    onTriggered: {
      const today = new Date().toISOString().substring(0, 10);
      if (today !== lastFetchDate) {
        fetchPrayerTimes();
      } else {
        updateCountdown();
      }
    }
  }

  function fetchPrayerTimes() {
    if (!active || fetchProcess.running) return;
    isLoading = true;
    hasError = false;
    Logger.d("RamadanIftar", "Fetching prayer times for", city, country, "method", method);
    const cityEnc = city.replace(/ /g, "%20");
    const countryEnc = country.replace(/ /g, "%20");
    const url = `https://api.aladhan.com/v1/timingsByCity?city=${cityEnc}&country=${countryEnc}&method=${method}`;
    Logger.d("RamadanIftar", "URL:", url);
    fetchProcess.command = ["curl", "-s", "-L", "--max-time", "15", "-H", "User-Agent: Mozilla/5.0", url];
    fetchProcess.running = true;
  }

  function parseResponse(text) {
    if (!active) return;
    try {
      const json = JSON.parse(text);
      if (json.code === 200 && json.data) {
        const timings = json.data.timings;
        // Strip any timezone suffix like "(BST)" from time strings
        const cleaned = {};
        for (const key in timings) {
          cleaned[key] = timings[key].replace(/\s*\(.*\)/, "").trim();
        }
        prayerTimings = cleaned;

        const hijri = json.data.date.hijri;
        hijriDateStr = hijri.date;
        hijriMonth = hijri.month.number;
        hijriYear = parseInt(hijri.year);
        hijriMonthName = hijri.month.en;
        gregorianDateStr = json.data.date.readable;
        lastFetchDate = new Date().toISOString().substring(0, 10);
        hasError = false;
        updateCountdown();
        Logger.d("RamadanIftar", "Prayer times loaded. Hijri month:", hijriMonth, "isRamadan:", isRamadan);
      } else {
        hasError = true;
        errorMessage = json.status || "API error";
        Logger.w("RamadanIftar", "API error:", errorMessage);
      }
    } catch (e) {
      hasError = true;
      errorMessage = "Parse error: " + e.message;
      Logger.e("RamadanIftar", "Parse error:", e.message);
    }
  }

  function updateCountdown() {
    if (!active) return;
    if (!prayerTimings || !prayerTimings.Maghrib) {
      secondsToIftar = -1;
      return;
    }
    const now = new Date();
    const parts = prayerTimings.Maghrib.split(":");
    const iftar = new Date();
    iftar.setHours(parseInt(parts[0]), parseInt(parts[1]), 0, 0);
    const diff = Math.floor((iftar - now) / 1000);
    if (diff <= 0) {
      iftarPassed = true;
      secondsToIftar = -1;
    } else {
      iftarPassed = false;
      secondsToIftar = diff;
    }
  }

  Component.onCompleted: {
    Qt.callLater(fetchPrayerTimes);
  }
  Component.onDestruction: stop()
}
