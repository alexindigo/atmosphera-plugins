.pragma library

// Actual control interaction signals, not page property assignments or field
// setters. These fixtures do not claim physical keyboard/pointer injection.
function find(root, predicate) {
    var visited = [];
    function walk(item) {
        if (!item || visited.indexOf(item) !== -1) return null;
        visited.push(item);
        if (predicate(item)) return item;
        for (var list of [item.children, item.resources, item.data, item.contentItem ? [item.contentItem] : null]) {
            if (!list) continue;
            for (var i = 0; i < list.length; i++) {
                var found = walk(list[i]);
                if (found) return found;
            }
        }
        return null;
    }
    return walk(root);
}

function folder(page, api, value) {
    var input = find(page, function (item) { return item.placeholderText === api.tr("settings.general.wallpapers_folder.text_input.placeholder") && typeof item.editCommitted === "function"; });
    if (!input) throw new Error("wallpaper-folder control missing");
    input.text = value;
    input.editCommitted();
}

function wallpaper(page, api, value) {
    var picker = find(page, function (item) { return item.title === api.tr("settings.general.select_wallpaper.file_picker.title") && typeof item.accepted === "function"; });
    if (!picker) throw new Error("wallpaper-picker control missing");
    picker.accepted([value]);
}

function volume(page, value) {
    var slider = find(page, function (item) { return item.objectName === "settings-range-volume"; });
    if (!slider) throw new Error("wallpaper-volume control missing");
    slider.moved(value);
}
