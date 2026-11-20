import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var compactModeField: pluginApi?.field("compactMode") ?? null
  readonly property var showIpAddressField: pluginApi?.field("showIpAddress") ?? null
  readonly property var showPeerCountField: pluginApi?.field("showPeerCount") ?? null
  readonly property var hideDisconnectedField: pluginApi?.field("hideDisconnected") ?? null
  readonly property var hideMullvadExitNodesField: pluginApi?.field("hideMullvadExitNodes") ?? null
  readonly property var showSearchBarField: pluginApi?.field("showSearchBar") ?? null
  readonly property var terminalCommandField: pluginApi?.field("terminalCommand") ?? null
  readonly property var sshUsernameField: pluginApi?.field("sshUsername") ?? null
  readonly property var pingCountField: pluginApi?.field("pingCount") ?? null
  readonly property var defaultPeerActionField: pluginApi?.field("defaultPeerAction") ?? null
  readonly property var taildropEnabledField: pluginApi?.field("taildropEnabled") ?? null
  readonly property var taildropDownloadDirField: pluginApi?.field("taildropDownloadDir") ?? null
  readonly property var taildropReceiveModeField: pluginApi?.field("taildropReceiveMode") ?? null
  readonly property var loginServerField: pluginApi?.field("loginServer") ?? null

  // Local state - initialized from saved settings or defaults
  readonly property int editRefreshInterval: root.refreshIntervalField?.value || 5000
  readonly property bool editCompactMode: root.compactModeField?.value ?? false
  readonly property bool editShowIpAddress: root.showIpAddressField?.value ?? true
  readonly property bool editShowPeerCount: root.showPeerCountField?.value ?? true
  readonly property bool editHideDisconnected: root.hideDisconnectedField?.value ?? false
  readonly property bool editHideMullvadExitNodes: root.hideMullvadExitNodesField?.value ?? true
  readonly property bool editShowSearchBar: root.showSearchBarField?.value ?? false
  readonly property string editTerminalCommand: root.terminalCommandField?.value || ""
  readonly property string editSshUsername: root.sshUsernameField?.value || ""
  readonly property int editPingCount: root.pingCountField?.value || 5
  readonly property string editDefaultPeerAction: root.defaultPeerActionField?.value || "copy-ip"
  readonly property bool editTaildropEnabled: root.taildropEnabledField?.value ?? true
  readonly property string editTaildropDownloadDir: root.taildropDownloadDirField?.value || "~/Downloads"
  readonly property string editTaildropReceiveMode: root.taildropReceiveModeField?.value || "operator"
  readonly property string editLoginServer: root.loginServerField?.value || ""
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  // Title section
  NText {
    text: pluginApi?.tr("settings.title")
    font.pointSize: Style.fontSizeXL
    font.bold: true
  }

  NText {
    text: pluginApi?.tr("settings.description")
    color: AtmoColor.mSecondary
    Layout.fillWidth: true
    wrapMode: Text.Wrap
  }

  // Refresh interval section
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.refresh-interval")
    description: pluginApi?.tr("settings.refresh-interval-desc") + " (" + root.editRefreshInterval + " ms)"
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

  // Display options section
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.display-options")
  }

  NPluginSettingsField {
    field: root.compactModeField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.compact-mode")
      description: pluginApi?.tr("settings.compact-mode-desc")
      checked: root.editCompactMode
      onToggled: checked => {
        root.compactModeField.set(checked);
        if (checked) {
          root.showIpAddressField.set(false);
          root.showPeerCountField.set(false);
        }
      }
    }
  }

  NPluginSettingsField {
    field: root.showIpAddressField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-ip")
      description: pluginApi?.tr("settings.show-ip-desc")
      checked: root.editShowIpAddress
      enabled: !root.editCompactMode
      onToggled: checked => {
        root.showIpAddressField.set(checked);
        if (checked) {
          root.compactModeField.set(false);
        } else if (!checked && !root.editShowPeerCount) {
          root.compactModeField.set(true);
        }
      }
    }
  }

  NPluginSettingsField {
    field: root.showPeerCountField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-peers")
      description: pluginApi?.tr("settings.show-peers-desc")
      checked: root.editShowPeerCount
      enabled: !root.editCompactMode
      onToggled: checked => {
        root.showPeerCountField.set(checked);
        if (checked) {
          root.compactModeField.set(false);
        } else if (!checked && !root.editShowIpAddress) {
          root.compactModeField.set(true);
        }
      }
    }
  }

  NPluginSettingsField {
    field: root.showSearchBarField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-search-bar")
      description: pluginApi?.tr("settings.show-search-bar-desc")
      checked: root.editShowSearchBar
      onToggled: checked => root.showSearchBarField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.hideDisconnectedField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.hide-disconnected")
      description: pluginApi?.tr("settings.hide-disconnected-desc")
      checked: root.editHideDisconnected
      onToggled: checked => root.hideDisconnectedField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.hideMullvadExitNodesField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.hide-mullvad-exit-nodes")
      description: pluginApi?.tr("settings.hide-mullvad-exit-nodes-desc")
      checked: root.editHideMullvadExitNodes
      onToggled: checked => root.hideMullvadExitNodesField.set(checked)
    }
  }

  // Authentication section
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.authentication")
  }

  NPluginSettingsField {
    field: root.loginServerField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.login-server")
      description: pluginApi?.tr("settings.login-server-desc")
      placeholderText: "https://login.tailscale.com"
      text: root.editLoginServer
      onEditCommitted: root.loginServerField.set(text)
    }
  }

  // Terminal section
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.terminal")
  }

  NPluginSettingsField {
    field: root.terminalCommandField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.terminal-command")
      description: pluginApi?.tr("settings.terminal-command-desc")
      placeholderText: "ghostty"
      text: root.editTerminalCommand
      onEditCommitted: root.terminalCommandField.set(text)
    }
  }

  NPluginSettingsField {
    field: root.sshUsernameField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.ssh-username")
      description: pluginApi?.tr("settings.ssh-username-desc")
      placeholderText: pluginApi?.tr("settings.ssh-username-placeholder")
      text: root.editSshUsername
      onEditCommitted: root.sshUsernameField.set(text)
    }
  }

  NLabel {
    label: pluginApi?.tr("settings.ping-count")
    description: pluginApi?.tr("settings.ping-count-desc") + " (" + root.editPingCount + ")"
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

  // Peer action section
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.peer-action")
  }

  NPluginSettingsField {
    field: root.defaultPeerActionField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.default-peer-action")
      description: pluginApi?.tr("settings.default-peer-action-desc")

      model: [
        {
          key: "copy-ip",
          name: pluginApi?.tr("context.copy-ip")
        },
        {
          key: "ssh",
          name: pluginApi?.tr("context.ssh")
        },
        {
          key: "ping",
          name: pluginApi?.tr("context.ping")
        }
      ]

      currentKey: root.editDefaultPeerAction
      onSelected: key => root.defaultPeerActionField.set(key)
    }
  }

  // Taildrop section
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.taildrop")
  }

  NPluginSettingsField {
    field: root.taildropEnabledField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.taildrop-enabled")
      description: pluginApi?.tr("settings.taildrop-enabled-desc")
      checked: root.editTaildropEnabled
      onToggled: checked => root.taildropEnabledField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.taildropDownloadDirField
    NTextInput {
      Layout.fillWidth: true
      enabled: root.editTaildropEnabled
      label: pluginApi?.tr("settings.taildrop-download-dir")
      description: pluginApi?.tr("settings.taildrop-download-dir-desc")
      placeholderText: "~/Downloads"
      text: root.editTaildropDownloadDir
      onEditCommitted: root.taildropDownloadDirField.set(text)
    }
  }

  NPluginSettingsField {
    field: root.taildropReceiveModeField
    NComboBox {
      Layout.fillWidth: true
      enabled: root.editTaildropEnabled
      label: pluginApi?.tr("settings.taildrop-receive-mode")
      description: pluginApi?.tr("settings.taildrop-receive-mode-desc")
      model: [
        {
          key: "operator",
          name: pluginApi?.tr("settings.taildrop-receive-mode-operator")
        },
        {
          key: "pkexec",
          name: pluginApi?.tr("settings.taildrop-receive-mode-pkexec")
        }
      ]
      currentKey: root.editTaildropReceiveMode
      onSelected: key => root.taildropReceiveModeField.set(key)
    }
  }

  // Save function - called by the dialog
  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Tailscale", "Cannot save: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("Tailscale", "Settings saved successfully");
    });
  }
}
