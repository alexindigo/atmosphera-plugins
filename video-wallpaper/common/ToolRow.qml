import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.Commons
import qs.Widgets
import "MonitorCommands.js" as Commands

RowLayout {
    id: root
    Layout.fillWidth: true

    
    /********************************
    * PROPERTIES
    ********************************/
    // Required properties
    required property var pluginApi

    required property string screenName

    // Optional properties
    // Use the inherited Item.enabled control input, not a shadow property.
    property var monitorSpecific: undefined
    property var settings: pluginApi?.pluginSettings || ({})
    property var settingWriter: null
    readonly property var monitorCommand: Commands.create(function () { return root.pluginApi?.pluginSettings?.monitors; },
        function (value) { root.pluginApi.pluginSettings.monitors = value; }, function (value) { return Settings.store.copyValue(value); },
        function () { return root.pluginApi?.manifest?.metadata?.defaultSettings; })

    // Monitor specific properties
    readonly property bool isPlaying: Commands.value(settings.monitors, screenName, "isPlaying", pluginApi?.manifest?.metadata?.defaultSettings)
    readonly property bool isMuted: Commands.value(settings.monitors, screenName, "isMuted", pluginApi?.manifest?.metadata?.defaultSettings)

    // Global properties
    readonly property bool globalMonitorSpecific: settings.monitorSpecific || false

    // Local properties
    readonly property bool _monitorSpecific: monitorSpecific === undefined ? globalMonitorSpecific : (typeof monitorSpecific === "boolean" ? monitorSpecific : false);


    /********************************
    * FUNCTIONS
    ********************************/
    function random() {
        if(pluginApi?.mainInstance == null) {
            Logger.e("video-wallpaper", "Main instance isn't loaded");
            return;
        }

        pluginApi.mainInstance.random(screenName);
    }

    function clear() {
        if(pluginApi?.mainInstance == null) {
            Logger.e("video-wallpaper", "Main instance isn't loaded");
            return;
        }

        pluginApi.mainInstance.clear(screenName);
    }

    function togglePlaying() {
        if (pluginApi == null) return;

        saveSetting("isPlaying", !isPlaying);
    }

    function toggleMute() {
        if(pluginApi == null) return;

        saveSetting("isMuted", !isMuted);
    }

    function saveSetting(key: string, value: var) {
        if (typeof settingWriter === "function") { settingWriter(key, value); return; }
        var names = _monitorSpecific ? [screenName] : Array.from(Quickshell.screens).map(screen => screen.name);
        if (!names.length) return;
        monitorCommand.submit(names.map(name => ({op: "set", screen: name, field: key, value: value})));

        pluginApi.saveSettings();
    }


    /********************************
    * COMPONENTS
    ********************************/
    NButton {
        icon: "dice"
        enabled:     root.enabled
        text:        root.pluginApi?.tr("common.tool_row.random.text")
        tooltipText: root.pluginApi?.tr("common.tool_row.random.tooltip")
        onClicked:   root.random()
    }

    NButton {
        icon: "clear-all"
        enabled:     root.enabled
        text:        root.pluginApi?.tr("common.tool_row.clear.text")
        tooltipText: root.pluginApi?.tr("common.tool_row.clear.tooltip")
        onClicked:   root.clear()
    }

    NButton {
        enabled:     root.enabled
        icon:        root.isPlaying ? "media-pause" : "media-play"
        text:        root.isPlaying ? root.pluginApi?.tr("common.tool_row.pause.text")    : root.pluginApi?.tr("common.tool_row.play.text")
        tooltipText: root.isPlaying ? root.pluginApi?.tr("common.tool_row.pause.tooltip") : root.pluginApi?.tr("common.tool_row.play.tooltip")
        onClicked:   root.togglePlaying();
    }

    NButton {
        enabled:     root.enabled
        icon:        root.isMuted ? "volume-high" : "volume-mute"
        text:        root.isMuted ? root.pluginApi?.tr("common.tool_row.unmute.text")    : root.pluginApi?.tr("common.tool_row.mute.text")
        tooltipText: root.isMuted ? root.pluginApi?.tr("common.tool_row.unmute.tooltip") : root.pluginApi?.tr("common.tool_row.mute.tooltip")
        onClicked:   root.toggleMute()
    }
}
