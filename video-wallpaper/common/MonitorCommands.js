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

// Resolve only the requested scalar, never expand a sparse stored record.
// Readers and relative commands share the same authored fallback policy.
function resolve(source, field, defaults) {
    var current = own(source, field);
    if (current !== undefined && current !== null) return current;
    var fallback = own(defaults, field);
    if (fallback !== undefined && fallback !== null) return fallback;
    if (field === "volume") return 1.0;
    if (field === "automationTime") return 300;
    var type = fieldType(field);
    return type === "boolean" ? false : type === "number" ? 0 : "";
}

function value(map, screen, field, defaults) {
    return resolve(record(map, screen), field, defaults);
}

// Automation inherits each absent monitor field from the effective global
// domain, not directly from manifest defaults. Share this scalar projection
// across the running timers, selected editor and immutable display baseline.
function automationSettings(settings, monitor, defaults) {
    return {
        automation: own(monitor, "automation") ?? settings?.automation ?? false,
        automationMode: own(monitor, "automationMode") ?? settings?.automationMode ?? defaults?.automationMode ?? "",
        automationTime: own(monitor, "automationTime") ?? settings?.automationTime ?? defaults?.automationTime ?? 0
    };
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

function create(readMap, assignMap, copyValue, readDefaults) {
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
                var current = resolve(source, command.field, readDefaults ? readDefaults() : undefined);
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
