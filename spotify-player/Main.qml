import QtQuick
import qs.Commons

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component { id: clientFactory; SpotifySettingsClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
      settingsContext: context, observation: root,
      retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }
    });
    _settingsConsumers.set(context, client);
    return client;
  }

  // Runtime actions supply their captured API. No page acquires this writer.
  function adoptTokens(client, input, tokens, callback) {
    var runtimeApi = input?.api;
    if (!tokens || !runtimeApi || _settingsConsumers.get(runtimeApi.settingsContext) !== client || !client.accepts(input)) return false;
    const applied = runtimeApi.pluginSettings;
    if ((applied.refreshToken || "") !== input.refreshToken || (applied.accessToken || "") !== input.accessToken ||
        (applied.tokenExpiresAt || 0) !== input.tokenExpiresAt) {
      callback(null);
      return true;
    }
    applied.accessToken = tokens.accessToken;
    // Omitting a refresh token means no field edit, not a copied override.
    if (typeof tokens.refreshToken === "string" && tokens.refreshToken) applied.refreshToken = tokens.refreshToken;
    applied.tokenExpiresAt = tokens.tokenExpiresAt;
    runtimeApi.saveSettings(function(result) {
      if (!client || !client.current || !client.accepts(input)) return;
      callback((result.status === "saved" || result.status === "nothing_to_save") &&
        (!result.unresolvedGroups || !result.unresolvedGroups.length));
    });
    return true;
  }

  // Calls without a placed origin remain deliberately plugin-level.
  function refreshAccessToken(runtimeApi) {
    var api = runtimeApi || pluginApi;
    return settingsConsumerFor(api?.settingsContext)?.refreshAccessToken(api) ?? false;
  }
}
