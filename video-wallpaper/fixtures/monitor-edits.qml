import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Plugins
import qs.Widgets

// Controls author intent, navigation only projects it, and native Apply owns IO.
ShellRoot {
    SettingsBootstrap { id: bootstrap }
    Loader {
        active: bootstrap.ready
        sourceComponent: Component {
            Item {
                id: root
                property var api: null
                property var receipt: null
                property bool started: false
                property bool cancelled: false
                property string phase: "start"
                readonly property bool cold: Quickshell.env("MINOR_REVIEW_COLD") === "1"
                readonly property string testCase: Quickshell.env("REVIEW23_CASE")
                function check(ok, label) { if (!ok) throw new Error("MONITOR_EDITS_ASSERT: " + phase + " " + label); }
                function find(item, predicate) {
                    if (predicate(item)) return item;
                    for (var child of item.children || []) {
                        var found = find(child, predicate);
                        if (found) return found;
                    }
                    return null;
                }
                function control(label, signalName) {
                    var item = find(popup.settingsPage, item => item.label === api.tr(label) && typeof item[signalName] === "function");
                    check(!!item, "actual control " + label);
                    return item;
                }
                function navigate() {
                    var bar = find(popup.settingsPage, item => "activeMonitor" in item);
                    check(!!bar && Quickshell.screens.length > 1, "real multiple-monitor selector");
                    bar.currentIndex = 1;
                    bar.currentIndex = 0;
                }
                function edit() {
                    // Equal to inherited/default/projected values is still intent.
                    control("settings.automation.toggle.label", "toggled").toggled(true);
                    control("settings.automation.mode.label", "selected").selected("alphabetically");
                    var time = find(popup.settingsPage, item => "time" in item && item.time === 300 && typeof item.clicked === "function");
                    check(!!time, "actual preset time button"); time.clicked();
                    var volume = find(popup.settingsPage, item => item.objectName === "settings-range-volume");
                    var orientation = find(popup.settingsPage, item => item.objectName === "settings-range-orientation");
                    check(!!volume && !!orientation, "actual projected range controls");
                    volume.moved(1.0); orientation.moved(270);
                    control("settings.advanced.fill_mode.label", "selected").selected(api.manifest.metadata.defaultSettings.fillMode);
                    control("settings.advanced.profile.label", "selected").selected(api.manifest.metadata.defaultSettings.profile);
                    control("settings.advanced.hardware_acceleration.label", "toggled").toggled(false);
                    if (testCase !== "acknowledge") navigate();
                }
                function begin() {
                    if (started || !Settings.isLoaded) return;
                    started = true;
                    Service._openSettingsOwner("video-wallpaper", function (owner) {
                        try {
                            check(!!owner, "native owner");
                            api = Service.createPluginAPI("video-wallpaper", JSON.parse(Quickshell.env("MINOR_REVIEW_MANIFEST")), owner, {}, {}, {});
                            var loaded = Object.assign({}, Service.loadedPlugins);
                            loaded["video-wallpaper"] = {api: api}; Service.loadedPlugins = loaded;
                            popup.openPluginSettings(api.manifest, "settings"); phase = "page";
                        } catch (error) { console.error(String(error)); Qt.exit(2); }
                    });
                }
                function drive() {
                    var page = popup.settingsPage;
                    if (phase === "page" && popup.opened && page) {
                        check(!page.settingsDirty, "opening and cold display clean");
                        if (cold) { console.log("MINOR_REVIEW: COLD_PASS"); Qt.quit(); return; }
                        if (testCase === "navigation" || testCase === "domains") {
                            if (testCase === "domains") {
                                control("settings.monitor_specific.label", "toggled").toggled(false);
                                control("settings.monitor_specific.label", "toggled").toggled(true);
                            }
                            navigate(); check(!page.settingsDirty, "navigation does not author fields");
                            page.wallpapersFolder += "/unrelated";
                        } else edit();
                        if (!cancelled && testCase !== "navigation") {
                            popup.requestClose(); check(popup.discardPending, "Cancel retains equal-valued intent");
                            popup.confirmDiscard(); phase = "cancel"; return;
                        }
                        if (testCase === "refusal") {
                            phase = "blocking"; fault.command = ["python3", "-c", "from pathlib import Path;import sys;p=Path(sys.argv[1]);p.rename(str(p)+'.original');p.mkdir()", Quickshell.env("MONITOR_INTENT_FILE")]; fault.running = true;
                        } else { popup.applySettings(); phase = "apply"; }
                    } else if (phase === "cancel" && !popup.visible && !popup.currentPlugin) {
                        var record = api.pluginSettings.monitors[Quickshell.screens[0].name];
                        check(record.volume === 1.75 && record.orientation === 333 && record.automation === undefined, "Cancel preserves live record");
                        cancelled = true; popup.openPluginSettings(api.manifest, "settings"); phase = "page";
                    } else if (phase === "refused" && !popup.busy) {
                        check(receipt && receipt.status === "failed" && !!page && page.settingsDirty, "failed Apply retains intent");
                        var live = api.pluginSettings.monitors[Quickshell.screens[0].name];
                        check(live.volume === 1.75 && live.automation === undefined, "failure preserves live record");
                        phase = "repairing"; fault.command = ["python3", "-c", "from pathlib import Path;import sys;p=Path(sys.argv[1]);p.rmdir();Path(str(p)+'.original').rename(p)", Quickshell.env("MONITOR_INTENT_FILE")]; fault.running = true;
                    } else if (phase === "apply" && !popup.busy) {
                        check(receipt && receipt.status !== "failed" && receipt.refreshState === "current", "native Apply current");
                        check(!page.settingsDirty && !popup.dirty, "accepted selected intent acknowledged");
                        console.log("MINOR_REVIEW: SAVED_PASS"); Qt.quit();
                    }
                }
                Process {
                    id: fault
                    onExited: code => {
                        try {
                            check(code === 0, "owned IO control");
                            if (root.phase === "blocking") { popup.applySettings(); root.phase = "refused"; }
                            else { popup.applySettings(); root.phase = "apply"; }
                        } catch (error) { console.error(String(error)); Qt.exit(2); }
                    }
                }
                FloatingWindow {
                    implicitWidth: 1000; implicitHeight: 850; visible: true
                    NPluginSettingsPopup { id: popup; parent: Overlay.overlay; onSettingsCompleted: result => root.receipt = result }
                }
                Connections { target: Settings; function onSettingsLoaded() { root.begin(); } }
                Component.onCompleted: begin()
                Timer { interval: 40; repeat: true; running: true; onTriggered: { try { root.drive(); } catch (error) { console.error(String(error)); Qt.exit(2); } } }
                Timer { interval: 25000; running: true; onTriggered: { console.error("MONITOR_EDITS_ASSERT: watchdog", root.phase); Qt.exit(2); } }
            }
        }
    }
}
