import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var hideSystemPortsField: pluginApi?.field("hideSystemPorts") ?? null
  readonly property var hideWhenEmptyField: pluginApi?.field("hideWhenEmpty") ?? null

  readonly property int editRefreshInterval: root.refreshIntervalField?.value ?? 5
  readonly property bool editHideSystemPorts: root.hideSystemPortsField?.value ?? false
  readonly property bool editHideWhenEmpty: root.hideWhenEmptyField?.value ?? false
  property bool _applyEffectPending: false
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._applyEffectPending = false;
      root.pluginApi.mainInstance?.refresh();
      Logger.i("Port Monitor", "Settings saved");
    }
  }

  spacing: Style.marginM

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.Wrap
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
  }

  // Refresh Interval
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.refreshInterval")
      description: pluginApi?.tr("settings.refreshIntervalDesc", {
                                   value: root.editRefreshInterval
                                 })
    }

    NPluginSettingsField {
      field: root.refreshIntervalField
      NSlider {
        id: rangeEditRefreshInterval
        objectName: "settings-range-editRefreshInterval"
        Layout.fillWidth: true
        from: 1
        to: 30
        stepSize: 1
        value: root.editRefreshInterval
        onMoved: root.refreshIntervalField.set(value)
      }
    }
  }

  // Hide System Ports
  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: systemToggle.implicitHeight
    NPluginSettingsField {
      field: root.hideSystemPortsField
      NToggle {
        id: systemToggle
        anchors.fill: parent
        label: pluginApi?.tr("settings.hideSystemPorts")
        description: pluginApi?.tr("settings.hideSystemPortsDesc")
        checked: root.editHideSystemPorts
        onToggled: checked => root.hideSystemPortsField.set(checked)
      }
    }
  }

  // Hide When Empty
  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: emptyToggle.implicitHeight
    NPluginSettingsField {
      field: root.hideWhenEmptyField
      NToggle {
        id: emptyToggle
        anchors.fill: parent
        label: pluginApi?.tr("settings.hideWhenEmpty")
        description: pluginApi?.tr("settings.hideWhenEmptyDesc")
        checked: root.editHideWhenEmpty
        onToggled: checked => root.hideWhenEmptyField.set(checked)
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Port Monitor", "Cannot save: pluginApi is null");
      return;
    }

    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true;
  }
}
