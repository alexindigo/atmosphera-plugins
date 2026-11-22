import QtQuick
import Quickshell.Io

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  property var _batterySources: new Map()
  property string currentProfile: "balanced"
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  Component { id: clientFactory; BatteryClient {} }
  Component { id: batteryFactory; BatterySource {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    const client = clientFactory.createObject(root, {
      owner: root, settingsContext: context,
      retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  function acquireBattery(path) {
    if (!_batterySources.has(path)) _batterySources.set(path, batteryFactory.createObject(root, {devicePath: path}));
    const source = _batterySources.get(path);
    source.subscribers++;
    return source;
  }
  function releaseBattery(source) {
    if (!source || !source.active) return;
    source.subscribers--;
    if (source.subscribers === 0) {
      _batterySources.delete(source.devicePath);
      source.active = false;
      source.destroy();
    }
  }
  function updatePowerProfile() { if (!profileGetter.running) profileGetter.running = true; }
  function setPowerProfile(profile, context) {
    context = context || pluginApi?.settingsContext;
    if (!context || !context.current()) return;
    profileSetter.command = ["powerprofilesctl", "set", profile];
    profileSetter.running = true;
    currentProfile = profile;
  }
  Process {
    id: profileGetter
    command: ["powerprofilesctl", "get"]
    stdout: SplitParser { onRead: data => root.currentProfile = data.trim() }
  }
  Process { id: profileSetter }
  Component.onCompleted: updatePowerProfile()
}
