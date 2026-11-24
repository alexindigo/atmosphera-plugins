import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root

  NSettingsBaseline {
    id: displayBaseline
    readonly property bool valueSyncEnabled: cfg.syncEnabled ?? defaults.syncEnabled ?? false
    readonly property string valueGithubToken: cfg.githubToken ?? defaults.githubToken ?? ""
  }
  readonly property bool settingsDirty: { return displayBaseline.differs({valueSyncEnabled: root.valueSyncEnabled, valueGithubToken: root.valueGithubToken}); }
  property bool _savePending: false
  property bool _syncPending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current") return;
      root._savePending = false;
      var sync = root._syncPending; root._syncPending = false;
      ToastService.showNotice(root.pluginApi?.tr("settings.saved"));
      if (sync) root.mainInstance?.manualSync();
    }
  }

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property var mainInstance: pluginApi?.mainInstance || null

  property bool valueSyncEnabled: displayBaseline.valueSyncEnabled
  property string valueGithubToken: displayBaseline.valueGithubToken

  spacing: Style.marginL

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.syncEnabled.label")
    description: pluginApi?.tr("settings.syncEnabled.desc")
    checked: root.valueSyncEnabled
    onToggled: checked => root.valueSyncEnabled = checked
  }

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.githubToken.label")
    description: pluginApi?.tr("settings.githubToken.desc")
    placeholderText: pluginApi?.tr("settings.githubToken.placeholder")
    text: root.valueGithubToken
    onTextChanged: root.valueGithubToken = text
  }

  NImageText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.githubToken.help")
    pointSize: Style.fontSizeS
    color: AtmoColor.mOnSurfaceVariant
    wrapMode: Text.Wrap
    format: "markdown"
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

    Item { Layout.fillWidth: true }

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
    root.saveSettings();
  }

  function saveSettings() {
    if (!pluginApi) {
      return;
    }

    pluginApi.pluginSettings.syncEnabled = root.valueSyncEnabled;
    root.valueGithubToken = root.valueGithubToken.trim();
    pluginApi.pluginSettings.githubToken = root.valueGithubToken;
    if (pluginApi.saveSettings() !== false) root._savePending = true;
  }
}
