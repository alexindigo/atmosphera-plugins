import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property string valueOutputDir: displayBaseline.valueOutputDir
    property int valueFps: displayBaseline.valueFps
    property int valueMaxRecordingSeconds: displayBaseline.valueMaxRecordingSeconds
    NSettingsBaseline {
        id: displayBaseline
        readonly property string valueOutputDir: cfg.outputDir ?? defaults.outputDir
        readonly property int valueFps: cfg.fps ?? defaults.fps
        readonly property int valueMaxRecordingSeconds: cfg.maxRecordingSeconds ?? defaults.maxRecordingSeconds
    }
    readonly property bool settingsDirty: displayBaseline.differs({valueOutputDir: root.valueOutputDir, valueFps: root.valueFps, valueMaxRecordingSeconds: root.valueMaxRecordingSeconds})

    spacing: Style.marginL

    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.outputDir.label")
        description: pluginApi?.tr("settings.outputDir.description")
        text: root.valueOutputDir
        onTextChanged: root.valueOutputDir = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.fps.label")
        description: pluginApi?.tr("settings.fps.description")
        text: String(root.valueFps)
        onTextChanged: root.valueFps = parseInt(text) || 20
    }

    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.maxRecordingSeconds.label")
        description: pluginApi?.tr("settings.maxRecordingSeconds.description")
        text: String(root.valueMaxRecordingSeconds)
        onTextChanged: root.valueMaxRecordingSeconds = parseInt(text) || 0
    }

    function saveSettings() {
        if (!pluginApi) return
        pluginApi.pluginSettings.outputDir = root.valueOutputDir
        pluginApi.pluginSettings.fps = root.valueFps
        pluginApi.pluginSettings.maxRecordingSeconds = root.valueMaxRecordingSeconds
        pluginApi.saveSettings()
    }
}
