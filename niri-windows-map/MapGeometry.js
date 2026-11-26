// Visible row geometry owns both painting and drop acceptance. Points and
// rectangles at this boundary are in the canvas root's coordinates.
function contains(rect, point) {
  return point.x >= rect.x && point.y >= rect.y
      && point.x < rect.x + rect.width && point.y < rect.y + rect.height;
}

function targetAt(point, viewport, phantom, origin, scale, rows, mapWidth, rowDrag) {
  if (contains(phantom, point))
    return {kind: "insert"};
  if (!contains(viewport, point) || scale <= 0)
    return null;
  var local = {x: (point.x - origin.x) / scale, y: (point.y - origin.y) / scale};
  if (local.x < 0)
    return null;
  for (var i = 0; i < rows.length; i++) {
    const row = rows[i];
    if (local.y < row.y || local.y >= row.y + row.height)
      continue;
    if (!row.trailing && rowDrag?.workspaceId === row.id && local.x < mapWidth + rowDrag.gutter)
      return rowPlacement(local, row, rowDrag);
    if (local.x < mapWidth)
      return row.trailing ? {kind: "trailing"} : {kind: "row", id: row.id};
    break;
  }
  return null;
}

function midpoint(a, b) {
  return (a + b) / 2;
}

function rowPlacement(point, row, drag) {
  const columns = drag.columns;
  const sourceColumn = columns.findIndex(column => column.some(tile => tile.id === drag.windowId));
  if (sourceColumn < 0 || point.x < drag.leftEdge || contains(columns[sourceColumn].find(tile => tile.id === drag.windowId).rect, point))
    return null;

  let left = drag.leftEdge;
  for (let i = 0; i <= columns.length; i++) {
    const column = columns[i];
    const right = column ? column[0].rect.x : left + drag.gutter;
    if (!column || point.x < right) {
      // Either gap beside a singleton would put it back in the same place.
      if (columns[sourceColumn].length === 1 && (i === sourceColumn || i === sourceColumn + 1))
        return null;
      const anchorId = i > 0 ? columns[i - 1].find(tile => tile.id !== drag.windowId).id : null;
      return {kind: "gap", workspaceId: row.id, anchorId, seam: Qt.rect(midpoint(left, right), row.y, 0, row.height)};
    }

    const box = column[0].rect;
    left = box.x + box.width;
    if (point.x >= left)
      continue;
    const tiles = column.filter(tile => tile.id !== drag.windowId);
    if (tiles.length === 0)
      return null;
    // Select by midpoints, then draw at the actual boundary of the slot.
    let slot = 0;
    while (slot < tiles.length && point.y >= tiles[slot].rect.y + tiles[slot].rect.height / 2)
      slot++;
    if (i === sourceColumn && slot === column.findIndex(tile => tile.id === drag.windowId))
      return null;
    const before = tiles[slot - 1]?.rect;
    const after = tiles[slot]?.rect;
    const seam = before && after ? midpoint(before.y + before.height, after.y) : (after ? after.y : before.y + before.height);
    return {kind: "stack", workspaceId: row.id, anchorId: tiles[0].id, index: slot + 1, seam: Qt.rect(box.x, seam, box.width, 0)};
  }
  return null;
}

// At the bottom stop, pack whole workspace slots above the compact trailing
// strip. Put leftover viewport space before the strip, keeping up to one row
// gap at the top. This changes the scroll range, not the viewport or row pitch.
function trailingLandingSpace(viewHeight, rowHeight, rowGap, rowCount, stripHeight) {
  var pitch = rowHeight + rowGap;
  var available = viewHeight - stripHeight;
  if (available < pitch || available >= rowCount * pitch)
    return 0;
  var leftover = available % pitch;
  return Math.max(0, leftover - rowGap);
}

function edgeStrength(position, length) {
  var band = Math.min(32, length / 2);
  if (band <= 0)
    return 0;
  if (position < band)
    return -Math.min(1, (band - position) / band);
  return Math.max(0, Math.min(1, (position - (length - band)) / band));
}

function dragScroll(point, viewport, bounds, offset, elapsedMs) {
  var distance = 1200 * elapsedMs / 1000;
  var y = point.y - viewport.y;
  // The fixed insert strip above the viewport does not drive vertical scroll.
  var dx = distance * edgeStrength(point.x - viewport.x, viewport.width);
  var dy = y < 0 ? 0 : distance * edgeStrength(y, viewport.height);
  return Qt.point(Math.max(bounds.x, Math.min(offset.x + dx, bounds.x + bounds.width)),
                  Math.max(bounds.y, Math.min(offset.y + dy, bounds.y + bounds.height)));
}

function revealOffset(start, size, viewport, current, extent) {
  var end = start + size;
  if (size > viewport) {
    // A viewport already inside an oversized tile needs no correction.
    if (current < start)
      current = start;
    else if (current + viewport > end)
      current = end - viewport;
  } else if (start < current) {
    current = start;
  } else if (end > current + viewport) {
    current = end - viewport;
  }
  return Math.max(0, Math.min(current, Math.max(0, extent - viewport)));
}
