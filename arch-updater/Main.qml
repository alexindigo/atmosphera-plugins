import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  id: root

  // Plugin API (injected by PluginService)
  property var pluginApi: null

  // Configuration-dependent checks belong to one client per captured
  // runtime identity; Main owns their cache and lifetime.
  property var _settingsConsumers: new Map()
  Component {
    id: clientFactory
    ArchUpdaterSettingsClient {}
  }
  function settingsConsumerFor(context) {
    if (!context || !context.current())
      return null;
    if (_settingsConsumers.has(context))
      return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
                                              settingsContext: context,
                                              pluginApi: pluginApi,
                                              retire: function (retired) {
                                                root._settingsConsumers.delete(context);
                                                retired.destroy();
                                              }
                                            });
    _settingsConsumers.set(context, client);
    return client;
  }
  // Existing plugin-level entry points remain explicitly plugin-scoped.
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property string systemStr: settingsConsumer?.systemStr ?? ""
  readonly property string aurStr: settingsConsumer?.aurStr ?? ""
  readonly property string flatpakStr: settingsConsumer?.flatpakStr ?? ""
  readonly property var updates: settingsConsumer?.updates ?? []
  readonly property bool refreshing: settingsConsumer?.refreshing ?? false
  readonly property bool noctaliaUpdate: settingsConsumer?.noctaliaUpdate ?? false

  // Process to return the repo URL for a package
  Process {
    id: checkRepo

    property string _output: ""
    property var _callback: null

    stdout: SplitParser {
      onRead: data => checkRepo._output += data + "\n"
    }

    onExited: {
      if (_callback)
        _callback(_output);
      _output = "";
      _callback = null;
    }

    function run(cmd, callback) {
      _output = "";
      _callback = callback;
      command = cmd;
      running = true;
    }
  }

  // Process to return the Homepage for a package
  // Same as checkRepo but kept seperate incase one ends up needing to be different
  Process {
    id: getHomepage

    property string _output: ""
    property var _callback: null

    stdout: SplitParser {
      onRead: data => getHomepage._output += data + "\n"
    }

    onExited: {
      if (_callback)
        _callback(_output);
      _output = "";
      _callback = null;
    }

    function run(cmd, callback) {
      _output = "";
      _callback = callback;
      command = cmd;
      running = true;
    }
  }

  function openURL(source, id) {
    // Opens the page for the package
    // AUR and Flatpaks have the same URL for all packages but pacman can have multiple repos from which it sources
    // So it also checks the repo from which a package originates to open the correct URL
    var url = "";
    switch (source) {
    case "system":
      checkRepo.run(["sh", "-c", "LC_ALL=C pacman -Si " + id + " 2>/dev/null | awk '/^Repository/  {print $3; exit}'"], output => {
        var repo = output.trim();
        switch (repo) {
        case "cachyos-znver4":
          url = "https://packages.cachyos.org/package/cachyos-znver4/x86_64_v4/" + id;
          break;
        case "cachyos-extra-znver4":
          url = "https://packages.cachyos.org/package/cachyos-extra-znver4/x86_64_v4/" + id;
          break;
        case "cachyos-core-znver4":
          url = "https://packages.cachyos.org/package/cachyos-core-znver4/x86_64_v4/" + id;
          break;
        case "extra":
          url = "https://archlinux.org/packages/extra/x86_64/" + id;
          break;
        case "multilib":
          url = "https://archlinux.org/packages/multilib/x86_64/" + id;
          break;
        case "core":
          url = "https://archlinux.org/packages/core/x86_64/" + id;
          break;
        default:
          Logger.w("Arch Updater", "Failed to match repo: " + repo);
          ToastService.showError("Failed to match repo: " + repo);
          url = "";
          break;
        }
        Logger.i("Arch Updater", "Opening URL: " + url);
        Qt.openUrlExternally(url);
      });
      break;
    case "aur":
      url = "https://aur.archlinux.org/packages/" + id;
      Logger.i("Arch Updater", "Opening URL: " + url);
      Qt.openUrlExternally(url);
      break;
    case "flatpak":
      url = "https://flathub.org/en/apps/" + id;
      Logger.i("Arch Updater", "Opening URL: " + url);
      Qt.openUrlExternally(url);
      break;
    default:
      Logger.w("Arch Updater", "Unkown source: " + source);
      ToastService.showError("Unable to open URL\nUnkown source: " + source);
      break;
    }
  }

  function copy(text) {
    // Copy the text and send a toast
    Quickshell.execDetached(["sh", "-c", "wl-copy '" + text + "'"]);
    ToastService.showNotice('Copied "' + text + '"');
    Logger.d("Arch Updater", "Copied " + text);
  }

  function openHomepage(source, id) {
    if (settingsConsumer)
      settingsConsumer.openHomepage(source, id);
  }

  function refresh() {
    if (settingsConsumer)
      settingsConsumer.refresh();
  }

  function update() {
    if (settingsConsumer)
      settingsConsumer.update();
  }

  IpcHandler {
    target: "plugin:arch-updater"

    function refresh() {
      Logger.d("Arch Updater", "Refreshing through IPC...");
      root.refresh();
    }

    function update() {
      Logger.d("Arch Updater", "Updating through IPC...");
      root.update();
    }
  }
}
