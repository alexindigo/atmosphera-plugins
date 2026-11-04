import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string editBindAddress: displayBaseline.editBindAddress
  property int editPort: displayBaseline.editPort
  property string editToken: displayBaseline.editToken
  property int editPollIntervalSec: displayBaseline.editPollIntervalSec
  property bool editHideWhenEmpty: displayBaseline.editHideWhenEmpty
  property bool _applyEffectPending: false
  NSettingsBaseline {
    id: displayBaseline
    readonly property string editBindAddress: cfg.bindAddress ?? defaults.bindAddress ?? "127.0.0.1"
    readonly property int editPort: Number(cfg.port ?? defaults.port ?? 55854)
    readonly property string editToken: cfg.token ?? defaults.token ?? ""
    readonly property int editPollIntervalSec: Number(cfg.pollIntervalSec ?? defaults.pollIntervalSec ?? 2)
    readonly property bool editHideWhenEmpty: cfg.hideWhenEmpty ?? defaults.hideWhenEmpty ?? false
  }
  readonly property bool settingsDirty: displayBaseline.differs({editBindAddress: root.editBindAddress, editPort: root.editPort, editToken: root.editToken, editPollIntervalSec: root.editPollIntervalSec, editHideWhenEmpty: root.editHideWhenEmpty})
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current") return;
      root._applyEffectPending = false;
      root.pluginApi.mainInstance?.restartService();
    }
  }

  spacing: Style.marginL

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.bindAddress.label")
    description: pluginApi?.tr("settings.bindAddress.desc")
    text: root.editBindAddress
    onTextChanged: root.editBindAddress = text
  }

  NSpinBox {
    label: pluginApi?.tr("settings.port.label")
    description: pluginApi?.tr("settings.port.desc")
    from: 1
    to: 65535
    value: root.editPort
    onValueChanged: root.editPort = value
  }

  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.token.label")
    description: pluginApi?.tr("settings.token.desc")
    text: root.editToken
    onTextChanged: root.editToken = text
  }

  NSpinBox {
    label: pluginApi?.tr("settings.pollInterval.label")
    description: pluginApi?.tr("settings.pollInterval.desc")
    from: 1
    to: 30
    value: root.editPollIntervalSec
    onValueChanged: root.editPollIntervalSec = value
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: hideToggle.implicitHeight

    NToggle {
      id: hideToggle
      anchors.fill: parent
      label: pluginApi?.tr("settings.hideWhenEmpty.label")
      description: pluginApi?.tr("settings.hideWhenEmpty.desc")
      checked: root.editHideWhenEmpty
      onToggled: checked => root.editHideWhenEmpty = checked
    }
  }

  function saveSettings() {
    if (!pluginApi) return

    root.editBindAddress = root.editBindAddress.trim() || "127.0.0.1"
    root.editToken = root.editToken.trim()
    pluginApi.pluginSettings.bindAddress = root.editBindAddress
    pluginApi.pluginSettings.port = root.editPort
    pluginApi.pluginSettings.token = root.editToken
    pluginApi.pluginSettings.pollIntervalSec = root.editPollIntervalSec
    pluginApi.pluginSettings.hideWhenEmpty = root.editHideWhenEmpty
    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true
  }
}
