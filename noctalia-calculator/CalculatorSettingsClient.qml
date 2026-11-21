import QtQuick

Item {
    id: client
    required property var settingsContext
    required property var calculation
    required property var retire
    readonly property bool current: settingsContext.current()
    readonly property var cfg: settingsContext.settingsView
    readonly property bool showBarValue: cfg.showBarValue ?? true
    readonly property int precision: Math.max(0, Math.min(cfg.precision ?? 8, 10))
    readonly property string currentInput: calculation.currentInput
    readonly property string displayText: calculation.displayText
    readonly property string expressionText: calculation.expressionText
    readonly property bool errorState: calculation.errorState
    readonly property bool hasCopyableResult: calculation.hasCopyableResult
    readonly property string badgeText: showBarValue ? calculation.compactDisplay(displayText, 9, precision) : ""
    function clearAll() { if (current) calculation.clearAll(); }
    function pressButton(action) { if (current) calculation.pressButton(action, precision); }
    function actionForKeyEvent(event) { return current ? calculation.actionForKeyEvent(event) : ""; }
    function handleKeyEvent(event) { return current ? calculation.handleKeyEvent(event, precision) : false; }
    function copyResult() { if (current) calculation.copyResult(); }
    property bool _constructed: false
    onCurrentChanged: if (!current && _constructed) retire(client)
    Component.onCompleted: _constructed = true
}
