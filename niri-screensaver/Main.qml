// Main.qml - niri-screensaver Noctalia plugin runtime
//
// Responsibilities:
//   1. Persist plugin settings to $XDG_CONFIG_HOME/niri-screensaver/config (or
//      ~/.config/niri-screensaver/config) in shell KEY="value" format so the
//      script-side driver picks them up.
//   2. Auto-register / deregister a screensaver entry in Noctalia's
//      Settings.data.idle.customCommands array based on plugin enable state.
//   3. Auto-write Noctalia's screenLock / screenUnlock hook slots (never
//      clobbering hooks the user authored manually).
//   4. Expose IPC: plugin:niri-screensaver { launch | kill | toggle }
//   5. Detect whether the bash CLI (niri-screensaver-launch) is on PATH so
//      Settings.qml can surface a banner if it's missing.
//
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var pluginApi: null
  property var selectedContext: null
  property bool retired: false
  property bool componentReady: false
  property int generation: 0
  property string ownedLockHook: ""
  property string ownedUnlockHook: ""
  property var queuedConfig: null
  readonly property var policyContext: selectedContext || pluginApi?.settingsContext
  readonly property bool policyCurrent: !retired && (policyContext?.current() ?? false)
  readonly property var cfg: policyCurrent ? policyContext.settingsView : ({})
  readonly property string policySignature: JSON.stringify(cfg)
  onPolicySignatureChanged: if (componentReady) syncDebounce.restart()
  onPolicyCurrentChanged: {
    if (componentReady && !policyCurrent) {
      generation++
      syncDebounce.stop()
      queuedConfig = null
      writeConfigProcess.running = false
      _removeRegistration()
    }
  }

  function applySettings(context) {
    context = context || pluginApi?.settingsContext
    if (retired || !context?.current()) return false
    generation++
    selectedContext = context
    syncDebounce.restart()
    return true
  }

  // Identifier used to find / remove our entry in Noctalia's idle.customCommands
  readonly property string entryName: "Niri Screensaver"

  // Centralized defaults (also mirrored in manifest.json defaultSettings)
  readonly property string defaultLauncherCommand: "niri-screensaver-launch launch"
  readonly property string defaultKillCommand: "niri-screensaver-launch kill"
  readonly property string cliBinary: "niri-screensaver-launch"

  // ----- File paths (XDG-aware) -----
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
  readonly property string configDir: configHome + "/niri-screensaver"
  readonly property string configFile: configDir + "/config"

  // ----- CLI presence (true|false|null=unknown), surfaced to Settings.qml -----
  property var cliAvailable: null

  // ----- Lifecycle -----
  Component.onCompleted: {
    componentReady = true
    if (pluginApi) {
      _syncAll()
      _detectCli()
    }
  }
  onPluginApiChanged: {
    if (componentReady && pluginApi) {
      _syncAll()
      _detectCli()
    }
  }

  // Collapse native field publications from one Apply into one effect batch.
  Timer {
    id: syncDebounce
    interval: 250
    repeat: false
    onTriggered: root._syncAll()
  }

  function _syncAll() {
    if (!componentReady || !policyCurrent) return
    const policy = {context: policyContext, generation: generation, values: cfg}
    _writeShellConfig(policy)
    _syncIdleEntry(policy.values)
    _syncHooks(policy.values)
  }

  // ----- Resolve a "command-or-default" setting into an exec array -----
  // For trusted defaults we use direct exec (no shell). For user overrides we
  // fall back to `sh -c` because the user may want shell semantics (env vars,
  // pipes, etc.) — they own the value.
  function _resolveCommand(value, fallbackString, directArgv) {
    if (!value || value === fallbackString) return directArgv
    return ["sh", "-c", String(value)]
  }
  function _launcherArgv(context) {
    context = context || pluginApi?.settingsContext
    if (retired || !context?.current()) return []
    return _resolveCommand(
      context.settingsView.launcherCommand,
      defaultLauncherCommand,
      ["niri-screensaver-launch", "launch"]
    )
  }
  function _killArgv(context) {
    context = context || pluginApi?.settingsContext
    if (retired || !context?.current()) return []
    return _resolveCommand(
      context.settingsView.killCommand,
      defaultKillCommand,
      ["niri-screensaver-launch", "kill"]
    )
  }
  // Quiet running-state probe for the bar widget's smart left-click toggle:
  // exit 0 if running, 1 if not. Uses the standard launcher on PATH (a fully
  // custom launcherCommand is rare and the launcher name is stable), so the
  // widget can decide whether a click should launch or stop.
  function _statusArgv() {
    return ["niri-screensaver-launch", "is-running"]
  }

  // ----- Shell config writer -----
  function _renderShellConfig(s) {
    var bool = function (b) { return b ? "true" : "false" }
    return [
      "# niri-screensaver config (managed by Noctalia plugin)",
      "BATTERY_MIN_PERCENT=\"" + _shEscape(s.batteryMinPercent || 0) + "\"",
      "FRAME_RATE=\"" + _shEscape(s.frameRate || 60) + "\"",
      "INCLUDE_EFFECTS=\"" + _shEscape(s.includeEffects) + "\"",
      "EXCLUDE_EFFECTS=\"" + _shEscape(s.excludeEffects) + "\"",
      "FADE_IN_EFFECT=\"" + _shEscape(s.fadeInEffect) + "\"",
      "FADE_OUT_EFFECT=\"" + _shEscape(s.fadeOutEffect) + "\"",
      "SHOW_CLOCK=\"" + bool(s.showClock) + "\"",
      "CLOCK_DURATION=\"" + _shEscape(s.clockDuration || 3) + "\"",
      "CLOCK_FORMAT=\"" + _shEscape(s.clockFormat) + "\"",
      "CLOCK_FONT=\"" + _shEscape(s.clockFont) + "\"",
      "SHOW_NOW_PLAYING=\"" + bool(s.showNowPlaying) + "\"",
      "NOW_PLAYING_DURATION=\"" + _shEscape(s.nowPlayingDuration || 3) + "\"",
      "LOGO_FILE=\"" + _shEscape(s.logoPath) + "\"",
      "CURSOR_HIDE=\"" + bool(s.cursorHide) + "\"",
      "CURSOR_WARP=\"" + bool(s.cursorWarp) + "\"",
      "DISMISS_ON_KEY=\"" + bool(s.dismissOnKey) + "\"",
      "RANDOM_LOGO=\"" + bool(s.randomLogo) + "\"",
      "LOGO_DIR=\"" + _shEscape(s.logoDir) + "\"",
      "MULTI_MONITOR_MODE=\"" + _shEscape(s.multiMonitorMode || "independent") + "\"",
      ""
    ].join("\n")
  }

  // Escape a value for inclusion inside a double-quoted shell string.
  // Backslash, dollar, backtick, double-quote all need escaping inside "...".
  function _shEscape(s) {
    if (s === undefined || s === null) return ""
    return String(s).replace(/\\/g, "\\\\").replace(/\$/g, "\\$").replace(/`/g, "\\`").replace(/"/g, '\\"')
  }

  Process {
    id: writeConfigProcess
    property var policy: null
    onExited: function (code) {
      if (code !== 0) {
        Logger.w("NiriScreensaver", "config write exited with code", code, "for", root.configFile)
      }
      policy = null
      Qt.callLater(function() { if (root) root._writeNextConfig(); })
    }
  }

  // Write config via positional shell args + a random heredoc marker.
  // - Paths are passed via "$1" / "$2", so a malicious HOME / XDG_CONFIG_HOME
  //   value cannot escape into the script body.
  // - The heredoc marker is randomized and collision-checked against the
  //   content, so a user-supplied config value cannot terminate the heredoc.
  function _writeShellConfig(policy) {
    queuedConfig = policy
    _writeNextConfig()
  }
  function _writeNextConfig() {
    if (writeConfigProcess.running) return
    const policy = queuedConfig
    queuedConfig = null
    if (!policyCurrent || !policy || policy.generation !== generation || policy.context !== policyContext || !policy.context.current()) return
    var content = _renderShellConfig(policy.values)
    var eof = "__NIRI_SS_EOF_" + Math.random().toString(36).slice(2)
    while (content.indexOf(eof) !== -1) {
      eof = "__NIRI_SS_EOF_" + Math.random().toString(36).slice(2)
    }
    var script = 'mkdir -p "$1" && cat > "$2" <<\'' + eof + "'\n" + content + eof + "\n"
    writeConfigProcess.command = ["sh", "-c", script, "sh", root.configDir, root.configFile]
    writeConfigProcess.policy = policy
    writeConfigProcess.running = true
  }

  // ----- Noctalia idle wiring -----
  function _syncIdleEntry(s) {
    if (!policyCurrent) return
    var raw = ""
    try {
      raw = Settings.data.idle.customCommands || "[]"
    } catch (e) {
      Logger.w("NiriScreensaver", "Settings.data.idle.customCommands unreachable:", e)
      return
    }

    var arr = []
    try { arr = JSON.parse(raw) } catch (e) { arr = [] }

    // Remove any existing entry of ours
    arr = arr.filter(function (e) { return e && e.name !== root.entryName })

    if (s.enabled) {
      arr.push({
        name: root.entryName,
        timeout: parseInt(s.idleSeconds) || 300,
        command: s.launcherCommand || root.defaultLauncherCommand,
        resumeCommand: s.killCommand || root.defaultKillCommand
      })
    }
    Settings.data.idle.customCommands = JSON.stringify(arr)
  }

  // ----- Noctalia Hooks wiring (screenLock / screenUnlock) -----
  //
  // Claim an empty slot, or replace/clear only a value we wrote to that slot.
  // Matching command text alone does not establish ownership of a manual hook.
  // Requires Settings.data.hooks.enabled = true to actually fire — the plugin
  // does not flip that master toggle for the user.
  function _syncHookSlot(slot, owned, desired) {
    const hooks = Settings.data.hooks
    if (!hooks) return ""
    const current = hooks[slot] || ""
    if ((owned && current === owned) || (desired && !current)) {
      hooks[slot] = desired
      return desired
    }
    return ""
  }

  function _syncHookSlots(command) {
    ownedLockHook = _syncHookSlot("screenLock", ownedLockHook, command)
    ownedUnlockHook = _syncHookSlot("screenUnlock", ownedUnlockHook, command)
  }

  function _syncHooks(s) {
    if (!policyCurrent) return
    if (!Settings.data.hooks) return  // Older Noctalia builds may lack hooks

    _syncHookSlots(s.enabled ? (s.killCommand || root.defaultKillCommand) : "")

    if (typeof Settings.saveImmediate === "function") {
      Settings.saveImmediate()
    }
  }

  // ----- CLI presence detection -----
  // Runs once at startup. Settings.qml reads `cliAvailable` to decide whether
  // to render the "install niri-screensaver first" banner.
  Process {
    id: cliDetectProcess
    onExited: function (code) {
      root.cliAvailable = (code === 0)
      if (!root.cliAvailable) {
        Logger.w("NiriScreensaver", root.cliBinary, "not found on PATH")
      }
    }
  }
  function _detectCli() {
    cliDetectProcess.command = ["sh", "-c", "command -v " + root.cliBinary]
    cliDetectProcess.running = true
  }

  // ----- IPC handlers -----
  IpcHandler {
    target: "plugin:niri-screensaver"

    function launch() {
      ipcLaunchProcess.command = root._launcherArgv()
      ipcLaunchProcess.running = ipcLaunchProcess.command.length > 0
    }
    function kill() {
      ipcKillProcess.command = root._killArgv()
      ipcKillProcess.running = ipcKillProcess.command.length > 0
    }
    function toggle() {
      if (!root.pluginApi) return
      var enabled = root.pluginApi.pluginSettings.enabled === true
      root.pluginApi.pluginSettings.enabled = !enabled
      root.pluginApi.saveSettings()
      root.applySettings(root.pluginApi.settingsContext)
    }
  }

  Process {
    id: ipcLaunchProcess
    onExited: function (code) {
      if (code !== 0) Logger.w("NiriScreensaver", "launch (IPC) exited with code", code)
    }
  }
  Process {
    id: ipcKillProcess
    onExited: function (code) {
      if (code !== 0) Logger.w("NiriScreensaver", "kill (IPC) exited with code", code)
    }
  }

  // ----- Cleanup on plugin disable / unload -----
  function _removeRegistration() {
    if (componentReady) {
      // Best-effort: remove our customCommands entry so we don't leave a dangling hook
      try {
        var arr = JSON.parse(Settings.data.idle.customCommands || "[]")
        arr = arr.filter(function (e) { return e && e.name !== root.entryName })
        Settings.data.idle.customCommands = JSON.stringify(arr)
      } catch (e) { /* ignore */ }

      // Mirror cleanup for hook slots — only clear values we wrote
      try {
        _syncHookSlots("")
      } catch (e) { /* ignore */ }

      if (typeof Settings.saveImmediate === "function") {
        Settings.saveImmediate()
      }
    }
  }
  Component.onDestruction: {
    retired = true
    generation++
    syncDebounce.stop()
    queuedConfig = null
    writeConfigProcess.running = false
    _removeRegistration()
    componentReady = false
  }
}
