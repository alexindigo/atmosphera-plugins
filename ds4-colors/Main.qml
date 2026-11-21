import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  // Map of controller base path -> { separator, red, green, blue, batteryLevel }
  property var controllers: ({})
  property bool isInitialScan: true
  property string lastError: ""
  property bool isApplying: false
  property var _colorOperation: null

  // Current color values
  property int currentR: 0
  property int currentG: 100
  property int currentB: 255

  // Periodic scan for controllers — only when none are detected
  Timer {
    id: scanTimer
    interval: 5000
    running: false
    repeat: true
    onTriggered: root.scanControllers()
  }

  function scanControllers() {
    if (controllerScanner.running)
      return;
    controllerScanner.running = true;
  }

  // Finds LED entries matching *:red or *::red under /sys/class/leds/,
  // resolves their real path, and outputs "led_path|real_path" per line.
  Process {
    id: controllerScanner
    command: ["sh", (pluginApi?.pluginDir ?? "") + "/scripts/scan_controllers.sh"]
    stdout: StdioCollector {
      id: scannerStdout
    }
    running: false

    onExited: function (exitCode, exitStatus) {
      const raw = scannerStdout.text || "";
      const lines = raw.trim().split("\n").filter(l => l.length > 0);
      const newControllers = {};

      for (let i = 0; i < lines.length; i++) {
        const parts = lines[i].split("|");
        if (parts.length < 2)
          continue;
        const redPath = parts[0];
        const realPath = parts[1];

        // Match Sony/PlayStation controllers only
        if (!realPath.toLowerCase().match(/sony|playstation|054c|ps-controller/))
          continue;
        const isDoubleColon = redPath.includes("::red");
        const suffix = isDoubleColon ? "::" : ":";
        const basePath = redPath.substring(0, redPath.lastIndexOf(suffix + "red"));
        if (!basePath)
          continue;

        // Carry over existing battery level
        const existingBattery = root.controllers[basePath]?.batteryLevel ?? -1;

        newControllers[basePath] = {
          separator: suffix,
          red: redPath,
          green: basePath + suffix + "green",
          blue: basePath + suffix + "blue",
          batteryLevel: existingBattery
        };
      }

      const oldKeys = Object.keys(root.controllers).sort();
      const newKeys = Object.keys(newControllers).sort();
      const controllersChanged = JSON.stringify(oldKeys) !== JSON.stringify(newKeys);

      if (controllersChanged || root.isInitialScan) {
        root.controllers = newControllers;

        if (controllersChanged) {
          Logger.i("DS4 Colors", "Controllers: " + newKeys.join(", "));
        }

        // Auto-apply saved color to newly connected controllers
        if (!root.isInitialScan && newKeys.length > 0) {
          root.applyColors();
        }
      }

      root.isInitialScan = false;

      // Only scan when no controllers are detected
      scanTimer.running = newKeys.length === 0;

      // Only scan battery when controllers exist
      if (newKeys.length > 0) {
        root.scanBattery();
      }
    }
  }

  // Battery scanning — matches by directory name and device symlink
  // to support NixOS (no "name" file) and standard distros.
  function scanBattery() {
    if (batteryScanProcess.running)
      return;
    batteryScanProcess.running = true;
  }

  Process {
    id: batteryScanProcess
    command: ["sh", (pluginApi?.pluginDir ?? "") + "/scripts/scan_battery.sh"]
    stdout: StdioCollector {
      id: batteryStdout
    }
    running: false

    onExited: function (exitCode, exitStatus) {
      const rawLevel = parseInt((batteryStdout.text || "").trim(), 10);
      const level = isNaN(rawLevel) ? -1 : rawLevel;

      // Update battery level on all detected controllers
      const updated = {};
      const keys = Object.keys(root.controllers);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const ctrl = root.controllers[key];
        updated[key] = {
          separator: ctrl.separator,
          red: ctrl.red,
          green: ctrl.green,
          blue: ctrl.blue,
          batteryLevel: level
        };
      }
      root.controllers = updated;
    }
  }

  // Apply color to all controllers
  function setColor(r, g, b, runtimeApi, context) {
    // Pages supply only a read context after their native Apply. Explicit
    // runtime/IPC actions additionally retain their own native writer.
    if (!context) {
      runtimeApi = runtimeApi || pluginApi;
      context = runtimeApi?.settingsContext;
    }
    if (!context?.current() || isApplying)
      return false;
    const controllerPaths = Object.keys(controllers);
    if (controllerPaths.length === 0) {
      lastError = pluginApi?.tr("errors.no_controllers");
      return false;
    }

    if (runtimeApi && runtimeApi.settingsContext !== context)
      return false;
    const pluginDir = pluginApi?.pluginDir ?? "";
    if (!pluginDir) {
      lastError = pluginApi?.tr("errors.plugin_dir_not_found");
      return false;
    }
    currentR = Math.max(0, Math.min(255, r));
    currentG = Math.max(0, Math.min(255, g));
    currentB = Math.max(0, Math.min(255, b));
    const targets = [];
    for (const path of controllerPaths) {
      const controller = controllers[path];
      targets.push({
                     path: path,
                     red: controller.red,
                     green: controller.green,
                     blue: controller.blue,
                     separator: controller.separator
                   });
    }
    const operation = {
      context: context,
      writer: runtimeApi || null,
      rgb: [currentR, currentG, currentB],
      pluginDir: pluginDir,
      controllers: targets,
      index: 0
    };
    _colorOperation = operation;
    isApplying = true;
    lastError = "";
    applyNextController(operation);
    return true;
  }

  function finishColor(operation, success) {
    if (_colorOperation !== operation)
      return;
    if (success && operation.context.current() && operation.writer) {
      operation.writer.pluginSettings.color = "#" + operation.rgb.map(value => value.toString(16).padStart(2, "0")).join("");
      operation.writer.saveSettings();
    }
    _colorOperation = null;
    isApplying = false;
  }

  function applyNextController(operation) {
    if (_colorOperation !== operation)
      return;
    if (!operation.context.current()) {
      finishColor(operation, false);
      return;
    }
    if (operation.index === operation.controllers.length) {
      finishColor(operation, true);
      return;
    }
    const target = operation.controllers[operation.index];
    const controller = target;
    if (!controller) {
      lastError = pluginApi?.tr("errors.controller_data_missing");
      finishColor(operation, false);
      return;
    }
    // Try direct write first (works when udev rules are set up)
    colorWriter.command = ["sh", operation.pluginDir + "/scripts/write_color.sh", controller.red, controller.green, controller.blue, String(operation.rgb[0]), String(operation.rgb[1]), String(operation.rgb[2])];
    colorWriter.operation = operation;
    colorWriter.running = true;
  }

  Process {
    id: colorWriter
    property var operation: null
    stdout: StdioCollector {
      id: writerStdout
    }
    running: false

    onExited: function (exitCode, exitStatus) {
      const output = (writerStdout.text || "").trim();
      const admitted = operation;
      if (!admitted || root._colorOperation !== admitted)
        return;
      if (output.includes("direct:ok")) {
        ++admitted.index;
        root.applyNextController(admitted);
      } else {
        if (!admitted.context.current()) {
          root.finishColor(admitted, false);
          return;
        }
        const target = admitted.controllers[admitted.index];
        // Escalate via pkexec for password prompt
        pkexecRunner.command = ["pkexec", admitted.pluginDir + "/scripts/set_ds4_color.sh", target.path, target.separator, String(admitted.rgb[0]), String(admitted.rgb[1]), String(admitted.rgb[2])];
        pkexecRunner.operation = admitted;
        pkexecRunner.running = true;
      }
    }
  }

  Process {
    id: pkexecRunner
    property var operation: null
    stderr: StdioCollector {
      id: pkexecStderr
    }
    running: false

    onExited: function (exitCode, exitStatus) {
      const admitted = operation;
      if (!admitted || root._colorOperation !== admitted)
        return;
      if (exitCode !== 0) {
        Logger.e("DS4 Colors", "pkexec failed (exit " + exitCode + "): " + (pkexecStderr.text || ""));
        root.lastError = pluginApi?.tr("errors.auth_failed");
        root.finishColor(admitted, false);
      } else {
        Logger.d("DS4 Colors", "Color applied via pkexec");
        ++admitted.index;
        root.applyNextController(admitted);
      }
    }
  }

  function applyColors(context, acceptedColor) {
    context = context || pluginApi?.settingsContext;
    if (!context?.current())
      return false;
    const cfg = context.settingsView;
    const selectedColor = acceptedColor ?? cfg?.color;
    if (!selectedColor)
      return false;

    const color = Qt.color(selectedColor);
    return setColor(Math.round(color.r * 255), Math.round(color.g * 255), Math.round(color.b * 255), null, context);
  }

  // IPC Handlers
  IpcHandler {
    target: "plugin:ds4-colors"

    // Set lightbar color by individual RGB components (0-255)
    function setColor(r: int, g: int, b: int) {
      root.setColor(r, g, b);
    }

    // Set lightbar color by hex string, e.g. "#ff0000" or "ff0000"
    function setColorHex(hex: string) {
      const clean = String(hex).replace("#", "");
      const r = parseInt(clean.substring(0, 2), 16) || 0;
      const g = parseInt(clean.substring(2, 4), 16) || 0;
      const b = parseInt(clean.substring(4, 6), 16) || 0;
      root.setColor(r, g, b);
    }

    // Turn the lightbar off
    function off(): void {
      root.setColor(0, 0, 0);
    }

    // Force an immediate rescan for connected controllers
    function scan(): void {
      root.scanControllers();
    }
  }

  Component.onCompleted: {
    if (pluginApi)
      root.scanControllers();
  }
}
