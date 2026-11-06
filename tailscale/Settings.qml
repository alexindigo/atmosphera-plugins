import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  // Local state - initialized from saved settings or defaults
  property int editRefreshInterval: displayBaseline.project("editRefreshInterval")
  property bool editCompactMode: displayBaseline.editCompactMode
  property bool editShowIpAddress: displayBaseline.editShowIpAddress
  property bool editShowPeerCount: displayBaseline.editShowPeerCount
  property bool editHideDisconnected: displayBaseline.editHideDisconnected
  property bool editHideMullvadExitNodes: displayBaseline.editHideMullvadExitNodes
  property bool editShowSearchBar: displayBaseline.editShowSearchBar
  property string editTerminalCommand: displayBaseline.editTerminalCommand
  property string editSshUsername: displayBaseline.editSshUsername
  property int editPingCount: displayBaseline.project("editPingCount")
  property string editDefaultPeerAction: displayBaseline.editDefaultPeerAction
  property bool editTaildropEnabled: displayBaseline.editTaildropEnabled
  property string editTaildropDownloadDir: displayBaseline.editTaildropDownloadDir
  property string editTaildropReceiveMode: displayBaseline.editTaildropReceiveMode
  property string editLoginServer: displayBaseline.editLoginServer
  NSettingsBaseline {
    ranges: [NSettingsRange { field: "editRefreshInterval"; from: rangeEditRefreshInterval.from; to: rangeEditRefreshInterval.to }, NSettingsRange { field: "editPingCount"; from: rangeEditPingCount.from; to: rangeEditPingCount.to }]
    id: displayBaseline
    readonly property int editRefreshInterval: pluginApi?.pluginSettings?.refreshInterval || pluginApi?.manifest?.metadata?.defaultSettings?.refreshInterval || 5000
    readonly property bool editCompactMode: pluginApi?.pluginSettings?.compactMode ?? pluginApi?.manifest?.metadata?.defaultSettings?.compactMode ?? false
    readonly property bool editShowIpAddress: pluginApi?.pluginSettings?.showIpAddress ?? pluginApi?.manifest?.metadata?.defaultSettings?.showIpAddress ?? true
    readonly property bool editShowPeerCount: pluginApi?.pluginSettings?.showPeerCount ?? pluginApi?.manifest?.metadata?.defaultSettings?.showPeerCount ?? true
    readonly property bool editHideDisconnected: pluginApi?.pluginSettings?.hideDisconnected ?? pluginApi?.manifest?.metadata?.defaultSettings?.hideDisconnected ?? false
    readonly property bool editHideMullvadExitNodes: pluginApi?.pluginSettings?.hideMullvadExitNodes ?? pluginApi?.manifest?.metadata?.defaultSettings?.hideMullvadExitNodes ?? true
    readonly property bool editShowSearchBar: pluginApi?.pluginSettings?.showSearchBar ?? pluginApi?.manifest?.metadata?.defaultSettings?.showSearchBar ?? false
    readonly property string editTerminalCommand: pluginApi?.pluginSettings?.terminalCommand || pluginApi?.manifest?.metadata?.defaultSettings?.terminalCommand || ""
    readonly property string editSshUsername: pluginApi?.pluginSettings?.sshUsername || pluginApi?.manifest?.metadata?.defaultSettings?.sshUsername || ""
    readonly property int editPingCount: pluginApi?.pluginSettings?.pingCount || pluginApi?.manifest?.metadata?.defaultSettings?.pingCount || 5
    readonly property string editDefaultPeerAction: pluginApi?.pluginSettings?.defaultPeerAction || pluginApi?.manifest?.metadata?.defaultSettings?.defaultPeerAction || "copy-ip"
    readonly property bool editTaildropEnabled: pluginApi?.pluginSettings?.taildropEnabled ?? pluginApi?.manifest?.metadata?.defaultSettings?.taildropEnabled ?? true
    readonly property string editTaildropDownloadDir: pluginApi?.pluginSettings?.taildropDownloadDir || pluginApi?.manifest?.metadata?.defaultSettings?.taildropDownloadDir || "~/Downloads"
    readonly property string editTaildropReceiveMode: pluginApi?.pluginSettings?.taildropReceiveMode || pluginApi?.manifest?.metadata?.defaultSettings?.taildropReceiveMode || "operator"
    readonly property string editLoginServer: pluginApi?.pluginSettings?.loginServer || pluginApi?.manifest?.metadata?.defaultSettings?.loginServer || ""
  }
  readonly property bool settingsDirty: displayBaseline.differs({editRefreshInterval: root.editRefreshInterval, editCompactMode: root.editCompactMode, editShowIpAddress: root.editShowIpAddress, editShowPeerCount: root.editShowPeerCount, editHideDisconnected: root.editHideDisconnected, editHideMullvadExitNodes: root.editHideMullvadExitNodes, editShowSearchBar: root.editShowSearchBar, editTerminalCommand: root.editTerminalCommand, editSshUsername: root.editSshUsername, editPingCount: root.editPingCount, editDefaultPeerAction: root.editDefaultPeerAction, editTaildropEnabled: root.editTaildropEnabled, editTaildropDownloadDir: root.editTaildropDownloadDir, editTaildropReceiveMode: root.editTaildropReceiveMode, editLoginServer: root.editLoginServer})

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

  // Display options section
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.display-options")
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.compact-mode")
    description: pluginApi?.tr("settings.compact-mode-desc")
    checked: root.editCompactMode
    onToggled: checked => {
      root.editCompactMode = checked
      if (checked) {
        root.editShowIpAddress = false
        root.editShowPeerCount = false
      }
    }
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.show-ip")
    description: pluginApi?.tr("settings.show-ip-desc")
    checked: root.editShowIpAddress
    enabled: !root.editCompactMode
    onToggled: checked => {
      root.editShowIpAddress = checked
      if (checked) {
        root.editCompactMode = false
      } else if (!checked && !root.editShowPeerCount) {
        root.editCompactMode = true
      }
    }
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.show-peers")
    description: pluginApi?.tr("settings.show-peers-desc")
    checked: root.editShowPeerCount
    enabled: !root.editCompactMode
    onToggled: checked => {
      root.editShowPeerCount = checked
      if (checked) {
        root.editCompactMode = false
      } else if (!checked && !root.editShowIpAddress) {
        root.editCompactMode = true
      }
    }
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.show-search-bar")
    description: pluginApi?.tr("settings.show-search-bar-desc")
    checked: root.editShowSearchBar
    onToggled: checked => root.editShowSearchBar = checked
  }


  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.hide-disconnected")
    description: pluginApi?.tr("settings.hide-disconnected-desc")
    checked: root.editHideDisconnected
    onToggled: checked => root.editHideDisconnected = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.hide-mullvad-exit-nodes")
    description: pluginApi?.tr("settings.hide-mullvad-exit-nodes-desc")
    checked: root.editHideMullvadExitNodes
    onToggled: checked => root.editHideMullvadExitNodes = checked
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

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.login-server")
    description: pluginApi?.tr("settings.login-server-desc")
    placeholderText: "https://login.tailscale.com"
    text: root.editLoginServer
    onTextChanged: root.editLoginServer = text
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

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.terminal-command")
    description: pluginApi?.tr("settings.terminal-command-desc")
    placeholderText: "ghostty"
    text: root.editTerminalCommand
    onTextChanged: root.editTerminalCommand = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.ssh-username")
    description: pluginApi?.tr("settings.ssh-username-desc")
    placeholderText: pluginApi?.tr("settings.ssh-username-placeholder")
    text: root.editSshUsername
    onTextChanged: root.editSshUsername = text
  }

  NLabel {
    label: pluginApi?.tr("settings.ping-count")
    description: pluginApi?.tr("settings.ping-count-desc") + " (" + root.editPingCount + ")"
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

  // Peer action section
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.peer-action")
  }

  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.default-peer-action")
    description: pluginApi?.tr("settings.default-peer-action-desc")

    model: [
      { key: "copy-ip", name: pluginApi?.tr("context.copy-ip") },
      { key: "ssh", name: pluginApi?.tr("context.ssh") },
      { key: "ping", name: pluginApi?.tr("context.ping") }
    ]

    currentKey: root.editDefaultPeerAction
    onSelected: key => root.editDefaultPeerAction = key
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

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.taildrop-enabled")
    description: pluginApi?.tr("settings.taildrop-enabled-desc")
    checked: root.editTaildropEnabled
    onToggled: checked => root.editTaildropEnabled = checked
  }

  NTextInput {
    Layout.fillWidth: true
    enabled: root.editTaildropEnabled
    label: pluginApi?.tr("settings.taildrop-download-dir")
    description: pluginApi?.tr("settings.taildrop-download-dir-desc")
    placeholderText: "~/Downloads"
    text: root.editTaildropDownloadDir
    onTextChanged: root.editTaildropDownloadDir = text
  }

  NComboBox {
    Layout.fillWidth: true
    enabled: root.editTaildropEnabled
    label: pluginApi?.tr("settings.taildrop-receive-mode")
    description: pluginApi?.tr("settings.taildrop-receive-mode-desc")
    model: [
      { key: "operator", name: pluginApi?.tr("settings.taildrop-receive-mode-operator") },
      { key: "pkexec",   name: pluginApi?.tr("settings.taildrop-receive-mode-pkexec") }
    ]
    currentKey: root.editTaildropReceiveMode
    onSelected: key => root.editTaildropReceiveMode = key
  }

  // Save function - called by the dialog
  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Tailscale", "Cannot save: pluginApi is null")
      return
    }

    pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval
    pluginApi.pluginSettings.compactMode = root.editCompactMode
    pluginApi.pluginSettings.showIpAddress = root.editShowIpAddress
    pluginApi.pluginSettings.showPeerCount = root.editShowPeerCount
    pluginApi.pluginSettings.hideDisconnected = root.editHideDisconnected
    pluginApi.pluginSettings.hideMullvadExitNodes = root.editHideMullvadExitNodes
    pluginApi.pluginSettings.showSearchBar = root.editShowSearchBar
    pluginApi.pluginSettings.terminalCommand = root.editTerminalCommand
    pluginApi.pluginSettings.sshUsername = root.editSshUsername
    pluginApi.pluginSettings.pingCount = root.editPingCount
    pluginApi.pluginSettings.defaultPeerAction = root.editDefaultPeerAction
    pluginApi.pluginSettings.taildropEnabled = root.editTaildropEnabled
    pluginApi.pluginSettings.taildropDownloadDir = root.editTaildropDownloadDir
    pluginApi.pluginSettings.taildropReceiveMode = root.editTaildropReceiveMode
    pluginApi.pluginSettings.loginServer = root.editLoginServer

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("Tailscale", "Settings saved successfully")
    })
  }
}
