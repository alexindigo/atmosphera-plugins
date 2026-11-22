import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _savePending: false
  property bool _syncPending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._savePending = false;
      var sync = root._syncPending;
      root._syncPending = false;
      ToastService.showNotice(root.pluginApi?.tr("settings.saved"));
      if (sync)
        root.mainInstance?.manualSync();
    }
  }

  property var pluginApi: null
  readonly property bool sharedScope: pluginApi?.scopeKind === "plugin"
  readonly property var syncEnabledField: pluginApi?.field("syncEnabled") ?? null
  readonly property var githubTokenField: pluginApi?.field("githubToken") ?? null

  property var mainInstance: pluginApi?.mainInstance || null

  readonly property bool valueSyncEnabled: root.syncEnabledField?.value ?? false
  readonly property string valueGithubToken: root.githubTokenField?.value ?? ""

  spacing: Style.marginL

  NText {
    Layout.fillWidth: true
    visible: !root.sharedScope
    text: root.pluginApi?.tr("settings.sharedEffect")
    wrapMode: Text.Wrap
  }

  NPluginSettingsField {
    field: root.syncEnabledField
    enabled: root.sharedScope
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.syncEnabled.label")
      description: pluginApi?.tr("settings.syncEnabled.desc")
      checked: root.valueSyncEnabled
      onToggled: checked => { if (root.sharedScope) root.syncEnabledField.set(checked); }
    }
  }

  NPluginSettingsField {
    field: root.githubTokenField
    enabled: root.sharedScope
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.githubToken.label")
      description: pluginApi?.tr("settings.githubToken.desc")
      placeholderText: pluginApi?.tr("settings.githubToken.placeholder")
      text: root.valueGithubToken
      onEditCommitted: { if (root.sharedScope) root.githubTokenField.set(text.trim()); }
    }
  }

  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.githubToken.help")
    pointSize: Style.fontSizeS
    color: AtmoColor.mOnSurfaceVariant
    wrapMode: Text.Wrap
    textFormat: Text.MarkdownText
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NButton {
      text: pluginApi?.tr("settings.syncNow")
      icon: "refresh"
      enabled: !mainInstance?.syncInProgress
      onClicked: root.requestSync()
    }

    Item {
      Layout.fillWidth: true
    }

    NText {
      text: {
        if (mainInstance?.syncInProgress) {
          return pluginApi?.tr("sync.syncing");
        }
        return mainInstance?.lastSyncMessage || "";
      }
      color: mainInstance?.lastSyncOk ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
      pointSize: Style.fontSizeS
      wrapMode: Text.Wrap
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignRight
    }
  }

  function requestSync() {
    root._syncPending = true;
  }

  function saveSettings() {
    if (!pluginApi) {
      return;
    }

    if (pluginApi.saveSettings() !== false)
      root._savePending = true;
  }
}
