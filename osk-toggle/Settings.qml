import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var backendField: pluginApi?.field("backend") ?? null
  readonly property var hideWhenUnavailableField: pluginApi?.field("hideWhenUnavailable") ?? null
  readonly property var disableHoverIconField: pluginApi?.field("disableHoverIcon") ?? null
  readonly property var wvkbdBinField: pluginApi?.field("wvkbdBin") ?? null

  readonly property string editBackend: root.backendField?.value ?? "auto"
  readonly property bool editHideWhenUnavailable: root.hideWhenUnavailableField?.value ?? false
  readonly property bool editDisableHoverIcon: root.disableHoverIconField?.value ?? false
  readonly property string editWvkbdBin: root.wvkbdBinField?.value ?? "wvkbd-mobintl"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  readonly property bool showWvkbdBin: editBackend === "wvkbd" || editBackend === "auto"

  spacing: Style.marginL

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.Wrap
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
  }

  NPluginSettingsField {
    field: root.backendField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.backend.label")
      description: pluginApi?.tr("settings.backend.desc")
      model: [
        {
          key: "auto",
          name: pluginApi?.tr("settings.backend.option.auto")
        },
        {
          key: "squeekboard",
          name: pluginApi?.tr("settings.backend.option.squeekboard")
        },
        {
          key: "wvkbd",
          name: pluginApi?.tr("settings.backend.option.wvkbd")
        }
      ]
      currentKey: root.editBackend
      onSelected: key => {
        root.backendField.set(key);
      }
    }
  }

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

  NPluginSettingsField {
    field: root.wvkbdBinField
    visible: root.showWvkbdBin
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.wvkbdBin.label")
      description: pluginApi?.tr("settings.wvkbdBin.desc")
      text: root.editWvkbdBin
      onEditCommitted: {
        root.wvkbdBinField.set(text);
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
        pluginApi?.mainInstance?.recheckState(pluginApi.runtimeContext);
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
    pluginApi.saveSettings(result => {
      if ((result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        pluginApi.mainInstance?.activatePolicy(pluginApi.runtimeContext);
    });
  }
}
