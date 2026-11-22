/*
* SPDX-FileCopyrightText: 2025 cod3ddot@proton.me
*
* SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  // noctalia plugin api, injected dynamically
  property var pluginApi: null
  readonly property var debugField: pluginApi?.field("debug") ?? null
  readonly property var rogccField: pluginApi?.field("rogcc") ?? null
  readonly property var supergfxctlField: pluginApi?.field("supergfxctl") ?? null
  // rogcc and supergfxctl are atomic records: a member control's intent is
  // the whole record with that member changed.
  function setRecord(handle, patch) {
    return handle.set(Object.assign({}, handle.value, patch));
  }
  readonly property bool editDebug: debugField?.value ?? false
  readonly property bool editListen: rogccField?.value?.listenToNotifications ?? false
  readonly property bool editPatchPending: supergfxctlField?.value?.patchPending ?? true
  readonly property bool editPolling: supergfxctlField?.value?.polling ?? false
  readonly property int editPollingInterval: supergfxctlField?.value?.pollingInterval ?? 3000
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.Wrap
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
  }

  // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NText.qml
  NText {
    text: "ROG Control Center"
    color: AtmoColor.mSecondary

    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  RowLayout {
    // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/AtmoIcon.qml
    AtmoIcon {
      icon: "barrier-block"
      pointSize: Style.fontSizeL
      color: AtmoColor.mTertiary
    }

    // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NToggle.qml
    NPluginSettingsField {
      field: root.rogccField
      NToggle {
        Layout.fillWidth: true
        // TODO: enable once implemented
        enabled: false
        label: root.pluginApi.tr("settings.rogcc.listenToNotifications.label")
        description: root.pluginApi.tr("settings.rogcc.listenToNotifications.description")
        checked: root.editListen
        onToggled: checked => root.setRecord(root.rogccField, {
                                               listenToNotifications: checked
                                             })
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true

    // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NText.qml
    NText {
      text: "supergfxctl"
      color: AtmoColor.mSecondary
      Layout.topMargin: Style.marginM
      Layout.bottomMargin: Style.marginM
    }

    NDivider {
      Layout.fillWidth: true
    }
  }

  // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NToggle.qml
  NPluginSettingsField {
    field: root.supergfxctlField
    NToggle {
      Layout.fillWidth: true
      label: root.pluginApi.tr("settings.supergfxctl.patchPending.label")
      description: root.pluginApi.tr("settings.supergfxctl.patchPending.description")
      checked: root.editPatchPending
      onToggled: checked => root.setRecord(root.supergfxctlField, {
                                             patchPending: checked
                                           })
    }
  }

  RowLayout {
    // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/AtmoIcon.qml
    AtmoIcon {
      icon: "flask"
      pointSize: Style.fontSizeL
      color: AtmoColor.mTertiary
    }

    // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NToggle.qml
    NPluginSettingsField {
      field: root.supergfxctlField
      NToggle {
        Layout.fillWidth: true
        label: root.pluginApi.tr("settings.supergfxctl.polling.label")
        description: root.pluginApi.tr("settings.supergfxctl.polling.description")
        checked: root.editPolling
        onToggled: checked => root.setRecord(root.supergfxctlField, {
                                               polling: checked
                                             })
      }
    }
  }

  NPluginSettingsField {
    field: root.supergfxctlField
    NValueSlider {
      id: pollingInput
      objectName: "settings-range-editPollingInterval"
      text: root.editPollingInterval + "ms"
      enabled: root.editPolling
      from: 1000
      to: 5000
      stepSize: 250
      value: root.editPollingInterval
      onMoved: value => root.setRecord(root.supergfxctlField, {
                                         pollingInterval: value
                                       })
    }
  }

  RowLayout {
    Layout.fillWidth: true

    // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NText.qml
    NText {
      text: "Miscellaneous"
      color: AtmoColor.mSecondary
      Layout.topMargin: Style.marginM
      Layout.bottomMargin: Style.marginM
    }

    NDivider {
      Layout.fillWidth: true
    }
  }

  // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NToggle.qml
  NPluginSettingsField {
    field: root.debugField
    NToggle {
      Layout.fillWidth: true
      label: root.pluginApi.tr("settings.debug.label")
      description: root.pluginApi.tr("settings.debug.description")
      checked: root.editDebug
      onToggled: checked => root.debugField.set(checked)
    }
  }

  // This function is called by noctalia dialog
  function saveSettings(): void {
    if (!root.pluginApi) {
      return console.error("supergfxctl", "[Settings]: cannot save settings: pluginApi is null");
    }

    // Completion observer only; the session owns publication.
    root.pluginApi.saveSettings(result => {
      if ((result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        root.pluginApi.mainInstance?.settingsConsumerFor(root.pluginApi.runtimeContext)?.refresh();
    });
  }
}
