import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

RowLayout {
    id: root

    required property var pluginApi

    Layout.fillWidth: true

    property bool isPlaying:
        pluginApi.pluginSettings.isPlaying ||
        false

    property bool isMuted:
        pluginApi.pluginSettings.isMuted ||
        false

    // Presentation never selects a persistence owner. Both Settings and runtime
    // callers supply the action appropriate to their captured context.
    required property var playingWriter
    required property var muteWriter
    required property var randomAction
    required property var clearAction


    NButton {
        enabled: root.enabled
        icon: "dice"
        text: pluginApi?.tr("settings.actions.random.text") || "Random"
        tooltipText: pluginApi?.tr("settings.actions.random.tooltip") || "Choose a random wallpaper from the wallpapers folder."
        onClicked: root.random()
    }

    NButton {
        enabled: root.enabled
        icon: "clear-all"
        text: pluginApi?.tr("settings.actions.clear.text") || "Clear"
        tooltipText: pluginApi?.tr("settings.actions.clear.tooltip") || "Clear the current wallpaper."
        onClicked: root.clear()
    }

    NButton {
        enabled: root.enabled
        icon: root.isPlaying ? "media-pause" : "media-play"
        text: root.isPlaying ? pluginApi?.tr("settings.actions.pause.text") || "Pause" : pluginApi?.tr("settings.actions.resume.text") || "Resume";
        tooltipText: root.isPlaying ? pluginApi?.tr("settings.actions.pause.tooltip") || "Pause the video wallpaper." : pluginApi?.tr("settings.actions.resume.tooltip") || "Resume the video wallpaper.";
        onClicked: root.togglePlaying();
    }

    NButton {
        enabled: root.enabled
        icon: root.isMuted ? "volume-high" : "volume-mute"
        text: root.isMuted ? pluginApi?.tr("settings.actions.unmute.text") || "Unmute" : pluginApi?.tr("settings.actions.mute.text") || "Mute";
        tooltipText: root.isMuted ? pluginApi?.tr("settings.actions.unmute.tooltip") || "Unmute the video wallpaper." : pluginApi?.tr("settings.actions.mute.tooltip") || "Mute the video wallpaper.";
        onClicked: root.toggleMute()
    }


    /********************************
    * Button functionality
    ********************************/
    function random() {
        randomAction();
    }

    function clear() {
        clearAction();
    }

    function togglePlaying() {
        if (pluginApi == null) return;

        playingWriter(!root.isPlaying);
    }

    function toggleMute() {
        if(pluginApi == null) return;

        muteWriter(!root.isMuted);
    }
}
