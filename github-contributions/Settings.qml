import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  property string editUsername: displayBaseline.editUsername
  property string editToken: displayBaseline.editToken
  property string editLayout: displayBaseline.editLayout
  property int editWeeksShown: displayBaseline.editWeeksShown
  property int editRefreshInterval: displayBaseline.editRefreshInterval
  property bool editShowTotal: displayBaseline.editShowTotal
  property bool editShowLabels: displayBaseline.editShowLabels
  property bool _applyEffectPending: false
  NSettingsBaseline {
    id: displayBaseline
    readonly property string editUsername: pluginApi?.pluginSettings?.username || pluginApi?.manifest?.metadata?.defaultSettings?.username || ""
    readonly property string editToken: pluginApi?.pluginSettings?.token || pluginApi?.manifest?.metadata?.defaultSettings?.token || ""
    readonly property string editLayout: pluginApi?.pluginSettings?.layout || pluginApi?.manifest?.metadata?.defaultSettings?.layout || "graph"
    readonly property int editWeeksShown: pluginApi?.pluginSettings?.weeksShown ?? pluginApi?.manifest?.metadata?.defaultSettings?.weeksShown ?? 52
    readonly property int editRefreshInterval: pluginApi?.pluginSettings?.refreshInterval ?? pluginApi?.manifest?.metadata?.defaultSettings?.refreshInterval ?? 60
    readonly property bool editShowTotal: pluginApi?.pluginSettings?.showTotal ?? pluginApi?.manifest?.metadata?.defaultSettings?.showTotal ?? true
    readonly property bool editShowLabels: pluginApi?.pluginSettings?.showLabels ?? pluginApi?.manifest?.metadata?.defaultSettings?.showLabels ?? true
  }
  readonly property bool settingsDirty: displayBaseline.differs({editUsername: root.editUsername, editToken: root.editToken, editLayout: root.editLayout, editWeeksShown: root.editWeeksShown, editRefreshInterval: root.editRefreshInterval, editShowTotal: root.editShowTotal, editShowLabels: root.editShowLabels})
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current") return;
      root._applyEffectPending = false;
      root.pluginApi.mainInstance?.refresh();
    }
  }

  spacing: Style.marginM

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.username.label")
    description: pluginApi?.tr("settings.username.desc")
    placeholderText: "octocat"
    text: root.editUsername
    onTextChanged: root.editUsername = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.token.label")
    description: pluginApi?.tr("settings.token.desc")
    placeholderText: "ghp_xxxxxxxxxxxx"
    text: root.editToken
    onTextChanged: root.editToken = text
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.layout.label")
    description: pluginApi?.tr("settings.layout.desc")
    model: [
      { key: "graph", name: pluginApi?.tr("settings.layout.graph") },
      { key: "stats", name: pluginApi?.tr("settings.layout.stats") }
    ]
    currentKey: root.editLayout
    onSelected: key => root.editLayout = key
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.weeksShown.label")
      description: pluginApi?.tr("settings.weeksShown.desc", { "count": root.editWeeksShown })
    }

    NSlider {
      Layout.fillWidth: true
      from: 4
      to: 53
      stepSize: 1
      value: root.editWeeksShown
      onValueChanged: root.editWeeksShown = value
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.refreshInterval.label")
      description: pluginApi?.tr("settings.refreshInterval.desc", { "count": root.editRefreshInterval })
    }

    NSlider {
      Layout.fillWidth: true
      from: 15
      to: 360
      stepSize: 15
      value: root.editRefreshInterval
      onValueChanged: root.editRefreshInterval = value
    }
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.showTotal.label")
    description: pluginApi?.tr("settings.showTotal.desc")
    checked: root.editShowTotal
    onToggled: checked => root.editShowTotal = checked
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.showLabels.label")
    description: pluginApi?.tr("settings.showLabels.desc")
    checked: root.editShowLabels
    onToggled: checked => root.editShowLabels = checked
  }

  function saveSettings() {
    if (!pluginApi) return

    root.editUsername = root.editUsername.trim()
    root.editToken = root.editToken.trim()
    pluginApi.pluginSettings.username = root.editUsername
    pluginApi.pluginSettings.token = root.editToken
    pluginApi.pluginSettings.layout = root.editLayout
    pluginApi.pluginSettings.weeksShown = root.editWeeksShown
    pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval
    pluginApi.pluginSettings.showTotal = root.editShowTotal
    pluginApi.pluginSettings.showLabels = root.editShowLabels
    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true
  }
}
