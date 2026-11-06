import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    readonly property var settings: pluginApi?.pluginSettings ?? ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})

    property bool valueEnabled: displayBaseline.valueEnabled
    property bool valuePerWorkspace: displayBaseline.valuePerWorkspace
    property bool valueOnlyAtMax: displayBaseline.valueOnlyAtMax
    property int valueMaxVisible: displayBaseline.project("valueMaxVisible")
    property int valueDebounceMs: displayBaseline.project("valueDebounceMs")
    property int valueMaxEventsPerSecond: displayBaseline.project("valueMaxEventsPerSecond")
    NSettingsBaseline {
        id: displayBaseline
        readonly property bool valueEnabled: settings.enabled ?? defaults.enabled ?? true
        readonly property bool valuePerWorkspace: settings.perWorkspace ?? defaults.perWorkspace ?? false
        readonly property bool valueOnlyAtMax: settings.onlyAtMax ?? defaults.onlyAtMax ?? true
        readonly property int valueMaxVisible: settings.maxVisible ?? defaults.maxVisible ?? 4
        readonly property int valueDebounceMs: settings.debounceMs ?? defaults.debounceMs ?? 300
        readonly property int valueMaxEventsPerSecond: settings.maxEventsPerSecond ?? defaults.maxEventsPerSecond ?? 20
        ranges: [NSettingsRange { field: "valueMaxVisible"; from: rangeValueMaxVisible.from; to: rangeValueMaxVisible.to }, NSettingsRange { field: "valueDebounceMs"; from: rangeValueDebounceMs.from; to: rangeValueDebounceMs.to }, NSettingsRange { field: "valueMaxEventsPerSecond"; from: rangeValueMaxEventsPerSecond.from; to: rangeValueMaxEventsPerSecond.to }]
    }
    readonly property bool settingsDirty: displayBaseline.differs({valueEnabled: root.valueEnabled, valuePerWorkspace: root.valuePerWorkspace, valueOnlyAtMax: root.valueOnlyAtMax, valueMaxVisible: root.valueMaxVisible, valueDebounceMs: root.valueDebounceMs, valueMaxEventsPerSecond: root.valueMaxEventsPerSecond})
    property bool _restartPending: false
    Connections {
        target: root.pluginApi
        function onSettingsCompleted(result) {
            if (!root._restartPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current") return;
            root._restartPending = false;
            root.pluginApi.mainInstance?.restartDaemon();
        }
    }

    spacing: Style.marginM

    function saveSettings(restart) {
        if (!pluginApi) return;
        pluginApi.pluginSettings.enabled = root.valueEnabled;
        pluginApi.pluginSettings.perWorkspace = root.valuePerWorkspace;
        pluginApi.pluginSettings.onlyAtMax = root.valueOnlyAtMax;
        pluginApi.pluginSettings.maxVisible = root.valueMaxVisible;
        pluginApi.pluginSettings.debounceMs = root.valueDebounceMs;
        pluginApi.pluginSettings.maxEventsPerSecond = root.valueMaxEventsPerSecond;
        if (pluginApi.saveSettings() !== false)
            root._restartPending = root._restartPending || restart === true;
    }

    // ─── Enable / Disable ───
    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.enabled")
        description: pluginApi?.tr("settings.enabled-desc")
        checked: root.valueEnabled
        onToggled: checked => {
            root.valueEnabled = checked;
            root.saveSettings();
        }
    }

    // ─── Per Workspace ───
    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.per-workspace")
        description: pluginApi?.tr("settings.per-workspace-desc")
        checked: root.valuePerWorkspace
        onToggled: checked => {
            root.valuePerWorkspace = checked;
            root.saveSettings(true);
        }
    }

    // ─── Only at Max ───
    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.only-at-max")
        description: pluginApi?.tr("settings.only-at-max-desc")
        checked: root.valueOnlyAtMax
        onToggled: checked => {
            root.valueOnlyAtMax = checked;
            root.saveSettings(true);
        }
    }

    // ─── Max Visible Columns ───
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.max-visible", {"value": root.valueMaxVisible})
            description: pluginApi?.tr("settings.max-visible-desc")
        }

        NSlider {
            id: rangeValueMaxVisible
            objectName: "settings-range-valueMaxVisible"
            Layout.fillWidth: true
            from: 1
            to: 8
            value: root.valueMaxVisible
            stepSize: 1
            onMoved: {
                root.valueMaxVisible = Math.round(value);
                root.saveSettings(true);
            }
        }
    }

    // ─── Debounce ───
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.debounce", {"value": root.valueDebounceMs})
            description: pluginApi?.tr("settings.debounce-desc")
        }

        NSlider {
            id: rangeValueDebounceMs
            objectName: "settings-range-valueDebounceMs"
            Layout.fillWidth: true
            from: 100
            to: 1000
            value: root.valueDebounceMs
            stepSize: 50
            onMoved: {
                root.valueDebounceMs = Math.round(value);
                root.saveSettings(true);
            }
        }
    }

    // ─── Rate Limit ───
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.rate-limit", {"value": root.valueMaxEventsPerSecond})
            description: pluginApi?.tr("settings.rate-limit-desc")
        }

        NSlider {
            id: rangeValueMaxEventsPerSecond
            objectName: "settings-range-valueMaxEventsPerSecond"
            Layout.fillWidth: true
            from: 5
            to: 50
            value: root.valueMaxEventsPerSecond
            stepSize: 5
            onMoved: {
                root.valueMaxEventsPerSecond = Math.round(value);
                root.saveSettings(true);
            }
        }
    }

    // ─── Status ───
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        spacing: Style.marginM

        Rectangle {
            width: Math.round(8 * Style.uiScaleRatio)
            height: Math.round(8 * Style.uiScaleRatio)
            radius: Math.round(4 * Style.uiScaleRatio)
            color: {
                const status = pluginApi?.mainInstance?.status ?? "stopped";
                if (status === "running") return AtmoColor.mPrimary;
                if (status === "error") return AtmoColor.mError;
                return AtmoColor.mOutline;
            }
        }

        NText {
            text: {
                const status = pluginApi?.mainInstance?.status ?? "stopped";
                if (status === "running") return pluginApi?.tr("settings.status-running");
                if (status === "error") return pluginApi?.tr("settings.status-error");
                return pluginApi?.tr("settings.status-stopped");
            }
            Layout.fillWidth: true
        }
    }

    // ─── About ───
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        spacing: Style.marginXS

        NText {
            text: pluginApi?.tr("settings.about-title")
            font.bold: true
        }

        NText {
            text: pluginApi?.tr("settings.about-credit")
            opacity: 0.7
            pointSize: Style.fontSizeS
        }

        NText {
            text: pluginApi?.tr("settings.about-date", {"date": "2026-02-19"})
            opacity: 0.5
            pointSize: Style.fontSizeXS
        }

        NText {
            text: "v" + (pluginApi?.manifest?.version ?? "1.1.0")
            opacity: 0.5
            pointSize: Style.fontSizeXS
        }
    }
}
