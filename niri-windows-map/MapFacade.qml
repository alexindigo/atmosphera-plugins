import QtQuick
import Quickshell.Io
import qs.Services.Compositor
import "MapState.js" as MapState

Item {
  id: root
  property var facade: CompositorService
  readonly property bool currentShell: facade.snapshot !== undefined && typeof facade.moveWindowToWorkspace === "function"
  property int _legacyRevision: 0
  readonly property var mapState: MapState.normalize(currentShell ? facade.snapshot : legacyState(_legacyRevision))

  Connections {
    target: root.currentShell ? null : root.facade
    function onWorkspaceChanged() { root._legacyRevision++; }
    function onWindowListChanged() { root._legacyRevision++; }
    function onActiveWindowChanged() { root._legacyRevision++; }
  }

  function legacyState(_revision) {
    const backend = facade.niriBackend;
    const rows = facade.workspaces;
    // Old facade ListModel cannot round-trip nested layout arrays. The
    // legacy niriBackend surface exposes the original plain window records.
    const windows = backend?.windows ?? [];
    const workspaces = Array.from({length: rows.count}, (_, i) => {
      const w = rows.get(i);
      // The old backend used numeric zero for an absent active window.
      const activeWindowId = w.activeWindowId === 0 && !windows.some(win => win.id === 0 && win.workspaceId === w.id) ? null : w.activeWindowId;
      return {id: w.id, idx: w.idx, output: w.output, isFocused: w.isFocused, isOccupied: w.isOccupied, activeWindowId};
    });
    return {ready: !!backend, windows, workspaces,
      focusedWindowId: facade.focusedWindowId, focusedWorkspaceId: workspaces.find(w => w.isFocused)?.id ?? null};
  }

  // Preserve the original type for typed legacy calls. Never reconstruct
  // a number from an ID string; the value may be wider than a JS integer.
  function windowArgument(id) {
    if (id === null || !mapState.windows.some(w => w.id === id))
      return null;
    if (currentShell)
      return {id};
    const raw = facade.niriBackend?.windows.find(w => MapState.exactId(w.id) === id);
    return raw ? {id: raw.id} : null;
  }

  function focusWindow(id): bool {
    const window = windowArgument(id);
    if (window)
      facade.focusWindow(window);
    return window !== null;
  }

  function closeWindow(id) {
    const window = windowArgument(id);
    if (window)
      facade.closeWindow(window);
  }

  function switchWorkspace(id): bool {
    const ws = mapState.workspaces.find(w => w.id === id);
    if (ws)
      facade.switchToWorkspace(ws);
    return !!ws;
  }

  function resolveDrop(id, target) {
    return MapState.drop(mapState, id, target);
  }

  function drop(id, target) {
    const move = resolveDrop(id, target);
    if (!move)
      return;
    if (currentShell)
      facade.moveWindowToWorkspace(move.windowId, move.workspace.id, null, move.insertAtIndex);
    else if (!legacyMove.running && !legacyReorder.running) {
      legacyMove.reorderIndex = move.insertAtIndex;
      legacyMove.reference = String(move.workspace.idx);
      legacyMove.command = ["niri", "msg", "action", "move-window-to-workspace", legacyMove.reference, "--window-id", move.windowId, "--focus", "false"];
      legacyMove.running = true;
    }
  }

  Process {
    id: legacyMove
    property var reorderIndex: null
    property string reference: ""
    onExited: (code, status) => {
      if (code === 0 && status === 0 && reorderIndex !== null) {
        legacyReorder.command = ["niri", "msg", "action", "move-workspace-to-index", String(reorderIndex), "--reference", reference];
        legacyReorder.running = true;
      }
    }
  }
  Process { id: legacyReorder }
}
