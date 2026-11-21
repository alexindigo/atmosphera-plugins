.pragma library

function hasNodeLinks(node, links) {
    return links.some(link => link && (link.source === node || link.target === node));
}

function appName(node) {
    return node.properties["application.name"] || node.nickname || node.name || "";
}

function microphone(nodes, links) {
    var apps = [], anonymous = false;
    for (var node of nodes) {
        if (!node || !node.isStream || !node.audio || node.isSink || !hasNodeLinks(node, links) || !node.properties) continue;
        if (node.properties["media.class"] !== "Stream/Input/Audio" || node.properties["stream.capture.sink"] === "true") continue;
        var name = appName(node);
        if (!name) anonymous = true;
        else if (apps.indexOf(name) === -1) apps.push(name);
    }
    return {active: anonymous || apps.length > 0, anonymous: anonymous, apps: apps};
}

function camera(apps, pattern) {
    var filter = null;
    try { if (pattern) filter = new RegExp(pattern); } catch (error) { /* Invalid patterns retain the unfiltered observation. */ }
    var result = [];
    for (var name of apps) {
        if (name && !(filter && filter.test(name)) && result.indexOf(name) === -1) result.push(name);
    }
    return result;
}

function filteredMicrophone(raw, pattern) {
    var apps = camera(raw.apps, pattern);
    return {active: raw.anonymous || apps.length > 0, apps: apps};
}
