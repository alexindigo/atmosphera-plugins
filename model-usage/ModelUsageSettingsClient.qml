import QtQuick
import Quickshell

Item {
    id: root
    visible: false

    required property var settingsContext
    required property var observation
    required property var retire
    readonly property bool current: settingsContext.current()
    readonly property var pluginSettings: settingsContext.settingsView
    readonly property string providerKey: JSON.stringify(pluginSettings.providers ?? ({}))
    property bool _constructed: false
    property var providers: []
    readonly property var enabledProviders: providers
    function release() {
        var old = providers; providers = [];
        for (var provider of old) observation.releaseProvider(provider);
    }
    function selectProviders() {
        var previous = providers, next = [];
        if (current) for (var id of ["claude", "codex", "copilot", "gemini", "openrouter", "zen"]) {
            if (!providerEnabled(id)) continue;
            var provider = observation.acquireProvider(id, pluginSettings.providers[id]);
            if (provider) next.push(provider);
        }
        providers = next;
        for (var old of previous) observation.releaseProvider(old);
    }

    property int activeIndex: 0
    property var activeProvider: enabledProviders.length > 0 ? enabledProviders[Math.min(activeIndex, enabledProviders.length - 1)] : null

    property string barDisplayMode: pluginSettings?.barDisplayMode ?? "active"
    property int barCycleIntervalSec: pluginSettings?.barCycleIntervalSec ?? 5
    property string barMetric: pluginSettings?.barMetric ?? "prompts"
    property int refreshIntervalSec: pluginSettings?.refreshIntervalSec ?? 30

    Timer {
        interval: root.barCycleIntervalSec * 1000
        running: root.current && root.barDisplayMode === "cycle" && root.enabledProviders.length > 1
        repeat: true
        onTriggered: {
            root.activeIndex = (root.activeIndex + 1) % root.enabledProviders.length;
        }
    }

    Timer {
        interval: root.refreshIntervalSec * 1000
        running: root.current
        repeat: true
        onTriggered: root.refreshAll()
    }

    onEnabledProvidersChanged: {
        if (enabledProviders.length === 0) {
            activeIndex = 0;
        } else if (activeIndex >= enabledProviders.length) {
            activeIndex = 0;
        }
    }

    function providerEnabled(id) {
        return pluginSettings?.providers?.[id]?.enabled ?? false;
    }

    function refresh() {
        refreshAll();
    }

    function refreshAll() {
        if (!current) return;
        for (const p of providers) {
            if (p.enabled)
                p.refresh();
        }
    }

    function formatTokenCount(n) {
        if (n === undefined || n === null)
            return "0";
        if (n >= 1e9)
            return (n / 1e9).toFixed(1) + "B";
        if (n >= 1e6)
            return (n / 1e6).toFixed(1) + "M";
        if (n >= 1e3)
            return (n / 1e3).toFixed(1) + "K";
        return String(n);
    }

    function friendlyModelName(id) {
        if (!id)
            return "Unknown";
        let name = id.replace(/^claude-/, "");
        name = name.replace(/-\d{8}$/, "");
        const parts = name.split("-");
        if (parts.length >= 3) {
            const family = parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
            return family + " " + parts[1] + "." + parts[2];
        }
        if (parts.length === 2) {
            const family = parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
            return family + " " + parts[1];
        }
        return name.charAt(0).toUpperCase() + name.slice(1);
    }
    onProviderKeyChanged: if (_constructed) selectProviders()
    onCurrentChanged: if (_constructed && !current) { release(); retire(root); }
    Component.onCompleted: { _constructed = true; selectProviders(); }
    Component.onDestruction: release()
}
