import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Portals
import qs.Widgets

ColumnLayout {
  id: root

  // Plugin API (injected by the settings dialog system)
  property var pluginApi: null

  // Local state for editing
  property string editNvim: displayBaseline.editNvim
  property bool editRunInTerminal: displayBaseline.editRunInTerminal
  property string editSessionDir: displayBaseline.editSessionDir
  property bool editIncludeInSearch: displayBaseline.editIncludeInSearch
  NSettingsBaseline {
    id: displayBaseline
    readonly property string editNvim: pluginApi?.pluginSettings?.nvim || pluginApi?.manifest?.metadata?.defaultSettings?.nvim || "nvim"
    readonly property bool editRunInTerminal: pluginApi?.pluginSettings?.runInTerminal ?? pluginApi?.manifest?.metadata?.defaultSettings?.runInTerminal ?? true
    readonly property string editSessionDir: pluginApi?.pluginSettings?.sessionDir ?? pluginApi?.manifest?.metadata?.defaultSettings?.sessionDir ?? "~/.local/share/nvim/sessions"
    readonly property bool editIncludeInSearch: pluginApi?.pluginSettings?.includeInSearch ?? pluginApi?.manifest?.metadata?.defaultSettings?.includeInSearch ?? true
  }
  readonly property bool settingsDirty: displayBaseline.differs({editNvim: root.editNvim, editRunInTerminal: root.editRunInTerminal, editSessionDir: root.editSessionDir, editIncludeInSearch: root.editIncludeInSearch})
  spacing: Style.marginM

  ColumnLayout {
      spacing: Style.marginL

      NLabel {
          label: pluginApi.tr("settings.nvim.title")
          description: pluginApi.tr("settings.nvim.description")
      }

      NTextInput {
          Layout.fillWidth: true
          placeholderText: "nvim"
          text: root.editNvim
          onTextChanged: root.editNvim = text
      }

      NCheckbox {
          Layout.fillWidth: true
          label: pluginApi.tr("settings.runInTerminal.label")
          description: pluginApi.tr("settings.runInTerminal.description") 
          checked: root.editRunInTerminal
          onToggled: (checked) => root.editRunInTerminal = checked
      }

      NTextInputButton {
          label: pluginApi.tr("settings.sessionDir.label")
          description: pluginApi.tr("settings.sessionDir.description")
          placeholderText: "~/.local/share/nvim/sessions"
          text: root.editSessionDir
          buttonIcon: "folder"
          buttonTooltip: pluginApi.tr("settings.sessionDir.select")
          onInputEditingFinished: root.editSessionDir = text
          onButtonClicked: filePicker.openFilePicker()
      }

      NCheckbox {
          Layout.fillWidth: true
          label: pluginApi.tr("settings.includeInSearch.label")
          description: pluginApi.tr("settings.includeInSearch.description")
          checked: root.editIncludeInSearch
          onToggled: (checked) => root.editIncludeInSearch = checked
      }

  }

  PortalFilePicker {
      id: filePicker
      selectionMode: "folders"
      title: pluginApi.tr("settings.sessionDir.title")
      initialPath: root.editSessionDir
      onAccepted: paths => {
          if (paths.length > 0) {
              root.editSessionDir = paths[0]
          }
      }
  }


  // Required: Save function called by the dialog
  function saveSettings() {
      pluginApi.pluginSettings.nvim = root.editNvim;
      pluginApi.pluginSettings.runInTerminal = root.editRunInTerminal;
      pluginApi.pluginSettings.sessionDir = root.editSessionDir;
      pluginApi.pluginSettings.includeInSearch = root.editIncludeInSearch;
      pluginApi.saveSettings();
  }
}
