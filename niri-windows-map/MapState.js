.pragma library

function exactId(value) {
  if (typeof value === "string")
    return /^(0|[1-9][0-9]*)$/.test(value) ? value : null;
  return Number.isSafeInteger(value) && value >= 0 ? String(value) : null;
}

function normalize(state) {
  if (!state?.ready)
    return {ready: false, windows: [], workspaces: [], focusedWindowId: null, focusedWorkspaceId: null};
  const windows = [];
  for (const raw of state.windows) {
    const id = exactId(raw.id);
    if (id !== null)
      windows.push(Object.assign({}, raw, {id, workspaceId: exactId(raw.workspaceId), pid: exactId(raw.pid)}));
  }
  const occupied = new Set(windows.map(w => w.workspaceId));
  const workspaces = [];
  for (const raw of state.workspaces) {
    const id = exactId(raw.id);
    const activeWindowId = exactId(raw.activeWindowId);
    if (id !== null)
      workspaces.push(Object.assign({}, raw, {id, activeWindowId, isOccupied: !!raw.isOccupied || activeWindowId !== null || occupied.has(id)}));
  }
  workspaces.sort((a, b) => a.idx - b.idx);
  return {ready: true, windows, workspaces, focusedWindowId: exactId(state.focusedWindowId), focusedWorkspaceId: exactId(state.focusedWorkspaceId)};
}

function drop(state, id, target) {
  if (!state.ready || !target || !["row", "trailing", "insert"].includes(target.kind))
    return null;
  const source = state.windows.find(w => w.id === id);
  const byRow = target.kind === "row";
  const ws = byRow ? state.workspaces.find(w => w.id === target.id) : state.workspaces[state.workspaces.length - 1];
  if (!source || !ws || ws.id === source.workspaceId || (!byRow && ws.isOccupied))
    return null;
  return {windowId: source.id, workspace: ws, insertAtIndex: target.kind === "insert" ? 1 : null};
}
