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
            requestEvents: function() { root.requestEvents(); },
            retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }
        });
        _settingsConsumers.set(context, client);
        return client;
    }
    readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null

    // CalendarService remains the one provider/cache owner. Coalesce the union
    // of active projection ranges, never let one view narrow another's request.
    function requestEvents() {
        if (_requestQueued) return;
        _requestQueued = true;
        Qt.callLater(function() {
            root._requestQueued = false;
            if (!CalendarService.available) return;
            var start = null, end = null;
            for (var client of root._settingsConsumers.values()) {
                if (!client.current || !client.hasLoadedOnce) continue;
                var first = new Date(client.weekStart), last = new Date(client.weekEnd);
                first.setDate(first.getDate() - 7);
                last.setDate(last.getDate() + 14);
                if (!start || first < start) start = first;
                if (!end || last > end) end = last;
            }
            if (!start || !end) return;
            var now = new Date();
            CalendarService.loadEvents(Math.max(0, Math.ceil((end - now) / 86400000)), Math.max(0, Math.ceil((now - start) / 86400000)));
        });
    }
    Connections {
        target: CalendarService
        function onEventsChanged() {
            for (var client of root._settingsConsumers.values())
                if (client.current) client.updateEventsFromService();
        }
        function onAvailableChanged() {
            if (!CalendarService.available) return;
            for (var client of root._settingsConsumers.values())
                if (client.current) client.loadEvents();
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
