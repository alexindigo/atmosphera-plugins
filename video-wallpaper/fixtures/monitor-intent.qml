import QtQuick
import QtQuick.Controls
import Quickshell
import "SettingsControls.js" as Controls
import qs.Commons
import qs.Services.Plugins
import qs.Widgets

// Real native Apply followed by a later global change and a separate cold run.
ShellRoot {
  SettingsBootstrap {
    id: bootstrap
  }
  Loader {
    active: bootstrap.ready
    sourceComponent: Component {
      Item {
        id: root
        property var api: null
        property var consumer: null
        property var receipt: null
        property var ticks: ({})
        property real since: 0
        property bool started: false
        property string phase: "start"
        readonly property bool cold: Quickshell.env("MINOR_REVIEW_COLD") === "1"
        function check(ok, label) {
          if (!ok)
            throw new Error("MONITOR_INTENT_ASSERT: " + phase + " " + label);
        }
        function begin() {
          if (started || !Settings.isLoaded)
            return;
          started = true;
          Service._openSettingsOwner("video-wallpaper", function (owner) {
            try {
              check(!!owner, "native owner");
              api = Service.createPluginAPI("video-wallpaper", JSON.parse(Quickshell.env("MINOR_REVIEW_MANIFEST")), owner, {}, {}, {});
              var loaded = Object.assign({}, Service.loadedPlugins);
              loaded["video-wallpaper"] = {
                api: api
              };
              Service.loadedPlugins = loaded;
              var component = Qt.createComponent("file://" + Registry.getPluginDir("video-wallpaper") + "/main/Automation.qml");
              check(component.status === Component.Ready, component.errorString());
              consumer = component.createObject(root, {
                                                  pluginApi: api
                                                });
              check(!!consumer, "actual timer consumer");
              function tick(name, mode) {
                try {
                  check(Array.from(Quickshell.screens).some(screen => screen.name === name), "configured timer target");
                  var key = name + ":" + mode;
                  ticks[key] = (ticks[key] || 0) + 1;
                } catch (error) {
                  console.error(String(error));
                  Qt.exit(2);
                }
              }
              consumer.random.connect(function (name) {
                tick(name, "random");
              });
              consumer.nextWallpaper.connect(function (name) {
                tick(name, "alphabetically");
              });
              popup.openPluginSettings(api.manifest, "settings");
              phase = "page";
            } catch (error) {
              console.error(String(error));
              Qt.exit(2);
            }
          });
        }
        function drive() {
          var page = popup.settingsPage;
          if (phase === "page" && popup.opened && page) {
            check(!page.settingsDirty, "projected form starts clean");
            if (cold) {
              ticks = {};
              since = Date.now();
              phase = "observing";
              return;
            }
            Controls.folder(page, api, page.wallpapersFolder + "/unrelated");
            popup.applySettings();
            phase = "apply";
          } else if (phase === "apply" && !popup.busy) {
            check(receipt && receipt.status !== "failed" && receipt.refreshState === "current", "native Apply current");
            phase = "global";
            api.pluginSettings.automationMode = "random";
            api.saveSettings(function (result) {
              try {
                check(result.status === "saved", "later global save");
                ticks = {};
                since = Date.now();
                phase = "observing";
              } catch (error) {
                console.error(String(error));
                Qt.exit(2);
              }
            });
          } else if (phase === "observing" && Date.now() - since > 1700) {
            for (var screen of Quickshell.screens) {
              check((ticks[screen.name + ":random"] || 0) > 0 && !ticks[screen.name + ":alphabetically"], "later global change reaches actual monitor timer " + screen.name);
            }
            console.log(cold ? "MINOR_REVIEW: COLD_PASS" : "MINOR_REVIEW: SAVED_PASS");
            Qt.quit();
          }
        }
        FloatingWindow {
          implicitWidth: 1000
          implicitHeight: 850
          visible: true
          NPluginSettingsPopup {
            id: popup
            parent: Overlay.overlay
            onSettingsCompleted: result => root.receipt = result
          }
        }
        Connections {
          target: Settings
          function onSettingsLoaded() {
            root.begin();
          }
        }
        Component.onCompleted: begin()
        Timer {
          interval: 40
          repeat: true
          running: true
          onTriggered: {
            try {
              root.drive();
            } catch (error) {
              console.error(String(error));
              Qt.exit(2);
            }
          }
        }
        Timer {
          interval: 20000
          running: true
          onTriggered: {
            console.error("MONITOR_INTENT_ASSERT: watchdog", root.phase);
            Qt.exit(2);
          }
        }
      }
    }
  }
}
