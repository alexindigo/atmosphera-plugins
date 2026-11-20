import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var username: pluginApi?.field("username")
  readonly property var token: pluginApi?.field("token")
  readonly property var layout: pluginApi?.field("layout")
  readonly property var weeks: pluginApi?.field("weeksShown")
  readonly property var interval: pluginApi?.field("refreshInterval")
  readonly property var total: pluginApi?.field("showTotal")
  readonly property var labels: pluginApi?.field("showLabels")
  readonly property bool settingsDirty: false
  spacing: Style.marginM
  NPluginSettingsField {
    field: root.username
    NTextInput {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.username.label")
      description: root.pluginApi?.tr("settings.username.desc")
      placeholderText: "octocat"
      text: root.username?.value ?? ""
      onEditCommitted: root.username.set(text.trim())
    }
  }
  NPluginSettingsField {
    field: root.token
    NTextInput {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.token.label")
      description: root.pluginApi?.tr("settings.token.desc")
      placeholderText: "ghp_xxxxxxxxxxxx"
      text: root.token?.value ?? ""
      onEditCommitted: root.token.set(text.trim())
    }
  }
  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }
  NPluginSettingsField {
    field: root.layout
    NComboBox {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.layout.label")
      description: root.pluginApi?.tr("settings.layout.desc")
      model: [
        {
          key: "graph",
          name: root.pluginApi?.tr("settings.layout.graph")
        },
        {
          key: "stats",
          name: root.pluginApi?.tr("settings.layout.stats")
        }
      ]
      currentKey: root.layout?.value ?? "graph"
      onSelected: key => root.layout.set(key)
    }
  }
  NPluginSettingsField {
    field: root.weeks
    NLabel {
      label: root.pluginApi?.tr("settings.weeksShown.label")
      description: root.pluginApi?.tr("settings.weeksShown.desc", {
                                        count: root.weeks?.value ?? 52
                                      })
    }
    NSlider {
      Layout.fillWidth: true
      from: 4
      to: 53
      stepSize: 1
      value: root.weeks?.value ?? 52
      onMoved: root.weeks.set(value)
    }
  }
  NPluginSettingsField {
    field: root.interval
    NLabel {
      label: root.pluginApi?.tr("settings.refreshInterval.label")
      description: root.pluginApi?.tr("settings.refreshInterval.desc", {
                                        count: root.interval?.value ?? 60
                                      })
    }
    NSlider {
      Layout.fillWidth: true
      from: 15
      to: 360
      stepSize: 15
      value: root.interval?.value ?? 60
      onMoved: root.interval.set(value)
    }
  }
  NPluginSettingsField {
    field: root.total
    NToggle {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.showTotal.label")
      description: root.pluginApi?.tr("settings.showTotal.desc")
      checked: root.total?.value ?? true
      onToggled: checked => root.total.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.labels
    NToggle {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.showLabels.label")
      description: root.pluginApi?.tr("settings.showLabels.desc")
      checked: root.labels?.value ?? true
      onToggled: checked => root.labels.set(checked)
    }
  }
  function saveSettings() {
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        root.pluginApi.mainInstance?.settingsConsumerFor(root.pluginApi.runtimeContext)?.refresh();
    });
  }
}
