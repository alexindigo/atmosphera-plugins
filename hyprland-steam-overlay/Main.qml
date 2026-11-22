import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var pluginApi: null

  property bool steamRunning: false
  property bool overlayActive: false
  property var steamWindows: []
  property var _overlayPolicy: null
  property bool _opening: false
  property bool _retired: false
  readonly property bool _policyCurrent: !_retired && (_overlayPolicy?.current ?? false)
  readonly property bool _observationsReady: luaModeProbed && resolutionProbed

  Component { id: policyComponent; OverlayPolicy {} }

  function policyCurrent(policy) {
    return !_retired && policy && policy === _overlayPolicy && policy.current;
  }

  function capturePolicy(context) {
    context = context || pluginApi?.settingsContext;
    if (_retired || !context?.current()) return null;
    return policyComponent.createObject(root, {context: context, values: context.settingsView,
      defaults: defaults, screenWidth: screenWidth, screenHeight: screenHeight, luaMode: luaMode});
  }

  function stopPolicy() {
    for (const process of [detectWindows, detectAllWindows, moveAllWindows, moveWindows,
      showWorkspace, hideWorkspace, focusAdditionalWindows, executeFocus, detectNewWindows, moveNewWindows])
      process.running = false;
    _opening = false;
  }

  on_PolicyCurrentChanged: { if (!_policyCurrent) stopPolicy(); }
  on_ObservationsReadyChanged: { if (_observationsReady) beginOpening(_overlayPolicy); }
  Component.onDestruction: { _retired = true; stopPolicy(); }

  function beginOpening(policy) {
    if (!policyCurrent(policy) || !_opening || !_observationsReady || overlayActive) return;
    // Configuration was captured at invocation. Settle common startup observations
    // once, before any request query or compositor effect can use this policy.
    policy.screenWidth = screenWidth;
    policy.screenHeight = screenHeight;
    policy.luaMode = luaMode;
    steamWindows = [];
    detectWindows.lines = [];
    detectWindows.policy = policy;
    detectWindows.running = true;
  }

  // Auto-detect screen resolution
  property int screenWidth: 3440  // Default, will be updated
  property int screenHeight: 1440  // Default, will be updated
  property bool resolutionProbed: false

  // The shared API supplies reference defaults, never an active caller's policy.
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Hyprland >= 0.55 deprecated hyprlang (.conf) in favour of Lua (.lua).
  // Under a Lua config, `hyprctl dispatch <name> <args>` is parsed AS LUA
  // (hl.dispatch(<text>)), so the classic syntax errors out. We probe once
  // at startup and emit the correct syntax for whichever config is active.
  property bool luaMode: false
  property bool luaModeProbed: false

  onPluginApiChanged: {
    if (pluginApi) {
      checkSteam.running = true;
    }
  }

  Component.onCompleted: {
    if (pluginApi) {
      checkSteam.running = true;
    }
    detectConfigMode.running = true;
    detectResolution.running = true;
    monitorTimer.start();
  }

  // Check if Steam is running
  Process {
    id: checkSteam
    command: ["pidof", "steam"]
    running: false

    onExited: (exitCode, exitStatus) => {
      steamRunning = (exitCode === 0);
    }
  }

  // Launch Steam
  Process {
    id: launchSteam
    command: ["steam", "steam://open/main"]
    running: false
  }

  // Probe whether Hyprland runs a Lua config (hyprctl dispatch parsed as Lua).
  // On Lua config `hl.dsp.no_op()` returns "ok"; on hyprlang it errors.
  Process {
    id: detectConfigMode
    command: ["hyprctl", "dispatch", "hl.dsp.no_op()"]
    running: false

    property string out: ""

    stdout: SplitParser {
      onRead: data => {
        detectConfigMode.out += data;
      }
    }

    onExited: (exitCode, exitStatus) => {
      root.luaMode = (exitCode === 0 && detectConfigMode.out.trim() === "ok");
      root.luaModeProbed = true;
      detectConfigMode.out = "";
    }
  }

  // Detect screen resolution
  Process {
    id: detectResolution
    command: ["bash", "-c", "hyprctl monitors -j | jq -r '.[0] | \"\\(.width) \\(.height)\"'"]
    running: false

    stdout: SplitParser {
      onRead: data => {
        var parts = data.trim().split(" ");
        if (parts.length === 2) {
          screenWidth = parseInt(parts[0]);
          screenHeight = parseInt(parts[1]);
        }
      }
    }
    onExited: root.resolutionProbed = true
  }

  // Detect Steam windows (only Friends List, Main, and small Chat windows)
  Process {
    id: detectWindows
    command: ["bash", "-c", "hyprctl clients -j | jq -c '.[] | select(.class == \"steam\" and .fullscreen == 0) | {address: .address, title: .title, x: .at[0], y: .at[1], w: .size[0], h: .size[1]}'"]
    running: false

    property var lines: []
    property var policy: null

    stdout: SplitParser {
      onRead: data => {
        detectWindows.lines.push(data.trim());
      }
    }

    onExited: (exitCode, exitStatus) => {
      const admitted = policy;
      if (!root.policyCurrent(admitted)) { lines = []; return; }
      if (exitCode === 0 && lines.length > 0) {
        var allWindows = lines.map(line => JSON.parse(line));

        // Filter only main Steam UI windows (Friends List, Main Window, Chat)
        steamWindows = allWindows.filter(win => {
          var title = win.title || "";
          var width = win.w || 0;
          var height = win.h || 0;

          // Accept Friends List
          if (title.includes("Friends List")) return true;

          // Accept main Steam window
          if (title === "Steam") return true;

          // Accept chat windows (< 30% screen width and < 100% screen height)
          var maxChatWidth = admitted.screenWidth * 0.30;
          var maxChatHeight = admitted.screenHeight * 1.0;
          if (width < maxChatWidth && height < maxChatHeight) return true;

          // Reject everything else (games, large auxiliary windows, etc.)
          return false;
        });

      }
      lines = [];
      if (exitCode === 0 && steamWindows.length > 0) {
        detectAllWindows.allSteamWindows = [];
        detectAllWindows.policy = admitted;
        detectAllWindows.running = true;
      } else root._opening = false;
    }
  }

  // Move and position windows
  Process {
    id: moveWindows
    property var policy: null
    command: ["bash", "-c", ""]
    running: false

    onExited: (exitCode, exitStatus) => {
      if (!root.policyCurrent(policy)) return;
      if (exitCode === 0) root.doShowWorkspace(policy);
      else root._opening = false;
    }
  }

  // Show special workspace (only when opening overlay)
  Process {
    id: showWorkspace
    property var policy: null
    command: ["bash", "-c", ""]
    running: false

    onExited: (exitCode, exitStatus) => {
      const admitted = policy;
      if (!root.policyCurrent(admitted)) return;
      root._opening = false;
      if (exitCode === 0) {
        overlayActive = true;
        if (!admitted.useCustomLayout) {
          Qt.callLater(() => {
            if (!root.policyCurrent(admitted) || !overlayActive) return;
            focusAdditionalWindows.addresses = [];
            focusAdditionalWindows.policy = admitted;
            focusAdditionalWindows.running = true;
          });
        }
      }
    }
  }

  // Hide special workspace (only when closing overlay)
  Process {
    id: hideWorkspace
    property var policy: null
    command: ["bash", "-c", ""]
    running: false

    onExited: (exitCode, exitStatus) => {
      if (!root.policyCurrent(policy)) return;
      overlayActive = false;
      root._opening = false;
    }
  }

  // Focus additional (non-main) windows to bring them to front
  Process {
    id: focusAdditionalWindows
    command: ["bash", "-c", "hyprctl clients -j | jq -r '.[] | select(.class == \"steam\" and .workspace.name == \"special:steam\" and .fullscreen == 0) | .address'"]
    running: false

    property var addresses: []
    property var policy: null

    stdout: SplitParser {
      onRead: data => {
        var addr = data.trim();
        if (addr && addr.startsWith("0x")) {
          focusAdditionalWindows.addresses.push(addr);
        }
      }
    }

    onExited: (exitCode, exitStatus) => {
      const admitted = policy;
      if (!root.policyCurrent(admitted) || !overlayActive) { addresses = []; return; }
      if (exitCode === 0 && addresses.length > 0) {
        var focusCommands = [];

        // Focus only non-main windows
        for (var i = 0; i < addresses.length; i++) {
          var addr = addresses[i];
          var isMain = false;

          // Check if this is one of the 3 main windows
          for (var j = 0; j < steamWindows.length; j++) {
            if (steamWindows[j].address === addr) {
              isMain = true;
              break;
            }
          }

          // Bring additional windows to top (without focusing/moving cursor)
          if (!isMain) {
            focusCommands.push(root.hdAlterTop(addr, admitted));
          }
        }

        if (focusCommands.length > 0) {
          executeFocus.command = ["bash", "-c", focusCommands.join(" && ")];
          executeFocus.policy = admitted;
          executeFocus.running = true;
        }
      }
      addresses = [];
    }
  }

  // Execute focus commands
  Process {
    id: executeFocus
    property var policy: null
    command: ["bash", "-c", ""]
    running: false
  }

  // Timer to monitor Steam
  Timer {
    id: monitorTimer
    interval: 3000
    repeat: true
    running: false

    onTriggered: {
      checkSteam.running = true;
    }
  }

  // Timer to monitor for NEW Steam windows while overlay is active
  Timer {
    id: newWindowMonitor
    interval: 150
    repeat: true
    running: overlayActive && root._policyCurrent && !root._opening

    onTriggered: {
      if (!detectNewWindows.running) {
        detectNewWindows.windowData = [];
        detectNewWindows.policy = root._overlayPolicy;
        detectNewWindows.running = true;
      }
    }
  }

  // Process to detect new Steam windows that appeared after overlay was opened
  Process {
    id: detectNewWindows
    command: ["bash", "-c", "hyprctl clients -j | jq -c '.[] | select(.class == \"steam\" and .fullscreen == 0 and (.title | startswith(\"notificationtoasts\") | not)) | {address: .address, workspace: .workspace.name}'"]
    running: false

    property var windowData: []
    property var policy: null

    stdout: SplitParser {
      onRead: data => {
        var line = data.trim();
        if (line) {
          try {
            detectNewWindows.windowData.push(JSON.parse(line));
          } catch (e) {}
        }
      }
    }

    onExited: (exitCode, exitStatus) => {
      const admitted = policy;
      if (!root.policyCurrent(admitted) || !overlayActive) { windowData = []; return; }
      if (exitCode === 0 && windowData.length > 0) {
        var windowsToMove = [];

        for (var i = 0; i < windowData.length; i++) {
          var win = windowData[i];
          var addr = win.address;
          var workspace = win.workspace || "";

          // Move ANY Steam window that is not in special:steam
          if (workspace !== "special:steam") {
            windowsToMove.push(addr);
          }
        }

        // Move windows to overlay and bring to top
        if (windowsToMove.length > 0) {
          var commands = [];
          for (var j = 0; j < windowsToMove.length; j++) {
            var addr = windowsToMove[j];
            commands.push(root.hdMoveToSpecial(addr, admitted));
            if (!admitted.useCustomLayout) {
              commands.push(root.hdSetFloating(addr, admitted));
              commands.push(root.hdAlterTop(addr, admitted));
            }
          }
          if (!moveNewWindows.running) {
            moveNewWindows.command = ["bash", "-c", commands.join(" && ")];
            moveNewWindows.policy = admitted;
            moveNewWindows.running = true;
          }
        }
      }
    }
  }

  // Execute move commands for new windows
  Process {
    id: moveNewWindows
    property var policy: null
    command: ["bash", "-c", ""]
    running: false
  }

  // Detect ALL Steam windows (including additional ones)
  Process {
    id: detectAllWindows
    command: ["bash", "-c", "hyprctl clients -j | jq -c '.[] | select(.class == \"steam\" and .fullscreen == 0) | {address: .address, title: .title}'"]
    running: false

    property var allSteamWindows: []
    property var policy: null

    stdout: SplitParser {
      onRead: data => {
        var line = data.trim();
        if (line) {
          try {
            detectAllWindows.allSteamWindows.push(JSON.parse(line));
          } catch (e) {}
        }
      }
    }

    onExited: (exitCode, exitStatus) => {
      const admitted = policy;
      if (!root.policyCurrent(admitted)) { allSteamWindows = []; return; }
      if (exitCode === 0 && allSteamWindows.length > 0) {
        var commands = [];

        for (var i = 0; i < allSteamWindows.length; i++) {
          var win = allSteamWindows[i];
          var addr = win.address;
          var title = win.title || "";

          // Skip notification toasts
          if (title.includes("notificationtoasts")) {
            continue;
          }

          // Move all Steam windows to the overlay workspace. With the custom
          // Lua layout active the layout tiles them, so we must NOT float.
          commands.push(root.hdMoveToSpecial(addr, admitted));
          if (!admitted.useCustomLayout) {
            commands.push(root.hdSetFloating(addr, admitted));
          }
        }

        if (commands.length > 0) {
          moveAllWindows.command = ["bash", "-c", commands.join(" && ")];
          moveAllWindows.policy = admitted;
          moveAllWindows.running = true;
        } else root._opening = false;
      } else root._opening = false;
      allSteamWindows = [];
    }
  }

  // Execute move all windows commands
  Process {
    id: moveAllWindows
    property var policy: null
    command: ["bash", "-c", ""]
    running: false

    onExited: (exitCode, exitStatus) => {
      const admitted = policy;
      if (!root.policyCurrent(admitted)) return;
      if (exitCode === 0) {
        Qt.callLater(() => {
          if (!root.policyCurrent(admitted)) return;
          if (admitted.useCustomLayout) {
            // Hyprland's lua:steam layout arranges the windows; just reveal.
            root.doShowWorkspace(admitted);
          } else if (steamWindows.length > 0) {
            moveWindowsToOverlay(admitted);
          }
        });
      } else root._opening = false;
    }
  }


  // ---- Dual-mode hyprctl dispatch builders -------------------------------
  // Each returns a full `hyprctl dispatch ...` shell fragment, using Lua
  // (hl.dsp.*) syntax under a Lua config or classic syntax under hyprlang.
  function hdToggleSpecial(policy) {
    return policy.luaMode
      ? "hyprctl dispatch 'hl.dsp.workspace.toggle_special(\"steam\")'"
      : "hyprctl dispatch togglespecialworkspace steam";
  }

  function hdMoveToSpecial(addr, policy) {
    return policy.luaMode
      ? "hyprctl dispatch 'hl.dsp.window.move({ workspace = \"special:steam\", follow = false, window = \"address:" + addr + "\" })'"
      : "hyprctl dispatch movetoworkspacesilent special:steam,address:" + addr;
  }

  function hdSetFloating(addr, policy) {
    return policy.luaMode
      ? "hyprctl dispatch 'hl.dsp.window.float({ action = \"enable\", window = \"address:" + addr + "\" })'"
      : "hyprctl dispatch setfloating address:" + addr;
  }

  function hdAlterTop(addr, policy) {
    return policy.luaMode
      ? "hyprctl dispatch 'hl.dsp.window.alter_zorder({ mode = \"top\", window = \"address:" + addr + "\" })'"
      : "hyprctl dispatch alterzorder top,address:" + addr;
  }

  function hdResize(w, h, addr, policy) {
    return policy.luaMode
      ? "hyprctl dispatch 'hl.dsp.window.resize({ x = " + w + ", y = " + h + ", exact = true, window = \"address:" + addr + "\" })'"
      : "hyprctl dispatch resizewindowpixel exact " + w + " " + h + ",address:" + addr;
  }

  function hdMovePixel(x, y, addr, policy) {
    return policy.luaMode
      ? "hyprctl dispatch 'hl.dsp.window.move({ x = " + x + ", y = " + y + ", window = \"address:" + addr + "\" })'"
      : "hyprctl dispatch movewindowpixel exact " + x + " " + y + ",address:" + addr;
  }

  function doShowWorkspace(policy) {
    if (!policyCurrent(policy)) return;
    showWorkspace.policy = policy;
    showWorkspace.command = ["bash", "-c", hdToggleSpecial(policy)];
    showWorkspace.running = true;
  }

  function doHideWorkspace(policy) {
    if (!policyCurrent(policy)) return;
    hideWorkspace.policy = policy;
    hideWorkspace.command = ["bash", "-c", hdToggleSpecial(policy)];
    hideWorkspace.running = true;
  }

  function toggleOverlay(context) {
    context = context || pluginApi?.settingsContext;
    if (_retired || !context?.current() || _opening) return false;
    if (!steamRunning) {
      launchSteam.running = true;
      return true;
    }
    stopPolicy();
    const previous = _overlayPolicy;
    _overlayPolicy = capturePolicy(context);
    if (previous) previous.destroy();
    if (!_overlayPolicy) return false;
    _opening = true;
    if (overlayActive) {
      root.doHideWorkspace(_overlayPolicy);
    } else {
      beginOpening(_overlayPolicy);
    }
    return true;
  }

  function moveWindowsToOverlay(policy) {
    if (!policyCurrent(policy)) return;
    var commands = [];

    for (var i = 0; i < steamWindows.length; i++) {
      var win = steamWindows[i];
      var addr = win.address;
      var title = win.title;

      // Position based on title with percentage layout + center offset
      var x = 0, y = policy.topMargin, w = 800, h = policy.windowHeight;

      if (title === "Steam") {
        // Main window: center + friends + gap
        x = policy.centerOffset + policy.friendsWidth + policy.gapSize;
        w = policy.mainWidth;
      } else if (title === "Friends List") {
        // Friends: center offset (left side)
        x = policy.centerOffset;
        w = policy.friendsWidth;
      } else {
        // Chat: center + friends + gap + main + gap
        x = policy.centerOffset + policy.friendsWidth + policy.gapSize + policy.mainWidth + policy.gapSize;
        w = policy.chatWidth;
      }

      // Position and size the 3 main windows (they are already floating and in overlay)
      commands.push(root.hdResize(w, h, addr, policy));
      commands.push(root.hdMovePixel(x, y, addr, policy));
    }

    if (commands.length > 0) {
      moveWindows.command = ["bash", "-c", commands.join(" && ")];
      moveWindows.policy = policy;
      moveWindows.running = true;
    }
  }

  // IPC Handler
  IpcHandler {
    target: "plugin:hyprland-steam-overlay"

    function toggle() {
      root.toggleOverlay();
    }
  }
}
