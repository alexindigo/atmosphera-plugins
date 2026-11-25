import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  readonly property bool ownerCurrent: pluginApi?.settingsContext?.current() ?? false
  property int requestGeneration: 0
  property var currentRequest: null
  property var pendingFileLoader: null
  onOwnerCurrentChanged: if (!ownerCurrent)
                           invalidateSession()
  onPluginApiChanged: invalidateSession()

  // ── Inline state object ──
  property QtObject state: QtObject {
    property int sessionId: 0
    property var items: []
    property string prompt: ""
    property bool allowCustomInput: false
    property bool closeOnSelect: true
    property string resultFile: "/tmp/noctalia-dmenu-result"
    property string resultFormat: "plain"
    property string callbackCmd: ""
    property var altActions: ({})
    property int maxResults: 200
    property bool showToastOnSelect: false
    property string customInputPrefix: ""
    property var request: null
    property bool active: false
  }

  // Signals for the provider to react to
  signal itemsChanged
  signal sessionStarted(int sid)
  signal sessionEnded(int sid)
  signal sessionInvalidated()

  // ── Deferred launcher open ──
  // When openPanel is called shortly after a closePanel (chaining),
  // we defer it to let the close animation finish.
  property real lastCloseTimestamp: 0
  readonly property int chainDelay: 350  // ms to wait after close before reopen

  Timer {
    id: launcherOpenTimer
    interval: root.chainDelay
    repeat: false
    property var request: null
    onTriggered: root.openCapturedPanel(request)
  }

  // Smart open: if the panel is already showing (rapid replacement), just
  // let onItemsChanged refresh it. If we recently closed (chaining), defer.
  // Otherwise open immediately.
  function requestCurrent(request) {
    // Component initial properties may copy a JS record. The captured API
    // and admission generation, not record reference equality, identify it.
    return request !== null && currentRequest !== null && request.generation === requestGeneration && request.api === pluginApi && ownerCurrent;
  }

  function openCapturedPanel(request) {
    if (!requestCurrent(request) || !state.active)
      return;
    request.api.withCurrentScreen(function (screen) {
      if (root.requestCurrent(request) && state.active)
        request.api.openPanel(screen);
    });
  }

  function openPanelSmart(request) {
    if (!requestCurrent(request))
      return;

    var now = Date.now();
    var elapsed = now - lastCloseTimestamp;

    // If we recently called closePanel (chaining), the panel is in its
    // close animation and panelOpenScreen hasn't cleared yet.
    // Defer the open to let the animation finish.
    if (elapsed < chainDelay) {
      launcherOpenTimer.interval = chainDelay - elapsed + 50;
      launcherOpenTimer.request = request;
      launcherOpenTimer.restart();
      Logger.d("DmenuProvider", "Deferring panel open by " + launcherOpenTimer.interval + "ms");
      return;
    }

    // No recent close — if the panel is still open (rapid replacement),
    // just let onItemsChanged refresh it in place.
    if (request.api.panelOpenScreen) {
      Logger.d("DmenuProvider", "Panel already open, refreshing in place");
      return;
    }

    // Panel is closed and no recent close — open immediately
    openCapturedPanel(request);
  }

  // ── Session management ──
  function beginSession(config, request) {
    if (!requestCurrent(request))
      return 0;
    state.sessionId++;
    var newSid = state.sessionId;

    state.items = config.items || [];
    state.prompt = config.prompt || "";
    state.allowCustomInput = config.allowCustomInput !== undefined ? config.allowCustomInput : false;
    state.closeOnSelect = config.closeOnSelect !== undefined ? config.closeOnSelect : true;
    state.resultFile = config.resultFile || "/tmp/noctalia-dmenu-result";
    state.resultFormat = config.resultFormat || "plain";
    state.callbackCmd = config.callbackCmd || "";
    state.altActions = config.altActions || {};
    state.maxResults = config.maxResults || 200;
    state.showToastOnSelect = config.showToastOnSelect ?? false;
    state.customInputPrefix = config.customInputPrefix ?? "";
    state.request = request;

    state.active = true;
    sessionStarted(newSid);
    itemsChanged();

    return newSid;
  }

  function retireFileLoader() {
    var retired = pendingFileLoader;
    pendingFileLoader = null;
    if (retired)
      retired.destroy();
  }

  function invalidateSession() {
    endSession(false);
    sessionInvalidated();
  }

  function recordPanelClose() {
    lastCloseTimestamp = Date.now();
  }

  function endSession(closePanel = true) {
    var capturedApi = currentRequest?.api ?? pluginApi;
    currentRequest = null;
    requestGeneration++;
    var generation = requestGeneration;
    launcherOpenTimer.stop();
    launcherOpenTimer.request = null;
    retireFileLoader();
    var wasActive = state.active;
    var oldSid = state.sessionId;
    state.active = false;
    state.request = null;
    state.items = [];
    state.prompt = "";
    state.callbackCmd = "";
    state.altActions = {};
    if (wasActive)
      sessionEnded(oldSid);
    if (closePanel && capturedApi && capturedApi === pluginApi && ownerCurrent) {
      recordPanelClose();
      capturedApi.withCurrentScreen(function (screen) {
        if (root.ownerCurrent && capturedApi === root.pluginApi && generation === root.requestGeneration)
          capturedApi.closePanel(screen);
      });
    }
  }

  function beginRequest() {
    if (!ownerCurrent)
      return null;
    // Admission captures applied operation defaults, not the page preview.
    var defaults = pluginApi.pluginSettings;
    var manifest = pluginApi.manifest.metadata.defaultSettings || {};
    var captured = {
      resultFile: defaults.resultFile || manifest.resultFile || "/tmp/noctalia-dmenu-result",
      maxResults: defaults.maxResults || manifest.maxResults || 200,
      showToastOnSelect: defaults.showToastOnSelect ?? manifest.showToastOnSelect ?? false,
      customInputPrefix: defaults.customInputPrefix ?? manifest.customInputPrefix ?? ""
    };
    endSession(false);
    var request = {
      api: pluginApi,
      generation: requestGeneration,
      defaults: captured
    };
    currentRequest = request;
    return request;
  }

  function formatResult(value, index) {
    if (state.resultFormat === "json") {
      return JSON.stringify({
                              "value": value,
                              "index": index,
                              "sessionId": state.sessionId
                            });
    } else if (state.resultFormat === "index") {
      return index.toString();
    }
    return value;
  }

  // ── Config builder ──
  function buildConfig(overrides, request) {
    var defaults = request.defaults;
    var cfg = {};

    cfg.resultFile = overrides.resultFile || defaults.resultFile || "/tmp/noctalia-dmenu-result";
    cfg.resultFormat = overrides.resultFormat || "plain";
    cfg.allowCustomInput = overrides.allowCustomInput;
    cfg.closeOnSelect = overrides.closeOnSelect;
    cfg.maxResults = overrides.maxResults || defaults.maxResults || 200;
    cfg.showToastOnSelect = overrides.showToastOnSelect !== undefined ? overrides.showToastOnSelect : (defaults.showToastOnSelect || false);
    cfg.customInputPrefix = overrides.customInputPrefix ?? defaults.customInputPrefix ?? "";

    cfg.items = overrides.items || [];
    cfg.prompt = overrides.prompt || "";
    cfg.callbackCmd = overrides.callbackCmd || "";
    cfg.altActions = overrides.altActions || {};

    return cfg;
  }

  // ── Item parsing ──
  function parseItems(input, separator) {
    if (typeof input === "string") {
      try {
        var parsed = JSON.parse(input);
        if (Array.isArray(parsed)) {
          return normalizeItems(parsed);
        }
        if (parsed.items && Array.isArray(parsed.items)) {
          return normalizeItems(parsed.items);
        }
      } catch (e) {
        // Not JSON — treat as separated string
      }
      var sep = separator || "\n";
      // Unescape common separator literals passed as strings from IPC
      // (IPC sends "\n" as two chars: backslash + n)
      sep = sep.replace(/\\n/g, "\n").replace(/\\t/g, "\t").replace(/\\r/g, "\r");
      var lines = input.split(sep).filter(function (l) {
        return l.length > 0;
      });
      return lines.map(function (line, idx) {
        return {
          name: line.trim(),
          value: line.trim(),
          index: idx
        };
      });
    }
    if (Array.isArray(input)) {
      return normalizeItems(input);
    }
    return [];
  }

  function normalizeItems(arr) {
    if (!Array.isArray(arr)) {
      Logger.w("DmenuProvider", "normalizeItems received non-array, wrapping");
      arr = [arr];
    }
    return arr.map(function (item, idx) {
      if (typeof item === "string") {
        return {
          name: item,
          value: item,
          index: idx
        };
      }
      return {
        name: item.name || item.label || item.value || ("Item " + idx),
        description: item.description || "",
        value: item.value || item.name || item.label || "",
        icon: item.icon || "",
        image: item.image || "",
        isTablerIcon: item.isTablerIcon !== undefined ? item.isTablerIcon : true,
        altActions: item.altActions || {},
        index: idx
      };
    });
  }

  // ── Selection handler ──
  function handleSelection(value, index, altKey) {
    if (!state.active || !requestCurrent(state.request))
      return;

    var capturedApi = state.request.api;
    var sid = state.sessionId;
    var resultStr = formatResult(value, index);
    var resultFile = state.resultFile;
    var callbackCmd = state.callbackCmd;
    var showToast = state.showToastOnSelect;
    var shouldClose = state.closeOnSelect;

    // Capture item name BEFORE endSession clears items
    var itemName = "";
    if (index >= 0 && index < state.items.length) {
      itemName = state.items[index].name || "";
    }

    // Handle alt-action
    var actualCallback = callbackCmd;
    if (altKey && altKey !== "") {
      var itemAltActions = {};
      if (index >= 0 && index < state.items.length) {
        itemAltActions = state.items[index].altActions || {};
      }
      var globalAltActions = state.altActions || {};
      var altAction = itemAltActions[altKey] || globalAltActions[altKey];
      if (altAction) {
        if (typeof altAction === "string") {
          actualCallback = altAction;
        } else if (altAction.callback) {
          actualCallback = altAction.callback;
        }
        if (altAction.value !== undefined) {
          resultStr = formatResult(altAction.value, index);
        }
      }
    }

    // Step 1: Write result file (atomic: tmp + mv)
    var escaped = resultStr.replace(/'/g, "'\\''");
    var escapedFile = resultFile.replace(/'/g, "'\\''");
    Quickshell.execDetached(["sh", "-c", "printf '%s' '" + escaped + "' > '" + escapedFile + ".tmp' && mv '" + escapedFile + ".tmp' '" + escapedFile + "'"]);

    // Main alone owns close policy; the Panel cannot override this capture.
    endSession(shouldClose);

    // Step 4: Toast
    if (showToast) {
      ToastService.showNotice(capturedApi.tr("provider.selected", {
                                               value: value
                                             }));
    }

    // Step 5: Fire callback immediately
    // The callback itself may call show/showSimple, which will use
    // openPanelSmart() to defer the open if needed.
    if (actualCallback && actualCallback !== "") {
      var cmd = actualCallback.replace(/\{\}/g, resultStr);
      cmd = cmd.replace(/\{value\}/g, resultStr);
      cmd = cmd.replace(/\{index\}/g, index.toString());
      cmd = cmd.replace(/\{name\}/g, itemName || resultStr);
      Quickshell.execDetached(["sh", "-c", cmd]);
    }

    Logger.i("DmenuProvider", "Session " + sid + " selection: " + value + (altKey ? " (alt: " + altKey + ")" : ""));
  }

  function handleCustomInput(text) {
    if (!state.active || !state.allowCustomInput)
      return;
    handleSelection(state.customInputPrefix + text, -1, "");
  }

  // ── IPC Handlers ──
  IpcHandler {
    target: "plugin:dmenu"

    // ── showItems(items, options) ──
    // For plain text item lists.
    //   items:   delimiter-separated string
    //   options: JSON object (or "") with separator, prompt, callbackCmd, etc.
    function showItems(items: string, options: string) {
      if (!pluginApi)
        return;
      var opts = {};
      if (options && options !== "") {
        try {
          opts = JSON.parse(options);
        } catch (e) {
          Logger.e("DmenuProvider", "Invalid options JSON:", e);
          return;
        }
      }
      var sep = opts.separator || "\n";
      opts.items = root.parseItems(items, sep);
      var request = root.beginRequest();
      if (!request)
        return;
      var merged = root.buildConfig(opts, request);
      root.beginSession(merged, request);
      root.openPanelSmart(request);
      Logger.i("DmenuProvider", "Session " + root.state.sessionId + " started with " + merged.items.length + " items");
    }

    // ── showJson(config) ──
    // For structured items with descriptions, icons, images.
    // Single JSON object containing items array + all options.
    //
    // {
    //   "items": ["a", "b"] or [{"name":"a","value":"x","icon":"star"}, ...],
    //   "prompt": "Pick:",
    //   "callbackCmd": "echo {}",
    //   "resultFormat": "plain",
    //   ...any other option
    // }
    //
    // This avoids Quickshell's CLI bug where [...] at the top level
    // gets split by the argument parser. The outer {…} is safe.
    function showJson(config: string) {
      if (!pluginApi)
        return;
      var cfg;
      try {
        cfg = JSON.parse(config);
      } catch (e) {
        Logger.e("DmenuProvider", "Invalid JSON config:", e);
        return;
      }
      if (!cfg.items) {
        Logger.e("DmenuProvider", "showJson: missing 'items' key");
        return;
      }
      cfg.items = root.normalizeItems(Array.isArray(cfg.items) ? cfg.items : [cfg.items]);
      var request = root.beginRequest();
      if (!request)
        return;
      var merged = root.buildConfig(cfg, request);
      root.beginSession(merged, request);
      root.openPanelSmart(request);
      Logger.i("DmenuProvider", "Session " + root.state.sessionId + " started with " + merged.items.length + " items");
    }

    // ── showFromFile(filePath, options) ──
    // Read items from a file. Auto-detects format:
    //   - JSON array if file starts with '['
    //   - JSON config object with "items" key if file starts with '{'
    //   - Delimiter-separated text otherwise
    // options is JSON (or "").
    function showFromFile(filePath: string, options: string) {
      if (!pluginApi)
        return;
      var opts = {};
      if (options && options !== "") {
        try {
          opts = JSON.parse(options);
        } catch (e) {
          Logger.e("DmenuProvider", "Invalid options JSON:", e);
          return;
        }
      }
      var request = root.beginRequest();
      if (!request)
        return;
      root.pendingFileLoader = fileLoaderComponent.createObject(root, {
                                                                  request: request,
                                                                  options: opts
                                                                });
      root.pendingFileLoader.path = filePath;
    }

    function toggle() {
      if (!root.ownerCurrent)
        return;
      var capturedApi = pluginApi, generation = root.requestGeneration;
      capturedApi.withCurrentScreen(function (screen) {
        if (root.ownerCurrent && capturedApi === pluginApi && generation === root.requestGeneration)
          capturedApi.togglePanel(screen);
      });
    }

    function close() {
      if (!pluginApi)
        return;
      root.endSession();
    }

    function clear() {
      root.endSession();
    }
  }

  // ── File loader ──
  Component {
    id: fileLoaderComponent
    FileView {
      id: fileLoader
      required property var request
      required property var options
      path: ""
      watchChanges: false
      onLoaded: Qt.callLater(root.finishFileRequest, fileLoader)
      onLoadFailed: {
        if (root.requestCurrent(request)) {
          Logger.e("DmenuProvider", "Could not load menu file");
          Qt.callLater(root.failFileRequest, request);
        }
      }
    }
  }

  function failFileRequest(request) {
    if (requestCurrent(request))
      endSession();
  }

  function finishFileRequest(loader) {
    if (!loader || pendingFileLoader !== loader || !requestCurrent(loader.request))
      return;
    var request = loader.request;
    var content = loader.text();
    var opts = Object.assign({}, loader.options);
    var parsed;
    var trimmed = content.replace(/^\s+/, "");

    if (trimmed.charAt(0) === "[") {
      // JSON array file
      try {
        parsed = root.normalizeItems(JSON.parse(content));
      } catch (e) {
        Logger.e("DmenuProvider", "Invalid JSON file:", e);
        failFileRequest(request);
        return;
      }
    } else if (trimmed.charAt(0) === "{") {
      // JSON config object with items key
      try {
        var config = JSON.parse(content);
        parsed = root.normalizeItems(config.items || []);
        // Explicit request options win; file config fills absent options.
        for (var key in config) {
          if (key !== "items" && opts[key] === undefined)
            opts[key] = config[key];
        }
      } catch (e) {
        Logger.e("DmenuProvider", "Invalid JSON config file:", e);
        failFileRequest(request);
        return;
      }
    } else {
      // Delimiter-separated text
      parsed = root.parseItems(content, opts.separator || "\n");
    }

    opts.items = parsed;
    var merged = root.buildConfig(opts, request);
    retireFileLoader();
    root.beginSession(merged, request);
    root.openPanelSmart(request);

    Logger.i("DmenuProvider", "Session " + root.state.sessionId + " (file) started with " + parsed.length + " items");
  }

  Component.onCompleted: {
    Logger.i("DmenuProvider", "Main component loaded");
  }
}
