import QtQuick
import Quickshell.Io
import qs.Services.UI
import qs.Commons
import "./Services"

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component { id: clientFactory; KdeSettingsClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
      settingsContext: context, observation: KDEConnect,
      retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }
    });
    _settingsConsumers.set(context, client);
    return client;
  }

  onPluginApiChanged: {
    KDEConnect.setMainDevice(pluginApi?.pluginSettings?.mainDeviceId || "")
  }

  IpcHandler {
    target: "plugin:kde-connect"
    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(screen => {
          pluginApi.openPanel(screen);
        });
      }
    }
  }
}
