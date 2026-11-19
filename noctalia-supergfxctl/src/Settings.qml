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
    NSettingsBaseline {
        id: displayBaseline
        readonly property bool editDebug: root.pluginApi?.initialSettings?.debug ?? false
        readonly property bool editListen: root.pluginApi?.initialSettings?.rogcc?.listenToNotifications ?? false
        readonly property bool editPatchPending: root.pluginApi?.initialSettings?.supergfxctl?.patchPending ?? true
        readonly property bool editPolling: root.pluginApi?.initialSettings?.supergfxctl?.polling ?? false
        readonly property int editPollingInterval: root.pluginApi?.initialSettings?.supergfxctl?.pollingInterval ?? 3000
        ranges: [NSettingsRange { field: "editPollingInterval"; from: pollingInput.from; to: pollingInput.to }]
    }
    property bool editDebug: displayBaseline.editDebug
    property bool editListen: displayBaseline.editListen
    property bool editPatchPending: displayBaseline.editPatchPending
    property bool editPolling: displayBaseline.editPolling
    property int editPollingInterval: displayBaseline.project("editPollingInterval")
    readonly property bool settingsDirty: displayBaseline.differs({editDebug: editDebug, editListen: editListen, editPatchPending: editPatchPending, editPolling: editPolling, editPollingInterval: editPollingInterval})

    spacing: Style.marginM

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
        NToggle {
            Layout.fillWidth: true
            // TODO: enable once implemented
            enabled: false
            label: root.pluginApi.tr("settings.rogcc.listenToNotifications.label")
            description: root.pluginApi.tr("settings.rogcc.listenToNotifications.description")
            checked: root.editListen
            onToggled: checked => root.editListen = checked
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
    NToggle {
        Layout.fillWidth: true
        label: root.pluginApi.tr("settings.supergfxctl.patchPending.label")
        description: root.pluginApi.tr("settings.supergfxctl.patchPending.description")
        checked: root.editPatchPending
        onToggled: checked => root.editPatchPending = checked
    }

    RowLayout {
        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/AtmoIcon.qml
        AtmoIcon {
            icon: "flask"
            pointSize: Style.fontSizeL
            color: AtmoColor.mTertiary
        }

        // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NToggle.qml
        NToggle {
            Layout.fillWidth: true
            label: root.pluginApi.tr("settings.supergfxctl.polling.label")
            description: root.pluginApi.tr("settings.supergfxctl.polling.description")
            checked: root.editPolling
            onToggled: checked => root.editPolling = checked
        }
    }

    NValueSlider {
        id: pollingInput
        objectName: "settings-range-editPollingInterval"
        text: root.editPollingInterval + "ms"
        enabled: root.editPolling
        from: 1000
        to: 5000
        stepSize: 250
        value: root.editPollingInterval
        onMoved: value => root.editPollingInterval = value
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
    NToggle {
        Layout.fillWidth: true
        label: root.pluginApi.tr("settings.debug.label")
        description: root.pluginApi.tr("settings.debug.description")
        checked: root.editDebug
        onToggled: checked => root.editDebug = checked
    }

    // This function is called by noctalia dialog
    function saveSettings(): void {
        if (!root.pluginApi) {
            return console.error("supergfxctl", "[Settings]: cannot save settings: pluginApi is null");
        }

        root.pluginApi.pluginSettings.debug = editDebug;
        root.pluginApi.pluginSettings.rogcc = Object.assign({}, root.pluginApi.pluginSettings.rogcc, {listenToNotifications: editListen});
        root.pluginApi.pluginSettings.supergfxctl = Object.assign({}, root.pluginApi.pluginSettings.supergfxctl, {patchPending: editPatchPending, polling: editPolling, pollingInterval: editPollingInterval});

        // Persist to disk
        root.pluginApi.saveSettings();

    }
}
