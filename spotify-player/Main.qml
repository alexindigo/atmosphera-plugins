import QtQuick
import Quickshell
import Quickshell.Io
import "Auth.js" as Auth
import qs.Commons
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null
  property var _lifetime: ({
                             alive: true
                           })
  property var _request: null
  Component.onDestruction: {
    _lifetime.alive = false;
    if (_request)
      _request.abort();
  }

  // Generated OAuth session state from an explicit Settings authorization:
  // the runtime owner adopts it; it is never a preference draft.
  function adoptTokens(tokens) {
    if (!pluginApi || !tokens)
      return false;
    pluginApi.pluginSettings.accessToken = tokens.accessToken;
    if (tokens.refreshToken)
      pluginApi.pluginSettings.refreshToken = tokens.refreshToken;
    pluginApi.pluginSettings.tokenExpiresAt = tokens.tokenExpiresAt;
    return pluginApi.saveSettings() !== false;
  }

  function refreshAccessToken() {
    if (!pluginApi || _request)
      return;
    var api = pluginApi;
    var lifetime = _lifetime;
    var input = {
      clientId: api.pluginSettings.clientId,
      clientSecret: api.pluginSettings.clientSecret,
      refreshToken: api.pluginSettings.refreshToken
    };
    _request = Auth.requestToken(Qt.btoa(input.clientId + ":" + input.clientSecret), {
                                   refresh_token: input.refreshToken,
                                   grant_type: "refresh_token"
                                 }, function (tokens, error) {
                                   if (!lifetime.alive)
                                     return;
                                   root._request = null;
                                   if (error) {
                                     Logger.e("spotify-player", "Token refresh failed");
                                     return;
                                   }
                                   if (root.pluginApi !== api || api.pluginSettings.clientId !== input.clientId || api.pluginSettings.clientSecret !== input.clientSecret || api.pluginSettings.refreshToken !== input.refreshToken)
                                     return;
                                   api.pluginSettings.accessToken = tokens.accessToken;
                                   api.pluginSettings.refreshToken = tokens.refreshToken || input.refreshToken;
                                   api.pluginSettings.tokenExpiresAt = tokens.tokenExpiresAt;
                                   api.saveSettings(function (result) {
                                     if (lifetime.alive && (result.status === "saved" || result.status === "nothing_to_save"))
                                       Logger.i("spotify-player", "Token refreshed successfully");
                                   });
                                 });
  }
}
