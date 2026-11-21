import QtQuick
import Quickshell
import "providers" as Providers

Item {
    id: root
    property var pluginApi: null
    property var _settingsConsumers: new Map()
    property var _providerLeases: new Map()
    Component { id: clientFactory; ModelUsageSettingsClient {} }
    Component { id: claudeFactory; Providers.Claude {} }
    Component { id: codexFactory; Providers.Codex {} }
    Component { id: copilotFactory; Providers.Copilot {} }
    Component { id: geminiFactory; Providers.Gemini {} }
    Component { id: openRouterFactory; Providers.OpenRouter {} }
    Component { id: zenFactory; Providers.Zen {} }
    function sourceKeyFor(id, options) {
        var home = Quickshell.env("HOME") ?? "/home";
        function path(value) { return value && value.startsWith("~") ? home + value.substring(1) : value; }
        if (id === "claude") return JSON.stringify([id, path(options.statsPath ?? "~/.claude/stats-cache.json"), path(options.credentialsPath ?? "~/.claude/.credentials.json")]);
        if (id === "openrouter") return JSON.stringify([id, Quickshell.env("OPENROUTER_API_KEY") || (options.apiKey ?? "")]);
        if (id === "zen") return JSON.stringify([id, options.apiBaseUrl ?? "https://opencode.ai/zen/v1", Quickshell.env("OPENCODE_ZEN_API_KEY") || Quickshell.env("OPENCODE_API_KEY") || Quickshell.env("ZEN_API_KEY") || (options.apiKey ?? "")]);
        return JSON.stringify([id, home]);
    }
    function acquireProvider(id, options) {
        var key = sourceKeyFor(id, options);
        if (_providerLeases.has(key)) {
            var existing = _providerLeases.get(key); ++existing.leases; return existing;
        }
        var factory = {claude: claudeFactory, codex: codexFactory, copilot: copilotFactory, gemini: geminiFactory, openrouter: openRouterFactory, zen: zenFactory}[id];
        if (!factory) return null;
        var provider = factory.createObject(root, {sourceSettings: JSON.parse(JSON.stringify(options)), leaseKey: key, leases: 1});
        _providerLeases.set(key, provider); provider.enabled = true; return provider;
    }
    function releaseProvider(provider) {
        if (--provider.leases > 0) return;
        _providerLeases.delete(provider.leaseKey); provider.enabled = false; provider.cancelRequests(); provider.destroy();
    }
    function settingsConsumerFor(context) {
        if (!context || !context.current()) return null;
        if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
        var client = clientFactory.createObject(root, {settingsContext: context, observation: root,
            retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }});
        _settingsConsumers.set(context, client); return client;
    }
    readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
    readonly property var providers: settingsConsumer?.providers ?? []
    readonly property var enabledProviders: settingsConsumer?.enabledProviders ?? []
    readonly property var activeProvider: settingsConsumer?.activeProvider ?? null
    readonly property string barDisplayMode: settingsConsumer?.barDisplayMode ?? "active"
    readonly property string barMetric: settingsConsumer?.barMetric ?? "prompts"
    function refresh() { settingsConsumer?.refresh(); }
    function refreshAll() { settingsConsumer?.refreshAll(); }
    function formatTokenCount(n) { return settingsConsumer?.formatTokenCount(n) ?? "0"; }
    function friendlyModelName(id) { return settingsConsumer?.friendlyModelName(id) ?? "Unknown"; }
}
