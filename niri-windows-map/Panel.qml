import QtQuick
import Quickshell.Io
import qs.Commons

// Niri Windows Map — panel content loaded by PluginPanelSlot (a SmartPanel).
// The slot passes through these behavior opt-outs, making the panel a
// persistent, click-through, non-dimming, non-exclusive overlay anchored
// bottom-right, with the bottom-right corner flattened into the screen edge.
Item {
  id: root

  // Injected by PluginPanelSlot
  property var pluginApi: null
  property var screen: null

  anchors.fill: parent

  // Single position value — the slot derives its SmartPanel anchors from
  // this one string (same pattern as ControlCenter/Dock/Launcher), so all
  // four anchor reads stay consistent. Bottom-right is the default.
  readonly property string corner: pluginApi?.pluginSettings?.corner || "bottomRight"

  // SmartPanel behavior opt-outs (passed through by the slot)
  readonly property bool dimEnabled: false
  readonly property bool closeOnClickOutside: false
  readonly property bool exclusiveKeyboard: false
  readonly property bool flattenScreenCorners: true
  readonly property bool exclusiveOpen: false

  // Terminal identity bridge: winId -> {cwd, cwdBase, fg, fgCmd} for
  // terminal windows, resolved by the python helper from /proc.
  readonly property bool terminalIcons: pluginApi?.pluginSettings?.terminalIcons ?? true
  property var terminalInfo: ({})
  readonly property string _bridgePath: Qt.resolvedUrl("terminal-bridge.py").toString().replace("file://", "")

  Process {
    id: terminalBridge
    // Only poll while the map is actually open and the feature is on
    running: root.visible && root.terminalIcons
    command: ["python3", root._bridgePath]
    onRunningChanged: {
      if (!running)
        root.terminalInfo = ({});
    }
    stdout: SplitParser {
      onRead: data => {
        try {
          const arr = JSON.parse(data);
          const m = {};
          for (const e of arr)
            m[e.winId] = e;
          root.terminalInfo = m;
        } catch (err) {
          // partial line — ignore
        }
      }
    }
  }

  // Browser identity bridge: winId -> {url, host, icon} for browser
  // windows, resolved locally from browser history + favicon caches.
  readonly property bool browserIcons: pluginApi?.pluginSettings?.browserIcons ?? true
  property var browserInfo: ({})

  // Audio attribution: winId -> {node, muted} for windows confidently
  // matched to a live output stream (sticky cache in AudioMap)
  readonly property bool audioIndicators: pluginApi?.pluginSettings?.audioIndicators ?? true

  MapFacade {
    id: facadeAdapter
  }

  AudioMap {
    id: audioMap
    windows: facadeAdapter.mapState.windows
    // NOT tied to root.visible: the sticky stream↔window cache must stay
    // warm while the map is closed, or pairs formed during the
    // single-stream era are lost before the map ever opens
    active: root.audioIndicators
  }

  readonly property string _browserBridgePath: Qt.resolvedUrl("browser-bridge.py").toString().replace("file://", "")

  Process {
    id: browserBridge
    running: root.visible && root.browserIcons
    command: ["python3", root._browserBridgePath]
    onRunningChanged: {
      if (!running)
        root.browserInfo = ({});
    }
    stdout: SplitParser {
      onRead: data => {
        try {
          const arr = JSON.parse(data);
          const m = {};
          for (const e of arr)
            m[e.winId] = e;
          root.browserInfo = m;
        } catch (err) {
          // partial line — ignore
        }
      }
    }
  }

  // Presets choose the row height and width cap. Light desks never grow
  // to fill the screen-relative limits.
  readonly property string _sizeKey: pluginApi?.pluginSettings?.panelSize || "regular"
  readonly property real _screenW: root.screen?.width || 1920
  readonly property real _screenH: root.screen?.height || 1080
  readonly property real _panelLimitW: Math.round(_screenW * (_sizeKey === "compact" ? 0.25 : (_sizeKey === "large" ? 0.5 : 0.375)))
  readonly property real _panelLimitH: Math.round(_screenH * 0.7)

  // Bounding box is the UPPER LIMIT; the visible panel hugs the content
  // so aspect-mismatch never leaves letterbox gaps around the map.
  readonly property real contentPreferredWidth: Math.min(_panelLimitW, mapCanvas.renderedW + 16)
  // The cap applies to the MAP's budget; the phantom strip adds BEYOND it
  // during a drag (the container grows upward to reveal it, per the design)
  readonly property real contentPreferredHeight: Math.min(_panelLimitH, mapCanvas.renderedH + 16) + (mapCanvas.dragActive ? mapCanvas.phantomHeight : 0)

  MapCanvas {
    id: mapCanvas
    mapFacade: facadeAdapter
    anchors.fill: parent
    anchors.margins: 8
    screen: root.screen
    maxPanelW: root._panelLimitW
    maxPanelH: root._panelLimitH
    hideIcons: pluginApi?.pluginSettings?.hideIcons ?? false
    terminalIcons: root.terminalIcons
    terminalInfo: root.terminalInfo
    browserIcons: root.browserIcons
    browserInfo: root.browserInfo
    audioIndicators: root.audioIndicators
    audioInfo: audioMap.audioInfo
    hoverInfo: pluginApi?.pluginSettings?.hoverInfo ?? true
    sizeKey: root._sizeKey
    onMuteToggleRequested: winId => audioMap.toggleMute(winId)
    onPlayToggleRequested: winId => audioMap.togglePlay(winId)
    // Hide after navigation only (tile focus / workspace switch / menu
    // Focus) — future interactions (drag, zoom, menu Close) won't hide
    onNavigationRequested: {
      if (pluginApi?.pluginSettings?.hideOnClick)
        pluginApi.closePanel(root.screen);
    }
  }
}
