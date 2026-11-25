import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var platform: pluginApi?.field("platform")
  readonly property var repo: pluginApi?.field("repo")
  readonly property var group: pluginApi?.field("group")
  readonly property var interval: pluginApi?.field("refreshInterval")
  readonly property bool settingsDirty: false
  spacing: Style.marginL
  NPluginSettingsField {
    field: root.platform
    NComboBox {
      Layout.fillWidth: true
      currentKey: root.platform?.value ?? ""
      description: root.pluginApi?.tr("settings.platform.desc")
      label: root.pluginApi?.tr("settings.platform.label")
      model: [
        {
          key: "github",
          name: "GitHub"
        },
        {
          key: "gitlab",
          name: "GitLab"
        }
      ]
      onSelected: key => root.platform.set(key)
    }
  }
  NPluginSettingsField {
    field: root.repo
    NTextInput {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.repo.label")
      description: root.pluginApi?.tr("settings.repo.desc")
      placeholderText: "owner/repo"
      text: root.repo?.value ?? ""
      onEditCommitted: root.repo.set(text)
    }
  }
  NPluginSettingsField {
    field: root.group
    NTextInput {
      Layout.fillWidth: true
      label: root.pluginApi?.tr(root.platform?.value === "gitlab" ? "settings.group.label" : "settings.org.label")
      description: root.pluginApi?.tr(root.platform?.value === "gitlab" ? "settings.group.desc" : "settings.org.desc")
      placeholderText: root.platform?.value === "gitlab" ? "my-group" : "my-org"
      text: root.group?.value ?? ""
      onEditCommitted: root.group.set(text)
    }
  }
  NPluginSettingsField {
    field: root.interval
    NSpinBox {
      Layout.fillWidth: true
      description: root.pluginApi?.tr("settings.refreshInterval.desc")
      label: root.pluginApi?.tr("settings.refreshInterval.label")
      stepSize: 1
      from: 30
      to: 90
      value: root.interval?.value ?? 60
      requestValue: value => root.interval.set(value)
    }
  }
  function saveSettings() {
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("Git Companion", "Settings saved successfully");
    });
  }
}
