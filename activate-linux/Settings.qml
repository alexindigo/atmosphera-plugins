import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var customizeTextField: pluginApi?.field("customizeText") ?? null
  readonly property var firstLineField: pluginApi?.field("firstLine") ?? null
  readonly property var secondLineField: pluginApi?.field("secondLine") ?? null

  readonly property bool editCustomizeText: root.customizeTextField?.value ?? false
  readonly property string editFirstLine: root.firstLineField?.value ?? "Activate Linux"
  readonly property string editSecondLine: root.secondLineField?.value ?? "Go to Settings to activate Linux."
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  NPluginSettingsField {
    field: root.customizeTextField
    NToggle {
      Layout.fillWidth: true
      label: "Customize Text"
      description: "Write some custom text to display"
      checked: root.editCustomizeText
      onToggled: checked => {
        root.customizeTextField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.firstLineField
    visible: root.editCustomizeText
    NTextInput {
      Layout.fillWidth: true
      label: "First line"
      placeholderText: "Activate Linux, Windows, BSD, ..."
      text: root.editFirstLine
      onEditCommitted: {
        root.firstLineField.set(text);
      }
    }
  }

  NPluginSettingsField {
    field: root.secondLineField
    visible: root.editCustomizeText
    NTextInput {
      Layout.fillWidth: true
      label: "Second line"
      placeholderText: "Go to Settings..."
      text: root.editSecondLine
      onEditCommitted: {
        root.secondLineField.set(text);
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("ActivateLinux", "Cannot save: pluginApi is null");
      return;
    }
    pluginApi.saveSettings();
  }
}
