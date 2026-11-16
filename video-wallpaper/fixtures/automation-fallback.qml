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
                property var ticks: Object.create(null)
                property var beforeTicks: Object.create(null)
                property var expectedByMonitor: Object.create(null)
                property real observationTime: 500
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
                            var domains = Object.create(null);
                            for (var screen of Quickshell.screens) {
                                var domain = screen.name === Quickshell.screens[0].name ? expected : {
                                    automation: api.pluginSettings.automation,
                                    automationMode: api.pluginSettings.automationMode,
                                    automationTime: api.pluginSettings.automationTime
                                };
                                domains[screen.name] = domain;
                                if (domain.automation)
                                    observationTime = Math.max(observationTime, domain.automationTime * 1000 + 500);
                            }
                            expectedByMonitor = domains;
                            var component = Qt.createComponent("file://" + Registry.getPluginDir("video-wallpaper") + "/main/Automation.qml");
                            check(component.status === Component.Ready, component.errorString());
                            consumer = component.createObject(root, {pluginApi: api});
                            check(!!consumer, "actual timer consumer");
                            function tick(name, mode) {
                                try {
                                    var domain = Object.getOwnPropertyDescriptor(expectedByMonitor, name)?.value;
                                    check(name !== undefined && !!domain && domain.automation && mode === domain.automationMode, "timer selected domain and mode");
                                    ticks[name] = (ticks[name] || 0) + 1;
                                } catch (error) { console.error(String(error)); Qt.exit(2); }
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
                        if (cold) { beforeTicks = Object.assign(Object.create(null), ticks); since = Date.now(); phase = "observing"; return; }
                        // Do not edit any automation control. Observe the running
                        // timer after an unrelated native Apply, not just the form.
                        page.wallpapersFolder += "/unrelated";
                        popup.applySettings(); phase = "apply";
                    } else if (phase === "apply" && !popup.busy) {
                        check(receipt && receipt.status !== "failed" && receipt.refreshState === "current", "native Apply current");
                        beforeTicks = Object.assign(Object.create(null), ticks); since = Date.now(); phase = "observing";
                    } else if (phase === "observing" && Date.now() - since > observationTime) {
                        for (var name of Object.keys(expectedByMonitor)) {
                            var count = (ticks[name] || 0) - (beforeTicks[name] || 0);
                            check(expectedByMonitor[name].automation ? count > 0 : count === 0, "unrelated Apply preserves actual timer action " + name);
                        }
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
