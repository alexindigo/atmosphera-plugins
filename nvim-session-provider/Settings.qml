import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Portals
import qs.Widgets

ColumnLayout {
  id: root

  // Plugin API (injected by the settings dialog system)
  property var pluginApi: null
  readonly property var nvimField: pluginApi?.field("nvim") ?? null
  readonly property var runInTerminalField: pluginApi?.field("runInTerminal") ?? null
  readonly property var sessionDirField: pluginApi?.field("sessionDir") ?? null
  readonly property var includeInSearchField: pluginApi?.field("includeInSearch") ?? null

  // Local state for editing
  readonly property string editNvim: root.nvimField?.value || "nvim"
  readonly property bool editRunInTerminal: root.runInTerminalField?.value ?? true
  readonly property string editSessionDir: root.sessionDirField?.value ?? "~/.local/share/nvim/sessions"
  readonly property bool editIncludeInSearch: root.includeInSearchField?.value ?? true
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  ColumnLayout {
    spacing: Style.marginL

    NLabel {
      label: pluginApi.tr("settings.nvim.title")
      description: pluginApi.tr("settings.nvim.description")
    }

    NPluginSettingsField {
      field: root.nvimField
      NTextInput {
        Layout.fillWidth: true
        placeholderText: "nvim"
        text: root.editNvim
        onEditCommitted: root.nvimField.set(text)
      }
    }

    NPluginSettingsField {
      field: root.runInTerminalField
      NCheckbox {
        Layout.fillWidth: true
        label: pluginApi.tr("settings.runInTerminal.label")
        description: pluginApi.tr("settings.runInTerminal.description")
        checked: root.editRunInTerminal
        onToggled: checked => root.runInTerminalField.set(checked)
      }
    }

    NPluginSettingsField {
      field: root.sessionDirField
      NTextInputButton {
        label: pluginApi.tr("settings.sessionDir.label")
        description: pluginApi.tr("settings.sessionDir.description")
        placeholderText: "~/.local/share/nvim/sessions"
        text: root.editSessionDir
        buttonIcon: "folder"
        buttonTooltip: pluginApi.tr("settings.sessionDir.select")
        onInputEditCommitted: root.sessionDirField.set(text)
        onButtonClicked: filePicker.openFilePicker()
      }
    }

    NPluginSettingsField {
      field: root.includeInSearchField
      NCheckbox {
        Layout.fillWidth: true
        label: pluginApi.tr("settings.includeInSearch.label")
        description: pluginApi.tr("settings.includeInSearch.description")
        checked: root.editIncludeInSearch
        onToggled: checked => root.includeInSearchField.set(checked)
      }
    }
  }

  PortalFilePicker {
    id: filePicker
    selectionMode: "folders"
    title: pluginApi.tr("settings.sessionDir.title")
    initialPath: root.editSessionDir
    onAccepted: paths => {
      if (paths.length > 0) {
        root.sessionDirField.set(paths[0]);
      }
    }
  }

  // Required: Save function called by the dialog
  function saveSettings() {
    pluginApi.saveSettings();
  }
}
