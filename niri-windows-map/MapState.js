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

// Freeze the actual column/tile order rather than trusting window-list order.
// Focus/title changes do not invalidate a placement; tiled membership does.
function tiledRow(state, id) {
  if (!state.ready)
    return null;
  const source = state.windows.find(w => w.id === id && w.layout?.posInScrollingLayout?.length === 2);
  const workspace = source && state.workspaces.find(w => w.id === source.workspaceId);
  if (!workspace)
    return null;
  const position = w => w.layout.posInScrollingLayout;
  const windows = state.windows.filter(w => w.workspaceId === workspace.id && w.layout?.posInScrollingLayout?.length === 2);
  windows.sort((a, b) => position(a)[0] - position(b)[0] || position(a)[1] - position(b)[1]);
  const columns = [];
  for (const window of windows) {
    const last = columns[columns.length - 1];
    if (last && position(last[0])[0] === position(window)[0])
      last.push(window);
    else
      columns.push([window]);
  }
  return {workspaceId: workspace.id, columns, key: JSON.stringify([workspace.idx, workspace.output,
    windows.map(w => [w.id, position(w)[0], position(w)[1]])])};
}

function sameRow(a, b) {
  return !!a && !!b && a.workspaceId === b.workspaceId && a.key === b.key;
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
