import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Portals
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var obsidianConfigPathField: pluginApi?.field("obsidianConfigPath") ?? null
  readonly property var includeInSearchField: pluginApi?.field("includeInSearch") ?? null

  readonly property string editConfigPath: root.obsidianConfigPathField?.value ?? ""
  readonly property bool editIncludeInSearch: root.includeInSearchField?.value ?? true
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  NPluginSettingsField {
    field: root.obsidianConfigPathField
    NTextInputButton {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.configPath.label")
      description: pluginApi?.tr("settings.configPath.desc")
      placeholderText: pluginApi?.tr("settings.configPath.placeholder")
      text: root.editConfigPath
      buttonIcon: "file"
      buttonTooltip: pluginApi?.tr("settings.configPath.buttonTooltip")
      onInputEditCommitted: root.obsidianConfigPathField.set(text)
      onButtonClicked: filePicker.openFilePicker()
    }
  }

  NPluginSettingsField {
    field: root.includeInSearchField
    NCheckbox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.includeInSearch.label")
      description: pluginApi?.tr("settings.includeInSearch.desc")
      checked: root.editIncludeInSearch
      onToggled: checked => root.includeInSearchField.set(checked)
    }
  }

  PortalFilePicker {
    id: filePicker
    selectionMode: "files"
    title: pluginApi?.tr("settings.configPath.pickerTitle")
    initialPath: root.editConfigPath
    onAccepted: paths => {
      if (paths.length > 0) {
        root.obsidianConfigPathField.set(paths[0]);
      }
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }
}
