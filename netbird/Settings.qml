import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    text: root.pluginApi?.tr("settings.shared-effect") || ""
    wrapMode: Text.WordWrap
    color: AtmoColor.mOnSurfaceVariant
  }
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var compactModeField: pluginApi?.field("compactMode") ?? null
  readonly property var showIpAddressField: pluginApi?.field("showIpAddress") ?? null
  readonly property var hideDisconnectedField: pluginApi?.field("hideDisconnected") ?? null
  readonly property var showPingField: pluginApi?.field("showPing") ?? null
  readonly property var terminalCommandField: pluginApi?.field("terminalCommand") ?? null
  readonly property var managementUrlField: pluginApi?.field("managementUrl") ?? null
  readonly property var pingCountField: pluginApi?.field("pingCount") ?? null
  readonly property var defaultPeerActionField: pluginApi?.field("defaultPeerAction") ?? null

  readonly property int editRefreshInterval: root.refreshIntervalField?.value || 5000

  readonly property bool editCompactMode: root.compactModeField?.value ?? false

  readonly property bool editShowIpAddress: root.showIpAddressField?.value ?? true

  readonly property bool editHideDisconnected: root.hideDisconnectedField?.value ?? false

  readonly property bool editShowPing: root.showPingField?.value ?? false

  readonly property int editPingCount: root.pingCountField?.value || 5

  readonly property string editTerminalCommand: root.terminalCommandField?.value || ""

  readonly property string editManagementUrl: root.managementUrlField?.value ?? ""

  readonly property string editDefaultPeerAction: root.defaultPeerActionField?.value || "copy-ip"

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

  NPluginSettingsField {
    field: root.refreshIntervalField
    NSlider {
      id: rangeEditRefreshInterval
      objectName: "settings-range-editRefreshInterval"
      Layout.fillWidth: true
      from: 1000
      to: 60000
      stepSize: 1000
      value: root.editRefreshInterval
      onMoved: root.refreshIntervalField.set(value)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.display-options") || "Display Options"
  }

  NPluginSettingsField {
    field: root.compactModeField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.compact-mode") || "Compact Mode"
      description: pluginApi?.tr("settings.compact-mode-desc") || "Show only icon in the bar"
      checked: root.editCompactMode
      onToggled: checked => {
        root.compactModeField.set(checked);
        if (checked) {
          root.showIpAddressField.set(false);
        }
      }
    }
  }

  NPluginSettingsField {
    field: root.showIpAddressField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-ip") || "Show IP Address"
      description: pluginApi?.tr("settings.show-ip-desc") || "Display NetBird IP in the bar widget"
      checked: root.editShowIpAddress
      enabled: !root.editCompactMode
      onToggled: checked => {
        root.showIpAddressField.set(checked);
        if (checked) {
          root.compactModeField.set(false);
        } else {
          root.compactModeField.set(true);
        }
      }
    }
  }

  NPluginSettingsField {
    field: root.hideDisconnectedField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.hide-disconnected") || "Hide Disconnected Peers"
      description: pluginApi?.tr("settings.hide-disconnected-desc") || "Only show online peers in the panel"
      checked: root.editHideDisconnected
      onToggled: checked => root.hideDisconnectedField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.showPingField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-ping") || "Show Ping Latency"
      description: pluginApi?.tr("settings.show-ping-desc") || "Ping all connected peers and display latency (ms). Refreshes at the same interval as status."
      checked: root.editShowPing
      onToggled: checked => root.showPingField.set(checked)
    }
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

  NPluginSettingsField {
    field: root.terminalCommandField
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
      onEditCommitted: root.terminalCommandField.set(text)
    }
  }

  NPluginSettingsField {
    field: root.managementUrlField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.management-url")
      description: pluginApi?.tr("settings.management-url-desc")
      placeholderText: pluginApi?.manifest?.metadata?.defaultSettings?.managementUrl
      text: root.editManagementUrl
      onEditCommitted: root.managementUrlField.set(text)
    }
  }

  NLabel {
    label: pluginApi?.tr("settings.ping-count") || "Ping Count"
    description: (pluginApi?.tr("settings.ping-count-desc") || "Number of ping packets to send when testing connectivity") + " (" + root.editPingCount + ")"
  }

  NPluginSettingsField {
    field: root.pingCountField
    NSlider {
      id: rangeEditPingCount
      objectName: "settings-range-editPingCount"
      Layout.fillWidth: true
      from: 1
      to: 20
      stepSize: 1
      value: root.editPingCount
      onMoved: root.pingCountField.set(value)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.peer-action") || "Peer Click Action"
  }

  NPluginSettingsField {
    field: root.defaultPeerActionField
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
      onSelected: key => root.defaultPeerActionField.set(key)
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("NetBird", "Cannot save: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("NetBird", "Settings saved successfully");
    });
  }
}
