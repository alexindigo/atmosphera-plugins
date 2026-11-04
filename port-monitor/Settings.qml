import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property int editRefreshInterval: displayBaseline.editRefreshInterval
  property bool editHideSystemPorts: displayBaseline.editHideSystemPorts
  property bool editHideWhenEmpty: displayBaseline.editHideWhenEmpty
  property bool _applyEffectPending: false
  NSettingsBaseline {
    id: displayBaseline
    readonly property int editRefreshInterval: cfg.refreshInterval ?? defaults.refreshInterval ?? 5
    readonly property bool editHideSystemPorts: cfg.hideSystemPorts ?? defaults.hideSystemPorts ?? false
    readonly property bool editHideWhenEmpty: cfg.hideWhenEmpty ?? defaults.hideWhenEmpty ?? false
  }
  readonly property bool settingsDirty: displayBaseline.differs({editRefreshInterval: root.editRefreshInterval, editHideSystemPorts: root.editHideSystemPorts, editHideWhenEmpty: root.editHideWhenEmpty})
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current") return;
      root._applyEffectPending = false;
      root.pluginApi.mainInstance?.refresh();
      Logger.i("Port Monitor", "Settings saved");
    }
  }

  spacing: Style.marginM

  // Refresh Interval
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.refreshInterval")
      description: pluginApi?.tr("settings.refreshIntervalDesc", { value: root.editRefreshInterval })
    }

    NSlider {
      Layout.fillWidth: true
      from: 1
      to: 30
      stepSize: 1
      value: root.editRefreshInterval
      onValueChanged: root.editRefreshInterval = value
    }
  }

  // Hide System Ports
  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: systemToggle.implicitHeight
    NToggle {
      id: systemToggle
      anchors.fill: parent
      label: pluginApi?.tr("settings.hideSystemPorts")
      description: pluginApi?.tr("settings.hideSystemPortsDesc")
      checked: root.editHideSystemPorts
      onToggled: checked => root.editHideSystemPorts = checked
    }
  }

  // Hide When Empty
  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: emptyToggle.implicitHeight
    NToggle {
      id: emptyToggle
      anchors.fill: parent
      label: pluginApi?.tr("settings.hideWhenEmpty")
      description: pluginApi?.tr("settings.hideWhenEmptyDesc")
      checked: root.editHideWhenEmpty
      onToggled: checked => root.editHideWhenEmpty = checked
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Port Monitor", "Cannot save: pluginApi is null")
      return
    }

    pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval
    pluginApi.pluginSettings.hideSystemPorts = root.editHideSystemPorts
    pluginApi.pluginSettings.hideWhenEmpty = root.editHideWhenEmpty

    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true
  }
}
