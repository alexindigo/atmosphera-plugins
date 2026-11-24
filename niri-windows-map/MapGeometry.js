// Visible row geometry owns both painting and drop acceptance. Points and
// rectangles at this boundary are in the canvas root's coordinates.
function contains(rect, point) {
  return point.x >= rect.x && point.y >= rect.y
      && point.x < rect.x + rect.width && point.y < rect.y + rect.height;
}

function targetAt(point, viewport, phantom, origin, scale, rows, mapWidth) {
  if (contains(phantom, point))
    return {kind: "insert"};
  if (!contains(viewport, point) || scale <= 0)
    return null;
  var local = {x: (point.x - origin.x) / scale, y: (point.y - origin.y) / scale};
  if (local.x < 0 || local.x >= mapWidth)
    return null;
  for (var i = 0; i < rows.length; i++) {
    if (local.y >= rows[i].y && local.y < rows[i].y + rows[i].height)
      return rows[i].trailing ? {kind: "trailing"} : {kind: "row", id: rows[i].id};
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
