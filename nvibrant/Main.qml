import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var pluginApi: null

  readonly property var cfg: pluginApi?.pluginSettings ?? ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})

  readonly property bool vibrantEnabled: cfg.enabled ?? defaults.enabled ?? false
  readonly property int vibranceValue: cfg.vibranceValue ?? defaults.vibranceValue ?? 512
  // stored 1-based (1 = port 0), converted on use
  readonly property int displayIndex: (cfg.displayIndex ?? defaults.displayIndex ?? 1) - 1

  // Preserve the old typed QML int admission before building literal argv.
  property int admittedDisplayIndex: 0
  property int admittedVibranceValue: 0

  function buildCmd(value, display) {
    var parts = ["nvibrant"];
    for (var i = 0; i < display; i++)
      parts.push("0");
    parts.push(value.toString());
    return parts;
  }

  function applyVibrance(value, context) {
    context = context || pluginApi?.settingsContext;
    if (!context?.current())
      return false;
    admittedDisplayIndex = (context.settingsView.displayIndex ?? defaults.displayIndex ?? 1) - 1;
    admittedVibranceValue = value;
    Quickshell.execDetached(buildCmd(admittedVibranceValue, admittedDisplayIndex));
    return true;
  }

  function toggle(runtimeApi) {
    runtimeApi = runtimeApi || pluginApi;
    const context = runtimeApi?.settingsContext;
    if (!context?.current())
      return false;
    const selected = context.settingsView;
    const newEnabled = !(selected.enabled ?? defaults.enabled ?? false);
    const value = selected.vibranceValue ?? defaults.vibranceValue ?? 512;
    runtimeApi.pluginSettings.enabled = newEnabled;
    runtimeApi.saveSettings();
    return applyVibrance(newEnabled ? value : 0, context);
  }

  IpcHandler {
    target: "plugin:nvibrant"
    function toggle() {
      root.toggle();
    }
  }
}
