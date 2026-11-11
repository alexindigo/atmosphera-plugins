import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../common/MonitorCommands.js" as Commands

Item {
    id: root
    required property var pluginApi
    readonly property var monitorCommand: Commands.create(function () { return root.pluginApi?.pluginSettings?.monitors; },
        function (value) { root.pluginApi.pluginSettings.monitors = value; }, function (value) { return Settings.store.copyValue(value); })


    /***************************
    * PROPERTIES
    ***************************/
    readonly property bool enabled: pluginApi?.pluginSettings?.enabled ?? false

    required property var random
    required property var clear
    required property var setWallpaper


    /***************************
    * FUNCTIONS
    ***************************/
    function deltaChangeMonitorProperty(key: string, delta: double, screen: string): void {
        submitMonitorCommand("delta", key, delta, screen);
    }

    function toggleMonitorProperty(key: string, screen: string): void {
        submitMonitorCommand("toggle", key, undefined, screen);
    }

    function saveMonitorProperty(key: string, value: var, screen: string): void {
        submitMonitorCommand("set", key, value, screen);
    }

    function submitMonitorCommand(op, key, value, screen) {
        if (!pluginApi) return;
        var names = screen === "" ? Array.from(Quickshell.screens).map(screen => screen.name) : [screen];
        if (!names.length) return;
        monitorCommand.submit(names.map(name => ({op: op, screen: name, field: key, value: value})));
        pluginApi.saveSettings();
    }

    function getMonitorProperty(key: string, screen: string): string {
        if(pluginApi == null) {
            Logger.e("video-wallpaper", "PluginAPI is null.");
            return;
        }

        if (screen === "") {
            let values = [];
            for (const screen of Quickshell.screens) {
                var value = Commands.own(Commands.record(root.pluginApi?.pluginSettings?.monitors, screen.name), key);
                if (value !== undefined) {
                    values.push(`${screen.name}: ${value}\n`);
                }
            }

            return values.join(", ");
        } else {
            var value = Commands.own(Commands.record(pluginApi?.pluginSettings?.monitors, screen), key);
            return value === undefined ? "" : String(value);
        }
    }


    /***************************
    * IPC HANDLER
    ***************************/
    IpcHandler {
        target: "plugin:videowallpaper"


        function random() {
            root.random();
        }

        function clear() {
            root.clear();
        }

        // Current wallpaper
        function setWallpaper(path: string, screen: string) {
            root.saveMonitorProperty("currentWallpaper", path, screen);
        }

        function getWallpaper(screen: string): string {
            return root.getMonitorProperty("currentWallpaper", screen);
        }

        // Enabled
        function setEnabled(enabled: bool) {
            if (root.pluginApi == null) return;

            root.pluginApi.pluginSettings.enabled = enabled;
            root.pluginApi.saveSettings();
        }

        function getEnabled(): bool {
            return root.enabled;
        }

        function toggleEnabled() {
            setEnabled(!root.enabled);
        }

        // Is playing
        function resume(screen: string) {
            root.saveMonitorProperty("isPlaying", true, screen);
        }

        function pause(screen: string) {
            root.saveMonitorProperty("isPlaying", false, screen);
        }

        function togglePlaying(screen: string) {
            root.toggleMonitorProperty("isPlaying", screen);
        }

        // Mute / unmute
        function mute(screen: string) {
            root.saveMonitorProperty("isMuted", true, screen);
        }

        function unmute(screen: string) {
            root.saveMonitorProperty("isMuted", false, screen);
        }

        function toggleMute(screen: string) {
            root.toggleMonitorProperty("isMuted", screen);
        }

        // Volume
        function setVolume(volume: real, screen: string) {
            root.saveMonitorProperty("volume", volume, screen);
        }

        function increaseVolume(screen: string) {
            root.deltaChangeMonitorProperty("volume", Settings.data.audio.volumeStep, screen);
        }

        function decreaseVolume(screen: string) {
            root.deltaChangeMonitorProperty("volume", -Settings.data.audio.volumeStep, screen);
        }

        // Panel
        function openPanel() {
            root.pluginApi.withCurrentScreen(screen => {
                root.pluginApi.openPanel(screen);
            });
        }
    }
}
