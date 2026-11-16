import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Plugins
import qs.Services.UI

ShellRoot {
    SettingsBootstrap { id: bootstrap }
    Loader {
        active: bootstrap.ready
        sourceComponent: Component {
            Item {
                id: root
                property var api: null
                property var main: null
                property var colorConsumer: null
                property var baselineConsumer: null
                property var producer: null
                property int attempts: 0
                property int saves: 0
                property int calls: 0
                property var held: null
                property var lastReceipt: null
                property var effects: []
                property string phase: "owner"
                property bool started: false
                readonly property string mode: Quickshell.env("WALLPAPER_REVIEW_CASE")
                readonly property string work: Quickshell.env("WALLPAPER_REVIEW_WORK")
                readonly property string first: Quickshell.env("WALLPAPER_REVIEW_FIRST")
                readonly property string outside: Quickshell.env("WALLPAPER_REVIEW_OUTSIDE")
                readonly property string original: Quickshell.env("WALLPAPER_REVIEW_ORIGINAL")
                readonly property string name: Quickshell.screens[0].name
                function check(ok, label) { if (!ok) throw new Error("WALLPAPER_GENERATION_ASSERT: " + phase + " " + label); }
                function fail(error) { console.error(String(error)); Qt.exit(2); }
                function find(item, type, seen) {
                    if (!item || seen.indexOf(item) !== -1) return null;
                    seen.push(item);
                    if (String(item).indexOf(type + "_QMLTYPE") === 0) return item;
                    for (var key of ["children", "resources", "instances"]) {
                        if (!(key in item)) continue;
                        for (var child of item[key] || []) {
                            var found = find(child, type, seen);
                            if (found) return found;
                        }
                    }
                    return null;
                }
                function command(argv, next) { phase = next; operation.command = argv; operation.running = true; }
                function select(path) {
                    var monitors = Settings.store.copyValue(api.pluginSettings.monitors);
                    monitors[name].currentWallpaper = path;
                    api.pluginSettings.monitors = monitors;
                }
                function pass() {
                    observed.setText(JSON.stringify({wallpaper: WallpaperService.getWallpaper(name), effects: effects, saves: saves, calls: calls}));
                    console.log("WALLPAPER_GENERATION: PASS " + mode);
                    Qt.exit(0);
                }
                function begin() {
                    if (started || !Settings.isLoaded) return;
                    started = true;
                    Service._openSettingsOwner("video-wallpaper", function (owner) {
                        try {
                            check(owner && owner.status === "Ready", "real native preference owner");
                            api = Service.createPluginAPI("video-wallpaper", JSON.parse(Quickshell.env("WALLPAPER_REVIEW_MANIFEST")), owner, {}, {}, {});
                            var save = api.saveSettings;
                            api.saveSettings = function (callback) {
                                saves++;
                                return save(function (receipt) {
                                    lastReceipt = receipt;
                                    if (mode === "baseline-obsolete") held = function () { callback(receipt); };
                                    else if (typeof callback === "function") callback(receipt);
                                });
                            };
                            var loaded = Object.assign({}, Service.loadedPlugins);
                            loaded["video-wallpaper"] = {api: api}; Service.loadedPlugins = loaded;
                            WallpaperService.init(); phase = "service";
                        } catch (error) { fail(error); }
                    });
                }
                function drive() {
                    if (phase === "service" && WallpaperService.isInitialized) {
                        var directory = Settings.configDir + "plugins/video-wallpaper";
                        var component = Qt.createComponent("file://" + directory + "/Main.qml");
                        check(component.status === Component.Ready, component.errorString());
                        main = component.createObject(root, {pluginApi: api});
                        check(main !== null, "actual Main constructed");
                        colorConsumer = find(main, "ColorGeneration", []);
                        baselineConsumer = find(main, "InnerService", []);
                        producer = find(main, "Thumbnails", []);
                        check(colorConsumer && baselineConsumer, "actual per-screen consumers");
                        phase = "generation";
                    }
                    if (phase === "generation") {
                        if (mode === "init-retry") {
                            if (!main.thumbnailGenerationFailed) return;
                            check(!main.thumbCacheReady && saves === 0, "failed real mkdir cannot publish cache readiness or preferences");
                            command(["chmod", "755", ImageCacheService.wpThumbDir], "init-repaired");
                            return;
                        }
                        if (mode === "refresh-membership" && main.thumbCacheReady && WallpaperService.getWallpaper(name) === main.getThumbPath(outside)) {
                            check(producer.pathFor(first) !== "", "initial directory media was produced");
                            command(["sh", "-c", "cp -- \"$1\" \"$2\" && rm -- \"$3\"", "refresh-media", work + "/valid.mp4", work + "/media/added.mp4", first], "membership-changed");
                            return;
                        }
                        if (mode === "failure" || mode === "retry") {
                            if (!main.thumbnailGenerationFailed) return;
                            check(!main.thumbCacheReady, "failed real FFmpeg never publishes readiness");
                            phase = "settle-failure"; settle.start(); return;
                        }
                        if ((mode === "replacement" || mode === "disable") && calls === 1) {
                            check(!main.thumbCacheReady, "real FFmpeg is causally held");
                            if (mode === "replacement") select(outside);
                            else api.pluginSettings.enabled = false;
                            command(["touch", work + "/release-1"], mode === "replacement" ? "replacement" : "disabled");
                            return;
                        }
                        if (mode.indexOf("baseline-") === 0 && main.thumbCacheReady) {
                            check(saves === 0 && WallpaperService.getWallpaper(name) === original, "startup is not a preference action or color effect while disabled");
                            if (mode === "baseline-retry") command(["chmod", "555", Settings.configDir + "settings/plugins"], "baseline-denied");
                            else { phase = "baseline-held"; api.pluginSettings.enabled = true; }
                            return;
                        }
                        if (mode === "outside" && WallpaperService.getWallpaper(name) === main.getThumbPath(outside)) {
                            check(saves === 0, "outside-folder selection has one shared producer and no startup save"); pass();
                        }
                    }
                    if (phase === "replacement" && calls === 2) {
                        check(!main.thumbCacheReady, "obsolete generation cannot acknowledge the replacement");
                        check(effects.indexOf(main.getThumbPath(first)) === -1, "old completion never applies old colors");
                        command(["touch", work + "/release-2"], "replacement-released"); return;
                    }
                    if (phase === "disabled" && main.thumbCacheReady) {
                        phase = "settle-disabled"; settle.start(); return;
                    }
                    if (phase === "baseline-failed") {
                        check(WallpaperService.getWallpaper(name) === original, "unacknowledged baseline cannot apply colors");
                        if (lastReceipt?.status !== "failed") return;
                        check(!baselineConsumer.baselineReady && WallpaperService.getWallpaper(name) === original, "failed baseline blocks the color effect");
                        command(["chmod", "755", Settings.configDir + "settings/plugins"], "baseline-repaired"); return;
                    }
                    if (phase === "baseline-held" && held) {
                        check(WallpaperService.getWallpaper(name) === original && !baselineConsumer.baselineReady, "real saved baseline receipt is held before acknowledgement");
                        select(outside);
                        var release = held; held = null; phase = "baseline-replacement-pending"; release();
                        return;
                    }
                    if (phase === "baseline-replacement-pending") {
                        check(WallpaperService.getWallpaper(name) === original, "replacement baseline still waits for its own receipt");
                        if (held) { phase = "settle-baseline"; settle.start(); }
                        return;
                    }
                    if (phase === "refresh-generating") {
                        check(!main.thumbnailGenerationFailed, "Refresh still uses removed source inventory");
                        if (!main.thumbCacheReady) return;
                        var added = work + "/media/added.mp4";
                        check(producer.folderModel.indexOf(added) !== -1 && producer.folderModel.indexOf(first) === -1, "Refresh observes added and removed real media");
                        check(producer.pathFor(added) !== "" && producer.pathFor(first) === "", "current thumbnail inventory follows refreshed source membership");
                        check(producer.thumbFolderModel.indexOf(main.getThumbPath(first)) === -1, "deleted media thumbnail is removed");
                        select(added); phase = "refresh-selected";
                    }
                    var selected = phase === "refresh-selected" ? work + "/media/added.mp4" : phase === "replacement-released" || phase === "baseline-replaced" ? outside : first;
                    if (["retrying", "replacement-released", "baseline-retrying", "baseline-replaced", "init-retrying", "refresh-selected"].indexOf(phase) !== -1 && WallpaperService.getWallpaper(name) === main.getThumbPath(selected)) {
                        check(!colorConsumer.generationFailed && main.thumbCacheReady, "consumer sees repaired current generation");
                        if (phase === "baseline-replaced") check(effects.indexOf(main.getThumbPath(first)) === -1, "obsolete baseline receipt cannot apply old colors");
                        pass();
                    }
                }
                Timer { interval: 20; running: true; repeat: true; onTriggered: { try { root.drive(); } catch (error) { stop(); root.fail(error); } } }
                Timer {
                    id: settle
                    interval: 100
                    onTriggered: { root.attempts = root.colorConsumer.reviewAttempts; stable.start(); }
                }
                Timer {
                    id: stable
                    interval: 100
                    onTriggered: {
                        try {
                            root.check(root.colorConsumer.reviewAttempts === root.attempts, "no event-loop polling without a dependency change: " + root.attempts + " -> " + root.colorConsumer.reviewAttempts);
                            if (root.phase === "settle-disabled") {
                                root.check(WallpaperService.getWallpaper(root.name) === root.original && root.effects.indexOf(root.main.getThumbPath(root.first)) === -1, "disabled request cannot apply late colors");
                                root.pass(); return;
                            }
                            if (root.phase === "settle-baseline") {
                                root.check(WallpaperService.getWallpaper(root.name) === root.original, "obsolete baseline receipt cannot authorize replacement colors");
                                var release = root.held; root.held = null; root.phase = "baseline-replaced"; release();
                                return;
                            }
                            root.check(root.colorConsumer.generationFailed, "actual color consumer observes shared failure");
                            if (root.mode === "failure") root.pass();
                            else root.command(["cp", "--", root.work + "/valid.mp4", root.first], "repair-media");
                        } catch (error) { root.fail(error); }
                    }
                }
                Process {
                    id: operation
                    onExited: exitCode => {
                        try {
                            root.check(exitCode === 0, "real dependency operation");
                            if (root.phase === "repair-media") { root.phase = "retrying"; root.main.thumbRegenerate(); }
                            else if (root.phase === "baseline-denied") { root.phase = "baseline-failed"; root.api.pluginSettings.enabled = true; }
                            else if (root.phase === "baseline-repaired") { root.phase = "baseline-retrying"; root.main.thumbRegenerate(); }
                            else if (root.phase === "init-repaired") { root.phase = "init-retrying"; root.main.thumbRegenerate(); }
                            else if (root.phase === "membership-changed") { root.phase = "refresh-generating"; root.main.thumbRegenerate(); }
                        } catch (error) { root.fail(error); }
                    }
                }
                FileView {
                    path: Quickshell.env("I5_THUMB_CONTROL")
                    watchChanges: true
                    printErrors: false
                    onFileChanged: reload()
                    onLoaded: root.calls = JSON.parse(text()).calls
                }
                FileView { id: observed; path: root.work + "/observed.json"; printErrors: false }
                Connections {
                    target: WallpaperService
                    function onWallpaperChanged(screenName, path) { if (screenName === root.name) root.effects.push(path); }
                }
                Connections { target: Settings; function onSettingsLoaded() { root.begin(); } }
                Component.onCompleted: Qt.callLater(begin)
                Timer { interval: 25000; running: true; onTriggered: root.fail("generation deadline " + root.phase) }
            }
        }
    }
}
