import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.Compositor

Item {
  id: root
  property var pluginApi: null

  property var configClients: new Map()
  readonly property var sharedConfig: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null

  function settingsConsumerFor(context) {
    context = context || pluginApi?.settingsContext;
    if (!context?.current()) return null;
    if (configClients.has(context)) return configClients.get(context);
    const client = configComponent.createObject(root, {pluginApi: pluginApi, settingsContext: context,
      retire: function (retired) { root.configClients.delete(context); retired.destroy(); }});
    configClients.set(context, client);
    return client;
  }
  Component { id: configComponent; DisplayConfigClient {} }

  readonly property var liveOutputs: isNiri ? niriProvider.outputs : wlrProvider.outputs
  readonly property var niriOutputs: sharedConfig?.outputs ?? []
  readonly property bool isNiri: CompositorService.isNiri
  readonly property bool liveLoading: niriProvider.loading || wlrProvider.loading
  readonly property bool loading: liveLoading || (sharedConfig?.loading ?? false)
  readonly property bool modifying: niriProvider.modifying

  Component.onCompleted: { if (pluginApi) refresh() }
  onPluginApiChanged: { if (pluginApi) refresh() }

  function refresh(context) {
    refreshLive()
    if (isNiri) refreshConfig(context)
  }

  function refreshLive() {
    if (isNiri) niriProvider.refresh()
    else wlrProvider.refresh()
  }

  function refreshConfig(context) {
    return settingsConsumerFor(context)?.refresh() ?? false;
  }

  function setMode(name, mode) { niriProvider.setMode(name, mode) }
  function setScale(name, scale) { niriProvider.setScale(name, scale) }
  function setTransform(name, t) { niriProvider.setTransform(name, t) }
  function setVrr(name, on) { niriProvider.setVrr(name, on) }
  function setPower(name, on) { niriProvider.setPower(name, on) }

  function startMonitor() { udev.start() }
  function stopMonitor() { udev.stop() }

  NiriOutputProvider {
    id: niriProvider
    onModifySucceeded: root.refreshLive()
  }

  WlrOutputProvider { id: wlrProvider }

  Component.onDestruction: { for (const client of configClients.values()) client.destroy(); }

  UdevMonitor {
    id: udev
    onTriggered: root.refreshLive()
  }

  IpcHandler {
    target: "plugin:display-settings"

    function toggle() {
      if (root.pluginApi) {
        root.pluginApi.withCurrentScreen(screen => root.pluginApi.togglePanel(screen))
      }
    }
  }
}
