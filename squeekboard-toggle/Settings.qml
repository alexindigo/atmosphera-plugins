import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var hideWhenUnavailableField: pluginApi?.field("hideWhenUnavailable") ?? null
  readonly property var disableHoverIconField: pluginApi?.field("disableHoverIcon") ?? null

  readonly property bool editHideWhenUnavailable: root.hideWhenUnavailableField?.value ?? false
  readonly property bool editDisableHoverIcon: root.disableHoverIconField?.value ?? false
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  NPluginSettingsField {
    field: root.hideWhenUnavailableField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.hideWhenUnavailable.label")
      description: pluginApi?.tr("settings.hideWhenUnavailable.desc")
      checked: root.editHideWhenUnavailable
      onToggled: checked => {
        root.hideWhenUnavailableField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.disableHoverIconField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.disableHoverIcon.label")
      description: pluginApi?.tr("settings.disableHoverIcon.desc")
      checked: root.editDisableHoverIcon
      onToggled: checked => {
        root.disableHoverIconField.set(checked);
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true

    NLabel {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.recheck.desc")
    }

    NButton {
      text: recheckDone ? pluginApi?.tr("settings.recheck.done") : pluginApi?.tr("settings.recheck.label")
      property bool recheckDone: false
      onClicked: {
        pluginApi?.mainInstance?.recheckState();
        recheckDone = true;
        recheckTimer.restart();
      }
      Timer {
        id: recheckTimer
        interval: 1500
        onTriggered: parent.recheckDone = false
      }
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }
}
