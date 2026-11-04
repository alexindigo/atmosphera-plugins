import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property bool editCustomizeText: displayBaseline.editCustomizeText
  property string editFirstLine: displayBaseline.editFirstLine
  property string editSecondLine: displayBaseline.editSecondLine
  NSettingsBaseline {
    id: displayBaseline
    readonly property bool editCustomizeText: pluginApi?.pluginSettings?.customizeText ?? pluginApi?.manifest?.metadata?.defaultSettings?.customizeText ?? false
    readonly property string editFirstLine: pluginApi?.pluginSettings?.firstLine || pluginApi?.manifest?.metadata?.defaultSettings?.firstLine || "Activate Linux"
    readonly property string editSecondLine: pluginApi?.pluginSettings?.secondLine || pluginApi?.manifest?.metadata?.defaultSettings?.secondLine || "Go to Settings to activate Linux."
  }
  readonly property bool settingsDirty: displayBaseline.differs({editCustomizeText: root.editCustomizeText, editFirstLine: root.editFirstLine, editSecondLine: root.editSecondLine})

  spacing: Style.marginM

  NToggle {
    Layout.fillWidth: true
    label: "Customize Text"
    description: "Write some custom text to display"
    checked: root.editCustomizeText
    onToggled: checked => {
      root.editCustomizeText = checked;
      root.saveSettings();
    }
  }

  NTextInput {
    visible: root.editCustomizeText
    Layout.fillWidth: true
    label: "First line"
    placeholderText: "Activate Linux, Windows, BSD, ..."
    text: root.editFirstLine
    onTextChanged: {
      root.editFirstLine = text;
    }
    onTextEdited: root.saveSettings()
  }

  NTextInput {
    visible: root.editCustomizeText
    Layout.fillWidth: true
    label: "Second line"
    placeholderText: "Go to Settings..."
    text: root.editSecondLine
    onTextChanged: {
      root.editSecondLine = text;
    }
    onTextEdited: root.saveSettings()
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("ActivateLinux", "Cannot save: pluginApi is null")
      return
    }
    pluginApi.pluginSettings.customizeText = root.editCustomizeText
    pluginApi.pluginSettings.firstLine = root.editFirstLine
    pluginApi.pluginSettings.secondLine = root.editSecondLine
    pluginApi.saveSettings()
  }
}
