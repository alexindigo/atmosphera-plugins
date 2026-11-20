import QtQuick
import Quickshell
import Quickshell.Io

// This fixture supplies only the host logger; Main and its helper are real.
// MUSIC_CACHE_DIR must contain a tracked download already at its configured limit.
ShellRoot {
    id: test
    property var consumer: null
    property var dictionary: ({})

    FileView {
        path: Quickshell.env("MUSIC_PLUGIN_ROOT") + "/i18n/en.json"
        onLoaded: test.dictionary = JSON.parse(text())
    }
    QtObject {
        id: api
        property var manifest: ({metadata: {defaultSettings: {}}})
        property var pluginSettings: ({})
        function tr(key, args) {
            var result = test.dictionary;
            for (var part of key.split(".")) result = result?.[part];
            return typeof result === "string" ? result : key;
        }
    }
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (!test.dictionary.errors || test.consumer) return;
            var component = Qt.createComponent("file://" + Quickshell.env("MUSIC_PLUGIN_ROOT") + "/Main.qml");
            if (component.status !== Component.Ready) {
                console.error(component.errorString());
                Qt.exit(2);
                return;
            }
            test.consumer = component.createObject(test, {pluginApi: api});
            if (!test.consumer) { Qt.exit(2); return; }
            test.consumer.lastErrorChanged.connect(function () {
                if (!test.consumer.lastError) return;
                if (test.consumer.lastError !== test.dictionary.errors.downloadLimitReached) {
                    console.error("Unexpected download error: " + test.consumer.lastError);
                    Qt.exit(2);
                    return;
                }
                console.log("MUSIC_LIMIT_UI: PASS " + test.consumer.lastError);
                Qt.quit();
            });
            test.consumer.downloadEntry({title: "Fixture", url: "https://example.invalid/track"});
        }
    }
    Timer {
        interval: 10000
        running: true
        onTriggered: { console.error("MUSIC_LIMIT_UI: timeout"); Qt.exit(2); }
    }
}
