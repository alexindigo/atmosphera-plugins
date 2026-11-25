import QtQuick
import Quickshell
import qs.Widgets
import "./Services"

AtmoIconButtonHot {
    property ShellScreen screen
    property var pluginApi: null
    readonly property var settingsConsumer: pluginApi?.mainInstance?.settingsConsumerFor(pluginApi.settingsContext) ?? null

    function getTooltip(device) {
        const batteryLabel = pluginApi?.tr("panel.card.battery") || "Battery";
        const stateLabel = pluginApi?.tr("control_center.state-label") || "State";

        const batteryLine = (device !== null && device.reachable && device.paired && device.battery !== -1) ? (batteryLabel + ": " + device.battery + "%\n") : "";

        const stateKey = KDEConnectUtils.getConnectionStateKey(device, KDEConnect.daemonAvailable);
        const stateValue = pluginApi?.tr(stateKey) || "Unknown";
        const stateLine = stateLabel + ": " + stateValue;

        return batteryLine + stateLine;
    }

    icon: KDEConnectUtils.getConnectionStateIcon(settingsConsumer?.mainDevice ?? null, KDEConnect.daemonAvailable)
    tooltipText: getTooltip(settingsConsumer?.mainDevice ?? null)

    onClicked: pluginApi?.togglePanel(screen, this)
}
