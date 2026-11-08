import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM
    Layout.fillWidth: true

    required property var pluginApi
    required property bool active

    readonly property bool isMuted:
        pluginApi.pluginSettings.isMuted ||
        false

    NSettingsBaseline {
        id: displayBaseline
        readonly property real volume: root.pluginApi?.initialSettings?.volume ?? 100
        ranges: [NSettingsRange { field: "volume"; from: volumeInput.from; to: volumeInput.to }]
    }
    property real volume: displayBaseline.project("volume")
    readonly property bool settingsDirty: displayBaseline.differs({volume: volume})


    // Volume
    NValueSlider {
        id: volumeInput
        objectName: "settings-range-volume"
        enabled: root.active && !root.isMuted
        from: 0
        to: 100
        value: root.volume
        stepSize: Settings.data.audio.volumeStep
        label: pluginApi?.tr("settings.volume.label") || "Volume"
        description: pluginApi?.tr("settings.volume.description") || "The volume of the video wallpaper playing."
        onMoved: value => root.volume = value
    }


    /********************************
    * Save settings functionality
    ********************************/
    function saveSettings() {
        if(!pluginApi) {
            Logger.e("mpvpaper", "Cannot save: pluginApi is null");
            return;
        }
        pluginApi.pluginSettings.volume = volume;
    }
}
