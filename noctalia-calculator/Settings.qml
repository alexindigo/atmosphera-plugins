import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var showBarValueField: pluginApi?.field("showBarValue") ?? null
  readonly property var precisionField: pluginApi?.field("precision") ?? null

  readonly property bool valueShowBarValue: root.showBarValueField?.value ?? true
  readonly property int valuePrecision: root.precisionField?.value ?? 8
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  NText {
    Layout.fillWidth: true
    visible: root.pluginApi?.scopeKind === "instance"
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
    wrapMode: Text.WordWrap
  }

  function saveSettings() {
    if (!pluginApi?.pluginSettings)
      return;
    pluginApi.saveSettings();
  }

  NPluginSettingsField {
    field: root.showBarValueField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-bar")
      description: pluginApi?.tr("settings.show-bar-desc")
      checked: root.valueShowBarValue
      onToggled: checked => {
        root.showBarValueField.set(checked);
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.precision", {
                             "value": root.valuePrecision
                           })
      description: pluginApi?.tr("settings.precision-desc")
    }

    NPluginSettingsField {
      field: root.precisionField
      NSlider {
        id: rangeValuePrecision
        objectName: "settings-range-valuePrecision"
        Layout.fillWidth: true
        from: 0
        to: 10
        stepSize: 1
        value: root.valuePrecision
        onMoved: {
          root.precisionField.set(Math.round(value));
        }
      }
    }
  }

  NLabel {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.about")
    description: pluginApi?.tr("settings.developed-by", {
                                 "version": pluginApi?.manifest?.version ?? "1.0.0"
                               })
  }
}
