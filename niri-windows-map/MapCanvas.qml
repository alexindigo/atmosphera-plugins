import QtQuick
import "MapGeometry.js" as MapGeometry
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Widgets

// Spatial niri overview map, rendering the adapter's facade state.
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
  required property MapFacade mapFacade
  property bool audioIndicators: true
  // Show the hovered window's identity lines in the reserved info strip
  property bool hoverInfo: true
  // Current preset controls row height, spacing and hover typography.
  property string sizeKey: "regular"
  property real _userScale: 1.0
  property real _faviconCap: sizeKey === "large" ? 32 : 16
  property real _hoverPointSize: sizeKey === "compact" ? 8 : (sizeKey === "large" ? 11 : 9)
  readonly property int _hoverMaxLines: 2
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
  signal muteToggleRequested(string winId)
  // Emitted when a tile's play/pause button is clicked
  signal playToggleRequested(string winId)

  // ── Drag-to-move (DragHandler architecture) ──
  // The DragHandler owns the gesture; it takes the point over from the
  // Flickable, so drags and map-panning can't conflict. There is no
  // separate "armed" state: a drag BEGINS at the 300ms hold — at position
  // 0 (ghost at the press point) — and the handler continues it on move.
  property var _pressWinId: null  // pressed candidate (also gates the model freeze)
  property real _pressTime: 0  // press timestamp for the pan-vs-drag decision
  property point _pressStart: Qt.point(0, 0)  // press point in scene coordinates
  property var _dragWinId: null
  property bool _dragging: false
  on_DraggingChanged: {
    if (!root._dragging)
      Qt.callLater(root._keepCurrentInView);
  }

  // The hold timer STARTS the drag (position 0): ghost appears, source
  // becomes an empty slot, others dim — before any movement
  Timer {
    id: pressHoldTimer
    interval: 300
    repeat: false
    onTriggered: {
      if (root._pressWinId !== null) {
        flick.cancelFlick();
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
  property var _activeDragHandler: null
  property var _rowAtPress: null

  Connections {
    target: root.mapFacade
    function onMapStateChanged() {
      if (!root.mapFacade.mapState.ready)
        root._rowAtPress = null;
    }
  }

  function _cancelDrag() {
    _pressWinId = null;
    _activeDragHandler = null;
    _dragWinId = null;
    _dragging = false;
    _rowAtPress = null;
    pressHoldTimer.stop();
  }

  // The ghost and drop preview read one pointer, independent of content motion.
  property int _dragFrame: 0
  readonly property point _dragPointer: {
    if (!_dragging)
      return Qt.point(0, 0);
    // The panel can translate as it grows for the phantom strip. Qt's scene
    // mapping isn't reactive to that transform, so refresh it each drag frame.
    _dragFrame;
    return root.mapFromItem(null, _activeDragHandler ? _activeDragHandler.centroid.scenePosition : _pressStart);
  }
  readonly property rect _viewport: Qt.rect(flick.x, flick.y, flick.width, flick.height)
  readonly property rect _insertStrip: Qt.rect(phantomRow.x, phantomRow.y, phantomRow.width, phantomRow.height)

  // Explicit content offsets and scale re-evaluate the target even when the
  // pointer does not move. The ghost stays under the pointer while rows move.
  readonly property point _mapOriginInRoot: Qt.point(flick.x + mapContent.x - flick.contentX,
                                                    flick.y + mapContent.y - flick.contentY)
  readonly property var _workspaceRows: workspaceOrder().map(function (ws, index) {
    return {id: ws.id, y: root.workspaceRowY(index), height: root.workspaceRowHeight(index), trailing: index === root._workspaceOrder.length - 1};
  })
  readonly property var _sameRowDrag: {
    if (!_dragging || !mapFacade.matchesRow(_dragWinId, _rowAtPress))
      return null;
    return {windowId: _dragWinId, workspaceId: _rowAtPress.workspaceId, leftEdge: _barWidth, gutter: 2 * _colGap,
      columns: _rowAtPress.columns.map(column => column.map(w => ({id: w.id, rect: root.windowGeometry(w)})))};
  }

  function _targetAt(point) {
    return MapGeometry.targetAt(point, _viewport, _insertStrip, _mapOriginInRoot, _userScale, _workspaceRows, renderedW, _sameRowDrag);
  }

  readonly property var _dragTarget: _dragging ? _targetAt(_dragPointer) : null
  readonly property var _dropMove: mapFacade.resolveDrop(_dragWinId, _dragTarget)

  Timer {
    interval: 16
    repeat: true
    running: root._dragging
    onTriggered: {
      root._dragFrame++;
      if (!root._activeDragHandler)
        return;
      const bounds = Qt.rect(flick.originX, flick.originY,
                             Math.max(0, flick.contentWidth - flick.width),
                             Math.max(0, flick.contentHeight - flick.height));
      const next = MapGeometry.dragScroll(root._dragPointer, root._viewport, bounds,
                                         Qt.point(flick.contentX, flick.contentY), interval);
      if (next.x !== flick.contentX)
        flick.contentX = next.x;
      if (next.y !== flick.contentY)
        flick.contentY = next.y;
    }
  }

  // Emitted only when the user NAVIGATES via the map (tile focus click,
  // workspace-row click, context-menu Focus). Other interactions (context
  // menu open/close, zoom, drag, close-window) deliberately do NOT emit —
  // the hide-on-click setting keys off this signal.
  signal navigationRequested
  readonly property real _monH: screen ? screen.height : 960
  // Workspace under the mouse (null = none) drives the hover row band.
  // _hoverCount tracks how many hover areas currently hold the cursor
  // (tile areas and row areas overlap) so exits can't clear the band while
  // another area still holds it — enter/exit ordering between stacked
  // MouseAreas is not guaranteed.
  property var hoveredWs: null
  // Hovered tile's window id (null = none) drives the bottom-row info line.
  property var hoveredWinId: null
  property int _hoverCount: 0

  function hoverEnter(wsId) {
    _hoverCount++;
    hoveredWs = wsId;
  }

  function hoverExit() {
    _hoverCount--;
    if (_hoverCount <= 0) {
      _hoverCount = 0;
      hoveredWs = null;
    }
  }

  // Delegates may be destroyed while hovered (panel close) — reset
  onVisibleChanged: {
    if (!visible) {
      _hoverCount = 0;
      hoveredWs = null;
      hoveredWinId = null;
      _cancelDrag();
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
        parts.push({text: term.cwdDisp || term.cwd, elide: Text.ElideMiddle});
        if (term.fg)
          parts.push({text: term.fg, elide: Text.ElideRight});
      } else if (brw && brw.host) {
        parts.push({text: brw.host, elide: Text.ElideMiddle});
        if (w.title)
          parts.push({text: w.title, elide: Text.ElideRight});
      } else if (w.title) {
        parts.push({text: w.title, elide: Text.ElideRight});
      }
      if (parts.length === 0 && appName)
        parts.push({text: appName, elide: Text.ElideRight});
      info[w.id] = parts.slice(0, _hoverMaxLines);
    }
    return info;
  }

  // Hover reads the pre-assembled map — O(1), no hover-time work
  readonly property var _hoverInfoLines: hoveredWinId !== null ? (windowInfo[hoveredWinId] || []) : []

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

  readonly property real _winGap: Math.max(1, Math.round(_presetRowH / 32)) // stacked tiles
  readonly property real _colGap: Math.max(2, Math.round(_presetRowH / 16)) // columns
  readonly property real _rowGap: _colGap // workspace rows
  readonly property real _barWidth: 4
  readonly property real _leftInset: 12 // 4px bar + 8px gap before the first column

  // The current window: niri's focused window id (null: none). Window
  // records carry no focus flag; every focus-derived style reads this id.
  readonly property var currentWindowId: mapFacade.mapState.focusedWindowId
  onCurrentWindowIdChanged: Qt.callLater(root._keepCurrentInView)
  // Pure live view of laid-out windows (never frozen)
  readonly property var _windowsLive: {
    const rows = new Set(mapFacade.mapState.workspaces.map(ws => ws.id));
    return mapFacade.mapState.windows.filter(w => rows.has(w.workspaceId) && w.layout?.posInScrollingLayout?.length > 0);
  }
  // Frozen snapshot while a gesture holds the mouse grab (delegate survival)
  property var _windowsCache: []
  // The map's view: frozen during press/drag, live otherwise. No read+write
  // of the cache inside this binding — that was a binding loop.
  readonly property var _windows: (root._pressWinId !== null || root._dragging) ? _windowsCache : _windowsLive
  readonly property rect _focusedRectangle: {
    for (var i = 0; i < _windows.length; i++) {
      if (_windows[i].id === currentWindowId)
        return windowGeometry(_windows[i]);
    }
    return Qt.rect(0, 0, 0, 0);
  }
  on_FocusedRectangleChanged: Qt.callLater(root._keepCurrentInView)

  // ── Workspaces ──

  // All workspaces sorted by niri idx, including empty ones
  readonly property var _workspaceOrder: mapFacade.mapState.workspaces
  function workspaceOrder() {
    return _workspaceOrder;
  }

  // Row index of a workspace within workspaceOrder
  function workspaceSlotIndex(wsId) {
    var order = workspaceOrder();
    for (var i = 0; i < order.length; i++) {
      if (order[i].id === wsId)
        return i;
    }
    return -1;
  }

  // Active window of a workspace (niri's Workspace.active_window_id)
  function activeWindowId(wsId) {
    return _workspaceOrder.find(ws => ws.id === wsId)?.activeWindowId ?? null;
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
                   workspaceRowY(workspaceSlotIndex(w.workspaceId)) + tileY(w.workspaceId, col, row) * _autoScale * cs + tileCountAbove(w.workspaceId, col, row) * _winGap,
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
  readonly property real _trailingLandingSpace: _dragging ? MapGeometry.trailingLandingSpace(flick.height / _userScale, _monH * _autoScale, _rowGap, Math.max(0, _workspaceOrder.length - 1), _infoStripH) : 0

  function workspaceRowY(slot) {
    return slot * (_monH * _autoScale + _rowGap) + (slot === _workspaceOrder.length - 1 ? _trailingLandingSpace : 0);
  }

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
      flick.contentX = MapGeometry.revealOffset(left, right - left, flick.width, flick.contentX, flick.contentWidth);
      flick.contentY = MapGeometry.revealOffset(top, bottom - top, flick.height, flick.contentY, flick.contentHeight);
      return;
    }
  }

  // Single shared context menu instance
  MapWindowContextMenu {
    id: contextMenu
    onFocusRequested: id => {
      if (root.mapFacade.focusWindow(id))
        root.navigationRequested();
    }
    onCloseRequested: id => root.mapFacade.closeWindow(id)
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
    // Before the hold threshold this is a pan. Once the tile owns the drag,
    // only the edge-scroll timer drives the viewport; Flickable must not steal it.
    interactive: !root._dragging

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
      // Allow edge scrolling to expose the after-last-column gap even when
      // the last column fills the panel. The panel's resting size is unchanged.
      width: root.renderedW + (root._sameRowDrag?.gutter ?? 0)
      height: root.renderedH + root._trailingLandingSpace
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
            y: root.workspaceRowY(index)
            width: root.renderedW
            height: root.workspaceRowHeight(index)
            color: AtmoColor.mPrimary
            opacity: 0.07
            z: -1
          }

          // Drop-target outline while a drag hovers this row
          Rectangle {
            visible: root._dropMove?.insertAtIndex === null && modelData.id === root._dropMove?.workspace.id
            x: 0
            y: root.workspaceRowY(index)
            width: root.renderedW
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
            y: root.workspaceRowY(index)
            width: root._barWidth
            height: root.workspaceRowHeight(index)
            color: modelData.id === root.mapFacade.mapState.focusedWorkspaceId ? AtmoColor.mPrimary : AtmoColor.mOutline
            z: 10
          }

          // Row area not covered by tiles: hover drives the band, left
          // click switches to that workspace (including empty ones).
          MouseArea {
            x: 0
            y: root.workspaceRowY(index)
            width: root.renderedW
            height: root.workspaceRowHeight(index)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onEntered: root.hoverEnter(modelData.id)
            onExited: root.hoverExit()
            onClicked: {
              if (root.mapFacade.switchWorkspace(modelData.id))
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
          visible: _wsSlot >= 0 || _dragged
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

          // One proportional box drives the app icon and its overlays.
          readonly property real _iconSize: Math.min(width, height) * 0.6

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
            // Centered, uniform space on every side of the smaller tile axis.
            width: winRect._iconSize
            height: width
            // Hide icons on tiles too small to read them — evaluated at the
            // rendered size, so zooming in (Ctrl+scroll) reveals icons as
            // they become readable; user setting hides them entirely
            readonly property bool _inputReady: width * root._userScale >= 14
            property real _reveal: _inputReady ? 1 : 0
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
          MapFavicon {
            id: favBadge
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            readonly property real _box: winRect._iconSize
            // Per-mode rendered px cap: 32 on Large, 16 on Compact/Regular
            readonly property real _favCap: root._faviconCap
            // Native-res clamp with the mode cap on top
            width: Math.max(4, Math.min(_box * 0.6, Math.min(_favCap, winRect._faviconW) / root._userScale))
            height: width
            visible: !root.hideIcons && !winRect._dragged && winRect._favicon !== "" && iconWrap.visible
            opacity: iconWrap.opacity
            useSharedDecoder: root.mapFacade.currentShell
            iconSource: winRect._favicon
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
                root.hoveredWinId = null;
              root.hoverExit();
            }
            onPressed: mouse => {
              // Record press position/time; start the hold timer that will
              // BEGIN the drag (position 0) at 300ms
              root._cancelDrag();
              if (mouse.button === Qt.LeftButton) {
                root._pressTime = Date.now();
                root._windowsCache = root._windowsLive;
                root._rowAtPress = root.mapFacade.tiledRow(modelData.id);
                root._pressWinId = modelData.id;
                root._pressStart = hoverArea.mapToItem(null, mouse.x, mouse.y);
                dragH.enabled = true;
                pressHoldTimer.restart();
              }
            }
            onReleased: {
              root._pressWinId = null;
              pressHoldTimer.stop();
              // Held long enough to start the drag but never moved → the
              // handler never activated: cancel, no drop, no navigation
              if (root._dragging && !root._activeDragHandler)
                root._cancelDrag();
            }
            onCanceled: {
              // A DragHandler takeover also cancels MouseArea. Give the grab
              // transition a chance to adopt this press before clearing it.
              const pressTime = root._pressTime;
              const windowId = modelData.id;
              Qt.callLater(() => {
                if (root._pressTime === pressTime && root._pressWinId === windowId && !root._activeDragHandler)
                  root._cancelDrag();
              });
            }
            onClicked: function (mouse) {
              // A drag that the DragHandler consumed never reaches here —
              // the handler's takeover cancels the MouseArea's press
              if (mouse.button === Qt.LeftButton && Date.now() - root._pressTime < pressHoldTimer.interval) {
                if (root.mapFacade.focusWindow(modelData.id))
                  root.navigationRequested();
              } else if (mouse.button === Qt.RightButton) {
                contextMenu.windowId = modelData.id;
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
                if (root._pressWinId !== modelData.id || Date.now() - root._pressTime < pressHoldTimer.interval) {
                  // Too early — this is a map pan, not a tile drag. Hand
                  // the gesture back to the Flickable; next press re-arms.
                  dragH.enabled = false;
                  root._pressWinId = null;
                  pressHoldTimer.stop();
                  return;
                }
                // Adopt the press even if the movement arrived in the same
                // frame as the hold timeout, before the timer fired.
                pressHoldTimer.stop();
                flick.cancelFlick();
                root._dragWinId = modelData.id;
                root._activeDragHandler = dragH;
                root._dragging = true;
                root._pressWinId = null;
              }
            }
            onGrabChanged: (transition, point) => {
              if (root._activeDragHandler !== dragH)
                return;
              if (transition === PointerDevice.UngrabExclusive) {
                // The release event owns the final position; the centroid
                // can already have been reset by the time this signal fires.
                if (point.state === EventPoint.Released)
                  root.mapFacade.drop(root._dragWinId, root._targetAt(root.mapFromItem(null, point.scenePosition)), root._rowAtPress);
                root._cancelDrag();
              } else if (transition === PointerDevice.CancelGrabExclusive) {
                root._cancelDrag();
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
            readonly property real _box: winRect._iconSize
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
              enabled: iconWrap._inputReady
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
                  root.hoveredWinId = null;
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
            readonly property real _box: winRect._iconSize
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
              enabled: iconWrap._inputReady
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
                  root.hoveredWinId = null;
                root.hoverExit();
              }
              onClicked: root.muteToggleRequested(modelData.id)
            }
          }
        }
      }

      // This workspace reserves the info height and remains a scrolled drop
      // target. Its text is presented separately in the visible viewport.
      Item {
        id: trailingStrip
        y: root.workspaceRowY(Math.max(0, root._workspaceOrder.length - 1))
        width: mapContent.width
        height: root._infoStripH
      }
    }
  }

  // The ghost can enter the phantom. The placement marker draws above it
  // but remains clipped to the map viewport.
  Item {
    anchors.fill: parent
    visible: root._dragging
    z: 101

    Item {
      id: dragGhost

      readonly property var _win: {
        for (var i = 0; i < root._windows.length; i++) {
          if (root._windows[i].id === root._dragWinId)
            return root._windows[i];
        }
        return null;
      }
      width: Math.max(32, 240 * root._autoScale)
      height: width * 0.7
      readonly property point _position: root._dragPointer
      x: _position.x - width * scale / 2
      y: _position.y - height * scale / 2
      scale: root._userScale
      transformOrigin: Item.TopLeft

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

    Item {
      id: placementViewport

      x: root._viewport.x
      y: root._viewport.y
      width: root._viewport.width
      height: root._viewport.height
      clip: true
      visible: !!root._dragTarget?.seam
      readonly property rect seam: {
        root._mapOriginInRoot;
        mapContent.scale;
        const targetSeam = root._dragTarget?.seam;
        return targetSeam ? mapContent.mapToItem(placementViewport, targetSeam) : Qt.rect(0, 0, 0, 0);
      }

      Item {
        id: seamBox

        x: placementViewport.seam.x
        y: placementViewport.seam.y
        width: placementViewport.seam.width
        height: placementViewport.seam.height

        Rectangle {
          anchors.centerIn: parent
          anchors.alignWhenCentered: false
          width: seamBox.width || Style.borderM
          height: seamBox.height || Style.borderM
          color: AtmoColor.mPrimary
        }
      }
    }
  }

  // Viewport-owned presentation: horizontal scrolling cannot move the text
  // or enlarge its elision budget. Map the actual strip bounds vertically,
  // so vertical scrolling, drag growth and zoom still follow the workspace.
  Item {
    id: hoverViewport
    parent: flick
    anchors.left: parent.left
    anchors.right: parent.right
    readonly property rect _stripBounds: {
      flick.contentY;
      mapContent.y;
      mapContent.scale;
      trailingStrip.y;
      return trailingStrip.mapToItem(flick, Qt.rect(0, 0, trailingStrip.width, trailingStrip.height));
    }
    y: _stripBounds.y
    height: _stripBounds.height
    z: 90

    Column {
      id: hoverLines
      visible: root.hoverInfo && root._hoverInfoLines.length > 0
      scale: root._userScale
      // Convert the visible width to local units without zooming its margin.
      width: Math.max(0, (hoverViewport.width - 16) / scale)
      anchors.centerIn: parent
      Repeater {
        model: root._hoverInfoLines.slice(0, root._hoverMaxLines)
        NText {
          required property var modelData
          text: modelData.text
          color: AtmoColor.mOnSurfaceVariant
          pointSize: root._hoverPointSize
          width: hoverLines.width
          maximumLineCount: 1
          wrapMode: Text.NoWrap
          elide: modelData.elide
          horizontalAlignment: Text.AlignHCenter
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
      opacity: root._dropMove?.insertAtIndex === 1 ? 0.32 : 0.16
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
      opacity: root._dropMove?.insertAtIndex === 1 ? 1.0 : 0.6
    }
    // Left indicator bar (same as real rows)
    Rectangle {
      x: 0
      y: 0
      width: root._barWidth
      height: parent.height
      color: AtmoColor.mPrimary
      opacity: root._dropMove?.insertAtIndex === 1 ? 1.0 : 0.6
    }
  }

  NText {
    visible: root.mapFacade.mapState.ready && root._windows.length === 0
    anchors.centerIn: parent
    text: "No windows"
    color: AtmoColor.mOnSurfaceVariant
  }
}
