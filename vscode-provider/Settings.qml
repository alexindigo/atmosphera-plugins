import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  // Plugin API (injected by the settings dialog system)
  property var pluginApi: null
  readonly property var commandField: pluginApi?.field("command") ?? null
  readonly property var configNameField: pluginApi?.field("configName") ?? null
  readonly property var includeInSearchField: pluginApi?.field("includeInSearch") ?? null

  // Local state for editing
  readonly property string command: root.commandField?.value || "code"
  readonly property string configName: root.configNameField?.value || "Code"
  readonly property bool includeInSearch: root.includeInSearchField?.value ?? true
  property string forkKey: findCurrentFork()

  readonly property list<var> forks: [
    {
      key: "code",
      name: "Visual Studio Code",
      command: "code",
      configName: "Code"
    },
    {
      key: "code-oss",
      name: "Code - OSS",
      command: "code-oss",
      configName: "Code - OSS"
    },
    {
      key: "cursor",
      name: "Cursor",
      command: "cursor",
      configName: "Cursor"
    },
    {
      key: "other",
      name: "Other",
      command: "",
      configName: ""
    }
  ]

  spacing: Style.marginM

  function findCurrentFork(): string {
    Logger.i("VSCodeWorkspaceProvider", Array.isArray(forks));
    for (let f of forks) {
      if (f["command"] === command && f["configName"] === configName) {
        Logger.i("VSCodeWorkspaceProvider", "Current fork is", f["key"]);
        return f["key"];
      }
    }
    Logger.i("VSCodeWorkspaceProvider", "Current fork unknown, default to other");
    return "other";
  }

  ColumnLayout {
    spacing: Style.marginL

    NPluginSettingsField {
      field: root.includeInSearchField
      NCheckbox {
        Layout.fillWidth: true
        label: pluginApi.tr("settings.includeInSearch.label")
        description: pluginApi.tr("settings.includeInSearch.description")
        checked: root.includeInSearch
        onToggled: checked => root.includeInSearchField.set(checked)
      }
    }

    NPluginSettingsField {
      field: root.configNameField
      NPluginSettingsField {
        field: root.commandField
        NComboBox {
          id: forkComboBox
          Layout.fillWidth: true

          label: pluginApi.tr("settings.fork.label")
          description: pluginApi.tr("settings.fork.description")

          model: Array.from(root.forks)
          currentKey: forkKey
          defaultValue: "code"
          onSelected: key => {
            root.forkKey = key;
            const fork = forks[forkComboBox.comboBox.currentIndex];
            root.configNameField.set(fork.configName);
            root.commandField.set(fork.command);
            otherSettings.visible = root.forkKey === "other";
          }
        }
      }
    }

    RowLayout {
      id: otherSettings
      visible: root.forkKey === "other"

      NTextInput {
        label: pluginApi.tr("settings.otherCommand.label")
        description: pluginApi.tr("settings.otherCommand.description")
        text: root.command
        onEditCommitted: root.commandField.set(text)
      }

      NTextInput {
        label: pluginApi.tr("settings.otherConfigName.label")
        description: pluginApi.tr("settings.otherConfigName.description")
        text: root.configName
        onEditCommitted: root.configNameField.set(text)
      }
    }
  }

  // Required: Save function called by the dialog
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    pluginApi.saveSettings();
  }
}
