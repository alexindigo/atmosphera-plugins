import QtQuick

Item {
    id: root
    required property var runtimeApi
    required property var settingsContext
    required property var retire
    property bool retired: false
    readonly property bool current: !retired && runtimeApi !== null && runtimeApi.settingsContext === settingsContext && settingsContext.current()
    readonly property var cfg: settingsContext.settingsView

    property int hunger: cfg.hunger ?? 100
    property int happiness: cfg.happiness ?? 100
    property int cleanliness: cfg.cleanliness ?? 100
    property int energy: cfg.energy ?? 100
    readonly property real difficulty: cfg.difficulty ?? 50
    readonly property real difficultyFactor: 0.3 + (difficulty / 100) * 1.7
    property bool _sleeping: false
    property bool eating: false
    readonly property bool isDirty: cleanliness < 20
    property string lastPetState: "idle"
    readonly property string petState: {
        if (_sleeping && energy > 98) return lastPetState;
        if (_sleeping) return "sleeping";
        const isSad = happiness < 30, isTired = energy < 30, isHungry = hunger < 20;
        if (isSad && isHungry && isTired) return "angry";
        if (isHungry) return "hungry";
        if (isSad) return "sad";
        if (isTired) return "tired";
        return "idle";
    }

    function save() {
        if (!current) return;
        runtimeApi.pluginSettings.hunger = hunger;
        runtimeApi.pluginSettings.happiness = happiness;
        runtimeApi.pluginSettings.cleanliness = cleanliness;
        runtimeApi.pluginSettings.energy = energy;
        runtimeApi.saveSettings();
    }
    function sleep() {
        if (!current) return;
        if (_sleeping) _sleeping = false;
        else { lastPetState = petState; _sleeping = true; }
        save();
    }
    function clean(c) { if (!current) return; cleanliness = Math.min(100, cleanliness + c); save(); }
    function feed(v) { if (!current) return; hunger = Math.min(100, hunger + v); save(); }
    function play(h, e = 3) {
        if (!current || energy < 10 || happiness >= 99) return;
        happiness = Math.min(100, happiness + h);
        energy = Math.max(0, energy - e);
        save();
    }
    function _randFactor(min = 0.5, max = 1.7) { return min + Math.random() * (max - min); }
    function decay() {
        if (!current) return;
        const f = difficultyFactor;
        if (_sleeping) {
            energy = Math.min(100, energy + 3.5 * _randFactor());
            hunger = Math.max(0, hunger - 0.03 * f * _randFactor());
            happiness = Math.max(0, happiness - 0.005 * f * _randFactor());
            cleanliness = Math.max(0, cleanliness - 0.02 * f * _randFactor());
        } else {
            energy = Math.max(0, energy - 0.03 * f * _randFactor());
            hunger = Math.max(0, hunger - 0.05 * f * _randFactor());
            happiness = Math.max(0, happiness - 0.005 * f * _randFactor());
            cleanliness = Math.max(0, cleanliness - 0.05 * f * _randFactor());
        }
        save();
    }
    Timer { interval: 30000; running: root.current; repeat: true; onTriggered: root.decay() }
    Timer {
        interval: 100; running: !root.retired; repeat: true
        onTriggered: if (!root.current) { root.retired = true; root.retire(root); }
    }
}
