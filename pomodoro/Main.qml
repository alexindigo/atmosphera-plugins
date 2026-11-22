import QtQuick
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component { id: timerFactory; TimerClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    const timer = timerFactory.createObject(root, {
      settingsContext: context, pluginApi: pluginApi,
      retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }
    });
    _settingsConsumers.set(context, timer);
    return timer;
  }
  function timerFor(api) { return api?.settingsReady ? settingsConsumerFor(api.settingsContext) : null; }
  readonly property var settingsConsumer: timerFor(pluginApi)
  readonly property int workDuration: settingsConsumer?.workDuration ?? 1500
  readonly property int shortBreakDuration: settingsConsumer?.shortBreakDuration ?? 300
  readonly property int longBreakDuration: settingsConsumer?.longBreakDuration ?? 900
  readonly property int sessionsBeforeLongBreak: settingsConsumer?.sessionsBeforeLongBreak ?? 4
  readonly property bool autoStartBreaks: settingsConsumer?.autoStartBreaks ?? false
  readonly property bool autoStartWork: settingsConsumer?.autoStartWork ?? false
  readonly property bool compactMode: settingsConsumer?.compactMode ?? false
  readonly property bool pomodoroRunning: settingsConsumer?.pomodoroRunning ?? false
  readonly property bool pomodoroSoundPlaying: settingsConsumer?.pomodoroSoundPlaying ?? false
  readonly property int pomodoroMode: settingsConsumer?.pomodoroMode ?? 0
  readonly property int pomodoroRemainingSeconds: settingsConsumer?.pomodoroRemainingSeconds ?? 0
  readonly property int pomodoroTotalSeconds: settingsConsumer?.pomodoroTotalSeconds ?? 0
  readonly property int pomodoroOriginalTotal: settingsConsumer?.pomodoroOriginalTotal ?? 0
  readonly property int pomodoroCompletedSessions: settingsConsumer?.pomodoroCompletedSessions ?? 0
  function pomodoroStart(stopSound = true) { settingsConsumer?.pomodoroStart(stopSound); }
  function pomodoroPause() { settingsConsumer?.pomodoroPause(); }
  function pomodoroResetSession() { settingsConsumer?.pomodoroResetSession(); }
  function pomodoroResetAll() { settingsConsumer?.pomodoroResetAll(); }
  function pomodoroSkip() { settingsConsumer?.pomodoroSkip(); }
  function pomodoroStopAlarm() { settingsConsumer?.pomodoroStopAlarm(); }
  function pomodoroSetMode(mode) { settingsConsumer?.pomodoroSetMode(mode); }

  // Preserve the existing plugin-level legacy source and native runtime writer.
  FileView {
    path: Qt.resolvedUrl("settings.json")
    onTextChanged: {
      if (text && text.length > 0) {
        try {
          const values = JSON.parse(text);
          if (root.pluginApi && root.pluginApi.pluginSettings) {
            for (const key of ["workDuration", "shortBreakDuration", "longBreakDuration", "sessionsBeforeLongBreak", "autoStartBreaks", "autoStartWork", "compactMode"]) {
              if (values[key] !== undefined) root.pluginApi.pluginSettings[key] = values[key];
            }
            root.settingsConsumer?.refresh();
            Logger.i("Pomodoro", "Settings reloaded from file");
          }
        } catch (error) { Logger.e("Pomodoro", "Failed to parse settings.json: " + error); }
      }
    }
  }
  IpcHandler {
    target: "plugin:pomodoro"
    function toggle() { if (root.pluginApi) root.pluginApi.withCurrentScreen(screen => root.pluginApi.togglePanel(screen)); }
    function start() { root.pomodoroStart(); }
    function pause() { root.pomodoroPause(); }
    function reset() { root.pomodoroResetSession(); }
    function resetAll() { root.pomodoroResetAll(); }
    function skip() { root.pomodoroSkip(); }
    function stopAlarm() { root.pomodoroStopAlarm(); }
  }
}
