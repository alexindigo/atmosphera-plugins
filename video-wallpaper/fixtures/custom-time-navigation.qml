import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Plugins
import qs.Widgets

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
                property string phase: "start"
                readonly property bool cold: Quickshell.env("MINOR_REVIEW_COLD") === "1"
                readonly property string testCase: Quickshell.env("REVIEW23_CASE")
                readonly property string invalid: testCase === "space" ? " " : "not-a-time"
                function check(ok, label) { if (!ok) throw new Error("CUSTOM_TIME_ASSERT: " + phase + " " + label); }
                function find(item, predicate, seen) {
                    seen = seen || [];
                    if (!item || seen.indexOf(item) !== -1) return null;
                    seen.push(item);
                    if (predicate(item)) return item;
                    var children = Array.from(item.children || []).concat(Array.from(item.resources || []));
                    if (item.contentItem) children.push(item.contentItem);
                    for (var child of children) { var found = find(child, predicate, seen); if (found) return found; }
                    return null;
                }
                function customDialog() {
                    var dialog = find(popup.settingsPage, item => "closePolicy" in item && typeof item.save === "function");
                    check(!!dialog, "actual custom-time dialog"); return dialog;
                }
                function customInput() {
                    var input = find(customDialog(), item => typeof item.isCorrectFormat === "function");
                    check(!!input, "actual custom-time input"); return input;
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
                        check(!page.settingsDirty, "fresh and cold page clean");
                        if (cold) { console.log("MINOR_REVIEW: COLD_PASS"); Qt.quit(); return; }
                        page.currentWallpaper = "first-choice"; page.volume = 0.25;
                        customDialog().open(); page.customTimeText = invalid; customInput().accepted(); customDialog().close();
                        check(page.customTimeText === invalid, "dismissed invalid input retained");
                        var bar = find(page, item => "activeMonitor" in item);
                        var automation = find(page, item => "selectedMonitor" in item && "automationCustomTime" in item);
                        check(!!bar && !!automation && Quickshell.screens.length === 2, "actual two-monitor editor");
                        if (testCase === "monitor" || testCase === "discard") {
                            bar.currentIndex = 1;
                            check(automation.selectedMonitor === bar.activeMonitor && page.currentWallpaper === "" && page.volume === 1, "selection and displayed monitor stay aligned");
                            page.currentWallpaper = "second-choice"; page.volume = 0.5;
                            bar.currentIndex = 0;
                            check(page.currentWallpaper === "first-choice" && page.volume === 0.25, "monitor navigation retains each selected draft");
                        }
                        if (testCase === "domain" || testCase === "space") {
                            var toggle = find(page, item => item.label === api.tr("settings.monitor_specific.label") && typeof item.toggled === "function");
                            check(!!toggle, "actual domain toggle");
                            toggle.toggled(false); check(!page.monitorSpecific, "domain selection completes with invalid dialog input");
                            toggle.toggled(true); check(page.monitorSpecific, "original domain restored");
                        }
                        check(page.customTimeText === invalid, "selection never discards global dialog input");
                        popup.requestClose(); check(popup.discardPending, "parent Close asks about retained work");
                        popup.keepEditing(); check(page.customTimeText === invalid, "Keep editing retains invalid input");
                        if (testCase === "discard") {
                            popup.requestClose(); popup.confirmDiscard(); phase = "discarded"; return;
                        }
                        page.wallpapersFolder += "/unrelated";
                        popup.applySettings(); phase = "refused";
                    } else if (phase === "refused" && !popup.busy) {
                        check(receipt && receipt.status === "failed" && popup.saveFailed && page.settingsDirty, "invalid Apply truthfully refuses");
                        check(page.customTimeText === invalid, "refusal retains invalid input");
                        var live = api.pluginSettings.monitors[Quickshell.screens[0].name];
                        check(live.volume === 1.75 && live.currentWallpaper === undefined, "refusal preserves live preferences");
                        raw.reload(); raw.waitForJob();
                        check(JSON.parse(raw.text()).monitors[Quickshell.screens[0].name].volume === 1.75, "refusal preserves disk preferences");
                        customDialog().open();
                        var cancel = find(customDialog(), item => item.text === api.tr("settings.automation.time.custom.create.cancel") && typeof item.clicked === "function");
                        check(!!cancel, "actual explicit custom Cancel"); cancel.clicked();
                        check(page.customTimeText === "", "explicit custom Cancel clears only its draft");
                        page.customTimeText = "00:02";
                        if (testCase !== "domain") { customDialog().open(); customInput().accepted(); check(page.customTimeText === "", "valid Enter commits custom time"); }
                        popup.applySettings(); phase = "saved";
                    } else if (phase === "saved" && !popup.busy) {
                        check(receipt && receipt.status !== "failed" && receipt.refreshState === "current", "valid native Apply current");
                        check(!page.settingsDirty && !popup.dirty && page.customTimeText === "", "accepted page clean");
                        check(api.pluginSettings.automationCustomTime.length === 1 && api.pluginSettings.automationCustomTime[0] === 120, "custom time reaches live native consumer");
                        console.log("MINOR_REVIEW: SAVED_PASS"); Qt.quit();
                    } else if (phase === "discarded" && !popup.visible && !popup.currentPlugin) {
                        var live = api.pluginSettings.monitors[Quickshell.screens[0].name];
                        check(live.volume === 1.75 && live.currentWallpaper === undefined, "explicit parent discard preserves live preferences");
                        console.log("MINOR_REVIEW: SAVED_PASS"); Qt.quit();
                    }
                }
                FileView { id: raw; path: Quickshell.env("MONITOR_INTENT_FILE"); blockLoading: true; printErrors: false }
                FloatingWindow {
                    implicitWidth: 1000; implicitHeight: 850; visible: true
                    NPluginSettingsPopup { id: popup; parent: Overlay.overlay; onSettingsCompleted: result => root.receipt = result }
                }
                Connections { target: Settings; function onSettingsLoaded() { root.begin(); } }
                Component.onCompleted: begin()
                Timer { interval: 40; repeat: true; running: true; onTriggered: { try { root.drive(); } catch (error) { console.error(String(error)); Qt.exit(2); } } }
                Timer { interval: 25000; running: true; onTriggered: { console.error("CUSTOM_TIME_ASSERT: watchdog", root.phase); Qt.exit(2); } }
            }
        }
    }
}
