import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    
    property var pluginApi: null

    property int editRefreshInterval: displayBaseline.project("editRefreshInterval")

    property bool editCompactMode: displayBaseline.editCompactMode

    property bool editShowIpAddress: displayBaseline.editShowIpAddress

    property bool editHideDisconnected: displayBaseline.editHideDisconnected

    property bool editShowPing: displayBaseline.editShowPing

    property int editPingCount: displayBaseline.project("editPingCount")

    property string editTerminalCommand: displayBaseline.editTerminalCommand

    property string editManagementUrl: displayBaseline.editManagementUrl

    property string editDefaultPeerAction: displayBaseline.editDefaultPeerAction

    spacing: Style.marginM

    NText {
        text: pluginApi?.tr("settings.title") || "NetBird Settings"
        font.pointSize: Style.fontSizeXL
        font.bold: true
    }

    NText {
        text: pluginApi?.tr("settings.description") || "Configure NetBird VPN status display and behavior"
        color: AtmoColor.mSecondary
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    NLabel {
        label: pluginApi?.tr("settings.refresh-interval") || "Refresh Interval"
        description: (pluginApi?.tr("settings.refresh-interval-desc") || "How often to check NetBird status") + " (" + root.editRefreshInterval + " ms)"
    }

    NSlider {
        id: rangeEditRefreshInterval
        objectName: "settings-range-editRefreshInterval"
        Layout.fillWidth: true
        from: 1000
        to: 60000
        stepSize: 1000
        value: root.editRefreshInterval
        onValueChanged: root.editRefreshInterval = value
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    NLabel {
        label: pluginApi?.tr("settings.display-options") || "Display Options"
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.compact-mode") || "Compact Mode"
        description: pluginApi?.tr("settings.compact-mode-desc") || "Show only icon in the bar"
        checked: root.editCompactMode
        onToggled: checked => {
            root.editCompactMode = checked;
            if (checked) {
                root.editShowIpAddress = false;
            }
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.show-ip") || "Show IP Address"
        description: pluginApi?.tr("settings.show-ip-desc") || "Display NetBird IP in the bar widget"
        checked: root.editShowIpAddress
        enabled: !root.editCompactMode
        onToggled: checked => {
            root.editShowIpAddress = checked;
            if (checked) {
                root.editCompactMode = false;
            } else {
                root.editCompactMode = true;
            }
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.hide-disconnected") || "Hide Disconnected Peers"
        description: pluginApi?.tr("settings.hide-disconnected-desc") || "Only show online peers in the panel"
        checked: root.editHideDisconnected
        onToggled: checked => root.editHideDisconnected = checked
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.show-ping") || "Show Ping Latency"
        description: pluginApi?.tr("settings.show-ping-desc") || "Ping all connected peers and display latency (ms). Refreshes at the same interval as status."
        checked: root.editShowPing
        onToggled: checked => root.editShowPing = checked
    }

    NText {
        visible: root.editShowPing
        Layout.fillWidth: true
        text: "⚠ " + (pluginApi?.tr("settings.show-ping-warning") || "This feature sends ICMP packets to each connected peer at every refresh interval. It may increase network usage and CPU load.")
        pointSize: Style.fontSizeXS
        color: AtmoColor.mError
        wrapMode: Text.Wrap
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.terminal")
        description: pluginApi?.tr("settings.terminal-desc")
        placeholderText: {
            var detected = pluginApi?.mainInstance?.detectedTerminal || "";
            if (detected !== "") {
                return pluginApi?.tr("settings.terminal-detected") + ": " + detected;
            } else {
                return pluginApi?.tr("settings.terminal-none");
            }
        }
        text: root.editTerminalCommand
        onTextChanged: root.editTerminalCommand = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.management-url")
        description: pluginApi?.tr("settings.management-url-desc")
        placeholderText: pluginApi?.manifest?.metadata?.defaultSettings?.managementUrl
        text: root.editManagementUrl
        onTextChanged: root.editManagementUrl = text
    }

    NLabel {
        label: pluginApi?.tr("settings.ping-count") || "Ping Count"
        description: (pluginApi?.tr("settings.ping-count-desc") || "Number of ping packets to send when testing connectivity") + " (" + root.editPingCount + ")"
    }

    NSlider {
        id: rangeEditPingCount
        objectName: "settings-range-editPingCount"
        Layout.fillWidth: true
        from: 1
        to: 20
        stepSize: 1
        value: root.editPingCount
        onValueChanged: root.editPingCount = value
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    NLabel {
        label: pluginApi?.tr("settings.peer-action") || "Peer Click Action"
    }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.default-peer-action") || "Default Action"
        description: pluginApi?.tr("settings.default-peer-action-desc") || "Action when clicking on a peer in the panel"

        model: [
            {
                key: "copy-ip",
                name: pluginApi?.tr("context.copy-ip") || "Copy IP"
            },
            {
                key: "ssh",
                name: pluginApi?.tr("context.ssh") || "SSH to host"
            },
            {
                key: "ping",
                name: pluginApi?.tr("context.ping") || "Ping host"
            }
        ]

        currentKey: root.editDefaultPeerAction
        onSelected: key => root.editDefaultPeerAction = key
    }

    NSettingsBaseline {
      ranges: [NSettingsRange { field: "editRefreshInterval"; from: rangeEditRefreshInterval.from; to: rangeEditRefreshInterval.to }, NSettingsRange { field: "editPingCount"; from: rangeEditPingCount.from; to: rangeEditPingCount.to }]
      id: displayBaseline
      readonly property int editRefreshInterval: pluginApi?.pluginSettings?.refreshInterval || pluginApi?.manifest?.metadata?.defaultSettings?.refreshInterval || 5000
      readonly property bool editCompactMode: pluginApi?.pluginSettings?.compactMode ?? pluginApi?.manifest?.metadata?.defaultSettings?.compactMode ?? false
      readonly property bool editShowIpAddress: pluginApi?.pluginSettings?.showIpAddress ?? pluginApi?.manifest?.metadata?.defaultSettings?.showIpAddress ?? true
      readonly property bool editHideDisconnected: pluginApi?.pluginSettings?.hideDisconnected ?? pluginApi?.manifest?.metadata?.defaultSettings?.hideDisconnected ?? false
      readonly property bool editShowPing: pluginApi?.pluginSettings?.showPing ?? pluginApi?.manifest?.metadata?.defaultSettings?.showPing ?? false
      readonly property string editTerminalCommand: pluginApi?.pluginSettings?.terminalCommand || pluginApi?.manifest?.metadata?.defaultSettings?.terminalCommand || ""
      readonly property string editManagementUrl: pluginApi?.pluginSettings?.managementUrl ?? pluginApi?.manifest?.metadata?.defaultSettings?.managementUrl ?? ""
      readonly property int editPingCount: pluginApi?.pluginSettings?.pingCount || pluginApi?.manifest?.metadata?.defaultSettings?.pingCount || 5
      readonly property string editDefaultPeerAction: pluginApi?.pluginSettings?.defaultPeerAction || pluginApi?.manifest?.metadata?.defaultSettings?.defaultPeerAction || "copy-ip"
    }
    readonly property bool settingsDirty: displayBaseline.differs({editRefreshInterval: root.editRefreshInterval, editCompactMode: root.editCompactMode, editShowIpAddress: root.editShowIpAddress, editHideDisconnected: root.editHideDisconnected, editShowPing: root.editShowPing, editTerminalCommand: root.editTerminalCommand, editManagementUrl: root.editManagementUrl, editPingCount: root.editPingCount, editDefaultPeerAction: root.editDefaultPeerAction})

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("NetBird", "Cannot save: pluginApi is null");
            return;
        }

        pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval;
        pluginApi.pluginSettings.compactMode = root.editCompactMode;
        pluginApi.pluginSettings.showIpAddress = root.editShowIpAddress;
        pluginApi.pluginSettings.hideDisconnected = root.editHideDisconnected;
        pluginApi.pluginSettings.showPing = root.editShowPing;
        pluginApi.pluginSettings.terminalCommand = root.editTerminalCommand;
        pluginApi.pluginSettings.managementUrl = root.editManagementUrl;
        pluginApi.pluginSettings.pingCount = root.editPingCount;
        pluginApi.pluginSettings.defaultPeerAction = root.editDefaultPeerAction;

        pluginApi.saveSettings(function (result) {
            if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
                Logger.i("NetBird", "Settings saved successfully");
        });
    }
}
