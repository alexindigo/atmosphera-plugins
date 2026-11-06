function copyPresets(source) {
  if (!source || typeof source !== "object" || typeof source.slice !== "function" || !Number.isSafeInteger(source.length) || source.length < 0)
    return [];
  var presets = [];
  for (var index = 0; index < source.length; index++) presets.push(String(source[index]));
  return presets;
}

function validate(alias, presets, canonicalPrefix, validateAlias,
                  parseDuration) {
  var aliasResult = validateAlias(alias, canonicalPrefix);
  if (aliasResult.state !== "valid") {
    return {
      "valid": false,
      "field": "alias",
      "code": aliasResult.code
    };
  }

  var sourcePresets = copyPresets(presets);
  var normalizedPresets = [];
  for (var index = 0; index < sourcePresets.length; index++) {
    var parsed = parseDuration(sourcePresets[index]);
    if (parsed.state !== "valid") {
      return {
        "valid": false,
        "field": "preset",
        "index": index,
        "state": parsed.state,
        "code": parsed.code
      };
    }
    normalizedPresets.push(parsed.normalized);
  }

  return {
    "valid": true,
    "alias": aliasResult.normalized,
    "presets": normalizedPresets
  };
}
