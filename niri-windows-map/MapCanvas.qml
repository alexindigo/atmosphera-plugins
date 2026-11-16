import Niri 1.0
import Niri 1.0
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Compositor
import qs.Widgets

// Spatial niri overview map, streaming directly from CompositorService.niriBackend.
// Uniform layout model (per NiriWindowsLayout.drawio):
//  - every workspace row is a monH-tall slot, rows strided contiguously
//  - row contents (indicator bar + windows) are inset _rowInset px top/bottom,
//    so any two adjacent rows' contents are exactly _rowGap px apart
//  - within a row, each column's tiles scale proportionally to fill the inset
//    extent with _winGap px between tiles; columns are _colGap px apart
//  - 4px indicator bar + 4px gap at each row's left edge
// Helpers work in raw canvas units; ALL gaps are applied in screen px after
// _autoScale (canvas-unit gaps would shrink to nothing at map scale).
Item {
  id: root

  property var screen: null
  // When true, app icons are not drawn on tiles (user setting)
  property bool hideIcons: false
  // Terminal identity from Panel's bridge process: winId -> {cwd, fg, ...}.
  // When terminalIcons is on and the fg app resolves to a themed icon, the
  // tile shows the fg app's icon instead of the terminal's.
  property var terminalInfo: ({})
  property bool terminalIcons: true
  // Browser identity: winId -> {url, host, icon}. When browserIcons is on
  // and the bridge resolved a favicon, the tile shows the site favicon
  // instead of the browser's app icon.
  property var browserInfo: ({})
  property bool browserIcons: true
  // Audio attribution: winId -> {node, muted} for sounding windows.
  // Top-left speaker badge + top-right mute/unmute button when present.
  property var audioInfo: ({})
  property bool audioIndicators: true
  // Show the hovered window's identity lines in the reserved info strip
  property bool hoverInfo: true
  // Current panel size preset ("compact"/"regular"/"large") — info line
  // count and tile icon padding scale with it
  property string sizeKey: "regular"
  property real _userScale: 1.0
  property real _iconPad: sizeKey === "large" ? 16 : 8
  property real _faviconCap: sizeKey === "large" ? 32 : 16
  property real _hoverPointSize: sizeKey === "compact" ? 8 : (sizeKey === "large" ? 11 : 9)
  readonly property int _hoverMaxLines: sizeKey === "compact" ? 2 : (sizeKey === "large" ? 4 : 3)
  readonly property real _presetRowH: (sizeKey === "compact" ? 32 : (sizeKey === "large" ? 88 : 56)) * Style.uiScaleRatio
  // Measure the actual NText font, including font/UI scale and line spacing.
  // This reservation never depends on the hovered text or its visibility.
  readonly property real _infoStripH: Math.ceil(infoMeasure.implicitHeight)

  NText {
    id: infoMeasure
    visible: false
    pointSize: root._hoverPointSize
    text: Array(root._hoverMaxLines).fill("Ag").join("\n")
  }

  Behavior on _iconPad {
    NumberAnimation {
      duration: Style.animationNormal
    }
  }
  Behavior on _faviconCap {
    NumberAnimation {
      duration: Style.animationNormal
    }
  }
  Behavior on _hoverPointSize {
    NumberAnimation {
      duration: Style.animationNormal
    }
  }

  // Raster budgets follow the source, never the animated tile geometry.
  function _textureSize(pixels) {
    var px = Math.ceil(pixels * Screen.devicePixelRatio);
    return Qt.size(px, px);
  }

  // Emitted when a tile's mute button is clicked (NOT navigation — the
  // panel stays open regardless of hide-on-click)
  signal muteToggleRequested(int winId)
  // Emitted when a tile's play/pause button is clicked
  signal playToggleRequested(int winId)

  // ── Drag-to-move (DragHandler architecture) ──
  // The DragHandler owns the gesture; it takes the point over from the
  // Flickable, so drags and map-panning can't conflict. There is no
  // separate "armed" state: a drag BEGINS at the 300ms hold — at position
  // 0 (ghost at the press point) — and the handler continues it on move.
  property int _pressWinId: 0  // pressed candidate (also gates the model freeze)
  property real _pressTime: 0  // press timestamp for the pan-vs-drag decision
  property point _pressStart: Qt.point(0, 0)  // press point in mapContent (ghost's position 0)
  property int _dragWinId: 0
  property bool _dragging: false

  // The hold timer STARTS the drag (position 0): ghost appears, source
  // becomes an empty slot, others dim — before any movement
  Timer {
    id: pressHoldTimer
    interval: 300
    repeat: false
    onTriggered: {
      if (root._pressWinId !== 0) {
        root._dragWinId = root._pressWinId;
        root._dragging = true;
      }
    }
  }
  // Phantom strip height — a FULL workspace-row-height box above the first
  // row (the insert-above drop target), per the design
  readonly property real _phantomH: _monH * _autoScale
  readonly property bool dragActive: root._dragging
  readonly property real phantomHeight: root._phantomH
  // The delegate + handler of the active drag (for centroid mapping)
  property var _activeDragDelegate: null
  property var _activeDragHandler: null

  function _cancelDrag() {
    _pressWinId = 0;
    _activeDragDelegate = null;
    _activeDragHandler = null;
    _dragWinId = 0;
    _dragging = false;
    pressHoldTimer.stop();
  }

  // Ghost center in mapContent coordinates: the handler's centroid while
  // the drag is moving, else the press point (position 0)
  readonly property point _ghostPos: {
    if (root._activeDragDelegate && root._activeDragHandler)
      return root._activeDragDelegate.mapToItem(mapContent, root._activeDragHandler.centroid.position.x, root._activeDragHandler.centroid.position.y);
    if (root._dragging)
      return root._pressStart;
    return Qt.point(0, 0);
  }

  // Workspace row under the ghost center. The phantom strip lives ABOVE the
  // content's top edge (ghostPos.y < 0 during a drag), so that's the
  // insert-above target; real rows sit in place beneath it (no shifting).
  readonly property int _dragTargetWs: {
    if (!root._dragging)
      return 0;
    var rowH = _monH * _autoScale;
    var stride = rowH + _rowGap;
    var order = workspaceOrder();
    var y = root._ghostPos.y;
    // The phantom is fixed to the panel, not the scrolled map. Hit-test it
    // in panel coordinates so inserting above first also works while panned.
    var panelY = mapContent.mapToItem(root, root._ghostPos.x, y).y;
    if (panelY < root._phantomH)
      return panelY > -rowH ? -1 : 0;
    if (y < 0 || y >= renderedH)
      return 0;
    var slot = Math.floor(y / stride);
    return (slot >= 0 && slot < order.length) ? order[slot].id : 0;
  }

  function _moveWindowToWorkspace(winId, wsId) {
    var idx = -1;
    for (var i = 0; i < CompositorService.workspaces.count; i++) {
      var ws = CompositorService.workspaces.get(i);
      if (ws.id === wsId) {
        idx = ws.idx;
        break;
      }
    }
    if (idx < 0)
      return;
    moveWindowProcess.command = ["niri", "msg", "action", "move-window-to-workspace", String(idx), "--window-id", String(winId), "--focus", "false"];
    moveWindowProcess.running = true;
  }

  // Emulate "insert workspace above first" (no IPC for it): drop the window
  // on the trailing empty dynamic workspace, then reorder that workspace to
  // index 1 — niri's own reorder shifts everything else down. Two focus-free
  // ops, no window-level cascade (which niri's empty-ws removal breaks).
  function _insertAboveFirst(winId) {
    var trail = 1;
    for (var i = 0; i < CompositorService.workspaces.count; i++) {
      var ws = CompositorService.workspaces.get(i);
      if (ws.idx > trail)
        trail = ws.idx;
    }
    insertProcess.command = ["sh", "-c", "niri msg action move-window-to-workspace " + trail + " --window-id " + winId + " --focus false && " + "niri msg action move-workspace-to-index 1 --reference " + trail];
    insertProcess.running = true;
  }

  Process {
    id: insertProcess
  }

  Process {
    id: moveWindowProcess
  }

  // Emitted only when the user NAVIGATES via the map (tile focus click,
  // workspace-row click, context-menu Focus). Other interactions (context
  // menu open/close, zoom, drag, close-window) deliberately do NOT emit —
  // the hide-on-click setting keys off this signal.
  signal navigationRequested
  readonly property real _monH: screen ? screen.height : 960
  // Workspace under the mouse (0 = none) — drives the hover row band.
  // _hoverCount tracks how many hover areas currently hold the cursor
  // (tile areas and row areas overlap) so exits can't clear the band while
  // another area still holds it — enter/exit ordering between stacked
  // MouseAreas is not guaranteed.
  property int hoveredWs: 0
  // Hovered tile's window id (0 = none) — drives the bottom-row info line
  property int hoveredWinId: 0
  property int _hoverCount: 0

  function hoverEnter(wsId) {
    _hoverCount++;
    hoveredWs = wsId;
  }

  function hoverExit() {
    _hoverCount--;
    if (_hoverCount <= 0) {
      _hoverCount = 0;
      hoveredWs = 0;
    }
  }

  // Delegates may be destroyed while hovered (panel close) — reset
  onVisibleChanged: {
    if (!visible) {
      _hoverCount = 0;
      hoveredWs = 0;
      hoveredWinId = 0;
    } else {
      Qt.callLater(root._keepCurrentInView);
    }
  }

  // Memoized app-name lookup — findAppEntry fuzzy-searches all desktop
  // entries; never run it more than once per appId per session
  property var _appNameCache: ({})

  function _appName(appId) {
    if (!appId)
      return "";
    var cached = root._appNameCache[appId];
    if (cached !== undefined)
      return cached;
    var entry = ThemeIcons.findAppEntry(appId);
    var name = entry ? (entry.name || appId) : appId;
    root._appNameCache[appId] = name;
    return name;
  }

  // Proactively assembled identity lines for EVERY window — recomputed
  // when the window list or bridge data changes (not on hover)
  readonly property var windowInfo: {
    var info = {};
    for (var i = 0; i < _windows.length; i++) {
      var w = _windows[i];
      var appName = root._appName(w.appId || "");
      var term = terminalInfo ? terminalInfo[w.id] : null;
      var brw = browserInfo ? browserInfo[w.id] : null;
      var parts = [];
      if (term && (term.cwdDisp || term.cwd)) {
        parts.push(term.cwdDisp || term.cwd);
        if (term.fg)
          parts.push(term.fg);
      } else if (brw && brw.host) {
        parts.push(brw.host);
        if (w.title)
          parts.push(w.title);
      } else if (w.title) {
        parts.push(w.title);
      }
      if (parts.length === 0 && appName)
        parts.push(appName);
      info[w.id] = parts.slice(0, 3);
    }
    return info;
  }

  // Hover reads the pre-assembled map — O(1), no hover-time work
  readonly property var _hoverInfoLines: hoveredWinId !== 0 ? (windowInfo[hoveredWinId] || []) : []

  // Authoritative "cursor is over the widget" signal — independent of the
  // stacked tile/row MouseAreas (which don't reliably emit every exit, so
  // the counter can stick). blocking: false, so child areas keep working.
  HoverHandler {
    id: mapHover
    onHoveredChanged: {
      if (!hovered) {
        root._hoverCount = 0;
        root.hoveredWs = 0;
      }
    }
  }

  // Bumped on workspace changes so bindings that read the workspace
  // ListModel imperatively re-evaluate (ListModel reads aren't tracked).
  property int _wsRev: 0

  readonly property real _winGap: 1 // between stacked tiles within a column
  readonly property real _colGap: 2 // between columns
  readonly property real _rowGap: 2 // between workspace rows (slot stride = monH + _rowGap)
  readonly property real _barWidth: 4
  readonly property real _leftInset: 12 // 4px bar + 8px gap before the first column

  readonly property var _backend: CompositorService.niriBackend
  // The current window: niri's focused window id (null: none). Window
  // records carry no focus flag; every focus-derived style reads this id.
  readonly property var currentWindowId: _backend ? _backend.focusedWindowId : null
  onCurrentWindowIdChanged: Qt.callLater(root._keepCurrentInView)
  // Pure live view of laid-out windows (never frozen)
  readonly property var _windowsLive: {
    var all = (_backend && _backend.windows) ? _backend.windows : [];
    var out = [];
    for (var i = 0; i < all.length; i++) {
      var lay = all[i].layout;
      if (lay && lay.posInScrollingLayout && lay.posInScrollingLayout.length)
        out.push(all[i]);
    }
    return out;
  }
  // Frozen snapshot while a gesture holds the mouse grab (delegate survival)
  property var _windowsCache: []
  // The map's view: frozen during press/drag, live otherwise. No read+write
  // of the cache inside this binding — that was a binding loop.
  readonly property var _windows: (root._pressWinId !== 0 || root._dragging) ? _windowsCache : _windowsLive
  on_WindowsChanged: Qt.callLater(root._keepCurrentInView)

  // Keep the frozen snapshot current only while idle (no gesture)
  on_WindowsLiveChanged: {
    if (root._pressWinId === 0 && !root._dragging)
      root._windowsCache = _windowsLive;
  }

  Connections {
    target: CompositorService
    function onWorkspaceChanged() {
      root._wsRev++;
    }
  }

  // ── Workspaces ──

  // All workspaces sorted by niri idx, including empty ones
  function workspaceOrder() {
    _wsRev; // imperative-refresh dependency
    var list = [];
    for (var i = 0; i < CompositorService.workspaces.count; i++) {
      var ws = CompositorService.workspaces.get(i);
      list.push({
                  id: ws.id,
                  idx: ws.idx
                });
    }
    // Fallback: workspaces that have windows but aren't in the model
    for (var j = 0; j < _windows.length; j++) {
      var wsId = _windows[j].workspaceId;
      var found = false;
      for (var k = 0; k < list.length; k++) {
        if (list[k].id === wsId) {
          found = true;
          break;
        }
      }
      if (!found)
        list.push({
                    id: wsId,
                    idx: 9999
                  });
    }
    list.sort(function (a, b) {
      return a.idx - b.idx;
    });
    return list;
  }

  // Row index of a workspace within workspaceOrder
  function workspaceSlotIndex(wsId) {
    var order = workspaceOrder();
    for (var i = 0; i < order.length; i++) {
      if (order[i].id === wsId)
        return i;
    }
    return 0;
  }

  // Active window of a workspace (niri's Workspace.active_window_id)
  function activeWindowId(wsId) {
    _wsRev; // imperative-refresh dependency
    for (var i = 0; i < CompositorService.workspaces.count; i++) {
      var ws = CompositorService.workspaces.get(i);
      if (ws.id === wsId)
        return ws.activeWindowId || 0;
    }
    return 0;
  }

  // ── Column geometry (canvas units) ──

  // Per-row max tile heights for one column: {row: height}
  function columnRowHeights(wsId, col) {
    var rowH = {};
    for (var i = 0; i < _windows.length; i++) {
      var w = _windows[i];
      if (w.workspaceId !== wsId)
        continue;
      var lay = w.layout;
      if (lay.posInScrollingLayout[0] !== col)
        continue;
      var r = lay.posInScrollingLayout[1] || 0;
      var th = (lay.tileSize && lay.tileSize[1]) || 0;
      if (rowH[r] === undefined || th > rowH[r])
        rowH[r] = th;
    }
    return rowH;
  }

  // Max tile width among windows of one column
  function columnMaxWidth(wsId, col) {
    var max = 0;
    for (var i = 0; i < _windows.length; i++) {
      var w = _windows[i];
      if (w.workspaceId !== wsId)
        continue;
      var lay = w.layout;
      if (lay.posInScrollingLayout[0] !== col)
        continue;
      var tw = (lay.tileSize && lay.tileSize[0]) || 0;
      if (tw > max)
        max = tw;
    }
    return max;
  }

  // X offset of a column = sum of max widths of all columns left of it
  function columnX(wsId, col) {
    var cols = [];
    for (var i = 0; i < _windows.length; i++) {
      var w = _windows[i];
      if (w.workspaceId !== wsId)
        continue;
      var c = w.layout.posInScrollingLayout[0];
      if (c < col && cols.indexOf(c) === -1)
        cols.push(c);
    }
    var x = 0;
    for (var j = 0; j < cols.length; j++) {
      x += columnMaxWidth(wsId, cols[j]);
    }
    return x;
  }

  // Number of columns left of this one (drives the inter-column gap)
  function colCountLeft(wsId, col) {
    var cols = [];
    for (var i = 0; i < _windows.length; i++) {
      var w = _windows[i];
      if (w.workspaceId !== wsId)
        continue;
      var c = w.layout.posInScrollingLayout[0];
      if (c < col && cols.indexOf(c) === -1)
        cols.push(c);
    }
    return cols.length;
  }

  // Sum of tile heights above this row within its column (canvas units)
  function tileY(wsId, col, row) {
    var rowH = columnRowHeights(wsId, col);
    var y = 0;
    for (var key in rowH) {
      if (Number(key) < row)
        y += rowH[key];
    }
    return y;
  }

  // Number of tiles above this one in its column (drives the intra-column gap)
  function tileCountAbove(wsId, col, row) {
    var rowH = columnRowHeights(wsId, col);
    var n = 0;
    for (var key in rowH) {
      if (Number(key) < row)
        n++;
    }
    return n;
  }

  // Uniform proportional fill: factor that scales a column's tiles so they
  // fill the row's inset extent exactly, with _winGap px between tiles
  function columnScale(wsId, col) {
    var rowH = columnRowHeights(wsId, col);
    var n = 0, sum = 0;
    for (var key in rowH) {
      n++;
      sum += rowH[key];
    }
    if (n === 0 || sum <= 0)
      return 1.0;
    var avail = _monH * _autoScale - (n - 1) * _winGap;
    if (avail <= 0)
      return 0.05;
    return avail / (sum * _autoScale);
  }

  // Tiles and focus reveal share one geometry contract in map coordinates.
  function windowGeometry(w) {
    var col = w.layout.posInScrollingLayout[0];
    var row = w.layout.posInScrollingLayout[1] || 0;
    var cs = columnScale(w.workspaceId, col);
    return Qt.rect(columnX(w.workspaceId, col) * _autoScale + _leftInset + colCountLeft(w.workspaceId, col) * _colGap,
                   workspaceSlotIndex(w.workspaceId) * (_monH * _autoScale + _rowGap) + tileY(w.workspaceId, col, row) * _autoScale * cs + tileCountAbove(w.workspaceId, col, row) * _winGap,
                   Math.max(columnMaxWidth(w.workspaceId, col) * _autoScale, 4),
                   Math.max(((w.layout.tileSize && w.layout.tileSize[1]) || 50) * _autoScale * cs, 2));
  }

  // Position (workspace + column) of the current window — defines the
  // "active column" whose windows get the secondary highlight.
  function focusedWindowPos() {
    var fid = root.currentWindowId;
    if (fid === null || fid === undefined)
      return null;
    for (var i = 0; i < _windows.length; i++) {
      if (_windows[i].id === fid) {
        return {
          ws: _windows[i].workspaceId,
          col: _windows[i].layout.posInScrollingLayout[0]
        };
      }
    }
    return null;
  }

  // ── Canvas extent (raw canvas units; horizontal gaps reserved separately) ──

  readonly property real _canvasW: {
    var max = 0;
    for (var i = 0; i < _windows.length; i++) {
      var w = _windows[i];
      var col = w.layout.posInScrollingLayout[0];
      var right = columnX(w.workspaceId, col) + columnMaxWidth(w.workspaceId, col);
      if (right > max)
        max = right;
    }
    return max > 0 ? max : 100;
  }
  // Niri's trailing empty workspace is an info strip, not a monitor-sized
  // row. It still has its indicator and remains a workspace/drop target.
  readonly property real _canvasH: Math.max(0, workspaceOrder().length - 1) * _monH

  function workspaceRowHeight(slot) {
    return slot === workspaceOrder().length - 1 ? _infoStripH : _monH * _autoScale;
  }

  readonly property real _maxColsInRow: {
    var perWs = {};
    for (var i = 0; i < _windows.length; i++) {
      var w = _windows[i];
      var c = w.layout.posInScrollingLayout[0];
      if (!perWs[w.workspaceId])
        perWs[w.workspaceId] = [];
      if (perWs[w.workspaceId].indexOf(c) === -1)
        perWs[w.workspaceId].push(c);
    }
    var m = 0;
    for (var k in perWs) {
      if (perWs[k].length > m)
        m = perWs[k].length;
    }
    return m;
  }
  readonly property real _gapsW: _leftInset + Math.max(0, _maxColsInRow - 1) * _colGap
  readonly property real _gapsH: Math.max(0, workspaceOrder().length - 1) * _rowGap

  // Panel limits are independent of the animated viewport. First shrink
  // from the preset to fit, then stop at 60% and let the Flickable scroll.
  property real maxPanelW: Math.round((screen?.width || 1920) * 0.5)
  property real maxPanelH: Math.round((screen?.height || 1080) * 0.7)
  readonly property real _panelMargin: 8
  property real _autoScale: {
    var target = _presetRowH / _monH;
    var fitW = (maxPanelW - 2 * _panelMargin - _gapsW) / _canvasW;
    var fitH = _canvasH > 0 ? (maxPanelH - 2 * _panelMargin - _gapsH - _infoStripH) / _canvasH : target;
    return Math.max(target * 0.6, Math.min(target, fitW, fitH));
  }
  Behavior on _autoScale {
    NumberAnimation {
      duration: Style.animationNormal
    }
  }
  on_AutoScaleChanged: Qt.callLater(root._keepCurrentInView)
  on_UserScaleChanged: Qt.callLater(root._keepCurrentInView)
  // What the map actually renders at that scale (before panel margins)
  readonly property real renderedW: _canvasW * _autoScale + _gapsW
  readonly property real renderedH: _canvasH * _autoScale + _gapsH + _infoStripH

  // Reveal only on opening, focus/layout/scale changes and viewport resize,
  // not on a polling timer: manual panning remains under the user's control.
  function _keepCurrentInView() {
    if (!root.visible || root._dragging)
      return;
    for (var i = 0; i < _windows.length; i++) {
      var w = _windows[i];
      if (w.id !== currentWindowId)
        continue;
      var rect = windowGeometry(w);
      var left = mapContent.x + rect.x * _userScale;
      var top = mapContent.y + rect.y * _userScale;
      var right = left + rect.width * _userScale;
      var bottom = top + rect.height * _userScale;
      if (left < flick.contentX)
        flick.contentX = left;
      else if (right > flick.contentX + flick.width)
        flick.contentX = right - flick.width;
      if (top < flick.contentY)
        flick.contentY = top;
      else if (bottom > flick.contentY + flick.height)
        flick.contentY = bottom - flick.height;
      flick.contentX = Math.max(0, Math.min(flick.contentX, flick.contentWidth - flick.width));
      flick.contentY = Math.max(0, Math.min(flick.contentY, flick.contentHeight - flick.height));
      return;
    }
  }

  // Single shared context menu instance
  MapWindowContextMenu {
    id: contextMenu
    // Focus from the menu is navigation too; Close is not
    onNavigationRequested: root.navigationRequested()
  }

  Flickable {
    id: flick
    anchors.fill: parent
    anchors.topMargin: root._dragging ? root._phantomH : 0
    clip: true
    onWidthChanged: Qt.callLater(root._keepCurrentInView)
    onHeightChanged: Qt.callLater(root._keepCurrentInView)
    contentWidth: mapContent.width * root._userScale
    contentHeight: mapContent.height * root._userScale
    interactive: true

    WheelHandler {
      acceptedModifiers: Qt.ControlModifier
      onWheel: function (wheel) {
        var oldScale = root._userScale;
        root._userScale = Math.min(2.0, Math.max(0.1, root._userScale * (1 + wheel.angleDelta.y * 0.001)));
        flick.contentX += wheel.point.position.x * flick.contentWidth * (root._userScale - oldScale) / oldScale;
        flick.contentY += wheel.point.position.y * flick.contentHeight * (root._userScale - oldScale) / oldScale;
      }
    }

    Item {
      id: mapContent
      width: root.renderedW
      height: root.renderedH
      // Center within the Flickable viewport so any residual letterbox
      // distributes equally — EXCEPT during a drag, when the panel grows
      // upward for the phantom strip and the content stays bottom-anchored
      // (so the rows don't jump)
      x: Math.max(0, (flick.width - width * root._userScale) / 2)
      y: root._dragging ? Math.max(0, flick.height - height * root._userScale) : Math.max(0, (flick.height - height * root._userScale) / 2)
      scale: root._userScale
      transformOrigin: Item.TopLeft

      // Workspace row indicator bars: 4px strip at each row's left edge,
      // full slot height. Rows stride monH + _rowGap, so bars keep exactly
      // _rowGap px between them — uniform across all rows.
      // Focused = primary, rest = outline.
      Repeater {
        model: root.workspaceOrder()

        Item {
          // Row band — hover feedback only (no always-on highlight; the
          // current workspace is marked by the indicator bar alone)
          Rectangle {
            visible: modelData.id === root.hoveredWs
            x: 0
            y: index * (root._monH * root._autoScale + root._rowGap)
            width: mapContent.width
            height: root.workspaceRowHeight(index)
            color: AtmoColor.mPrimary
            opacity: 0.07
            z: -1
          }

          // Drop-target outline while a drag hovers this row
          Rectangle {
            visible: root._dragging && modelData.id === root._dragTargetWs
            x: 0
            y: index * (root._monH * root._autoScale + root._rowGap)
            width: mapContent.width
            height: root.workspaceRowHeight(index)
            color: AtmoColor.mPrimary
            opacity: 0.12
            border.color: AtmoColor.mPrimary
            border.width: 2
            z: 5
          }

          // Row indicator bar
          Rectangle {
            x: 0
            y: index * (root._monH * root._autoScale + root._rowGap)
            width: root._barWidth
            height: root.workspaceRowHeight(index)
            color: modelData.id === NiriState.focusedWorkspaceId ? AtmoColor.mPrimary : AtmoColor.mOutline
            z: 10
          }

          // Row area not covered by tiles: hover drives the band, left
          // click switches to that workspace (including empty ones).
          MouseArea {
            x: 0
            y: index * (root._monH * root._autoScale + root._rowGap)
            width: mapContent.width
            height: root.workspaceRowHeight(index)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onEntered: root.hoverEnter(modelData.id)
            onExited: root.hoverExit()
            onClicked: {
              CompositorService.switchToWorkspace(modelData);
              root.navigationRequested();
            }
          }
        }
      }

      Repeater {
        model: root._windows

        Item {
          id: winRect

          readonly property var _lay: modelData.layout
          readonly property bool _current: modelData.id === root.currentWindowId
          readonly property int _col: _lay.posInScrollingLayout[0]
          readonly property int _row: _lay.posInScrollingLayout[1] || 0
          readonly property int _wsSlot: root.workspaceSlotIndex(modelData.workspaceId)
          readonly property rect _geometry: root.windowGeometry(modelData)
          // Active window of this workspace (niri's per-workspace
          // active_window_id) — always shown; it's the "current window of
          // that row" marker, independent of which workspace is focused.
          readonly property bool _activeInWs: modelData.id === root.activeWindowId(modelData.workspaceId)
          readonly property bool _inActiveCol: {
            var fp = root.focusedWindowPos();
            return fp !== null && modelData.workspaceId === fp.ws && _col === fp.col;
          }
          // Secondary tier: active window of a non-focused workspace, or any
          // window in the focused window's column. The focused window itself
          // always keeps the primary tier.
          readonly property bool _secondary: !winRect._current && (_activeInWs || _inActiveCol)

          // Position: row slot top (stride monH + _rowGap) + proportional
          // tile offset within the column
          x: _geometry.x
          y: _geometry.y
          width: _geometry.width
          height: _geometry.height

          // Visual hierarchy: urgent (mError) > focused global (primary,
          // strongest fill) > secondary (active in workspace or in active
          // column) > normal
          readonly property color winColor: modelData.isUrgent ? AtmoColor.mError : (_secondary ? AtmoColor.mSecondary : AtmoColor.mPrimary)
          // Hover is STATE-DRIVEN: hoveredWinId is the single source of
          // truth — tile color, corner-button colors, icon wash and the
          // info line all derive from it, so setting hoveredWinId
          // programmatically renders exactly like a real mouseover
          readonly property bool _hovered: modelData.id === root.hoveredWinId

          // If this tile dies mid-gesture (model churn), abort the drag
          // rather than leaving a stuck ghost/highlight behind
          Component.onDestruction: {
            if (root._pressWinId === modelData.id || root._dragWinId === modelData.id)
              root._cancelDrag();
          }

          // This tile is the one being dragged — render as an empty slot
          // (outline only) so it reads as "will move", not "will copy"
          readonly property bool _dragged: modelData.id === root._dragWinId && root._dragging

          // DRAG AFFORDANCE: while a drag runs (from the 300ms hold), every
          // tile except the source dims to ~55% so the dragged window
          // (empty slot + ghost) is unmistakable
          readonly property real _dragDim: (root._dragging && modelData.id !== root._dragWinId) ? 0.55 : 1.0

          // Total padding subtracted from the icon box: 8px/side on Large
          // tiles, 4px/side otherwise
          readonly property real _iconPad: root._iconPad

          // Contrast glyph color derived from the tile's EFFECTIVE
          // background (tile color at its opacity, blended over the panel
          // surface): bright tile (green hover) -> dark glyph; dark tile
          // (blue focus, dim normal) -> light glyph
          function _lum(c) {
            return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
          }
          readonly property color _tileBg: _hovered ? AtmoColor.mTertiary : winColor
          readonly property real _tileBgOpacity: _hovered ? 1.0 : (winRect._current ? 1.0 : (_secondary ? 0.3 : 0.15))
          readonly property real _bgLum: _tileBgOpacity * _lum(_tileBg) + (1 - _tileBgOpacity) * _lum(AtmoColor.mSurface)
          readonly property color _contrastColor: _bgLum > 0.5 ? AtmoColor.mSurface : AtmoColor.mOnSurface
          // Shared by the tile's corner buttons: 50% mOnTertiary preview
          readonly property color _onTertiaryHalf: Qt.rgba(AtmoColor.mOnTertiary.r, AtmoColor.mOnTertiary.g, AtmoColor.mOnTertiary.b, 0.5)

          // Icon selection: foreground-app icon for terminal tiles when the
          // bridge resolved one (and the setting allows), else the window's
          // own app icon. An unresolvable fg icon falls through to the app
          // icon via AtmoAppIcon's fallbackName — "if available" is automatic.
          readonly property var _term: root.terminalInfo ? root.terminalInfo[modelData.id] : null
          readonly property string _appIcon: ThemeIcons.iconNameForAppId(modelData.appId || "")
          readonly property string _fgIcon: (root.terminalIcons && _term && _term.fg) ? ThemeIcons.iconNameForAppId(_term.fg) : ""
          // Browser favicon (file path from the bridge's cache) wins over
          // app/fg icons when resolved; empty string means "no favicon"
          readonly property var _browser: root.browserInfo ? root.browserInfo[modelData.id] : null
          readonly property string _favicon: (root.browserIcons && _browser && _browser.icon) ? ("file://" + _browser.icon) : ""
          // Native favicon px (0 = unknown); the overlay never renders
          // larger than this — small cached icons stay crisp
          readonly property real _faviconW: (_browser && _browser.iconW) || 32
          // Audio attribution for this tile's window (null = not sounding
          // or not confidently attributed — no badges then)
          readonly property var _audio: root.audioInfo ? root.audioInfo[modelData.id] : null

          // Tile body. Hover replaces the color with tertiary at full
          // opacity, regardless of tier. While dragged it becomes an
          // empty outline slot (the ghost carries the window's identity).
          Rectangle {
            anchors.fill: parent
            color: winRect._dragged ? "transparent" : (winRect._hovered ? AtmoColor.mTertiary : winRect.winColor)
            opacity: winRect._dragDim * (winRect._dragged ? 1.0 : (winRect._hovered ? 1.0 : (winRect._current ? 1.0 : (winRect._secondary ? 0.3 : 0.15))))
            Behavior on opacity {
              NumberAnimation {
                duration: 150
              }
            }
            border.color: winRect._dragged ? AtmoColor.mOutline : (winRect._hovered ? AtmoColor.mTertiary : winRect.winColor)
            border.width: winRect._dragged ? 1 : ((winRect._current || winRect._secondary || winRect._hovered) ? 2 : 1)
          }

          // Base app icon (terminal fg-app or window app), with a rounded
          // chunk CUT OUT of its bottom-right corner while a site favicon
          // badge sits there. The wash shader stays on the inner icon; the
          // cutout mask lives on this wrapper (inverted MultiEffect mask).
          Item {
            id: iconWrap
            anchors.centerIn: parent
            // Square icon filling the tile with a uniform 4px padding on all
            // sides (sized from the tile's smaller dimension)
            width: Math.max(4, Math.min(parent.width, parent.height) - winRect._iconPad)
            height: width
            // Hide icons on tiles too small to read them — evaluated at the
            // rendered size, so zooming in (Ctrl+scroll) reveals icons as
            // they become readable; user setting hides them entirely
            property real _reveal: width * root._userScale >= 14 ? 1 : 0
            Behavior on _reveal {
              NumberAnimation {
                duration: Style.animationFast
              }
            }
            visible: !root.hideIcons && !winRect._dragged && _reveal > 0
            opacity: _reveal * ((winRect._current || winRect._hovered) ? 1.0 : 0.75)

            // Badge rect (tile bottom-right, 2px margin) mapped into this
            // item's coordinate space for the cutout
            readonly property real _badgeX: (winRect.width - favBadge.width - 2) - x
            readonly property real _badgeY: (winRect.height - favBadge.height - 2) - y

            AtmoAppIcon {
              id: baseIcon
              anchors.fill: parent
              name: winRect._fgIcon || winRect._appIcon
              fallbackName: winRect._appIcon
              smooth: true

              layer.enabled: !(winRect._current || winRect._hovered)
              layer.textureSize: root._textureSize(baseIcon.pixelSize)
              layer.smooth: true
              layer.effect: ShaderEffect {
                property color targetColor: AtmoColor.mOnSurface
                // Mask mode (4.0): flat washed-out color, alpha from luminance —
                // dark icon backgrounds vanish, every icon reads as a uniform
                // soft watermark regardless of its original colors
                property real colorizeMode: 4.0
                property real blendStrength: 0.0
                property real hueAdjustment: 0.0
                fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
              }
            }

            // Cutout shape for the mask. Lives in place (MultiEffect needs
            // the item in-scene to capture it); hideSource keeps it off the
            // screen while the layer is active, and the rect's own visible
            // binding keeps it from painting when the layer is disabled
            // (non-browser tiles — an in-tree white rect would show).
            Item {
              id: cutoutMask
              anchors.fill: parent
              Rectangle {
                visible: favBadge.visible
                x: iconWrap._badgeX - 3
                y: iconWrap._badgeY - 3
                width: favBadge.width + 6
                height: favBadge.height + 6
                radius: 4
                color: "white"
              }
            }

            layer.enabled: favBadge.visible
            layer.textureSize: root._textureSize(baseIcon.pixelSize)
            layer.smooth: true
            layer.effect: MultiEffect {
              maskEnabled: true
              maskInverted: true
              maskThresholdMin: 0.5
              maskSpreadAtMin: 1.0
              maskSource: ShaderEffectSource {
                sourceItem: cutoutMask
                hideSource: true
                textureSize: iconWrap.layer.textureSize
              }
            }
          }

          // Site favicon for browser tiles — small badge anchored to the
          // tile's bottom-right corner, in the area cut out of the base
          // icon. Size is the smaller of 60% of the icon box and the
          // favicon's native resolution (clamped via the rendered scale),
          // so cached 32px icons stay crisp on huge tiles.
          Image {
            id: favBadge
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            readonly property real _box: Math.max(4, Math.min(parent.width, parent.height) - winRect._iconPad)
            // Per-mode rendered px cap: 32 on Large, 16 on Compact/Regular
            readonly property real _favCap: root._faviconCap
            // Native-res clamp with the mode cap on top
            width: Math.max(4, Math.min(_box * 0.6, Math.min(_favCap, winRect._faviconW) / root._userScale))
            height: width
            visible: !root.hideIcons && !winRect._dragged && winRect._favicon !== "" && iconWrap.visible
            opacity: iconWrap.opacity
            source: winRect._favicon
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            sourceSize: Qt.size(winRect._faviconW, winRect._faviconW)

            layer.enabled: !(winRect._current || winRect._hovered)
            layer.textureSize: root._textureSize(winRect._faviconW)
            layer.smooth: true
            layer.effect: ShaderEffect {
              property color targetColor: AtmoColor.mOnSurface
              property real colorizeMode: 4.0
              property real blendStrength: 0.0
              property real hueAdjustment: 0.0
              fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
            }
          }

          MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onEntered: {
              root.hoverEnter(modelData.workspaceId);
              root.hoveredWinId = modelData.id;
            }
            onExited: {
              if (root.hoveredWinId === modelData.id)
                root.hoveredWinId = 0;
              root.hoverExit();
            }
            onPressed: mouse => {
              // Record press position/time; start the hold timer that will
              // BEGIN the drag (position 0) at 300ms
              root._cancelDrag();
              if (mouse.button === Qt.LeftButton) {
                root._pressTime = Date.now();
                root._pressWinId = modelData.id;
                root._pressStart = mapToItem(mapContent, mouse.x, mouse.y);
                dragH.enabled = true;
                pressHoldTimer.restart();
              }
            }
            onReleased: {
              root._pressWinId = 0;
              pressHoldTimer.stop();
              // Held long enough to start the drag but never moved → the
              // handler never activated: cancel, no drop, no navigation
              if (root._dragging && !root._activeDragHandler)
                root._cancelDrag();
            }
            onClicked: function (mouse) {
              // A drag that the DragHandler consumed never reaches here —
              // the handler's takeover cancels the MouseArea's press
              if (mouse.button === Qt.LeftButton) {
                CompositorService.focusWindow({
                                                id: modelData.id
                                              });
                root.navigationRequested();
              } else if (mouse.button === Qt.RightButton) {
                contextMenu.windowData = modelData;
                contextMenu.open();
              }
            }
          }

          // The drag itself: ALWAYS enabled so it activates on any
          // press+move (enabling mid-press doesn't work — the handler only
          // arms for presses that START while enabled). Long-press is a
          // DECISION made at activation: grab too early (< 300ms) and we
          // deactivate, handing the gesture back to the Flickable as a map
          // pan; grab at/after 300ms and it's a real tile drag.
          DragHandler {
            id: dragH
            acceptedButtons: Qt.LeftButton
            target: null
            onActiveChanged: {
              if (dragH.active) {
                var heldMs = Date.now() - root._pressTime;
                if (heldMs < 300) {
                  // Too early — this is a map pan, not a tile drag. Hand
                  // the gesture back to the Flickable; next press re-arms.
                  dragH.enabled = false;
                  root._pressWinId = 0;
                  pressHoldTimer.stop();
                  return;
                }
                // Drag already running (started at the hold timer); claim
                // the handler for centroid tracking
                root._activeDragDelegate = winRect;
                root._activeDragHandler = dragH;
                root._pressWinId = 0;
              } else {
                if (root._dragWinId === modelData.id) {
                  // Phantom strip = insert-above-first; a real row = plain
                  // move; no target = cancel
                  if (root._dragTargetWs === -1)
                    root._insertAboveFirst(modelData.id);
                  else if (root._dragTargetWs !== 0 && root._dragTargetWs !== modelData.workspaceId)
                    root._moveWindowToWorkspace(modelData.id, root._dragTargetWs);
                  root._activeDragDelegate = null;
                  root._activeDragHandler = null;
                  root._dragWinId = 0;
                  root._dragging = false;
                }
              }
            }
          }

          // Play/pause button — top-left corner, mirrors the mute button.
          // Only shown when the window has a controllable MPRIS player
          Item {
            id: playButton
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.top: parent.top
            anchors.topMargin: 2
            readonly property real _box: Math.max(4, Math.min(parent.width, parent.height) - winRect._iconPad)
            width: Math.max(5, _box * 0.33)
            height: width
            visible: root.audioIndicators && !winRect._dragged && !!winRect._audio && !!winRect._audio.player && iconWrap.visible
            opacity: iconWrap._reveal

            AtmoIcon {
              anchors.fill: parent
              icon: (winRect._audio && winRect._audio.playing) ? Icon.mediaPause : Icon.mediaPlay
              pointSize: Math.max(5, playButton._box * 0.33)
              applyUiScale: false
              color: playArea.containsMouse ? AtmoColor.mOnTertiary : ((winRect._hovered || winRect._current) ? winRect._onTertiaryHalf : winRect._contrastColor)
              opacity: (winRect._current || winRect._hovered) ? 1.0 : 0.75

              layer.enabled: !(winRect._current || winRect._hovered)
              layer.textureSize: root._textureSize(baseIcon.pixelSize)
              layer.smooth: true
              layer.effect: ShaderEffect {
                property color targetColor: AtmoColor.mOnSurface
                property real colorizeMode: 4.0
                property real blendStrength: 0.0
                property real hueAdjustment: 0.0
                fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
              }
            }

            MouseArea {
              id: playArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton
              onEntered: {
                root.hoverEnter(modelData.workspaceId);
                root.hoveredWinId = modelData.id;
              }
              onExited: {
                if (root.hoveredWinId === modelData.id)
                  root.hoveredWinId = 0;
                root.hoverExit();
              }
              onClicked: root.playToggleRequested(modelData.id)
            }
          }

          // Audio indicator — combined state-icon + mute button at the
          // tile's top-right. Declared AFTER hoverArea so its MouseArea
          // wins clicks in its corner (clicking it must never focus the
          // window or close the panel). Icon shows stream state and flips
          // on mute, so the action is always reversible.
          Item {
            id: audioButton
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.top: parent.top
            anchors.topMargin: 2
            readonly property real _box: Math.max(4, Math.min(parent.width, parent.height) - winRect._iconPad)
            width: Math.max(5, _box * 0.33)
            height: width
            visible: root.audioIndicators && !winRect._dragged && !!winRect._audio && iconWrap.visible
            opacity: iconWrap._reveal

            AtmoIcon {
              anchors.fill: parent
              icon: (winRect._audio && winRect._audio.muted) ? Icon.volumeMute : Icon.volumeHigh
              pointSize: Math.max(5, audioButton._box * 0.33)
              applyUiScale: false
              // Icon hover -> mOnTertiary full; active/hovered tile ->
              // same color at 50% opacity (softer preview of the armed
              // state); otherwise luminance-derived contrast
              color: audioArea.containsMouse ? AtmoColor.mOnTertiary : ((winRect._hovered || winRect._current) ? winRect._onTertiaryHalf : winRect._contrastColor)
              opacity: (winRect._current || winRect._hovered) ? 1.0 : 0.75

              layer.enabled: !(winRect._current || winRect._hovered)
              layer.textureSize: root._textureSize(baseIcon.pixelSize)
              layer.smooth: true
              layer.effect: ShaderEffect {
                property color targetColor: AtmoColor.mOnSurface
                property real colorizeMode: 4.0
                property real blendStrength: 0.0
                property real hueAdjustment: 0.0
                fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
              }
            }

            MouseArea {
              id: audioArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton
              // Feed the workspace hover-band counter just like the tile's
              // own area, so crossing tile<->button doesn't flicker the band
              onEntered: {
                root.hoverEnter(modelData.workspaceId);
                root.hoveredWinId = modelData.id;
              }
              onExited: {
                if (root.hoveredWinId === modelData.id)
                  root.hoveredWinId = 0;
                root.hoverExit();
              }
              onClicked: root.muteToggleRequested(modelData.id)
            }
          }
        }
      }

      // Drag ghost: follows the cursor while a window is being dragged to
      // another workspace. Semi-transparent chip with the window's icon.
      Item {
        id: dragGhost
        // Escape the scrolling viewport's clip so the ghost can enter the
        // phantom row without exposing any of the offscreen map content.
        parent: root
        visible: root._dragging
        readonly property var _win: {
          for (var i = 0; i < root._windows.length; i++) {
            if (root._windows[i].id === root._dragWinId)
              return root._windows[i];
          }
          return null;
        }
        width: Math.max(32, 240 * root._autoScale)
        height: width * 0.7
        readonly property point _position: mapContent.mapToItem(root, root._ghostPos.x, root._ghostPos.y)
        x: _position.x - width * scale / 2
        y: _position.y - height * scale / 2
        scale: root._userScale
        transformOrigin: Item.TopLeft
        z: 101

        Rectangle {
          anchors.fill: parent
          radius: 6
          color: AtmoColor.mSurface
          border.color: AtmoColor.mPrimary
          border.width: 2
          opacity: 0.92
        }
        AtmoAppIcon {
          anchors.centerIn: parent
          width: Math.max(12, parent.height - 12)
          height: width
          name: dragGhost._win ? ThemeIcons.iconNameForAppId(dragGhost._win.appId || "") : "application-x-executable"
        }
      }

      // The trailing workspace reserves the maximum text height even when
      // nothing is hovered. Anchor the text inside that strip structurally.
      Item {
        y: Math.max(0, root.workspaceOrder().length - 1) * (root._monH * root._autoScale + root._rowGap)
        width: mapContent.width
        height: root._infoStripH
        NText {
          readonly property var _lines: root._hoverInfoLines
          visible: root.hoverInfo && _lines.length > 0
          text: _lines.join("\n")
          color: AtmoColor.mOnSurfaceVariant
          // Fixed per size preset (independent of the map scale)
          pointSize: root._hoverPointSize
          width: mapContent.width - 16
          maximumLineCount: root._hoverMaxLines
          wrapMode: Text.WordWrap
          elide: Text.ElideRight
          horizontalAlignment: Text.AlignHCenter
          anchors.centerIn: parent
          z: 90
        }
      }
    }
  }

  // Phantom "insert above first workspace" strip — rendered at the TOP of
  // the panel's content area, above the map. During a drag the panel grows
  // upward by _phantomH (Panel.qml) and the map content bottom-anchors, so
  // the strip appears above the rows without moving them.
  Item {
    id: phantomRow
    visible: root._dragging
    x: 0
    y: 0
    width: root.width
    height: root._phantomH
    z: 100

    // Soft band — clearly visible, brighter when it's the drop target
    Rectangle {
      anchors.fill: parent
      color: AtmoColor.mPrimary
      opacity: root._dragTargetWs === -1 ? 0.32 : 0.16
      Behavior on opacity {
        NumberAnimation {
          duration: 120
        }
      }
    }
    // Bright line at the very top edge
    Rectangle {
      x: 0
      y: 0
      width: parent.width
      height: 2
      color: AtmoColor.mPrimary
      opacity: root._dragTargetWs === -1 ? 1.0 : 0.6
    }
    // Left indicator bar (same as real rows)
    Rectangle {
      x: 0
      y: 0
      width: root._barWidth
      height: parent.height
      color: AtmoColor.mPrimary
      opacity: root._dragTargetWs === -1 ? 1.0 : 0.6
    }
  }

  NText {
    visible: root._windows.length === 0
    anchors.centerIn: parent
    text: "No windows"
    color: AtmoColor.mOnSurfaceVariant
  }
}
