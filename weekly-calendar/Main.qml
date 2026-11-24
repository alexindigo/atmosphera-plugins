import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.Location

Item {
    id: root
    property var pluginApi: null
    property var _settingsConsumers: new Map()
    property bool _requestQueued: false
    Component { id: clientFactory; WeeklyCalendarSettingsClient {} }

    function settingsConsumerFor(context) {
        if (!context || !context.current()) return null;
        if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
        var client = clientFactory.createObject(root, {
            settingsContext: context,
            translate: function(key) { return root.pluginApi.tr(key); },
            requestEvents: function(client, first, last) { root.requestEvents(client, first, last); },
            retire: function(retired) {
                CalendarService["clearEventRange"]?.(retired);
                root._settingsConsumers.delete(context);
                retired.destroy();
            }
        });
        _settingsConsumers.set(context, client);
        return client;
    }
    readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null

    // The service also applies these leases to periodic and native-card loads.
    function requestEvents(client, first, last) {
        if (typeof CalendarService["setEventRange"] === "function") {
            CalendarService["setEventRange"](client, first, last);
            return;
        }
        // Hosts without event-range leases still use the original one-shot API.
        if (_requestQueued) return;
        _requestQueued = true;
        Qt.callLater(function() {
            root._requestQueued = false;
            if (!CalendarService.available) return;
            var start = null, end = null;
            for (var client of root._settingsConsumers.values()) {
                if (!client.current || !client.hasLoadedOnce) continue;
                var range = client.eventRange();
                if (!start || range.start < start) start = range.start;
                if (!end || range.end > end) end = range.end;
            }
            if (!start || !end) return;
            var now = new Date();
            CalendarService.loadEvents(Math.max(0, Math.ceil((end - now) / 86400000)), Math.max(0, Math.ceil((now - start) / 86400000)));
        });
    }
    Component.onDestruction: {
        for (const client of _settingsConsumers.values())
            CalendarService["clearEventRange"]?.(client);
    }
    Connections {
        target: CalendarService
        function onEventsChanged() {
            for (var client of root._settingsConsumers.values())
                if (client.current) client.updateEventsFromService();
        }
        function onAvailableChanged() {
            for (var client of root._settingsConsumers.values()) {
                if (!client.current) continue;
                if (CalendarService.available) client.loadEvents();
                else client.updateEventsFromService();
            }
        }
    }

    // Existing explicit Main operations are plugin-level; views use their client.
    function initializePlugin() { settingsConsumer?.initializePlugin(); }
    function loadEvents() { settingsConsumer?.loadEvents(); }
    function updateEventsFromService() { settingsConsumer?.updateEventsFromService(); }
    function navigateWeek(days) { settingsConsumer?.navigateWeek(days); }
    function goToToday() { settingsConsumer?.goToToday(); }
    IpcHandler {
        target: "plugin:weekly-calendar"
        function togglePanel() { pluginApi?.withCurrentScreen(s => pluginApi.togglePanel(s)); }
    }

    // Retained pre-existing startup initialization, not a settings-page writer.
    Component.onCompleted: initializePluginSettings()
    function initializePluginSettings() {
        if (!pluginApi) return;
        if (!pluginApi.pluginSettings.weekStart) {
            var submitted = {weekStart: "1", timeFormat: "24h", lineColorType: "mOutline", hourLineOpacity: 0.5, dayLineOpacity: 1.0};
            for (var key of Object.keys(submitted)) pluginApi.pluginSettings[key] = submitted[key];
            pluginApi.saveSettings();
        }
    }
}
