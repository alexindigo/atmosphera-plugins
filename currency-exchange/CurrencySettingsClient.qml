import QtQuick
import Quickshell.Io
import qs.Commons

// Main owns one cache/process/timer per captured runtime context, not per view
// or configuration value. The endpoint is always USD-based, so changing a
// currency or interval does not invalidate otherwise fresh rates.
Item {
  id: root
  required property var settingsContext
  required property var pluginApi
  required property var retire
  required property var copyText
  readonly property bool current: settingsContext.current()
  readonly property var cfg: current ? settingsContext.settingsView : ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property int refreshInterval: parseInt(cfg.refreshInterval ?? defaults.refreshInterval ?? 5)
  readonly property string baseCurrency: "USD"
  readonly property int cacheMinutes: 5
  readonly property int retryDelaySeconds: 10
  property var cachedRates: ({})
  property real lastFetch: 0
  property real lastFetchAttempt: 0
  property bool loaded: false
  property bool loading: false
  property bool _constructed: false
  signal ratesUpdated

  function convert(amount, from, to) {
    var rate = getRate(from, to);
    return rate === null ? null : (amount / cachedRates[from]) * cachedRates[to];
  }
  function getRate(from, to) {
    if (!cachedRates || !cachedRates.hasOwnProperty(from) || !cachedRates.hasOwnProperty(to))
      return null;
    return cachedRates[to] / cachedRates[from];
  }
  function isValidCurrency(code) { return cachedRates.hasOwnProperty(code); }
  function formatNumber(num) {
    if (num >= 1000) {
      return num.toLocaleString('en-US', {maximumFractionDigits: 2});
    } else if (num >= 1) {
      return num.toFixed(2);
    } else if (num > 0) {
      return num.toFixed(4);
    }
    return "0";
  }
  function copyToClipboard(text) { copyText(text); }
  function fetchRates(forceRetry) {
    if (!current || loading)
      return;
    var now = Date.now();
    if (loaded && (now - lastFetch) < cacheMinutes * 60000)
      return;
    if (!forceRetry && !loaded && lastFetchAttempt > 0 && (now - lastFetchAttempt) < retryDelaySeconds * 1000)
      return;
    loading = true;
    lastFetchAttempt = now;
    apiProcess.running = true;
  }
  Process {
    id: apiProcess
    command: ["curl", "-sf", "--connect-timeout", "5", "--max-time", "10", "-L", "https://api.frankfurter.app/latest?from=USD"]
    stdout: StdioCollector { id: ratesOutput }
    onExited: exitCode => {
      if (!root.current)
        return;
      root.loading = false;
      if (exitCode === 0) {
        try {
          var response = JSON.parse(ratesOutput.text);
          if (response.rates) {
            response.rates["USD"] = 1.0;
            root.cachedRates = response.rates;
            root.loaded = true;
            root.lastFetch = Date.now();
            root.ratesUpdated();
          }
        } catch (e) {
          Logger.e("CurrencyEx", "Failed to parse rates:", e);
        }
      } else {
        Logger.e("CurrencyEx", "Failed to fetch rates, exit code:", exitCode);
      }
    }
  }
  Timer {
    interval: root.refreshInterval * 60000
    repeat: true
    running: root.current && root.refreshInterval > 0
    onTriggered: root.fetchRates()
  }
  onCurrentChanged: {
    if (!current && _constructed) {
      apiProcess.running = false;
      retire(root);
    }
  }
  Component.onCompleted: {
    _constructed = true;
    fetchRates();
  }
}
