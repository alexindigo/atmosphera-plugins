import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var haUrlField: pluginApi?.field("haUrl") ?? null
  readonly property var haTokenField: pluginApi?.field("haToken") ?? null

  // Local state
  readonly property string editUrl: root.haUrlField?.value ?? ""
  readonly property string editToken: root.haTokenField?.value ?? ""
  property bool _applyEffectPending: false
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._applyEffectPending = false;
      root.pluginApi.mainInstance?.reloadSettings();
    }
  }

  spacing: Style.marginM

  NPluginSettingsField {
    field: root.haUrlField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.url_label")
      placeholderText: pluginApi?.tr("settings.url_placeholder")
      text: root.editUrl
      onEditCommitted: root.haUrlField.set(text)
    }
  }

  NPluginSettingsField {
    field: root.haTokenField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.token_label")
      placeholderText: pluginApi?.tr("settings.token_placeholder")
      text: root.editToken
      onEditCommitted: root.haTokenField.set(text)
    }
  }

  function saveSettings() {
    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true;
  }
}
