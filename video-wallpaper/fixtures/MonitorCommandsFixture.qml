import QtQuick
import Quickshell
import ConfigQml 1.0
import "../common/MonitorCommands.js" as Commands

ShellRoot {
    id: root
    property bool started: false
    property var staged: null
    readonly property var data: store.values
    readonly property bool cold: Quickshell.env("I5_MAP_COLD") === "1"
    function check(ok, label) { if (!ok) throw new Error("I5_MONITOR_COMMAND_ASSERT: " + label); }
    ConfigStore {
        id: store
        autoSave: false
        schema: ConfigSchema {
            ConfigValue {
                key: "monitors"; valueType: ConfigValue.Map; defaultValue: ({})
                ConfigValue {
                    valueType: ConfigValue.Record; open: true
                    ConfigValue { key: "currentWallpaper"; valueType: ConfigValue.String; optional: true }
                    ConfigValue { key: "isMuted"; valueType: ConfigValue.Boolean; optional: true }
                    ConfigValue { key: "volume"; valueType: ConfigValue.Real; optional: true }
                    ConfigValue { key: "automationTime"; valueType: ConfigValue.Real; optional: true }
                }
            }
        }
        sources: [JsonFileSource {
            sourceId: "user"; layerId: "user"; path: Quickshell.env("I5_MAP_FILE")
            writable: true; optional: true; unknownData: JsonFileSource.Preserve
        }]
    }
    function finish() { store.close(function () { console.log("I5_MONITOR_COMMAND: " + (root.cold ? "COLD_PASS" : "SAVED_PASS")); Qt.exit(0); }); }
    function observe() {
        check(Commands.record(data.monitors, "__proto__").currentWallpaper === "captured", "opaque screen consumer");
        check(Commands.record(data.monitors, "constructor").volume === 0.75, "batch scalar consumer");
        check(Commands.record(data.monitors, "constructor").isMuted === true, "batch toggle consumer");
        check(Commands.record(data.monitors, "offline/\u03bb.1").currentWallpaper === "offline", "offline Unicode screen consumer");
        check(Commands.record(data.monitors, "remove-me") === undefined, "remove screen consumer");
        check(Commands.own(Commands.record(data.monitors, "__proto__"), "wide") !== undefined, "opaque native number retained");
        var defaults = Commands.record(data.monitors, "absent-defaults");
        check(defaults.volume === 0.5 && defaults.automationTime === 930 && defaults.isMuted === false, "absent scalar commands use injected effective defaults");
        check(Commands.own(defaults, "currentWallpaper") === undefined, "relative edits do not expand unrelated optional defaults");
    }
    function begin() {
        if (started || !store.ready) return;
        started = true;
        try {
            if (cold) { observe(); finish(); return; }
            var prefix = store.info(["monitors"]).latestInput;
            // Cross the QML-property boundary with an owned JS container. Keep
            // native opaque record members untouched inside it.
            staged = store.copyValue(data.monitors);
            var editor = Commands.create(function () { return root.staged; }, function (value) { root.staged = value; }, function (value) { return store.copyValue(value); });
            var input = [{op: "set", screen: "__proto__", field: "currentWallpaper", value: "captured"}];
            var captured = Commands.capture(input);
            input[0].value = "mutated-caller"; input.push({op: "remove", screen: "constructor"});
            editor.submit(captured);
            check(Commands.record(data.monitors, "__proto__").currentWallpaper === "original", "copy editing leaves owner untouched");
            check(store.info(["monitors"]).latestInput === prefix, "staged edit admits no input");
            var assignments = 0;
            var command = Commands.create(function () { return root.staged; }, function (value) {
                check(Commands.record(root.data.monitors, "__proto__").currentWallpaper === "original", "detached until owning assignment");
                assignments++;
                root.data.monitors = value;
            }, function (value) { return store.copyValue(value); }, function () { return {volume: 0.75, automationTime: 900, isMuted: true}; });
            command.submit([{op: "delta", screen: "constructor", field: "volume", value: 0.25},
                {op: "toggle", screen: "constructor", field: "isMuted"},
                {op: "set", screen: "offline/\u03bb.1", field: "currentWallpaper", value: "offline"},
                {op: "remove", screen: "remove-me"},
                {op: "delta", screen: "absent-defaults", field: "volume", value: -0.25},
                {op: "delta", screen: "absent-defaults", field: "automationTime", value: 30},
                {op: "toggle", screen: "absent-defaults", field: "isMuted"}]);
            check(assignments === 1, "one complete assignment per batch");
            check(Number(store.info(["monitors"]).latestInput) === Number(prefix) + 1, "one owning input");
            observe();
            store.save(function (result) {
                try { check(result.status === "saved", "acknowledged save"); observe(); finish(); }
                catch (error) { console.error(String(error)); Qt.exit(2); }
            });
        } catch (error) { console.error(String(error)); Qt.exit(2); }
    }
    Timer { interval: 10; repeat: true; running: true; onTriggered: root.begin() }
    Timer { interval: 20000; running: true; onTriggered: { console.error("I5_MONITOR_COMMAND_ASSERT: watchdog"); Qt.exit(2); } }
}
