.pragma library

// Value ownership is injected from the native store. Never serialize native
// numeric atoms or manufacture copies of attached container references here.
function own(value, key) {
    var property = value ? Object.getOwnPropertyDescriptor(value, key) : null;
    return property ? property.value : undefined;
}

function record(map, screen) {
    return own(map, screen);
}

function fieldType(field) {
    if (["currentWallpaper", "fillMode", "profile", "noctaliaWallpaper", "automationMode"].indexOf(field) !== -1) return "string";
    if (["hardwareAcceleration", "isMuted", "isPlaying", "automation"].indexOf(field) !== -1) return "boolean";
    if (["orientation", "volume", "automationTime"].indexOf(field) !== -1) return "number";
    throw new Error("monitor-command-field");
}

// Commands contain only finite, declared scalar inputs. Capture at submission,
// before a timer/caller can change the original array or command object.
function capture(commands) {
    if (!Array.isArray(commands) || commands.length === 0) throw new Error("monitor-command-input");
    return commands.map(function (input) {
        if (!input || typeof input.screen !== "string" || input.screen.length === 0) throw new Error("monitor-command-screen");
        var command = {op: input.op, screen: input.screen};
        if (input.op === "remove") return command;
        var type = fieldType(input.field);
        command.field = input.field;
        if (input.op === "unset") return command;
        if (input.op === "toggle" && type === "boolean") return command;
        if ((input.op !== "set" && input.op !== "delta") || (input.op === "delta" && type !== "number")
                || typeof input.value !== type || (type === "number" && !Number.isFinite(input.value)))
            throw new Error("monitor-command-value");
        command.value = input.value;
        return command;
    });
}

function create(readMap, assignMap, copyValue) {
    return {
        submit: function (commands) {
            var body = capture(commands);
            var next = copyValue(readMap() ?? Object.create(null));
            var changed = Object.create(null);
            var assigned = false;
            for (var command of body) {
                if (command.op === "remove") {
                    delete next[command.screen];
                    delete changed[command.screen];
                    assigned = true;
                    continue;
                }
                var source = own(next, command.screen);
                var current = own(source, command.field);
                if ((command.op === "delta" && typeof current !== "number") ||
                        (command.op === "toggle" && typeof current !== "boolean")) continue;
                if (!own(changed, command.screen)) {
                    next[command.screen] = source ?? Object.create(null);
                    changed[command.screen] = true;
                }
                var target = own(next, command.screen);
                if (command.op === "unset") delete target[command.field];
                else if (command.op === "toggle") target[command.field] = !current;
                else if (command.op === "delta") target[command.field] = current + command.value;
                else target[command.field] = command.value;
                // Normalize authored volume commands at their single input
                // boundary. Backend read notifications never write preferences.
                if (command.field === "volume" && command.op !== "unset")
                    target.volume = Math.max(0, Math.min(1, target.volume));
                assigned = true;
            }
            if (assigned) assignMap(next);
            return assigned;
        }
    };
}
