// Existing Mango grammar with explicit inputs, independent of QML ownership.
function parseMangoConfig(text, pluginApi, findMangoUnquotedComment,
                          extractMangoCategory, formatMangoKeyCombo,
                          formatMangoAction, mangoAxisMap, mangoButtonMap,
                          collectedBinds) {
  var lines = text.split('\n');
  var currentCategory = null;
  var defaultCat = pluginApi?.tr("default-category");

  for (var i = 0; i < lines.length; i++) {
    var rawLine = lines[i];
    var commentPos = findMangoUnquotedComment(rawLine);
    var effectiveLine = commentPos >= 0 ? rawLine.substring(0, commentPos).trim() : rawLine.trim();

    // Pure-comment lines: only candidate for category detection (# Title)
    if (effectiveLine.length === 0) {
      var categoryCandidate = extractMangoCategory(rawLine);
      if (categoryCandidate !== null) {
        currentCategory = categoryCandidate;
      }
      continue;
    }

    // Extract optional per-bind description: trailing #"description"
    var perBindDesc = null;
    var descMatch = effectiveLine.match(/#"([^"]*)"\s*$/);
    if (descMatch) {
      perBindDesc = descMatch[1];
      effectiveLine = effectiveLine.substring(0, descMatch.index).trim();
      if (effectiveLine.length === 0) continue;
    }

    // bind=MODS,KEY,ACTION,ARGS (also binds=, the keysym-based variant)
    var bindMatch = effectiveLine.match(/^binds?\s*=\s*(.+)$/);
    if (bindMatch) {
      var parts = bindMatch[1].split(',');
      if (parts.length >= 3) {
        var modStr = parts[0].trim();
        var key = parts[1].trim();
        var action = parts[2].trim();
        var args = parts.length >= 4 ? parts.slice(3).join(',').trim() : "";
        var cat = currentCategory || defaultCat;
        var formattedKeys = formatMangoKeyCombo(modStr, key, "bind");
        var description = perBindDesc || formatMangoAction(action, args);

        if (!collectedBinds[cat]) collectedBinds[cat] = [];
        collectedBinds[cat].push({ "keys": formattedKeys, "desc": description });
      }
      continue;
    }

    // axisbind=MODS,AXIS,ACTION,ARGS (also axisbinds=, the keysym variant)
    var axisMatch = effectiveLine.match(/^axisbinds?\s*=\s*(.+)$/);
    if (axisMatch) {
      var axisParts = axisMatch[1].split(',');
      if (axisParts.length >= 3) {
        var aModStr = axisParts[0].trim();
        var axis = axisParts[1].trim().toUpperCase();
        var aAction = axisParts[2].trim();
        var aArgs = axisParts.length >= 4 ? axisParts.slice(3).join(',').trim() : "";
        var aCat = currentCategory || defaultCat;
        var aKey = mangoAxisMap[axis] || axis;
        var aCombo = formatMangoKeyCombo(aModStr, aKey, "axis");
        var aDesc = perBindDesc || formatMangoAction(aAction, aArgs);

        if (!collectedBinds[aCat]) collectedBinds[aCat] = [];
        collectedBinds[aCat].push({ "keys": aCombo, "desc": aDesc });
      }
      continue;
    }

    // mousebind=MODS,BTN,ACTION,ARGS (also mousebinds=, the keysym variant)
    var mouseMatch = effectiveLine.match(/^mousebinds?\s*=\s*(.+)$/);
    if (mouseMatch) {
      var mouseParts = mouseMatch[1].split(',');
      if (mouseParts.length >= 3) {
        var mModStr = mouseParts[0].trim();
        var btn = mouseParts[1].trim().toUpperCase();
        var mAction = mouseParts[2].trim();
        var mArgs = mouseParts.length >= 4 ? mouseParts.slice(3).join(',').trim() : "";
        var mCat = currentCategory || defaultCat;
        var mKey = mangoButtonMap[btn] || btn;
        var mCombo = formatMangoKeyCombo(mModStr, mKey, "mouse");
        var mDesc = perBindDesc || formatMangoAction(mAction, mArgs);

        if (!collectedBinds[mCat]) collectedBinds[mCat] = [];
        collectedBinds[mCat].push({ "keys": mCombo, "desc": mDesc });
      }
    }
  }
}
