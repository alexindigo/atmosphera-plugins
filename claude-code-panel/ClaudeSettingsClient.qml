import QtQuick

Item {
  id: client
  required property var settingsContext
  required property var owner
  required property var retire
  readonly property bool current: settingsContext.current()
  readonly property var cfg: settingsContext.settingsView
  readonly property var claudeSettings: cfg.claude || ({})
  readonly property string workingDir: claudeSettings.workingDir || ""
  readonly property string permissionMode: claudeSettings.permissionMode || "default"
  readonly property bool dangerouslySkip: claudeSettings.dangerouslySkipPermissions === true
  readonly property real maxHistoryLength: cfg.maxHistoryLength || 200
  readonly property string identity: JSON.stringify(claudeSettings)
  function capture() {
    // Owned immutable action inputs, never a preference store or writer.
    return current ? Object.freeze({context: settingsContext, identity: identity,
      claude: Object.freeze(JSON.parse(JSON.stringify(claudeSettings))),
      workingDir: workingDir, maxHistoryLength: maxHistoryLength}) : null;
  }
  property bool _constructed: false
  onIdentityChanged: if (_constructed) owner.retireRequests(client)
  onCurrentChanged: if (!current && _constructed) retire(client)
  Component.onCompleted: _constructed = true
}
