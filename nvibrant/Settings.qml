import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var vibranceValueField: pluginApi?.field("vibranceValue") ?? null
  readonly property var displayIndexField: pluginApi?.field("displayIndex") ?? null
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.Wrap
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
  }

  NPluginSettingsField {
    field: root.vibranceValueField
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.vibrance-value")
      description: pluginApi?.tr("settings.vibrance-value-desc")
    }

    NSpinBox {
      id: vibranceSpinBox
      from: 0
      to: 1023
      stepSize: 64
      value: root.vibranceValueField?.value ?? 512
      requestValue: value => root.vibranceValueField.set(value)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NPluginSettingsField {
    field: root.displayIndexField
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.display-index")
      description: pluginApi?.tr("settings.display-index-desc")
    }

    NSpinBox {
      id: displayIndexSpinBox
      from: 1
      to: 8
      stepSize: 1
      value: root.displayIndexField?.value ?? 1
      requestValue: value => root.displayIndexField.set(value)
    }
  }

  // Completion observer only; native publication belongs to the session.
  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }
}
