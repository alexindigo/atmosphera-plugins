import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var terminalCommandField: pluginApi?.field("terminalCommand") ?? null
  readonly property var pollIntervalField: pluginApi?.field("pollInterval") ?? null
  readonly property var showInactiveHostsField: pluginApi?.field("showInactiveHosts") ?? null

  readonly property string editTerminalCommand: root.terminalCommandField?.value ?? ""
  readonly property int editPollInterval: root.pollIntervalField?.value ?? 10
  readonly property bool editShowInactiveHosts: root.showInactiveHostsField?.value ?? true

  spacing: Style.marginM

  // --- Terminal ---
  readonly property string detectedTerminal: pluginApi?.mainInstance?.detectedTerminal ?? ""

  NLabel {
    label: pluginApi?.tr("settings.terminal")
  }

  NText {
    Layout.fillWidth: true
    text: root.detectedTerminal !== "" ? pluginApi?.tr("settings.terminalDetected", {
                                                         terminal: root.detectedTerminal
                                                       }) : pluginApi?.tr("settings.terminalNone")
    color: root.detectedTerminal !== "" ? AtmoColor.mPrimary : AtmoColor.mError
    pointSize: Style.fontSizeS
    wrapMode: Text.Wrap
  }

  NPluginSettingsField {
    field: root.terminalCommandField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.terminalOverride")
      description: pluginApi?.tr("settings.terminalOverrideDesc")
      placeholderText: root.detectedTerminal
      text: root.editTerminalCommand
      onEditCommitted: root.terminalCommandField.set(text)
    }
  }

  // --- Poll Interval ---
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.pollInterval")
      description: pluginApi?.tr("settings.pollIntervalDesc") + root.editPollInterval
    }

    NPluginSettingsField {
      field: root.pollIntervalField
      NSlider {
        id: rangeEditPollInterval
        objectName: "settings-range-editPollInterval"
        Layout.fillWidth: true
        from: 5
        to: 30
        stepSize: 1
        value: root.editPollInterval
        onMoved: root.pollIntervalField.set(value)
      }
    }
  }

  // --- Display ---
  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: inactiveToggle.implicitHeight
    NPluginSettingsField {
      field: root.showInactiveHostsField
      NToggle {
        id: inactiveToggle
        anchors.fill: parent
        label: pluginApi?.tr("settings.showInactiveHosts")
        description: pluginApi?.tr("settings.showInactiveHostsDesc")
        checked: root.editShowInactiveHosts
        onToggled: checked => root.showInactiveHostsField.set(checked)
      }
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("SSH Sessions", "Cannot save: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("SSH Sessions", "Settings saved");
    });
  }
}
