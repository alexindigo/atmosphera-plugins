import QtQuick
import Quickshell
import Quickshell.Io
import "." as Local
import qs.Commons
import qs.Services.Plugins
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component {
    id: pollFactory
    PluginSettingsPoller {}
  }
  function settingsConsumerFor(context) {
    if (!context || !context.current())
      return null;
    if (_settingsConsumers.has(context))
      return _settingsConsumers.get(context);
    var client = pollFactory.createObject(root, {
                                            settingsContext: context,
                                            sourceInterval: Qt.binding(function () {
                                              return context.settingsView.refreshInterval ?? root.pluginApi?.manifest?.metadata?.defaultSettings?.refreshInterval ?? 300;
                                            }),
                                            intervalScale: 1000,
                                            requirePositiveInterval: true,
                                            requestRefresh: function () {
                                              service.fetchIp();
                                            },
                                            retire: function (retired) {
                                              root._settingsConsumers.delete(context);
                                              retired.destroy();
                                            }
                                          });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null

  // IP Monitor Service
  Item {
    id: service

    property var ipData: null
    property string currentIp: "n/a"
    property string fetchState: "idle" // idle, loading, success, error
    property int lastFetchTime: 0

    // Increment this to trigger refresh in all listening widgets (for IPC)
    property int refreshTrigger: 0

    // Compatibility surface remains explicitly plugin-level; views own schedules.
    readonly property int refreshInterval: root.settingsConsumer?.sourceInterval ?? 300

    // Process for fetching IP info
    property Process ipFetchProcess: Process {
      running: false
      command: ["curl", "-s", "-m", "10", "http://ip-api.com/json/?fields=status,continent,country,regionName,city,zip,lat,lon,timezone,currency,org,as,query"]
      stdout: StdioCollector {
        id: stdoutCollector
      }
      stderr: StdioCollector {
        id: stderrCollector
      }

      onStarted: {
        service.fetchState = "loading";
        Logger.d("IpMonitor", "Service fetching IP info...");
      }

      onExited: function (exitCode, exitStatus) {
        var output = stdoutCollector.text;
        Logger.d("IpMonitor", "Service process exited:", exitCode, "length:", output.length);

        if (exitCode === 0 && output.length > 0) {
          try {
            var data = JSON.parse(output);
            if (data.status === "success") {
              service.ipData = {
                ip: data.query,
                city: data.city || "n/a",
                country: data.country || "n/a",
                continent: data.continent || "n/a",
                region: data.regionName || "n/a",
                postal: data.zip || "n/a",
                loc: (data.lat && data.lon) ? (data.lat + "," + data.lon) : "n/a",
                timezone: data.timezone || "n/a",
                currency: data.currency || "n/a",
                org: data.org || "n/a",
                as: data.as || "n/a"
              };
              service.currentIp = data.query;
              service.fetchState = "success";
              service.lastFetchTime = Date.now();
              Logger.d("IpMonitor", "Service IP fetched successfully:", service.currentIp);
            } else {
              throw new Error("No IP field in response");
            }
          } catch (e) {
            Logger.e("IpMonitor", "Service parse error:", e.message);
            service.currentIp = "n/a";
            service.ipData = null;
            service.fetchState = "error";
          }
        } else {
          Logger.e("IpMonitor", "Service curl failed:", exitCode);
          service.currentIp = "n/a";
          service.ipData = null;
          service.fetchState = "error";
        }
      }
    }

    Component.onCompleted: {
      Logger.i("IpMonitor", "Service initialized, frist time fetching IP.");
      // Auto-fetch on startup
      Qt.callLater(() => fetchIp());
    }

    function fetchIp() {
      if (!service.ipFetchProcess) {
        Logger.e("IpMonitor", "Service ipFetchProcess is null!");
        return;
      }
      if (!service.ipFetchProcess.running) {
        Logger.d("IpMonitor", "Service starting ipFetchProcess");
        service.ipFetchProcess.running = true;
      } else {
        Logger.d("IpMonitor", "Service fetch already in progress");
      }
    }

    function triggerRefresh() {
      Logger.d("IpMonitor", "Service triggerRefresh() called");
      refreshTrigger++;
      fetchIp();
    }
  }

  // Expose service for access via pluginApi.root.ipMonitorService
  property alias ipMonitorService: service

  Component.onCompleted: {}

  // IPC handlers
  IpcHandler {
    target: "plugin:ip-monitor"

    function refreshIp() {
      Logger.i("IpMonitor", "IPC refreshIp() called");
      service.triggerRefresh();
      ToastService.showNotice("Refreshing IP info...");
    }

    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(screen => {
          pluginApi.openPanel(screen);
        });
      }
    }
  }
}
