import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.Panels.Settings
import qs.Services.Hardware
import qs.Services.UI
import qs.Widgets
import "./Services"

Item {
  id: root

  property var pluginApi: null
  readonly property var settingsConsumer: pluginApi?.mainInstance?.settingsConsumerFor(pluginApi.settingsContext) ?? null

  property ShellScreen screen

  // Widget properties passed from Bar.qml for per-instance settings
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  // Explicit screenName property ensures reactive binding when screen changes
  readonly property string screenName: screen ? screen.name : ""

  implicitWidth: pill.width
  implicitHeight: pill.height
  visible: !hideIfNoDeviceConnected ? true : KDEConnect.anyDevicesConnected;
  opacity: (!hideIfNoDeviceConnected ? true : KDEConnect.anyDevicesConnected) ? 1.0 : 0.0;

  property bool hideIfNoDeviceConnected: settingsConsumer?.hideIfNoDeviceConnected ?? false


  BarPill {
    id: pill

    screen: root.screen
    oppositeDirection: BarService.getPillDirection(root)
    customIconColor: AtmoColor.resolveColorKeyOptional(root.iconColorKey)
    customTextColor: AtmoColor.resolveColorKeyOptional(root.textColorKey)
    icon: KDEConnectUtils.getConnectionStateIcon(root.settingsConsumer?.mainDevice ?? null, KDEConnect.daemonAvailable)
    autoHide: false // Important to be false so we can hover as long as we want
    text: !KDEConnect.daemonAvailable || !root.settingsConsumer?.mainDevice || root.settingsConsumer.mainDevice.battery === -1 ? "" : (root.settingsConsumer.mainDevice.battery + "%")
    tooltipText: pluginApi?.tr("bar.tooltip")
    onClicked: {
      if (pluginApi) {
        pluginApi.openPanel(root.screen, this);
      }
    }
  }
}
