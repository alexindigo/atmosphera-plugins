import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Compositor
import "backends/SwayBackend.js" as SwayBackend
import "backends/HyprlandBackend.js" as HyprlandBackend

Item {
  id: root

  property var pluginApi: null

  property var selectedContext: null
  readonly property var policyContext: selectedContext || pluginApi?.settingsContext
  readonly property var cfg: policyContext?.settingsView || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property var fetchPolicy: null
  property var applyPolicy: null
  readonly property bool fetchCurrent: fetchPolicy?.context?.current() ?? false
  onFetchCurrentChanged: { if (fetchPolicy && !fetchCurrent) fetchProcess.running = false; }

  function activatePolicy(context) {
    context = context || pluginApi?.settingsContext;
    if (!context?.current()) return false;
    selectedContext = context;
    return true;
  }
  function capturePolicy(context) {
    context = context || pluginApi?.settingsContext;
    if (!context?.current()) return null;
    const settings = context.settingsView;
    return {context: context, settings: settings, backend: resolveBackendId(settings)};
  }

  property var liveOutputs: []
  property var draftOutputs: []
  property string selectedOutputId: ""
  property bool isRefreshing: false
  property bool isApplying: false
  property string errorText: ""
  property string statusText: ""
  property string refreshStderr: ""
  property string applyStderr: ""

  readonly property string backendId: resolveBackendId(cfg)
  readonly property bool hasPendingChanges: JSON.stringify(draftOutputs) !== JSON.stringify(liveOutputs)

  Component.onCompleted: {
    refreshOutputs();
  }

  IpcHandler {
    target: "plugin:layout-mon"

    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(screen => {
          pluginApi.togglePanel(screen);
        });
      }
    }

    function refresh() {
      root.refreshOutputs();
    }

    function apply() {
      root.applyLayout();
    }
  }

  Process {
    id: fetchProcess

    stdout: StdioCollector {
      onStreamFinished: {
        root.handleFetchOutput(this.text);
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        root.refreshStderr = this.text.trim();
      }
    }

    onExited: function (exitCode) {
      root.isRefreshing = false;
      if (!root.fetchPolicy?.context?.current()) return;
      if (exitCode !== 0) {
        root.errorText = root.refreshStderr !== "" ? root.refreshStderr : pluginApi?.tr("errors.fetchFailed");
        root.statusText = "";
        Logger.e("MonitorLayout", root.errorText);
      }
    }
  }

  Process {
    id: applyProcess

    stdout: StdioCollector {}

    stderr: StdioCollector {
      onStreamFinished: {
        root.applyStderr = this.text.trim();
      }
    }

    onExited: function (exitCode) {
      root.isApplying = false;
      const policy = root.applyPolicy;
      if (!policy?.context?.current()) return;
      if (exitCode === 0) {
        root.statusText = pluginApi?.tr("status.applied");
        root.errorText = "";
        root.refreshOutputs(policy.context, policy);
      } else {
        root.errorText = root.applyStderr !== "" ? root.applyStderr : pluginApi?.tr("errors.applyFailed");
        root.statusText = "";
        Logger.e("MonitorLayout", root.errorText);
      }
    }
  }



  function resolveBackendId(settings) {
    var preferred = settings.backend ?? defaults.backend ?? "auto";
    if (preferred !== "auto") {
      return preferred;
    }
    if (CompositorService.isHyprland) {
      return "hyprland";
    }
    if (CompositorService.isSway) {
      return "sway";
    }
    return "unsupported";
  }

  // --- Backend interface ---
  // Every backend module must export the following functions:
  //
  //   buildFetchCommand(cfg, defaults) -> Array<string>
  //     Return the command (as an argv array) that reads the current output state.
  //
  //   parseOutputs(rawText) -> { outputs } | { error }
  //     Parse the raw stdout text from the fetch command into a normalised array
  //     of output objects. Return { error: string } on failure.
  //
  //   outputs: Array of monitor/output objects, each with at least:
  //     {
  //       outputId: string,   // unique identifier for the output/monitor
  //       name: string,       // human-readable name
  //       x: number,          // X position
  //       y: number,          // Y position
  //       width: number,      // width in pixels
  //       height: number,     // height in pixels
  //       scale: number,      // scale factor
  //       modeId: string,     // current mode identifier
  //       availableModes: Array<{ id, width, height, refresh, label }>,
  //       ... (other backend-specific fields)
  //     }
  //
  //   buildApplyCommand(outputs, cfg, defaults) -> { script } | { error }
  //     Build a shell script string that applies the given draft outputs.
  //     Return { error: string } if the command cannot be built.
  //
  //   buildConfigFileContent(outputs) -> { content } | { error }
  //     Build a config file snippet for the given outputs (for copy-to-config).
  //     Return { error: string } if the config cannot be built.
  //
  // To add a new backend:
  //   1. Create backends/MyBackend.js implementing the interface above.
  //   2. Add: import "backends/MyBackend.js" as MyBackend  (top of file)
  //   3. Add a case for your backend id in each function below.
  // ---

  function backendBuildFetchCommand(policy) {
    if (policy.backend === "sway") return SwayBackend.buildFetchCommand(policy.settings, defaults);
    if (policy.backend === "hyprland") return HyprlandBackend.buildFetchCommand(policy.settings, defaults);
    return null;
  }

  function backendParseOutputs(rawText, policy) {
    if (policy.backend === "sway") return SwayBackend.parseOutputs(rawText);
    if (policy.backend === "hyprland") return HyprlandBackend.parseOutputs(rawText);
    return { "error": pluginApi?.tr("errors.unsupportedBackend") };
  }

  function backendBuildApplyCommand(policy) {
    if (policy.backend === "sway") return SwayBackend.buildApplyCommand(draftOutputs, policy.settings, defaults);
    if (policy.backend === "hyprland") return HyprlandBackend.buildApplyCommand(draftOutputs, policy.settings, defaults);
    return { "error": pluginApi?.tr("errors.unsupportedBackend") };
  }

  function backendBuildConfigFileContent(policy) {
    if (policy.backend === "sway") return SwayBackend.buildConfigFileContent(draftOutputs);
    if (policy.backend === "hyprland") return HyprlandBackend.buildConfigFileContent(draftOutputs);
    return { "error": pluginApi?.tr("errors.unsupportedBackend") };
  }


  readonly property bool snapToGridEnabled: cfg.snapToGrid ?? defaults.snapToGrid ?? true

  function gridSize(policy) {
    var parsed = parseInt(policy.settings.gridSize ?? defaults.gridSize ?? 40);
    return isFinite(parsed) && parsed > 0 ? parsed : 40;
  }

  function cloneValue(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function handleFetchOutput(rawText) {
    const policy = fetchPolicy;
    if (!policy?.context?.current()) return;
    var result = backendParseOutputs(rawText, policy);
    if (result.error) {
      errorText = result.error;
      statusText = "";
      Logger.e("MonitorLayout", errorText);
      return;
    }

    liveOutputs = cloneValue(result.outputs);
    draftOutputs = cloneValue(result.outputs);
    errorText = "";
    statusText = pluginApi?.tr("status.ready", {
      "count": draftOutputs.length
    });

    if (!selectedOutputId || findOutputIndex(selectedOutputId) === -1) {
      selectedOutputId = draftOutputs.length > 0 ? draftOutputs[0].outputId : "";
    }
  }

  function findOutputIndex(outputId) {
    for (var index = 0; index < draftOutputs.length; index++) {
      if (draftOutputs[index].outputId === outputId) {
        return index;
      }
    }
    return -1;
  }

  function getSelectedOutput() {
    var index = findOutputIndex(selectedOutputId);
    return index >= 0 ? draftOutputs[index] : null;
  }

  function selectOutput(outputId, context) {
    if (!activatePolicy(context)) return;
    selectedOutputId = outputId;
  }

  function roundCoordinate(value, snap, policy) {
    var rounded = Math.round(value);

    if (!snap || !(policy.settings.snapToGrid ?? defaults.snapToGrid ?? true)) {
      return rounded;
    }

    var step = gridSize(policy);
    return Math.round(rounded / step) * step;
  }

  function setOutputPosition(outputId, x, y, snap, context) {
    const policy = capturePolicy(context);
    if (!policy || !activatePolicy(policy.context)) return;
    var index = findOutputIndex(outputId);
    if (index === -1) {
      return;
    }

    var nextOutputs = cloneValue(draftOutputs);
    nextOutputs[index].x = roundCoordinate(x, snap, policy);
    nextOutputs[index].y = roundCoordinate(y, snap, policy);
    draftOutputs = nextOutputs;
    selectedOutputId = outputId;
    statusText = pluginApi?.tr("status.dirty");
  }

  function setOutputResolution(outputId, modeId, context) {
    if (!activatePolicy(context)) return;
    var index = findOutputIndex(outputId);
    if (index === -1) {
      return;
    }

    var nextOutputs = cloneValue(draftOutputs);
    var output = nextOutputs[index];
    var modes = output.availableModes || [];

    for (var modeIndex = 0; modeIndex < modes.length; modeIndex++) {
      var mode = modes[modeIndex];
      if (mode.id !== modeId) {
        continue;
      }

      output.modeId = mode.id;
      output.width = mode.width;
      output.height = mode.height;
      output.refresh = mode.refresh;
      output.resolutionLabel = mode.label;
      draftOutputs = nextOutputs;
      selectedOutputId = outputId;
      statusText = pluginApi?.tr("status.dirty");
      return;
    }
  }

  function setOutputScale(outputId, scaleValue, context) {
    if (!activatePolicy(context)) return;
    var index = findOutputIndex(outputId);
    if (index === -1) {
      return;
    }

    var parsed = Number(scaleValue);
    if (!isFinite(parsed) || parsed <= 0) {
      return;
    }

    // Keep scale within a practical range for Wayland compositors.
    var clamped = Math.max(0.25, Math.min(8, parsed));

    var nextOutputs = cloneValue(draftOutputs);
    nextOutputs[index].scale = Math.round(clamped * 100) / 100;
    draftOutputs = nextOutputs;
    selectedOutputId = outputId;
    statusText = t("status.dirty");
  }

  function resetDraftOutputs(context) {
    if (!activatePolicy(context)) return;
    draftOutputs = cloneValue(liveOutputs);
    statusText = pluginApi?.tr("status.reset");
    errorText = "";
    if (!selectedOutputId || findOutputIndex(selectedOutputId) === -1) {
      selectedOutputId = draftOutputs.length > 0 ? draftOutputs[0].outputId : "";
    }
  }

  function refreshOutputs(context, retainedPolicy) {
    if (isRefreshing) {
      return;
    }

    const policy = retainedPolicy || capturePolicy(context);
    if (!policy?.context?.current() || !activatePolicy(policy.context)) return;

    refreshStderr = "";
    errorText = "";
    statusText = pluginApi?.tr("status.refreshing");
    isRefreshing = true;

    var command = backendBuildFetchCommand(policy);
    if (!command) {
      isRefreshing = false;
      errorText = pluginApi?.tr("errors.unsupportedBackend");
      statusText = "";
      return;
    }

    fetchPolicy = policy;
    fetchProcess.command = command;
    fetchProcess.running = true;
  }

  function getConfigurationScript(context) {
    const policy = capturePolicy(context);
    if (!policy) return {"error": pluginApi?.tr("errors.unsupportedBackend")};
    var result = backendBuildConfigFileContent(policy);
    if (result.error) {
      return { "error": result.error };
    }
    return { "content": result.content, "backend": policy.backend };
  }

  function applyLayout(context) {
    if (isApplying) {
      return;
    }

    const policy = capturePolicy(context);
    if (!policy || !activatePolicy(policy.context)) return;
    var result = backendBuildApplyCommand(policy);
    if (result.error) {
      errorText = result.error;
      statusText = "";
      return;
    }

    applyStderr = "";
    errorText = "";
    statusText = pluginApi?.tr("status.applying");
    isApplying = true;
    applyPolicy = policy;
    applyProcess.command = ["sh", "-lc", result.script];
    applyProcess.running = true;
  }

  function noteConfigurationCopied(context) {
    if (activatePolicy(context)) statusText = pluginApi?.tr("status.configCopied");
  }
}
