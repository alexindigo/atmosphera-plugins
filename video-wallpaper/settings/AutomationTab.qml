pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM
    Layout.fillWidth: true


    /***************************
    * PROPERTIES
    ***************************/
    // Required properties
    required property var pluginApi
    required property bool enabled
    required property string selectedMonitor
    required property var monitorSettings
    NSettingsBaseline {
        id: displayBaseline
        readonly property bool automation: root.pluginApi?.initialSettings?.[root.selectedMonitor]?.automation ?? false
        readonly property string automationMode: root.pluginApi?.initialSettings?.[root.selectedMonitor]?.automationMode ?? root.pluginApi?.manifest?.metadata?.defaultSettings?.automationMode ?? ""
        readonly property real automationTime: root.pluginApi?.initialSettings?.[root.selectedMonitor]?.automationTime ?? root.pluginApi?.manifest?.metadata?.defaultSettings?.automationTime ?? 0
        readonly property var automationCustomTime: root.pluginApi?.initialSettings?.automationCustomTime || []
    }
    property alias customTimeText: customTimeInput.text
    readonly property bool settingsDirty: displayBaseline.differs({automation: automation, automationMode: automationMode, automationTime: automationTime, automationCustomTime: automationCustomTime}) || customTimeText.length > 0

    // Monitor specific properties
    property bool automation: monitorSettings.automation ?? false
    property string automationMode: monitorSettings.automationMode ?? pluginApi?.manifest?.metadata?.defaultSettings?.automationMode ?? ""
    property real automationTime: monitorSettings.automationTime ?? pluginApi?.manifest?.metadata?.defaultSettings?.automationTime ?? 0

    // Global properties
    property list<int> automationCustomTime: Array.from(displayBaseline.automationCustomTime)

    // Signals
    signal saveMonitorProperty(key: string, value: var);

    /***************************
    * EVENTS
    ***************************/
    function loadMonitor(record) {
        // Update the local variables
        automation = record.automation ?? false;
        automationMode = record.automationMode ?? pluginApi?.manifest?.metadata?.defaultSettings?.automationMode ?? "";
        automationTime = record.automationTime ?? pluginApi?.manifest?.metadata?.defaultSettings?.automationTime ?? 0;
    }


    /***************************
    * COMPONENTS
    ***************************/
    // Automation Toggle
    NToggle {
        enabled: root.enabled
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("settings.automation.toggle.label")
        description: root.pluginApi?.tr("settings.automation.toggle.description")
        checked: root.automation
        onToggled: checked => root.automation = checked
    }

    // Automation Mode
    NComboBox {
        enabled: root.enabled && root.automation
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("settings.automation.mode.label")
        description: root.pluginApi?.tr("settings.automation.mode.description")
        defaultValue: "random"
        model: [
            {
                "key": "random",
                "name": root.pluginApi?.tr("settings.automation.mode.random")
            },
            {
                "key": "alphabetically",
                "name": root.pluginApi?.tr("settings.automation.mode.alphabetically")
            }
        ]
        currentKey: root.automationMode
        onSelected: key => root.automationMode = key
    }

    ColumnLayout {
        NLabel {
            enabled: root.enabled && root.automation
            label:       root.pluginApi?.tr("settings.automation.time.label")
            description: root.pluginApi?.tr("settings.automation.time.description")
        }

        RowLayout {
            id: timesLayout
            spacing: Style.marginS

            Repeater {
                model: [
                    5 * 60,
                    30 * 60,
                    60 * 60,
                    90 * 60,
                    120 * 60
                ]

                TimeButton {
                    required property var modelData
                    time: modelData
                }
            }

            NDivider {
                vertical: true
            }

            Repeater {
                id: customTimeRepeater
                model: root.automationCustomTime

                CustomTimeButton {
                    required property var modelData
                    time: modelData
                }
            }

            AtmoIconButton {
                icon: "plus"
                tooltipText: root.pluginApi?.tr("settings.automation.time.custom.create.tooltip")
                enabled: root.enabled && root.automation
                onClicked: createCustomTime.open();
            }

            component TimeButton: NButton {
                required property int time

                text: {
                    const hour = Math.floor(time / 3600.0);
                    const minute = Math.max(Math.floor(time / 60.0), 1) - (hour * 60);
                    const hourTranslation =   root.pluginApi?.tr("settings.automation.time.h", {hour: hour});
                    const minuteTranslation = root.pluginApi?.tr("settings.automation.time.m", {minute: minute});

                    if (hour == 0) {
                        return minuteTranslation;
                    } else if (minute == 0) {
                        return hourTranslation;
                    } else {
                        return `${hourTranslation} ${minuteTranslation}`;
                    }
                }
                tooltipText: {
                    const hour = Math.floor(time / 3600.0);
                    const minute = Math.max(Math.floor(time / 60.0), 1) - (hour * 60);
                    const hourTranslation =   root.pluginApi?.trp("settings.automation.time.hour", hour, "1 hour", "{count} hours");
                    const minuteTranslation = root.pluginApi?.trp("settings.automation.time.minute", minute, "1 minute", "{count} minutes");

                    if (hour == 0) {
                        return minuteTranslation;
                    } else if (minute == 0) {
                        return hourTranslation;
                    } else {
                        return `${hourTranslation} ${minuteTranslation}`;
                    }
                }
                enabled: root.enabled && root.automation
                onClicked: root.automationTime = time
                outlined: root.automationTime === time
            }

            component CustomTimeButton: TimeButton {
                id: timeButton

                onRightClicked: {
                    customTimeButtonMenu.selectedSeconds = time;
                    customTimeButtonMenu.openAtItem(timeButton, 0, timeButton.height);
                }
            }
        }
    }

    Popup {
        id: createCustomTime

        width: 400

        anchors.centerIn: Overlay.overlay
        padding: Style.marginL

        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: AtmoColor.mSurfaceVariant
            radius: Style.iRadiusL
            border.color: AtmoColor.mOutline
            border.width: Style.borderS
        }

        function save() {
            // Check format of the text
            if (customTimeInput.isCorrectFormat()) {
                const times = customTimeInput.text.split(":");
                const hour = parseInt(times[0]);
                let minute = parseInt(times[1]);

                if (hour == 0) {
                    // Make sure that minute isn't 0
                    minute = Math.max(minute, 1);
                }

                const seconds = hour * 3600 + minute * 60;
                root.automationCustomTime = Array.from(new Set(Array.from(root.automationCustomTime).concat([seconds]))).sort();

                // Reset the input
                customTimeInput.text = "";

                createCustomTime.close();
                return true;
            }
            return false;
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Style.marginS

            NTextInput {
                id: customTimeInput
                label:           root.pluginApi?.tr("settings.automation.time.custom.create.label")
                description:     root.pluginApi?.tr("settings.automation.time.custom.create.description")
                placeholderText: root.pluginApi?.tr("settings.automation.time.custom.create.placeholder")
                Layout.fillWidth: true
                onAccepted: createCustomTime.save();

                function isCorrectFormat() {
                    // Check that : is included and that only one : is included
                    const times = customTimeInput.text.split(":");
                    if (times.length != 2) {
                        return false;
                    }

                    const isInteger = /^[0-9]+$/;
                    const isMinute = /^[0-5][0-9]$/;

                    // Check so that both sides are numbers and that the minute is in the range of [0-59]
                    if (!isInteger.test(times[0]) || !isInteger.test(times[1]) || !isMinute.test(times[1])) {
                        return false;
                    }

                    return true;
                }
            }

            RowLayout {
                spacing: Style.marginS
                layoutDirection: Qt.LeftToRight
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: root.pluginApi?.tr("settings.automation.time.custom.create.cancel")
                    onClicked: { customTimeInput.text = ""; createCustomTime.close(); }
                }

                NButton {
                    text: root.pluginApi?.tr("settings.automation.time.custom.create.save")
                    enabled: customTimeInput.isCorrectFormat();
                    onClicked: createCustomTime.save();
                }
            }
        }
    }

    NContextMenu {
        id: customTimeButtonMenu
        property int selectedSeconds: 0

        model: [
            {
                "label": root.pluginApi?.tr("settings.automation.time.custom.remove"),
                "action": "remove",
                "icon": "x"
            },
        ]

        onTriggered: action => {
            close();

            switch(action) {
                case "remove":
                    const index = root.automationCustomTime.indexOf(selectedSeconds);
                    if(index !== -1) {
                        // Remove the element from the list
                        var next = Array.from(root.automationCustomTime);
                        next.splice(index, 1);
                        root.automationCustomTime = next;
                    }
                    break;
                default:
                    Logger.e("video-wallpaper", "Error, action not found:", action);
            }
        }
    }

    
    /********************************
    * Save settings functionality
    ********************************/
    function saveSettings() {
        if(pluginApi == null) {
            Logger.e("video-wallpaper", "Cannot save, pluginApi is null");
            return;
        }
        if (customTimeText.trim() && !createCustomTime.save()) throw new Error("Invalid automation time");

        saveMonitorProperty("automation", automation);
        saveMonitorProperty("automationMode", automationMode);
        saveMonitorProperty("automationTime", automationTime);

    }
}
