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
