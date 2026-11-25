import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component {
    id: clientFactory
    CurrencySettingsClient {}
  }
  function settingsConsumerFor(context) {
    if (!context || !context.current())
      return null;
    if (_settingsConsumers.has(context))
      return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
                                              settingsContext: context,
                                              pluginApi: pluginApi,
                                              copyText: root.copyToClipboard,
                                              retire: function (retired) {
                                                root._settingsConsumers.delete(context);
                                                retired.destroy();
                                              }
                                            });
    _settingsConsumers.set(context, client);
    return client;
  }
  // Existing Main consumers and IPC remain explicitly plugin-level.
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property string baseCurrency: settingsConsumer?.baseCurrency ?? "USD"
  readonly property int cacheMinutes: settingsConsumer?.cacheMinutes ?? 5
  readonly property var cachedRates: settingsConsumer?.cachedRates ?? ({})
  readonly property real lastFetch: settingsConsumer?.lastFetch ?? 0
  readonly property real lastFetchAttempt: settingsConsumer?.lastFetchAttempt ?? 0
  readonly property bool loaded: settingsConsumer?.loaded ?? false
  readonly property bool loading: settingsConsumer?.loading ?? false
  readonly property int refreshInterval: settingsConsumer?.refreshInterval ?? 0
  readonly property int retryDelaySeconds: settingsConsumer?.retryDelaySeconds ?? 10
  signal ratesUpdated
  Connections {
    target: root.settingsConsumer
    function onRatesUpdated() { root.ratesUpdated(); }
  }
  function convert(amount, from, to) { return settingsConsumer?.convert(amount, from, to) ?? null; }
  function fetchRates(forceRetry) { settingsConsumer?.fetchRates(forceRetry); }
  function formatNumber(num) { return settingsConsumer?.formatNumber(num) ?? "0"; }
  function getRate(from, to) { return settingsConsumer?.getRate(from, to) ?? null; }
  function isValidCurrency(code) { return settingsConsumer?.isValidCurrency(code) ?? false; }
  function copyToClipboard(text) {
    var escaped = text.replace(/'/g, "'\\''");
    Quickshell.execDetached(["sh", "-c", "printf '%s' '" + escaped + "' | wl-copy"]);
  }
  IpcHandler {
    target: "plugin:currency-exchange"
    function togglePanel() {
      pluginApi.withCurrentScreen(screen => pluginApi.togglePanel(screen));
    }
    function toggle() {
      pluginApi.withCurrentScreen(screen => pluginApi.toggleLauncher(screen));
    }
  }
}
