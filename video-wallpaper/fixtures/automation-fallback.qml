import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Services.Plugins
import qs.Widgets

// Run through the native popup with a private synthetic plugin preference file.
ShellRoot {
    SettingsBootstrap { id: bootstrap }
    Loader {
        active: bootstrap.ready
        sourceComponent: Component {
            Item {
                id: root
                property var api: null
                property var consumer: null
                property var receipt: null
                property var displayed: null
                property bool initialDirty: false
                property int ticks: 0
                property int beforeTicks: 0
                property real since: 0
                property bool started: false
                property string phase: "start"
                readonly property bool cold: Quickshell.env("MINOR_REVIEW_COLD") === "1"
                readonly property var expected: JSON.parse(Quickshell.env("AUTOMATION_EXPECTED"))
                function check(ok, label) { if (!ok) throw new Error("AUTOMATION_FALLBACK_ASSERT: " + phase + " " + label); }
                function begin() {
                    if (started || !Settings.isLoaded) return;
                    started = true;
                    Service._openSettingsOwner("video-wallpaper", function (owner) {
                        try {
                            check(!!owner, "native owner");
                            api = Service.createPluginAPI("video-wallpaper", JSON.parse(Quickshell.env("MINOR_REVIEW_MANIFEST")), owner, {}, {}, {});
                            var loaded = Object.assign({}, Service.loadedPlugins);
                            loaded["video-wallpaper"] = {api: api}; Service.loadedPlugins = loaded;
                            var component = Qt.createComponent("file://" + Registry.getPluginDir("video-wallpaper") + "/main/Automation.qml");
                            check(component.status === Component.Ready, component.errorString());
                            consumer = component.createObject(root, {pluginApi: api});
                            check(!!consumer, "actual timer consumer");
                            function tick(name, mode) {
                                check(name === Quickshell.screens[0].name && mode === expected.automationMode, "timer selected domain and mode");
                                ticks++;
                            }
                            consumer.random.connect(function (name) { tick(name, "random"); });
                            consumer.nextWallpaper.connect(function (name) { tick(name, "alphabetically"); });
                            popup.openPluginSettings(api.manifest, "settings"); phase = "page";
                        } catch (error) { console.error(String(error)); Qt.exit(2); }
                    });
                }
                function drive() {
                    var page = popup.settingsPage;
                    if (phase === "page" && popup.opened && page) {
                        displayed = {automation: page.automationEnabled, automationMode: page.automationMode, automationTime: page.automationTime};
                        initialDirty = page.settingsDirty;
                        if (cold) { beforeTicks = ticks; since = Date.now(); phase = "observing"; return; }
                        // Do not edit any automation control. Observe the running
                        // timer after an unrelated native Apply, not just the form.
                        page.wallpapersFolder += "/unrelated";
                        popup.applySettings(); phase = "apply";
                    } else if (phase === "apply" && !popup.busy) {
                        check(receipt && receipt.status !== "failed" && receipt.refreshState === "current", "native Apply current");
                        beforeTicks = ticks; since = Date.now(); phase = "observing";
                    } else if (phase === "observing" && Date.now() - since > expected.automationTime * 1000 + 500) {
                        check(expected.automation ? ticks > beforeTicks : ticks === beforeTicks, "unrelated Apply preserves actual timer action");
                        check(displayed.automation === expected.automation && displayed.automationMode === expected.automationMode && displayed.automationTime === expected.automationTime, "editor inherits each missing field");
                        check(!initialDirty, "display baseline uses the same effective automation");
                        console.log(cold ? "MINOR_REVIEW: COLD_PASS" : "MINOR_REVIEW: SAVED_PASS"); Qt.quit();
                    }
                }
                FloatingWindow {
                    implicitWidth: 1000; implicitHeight: 850; visible: true
                    NPluginSettingsPopup { id: popup; parent: Overlay.overlay; onSettingsCompleted: result => root.receipt = result }
                }
                Connections { target: Settings; function onSettingsLoaded() { root.begin(); } }
                Component.onCompleted: begin()
                Timer { interval: 40; repeat: true; running: true; onTriggered: { try { root.drive(); } catch (error) { console.error(String(error)); Qt.exit(2); } } }
                Timer { interval: 20000; running: true; onTriggered: { console.error("AUTOMATION_FALLBACK_ASSERT: watchdog", root.phase); Qt.exit(2); } }
            }
        }
    }
}
