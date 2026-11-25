import QtQuick
import Quickshell.Io
import qs.Services.Compositor
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  property var _lifetime: ({ current: true })
  Component.onDestruction: _lifetime.current = false
  Component { id: clientFactory; ParserClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    const client = clientFactory.createObject(root, {
      settingsContext: context, pluginApi: pluginApi,
      publishCache: context === pluginApi.settingsContext ? function(source, data, compositor) {
        if (!context.current()) return;
        pluginApi.state.cheatsheetData = data;
        pluginApi.state.detectedCompositor = compositor;
        pluginApi.state.cheatsheetSource = source;
        pluginApi.saveState();
      } : null,
      retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  function clientFor(api) { return api?.settingsReady ? settingsConsumerFor(api.settingsContext) : null; }
  readonly property var settingsConsumer: clientFor(pluginApi)
  readonly property int cheatsheetDataVersion: settingsConsumer?.cheatsheetDataVersion ?? 0
  function refresh() { settingsConsumer?.refresh(); }
  function updateBind(api, bindId, desc, hidden) {
    const context = api?.settingsContext;
    if (!api?.settingsReady || !context?.current() || !bindId) return false;
    const client = settingsConsumerFor(context), life = _lifetime;
    const overrides = JSON.parse(JSON.stringify(api.pluginSettings.bindOverrides || {}));
    if (!overrides[bindId]) overrides[bindId] = {};
    if (hidden) overrides[bindId].hidden = true;
    else {
      const text = (desc || "").trim();
      if (text) overrides[bindId].desc = text;
      else {
        delete overrides[bindId].desc;
        if (Object.keys(overrides[bindId]).length === 0) delete overrides[bindId];
      }
    }
    api.pluginSettings.bindOverrides = overrides;
    api.saveSettings(function(result) {
      if (!life.current || !context.current()) return;
      // Runtime saveSettings returns the native saveSelected publication receipt,
      // not an editor Apply/read-observation receipt with refreshState=current.
      if (result.status === "saved" || result.status === "nothing_to_save") client?.refresh();
      else ToastService.showError("Keybind Cheatsheet", result.errorCode || "bind-save-failed");
    });
    return true;
  }
  IpcHandler {
    target: "plugin:keybind-cheatsheet"
    function toggle() { if (root.pluginApi) root.pluginApi.withCurrentScreen(screen => root.pluginApi.togglePanel(screen)); }
    function refresh() { root.refresh(); }
  }
}
