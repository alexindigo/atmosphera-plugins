import QtQuick
import qs.Commons
import qs.Services.System
import qs.Services.UI

Item {
  id: root

  required property var settingsContext
  required property var pluginApi
  required property var retire
  property bool retired: false
  readonly property bool current: !retired && settingsContext.current()
  readonly property var cfg: settingsContext.settingsView
  property int actionGeneration: 0

  readonly property string alarmSoundFile: Qt.resolvedUrl("alarm.mp3").toString().replace("file://", "")

  readonly property int modeWork: 0
  readonly property int modeShortBreak: 1
  readonly property int modeLongBreak: 2

  property bool pomodoroRunning: false
  property int pomodoroMode: modeWork  // 0-1-2 = work, short-break, long-break
  property int pomodoroRemainingSeconds: 0
  property int pomodoroTotalSeconds: 0
  property int pomodoroOriginalTotal: 0
  property int pomodoroCompletedSessions: 0
  property bool pomodoroSoundPlaying: false

  property int settingsVersion: 0

  property int workDuration: _computeWorkDuration()
  property int shortBreakDuration: _computeShortBreakDuration()
  property int longBreakDuration: _computeLongBreakDuration()
  property int sessionsBeforeLongBreak: _computeSessionsBeforeLongBreak()
  property bool autoStartBreaks: _computeAutoStartBreaks()
  property bool autoStartWork: _computeAutoStartWork()
  property bool compactMode: _computeCompactMode()

  readonly property bool playSound: cfg.playSound !== false
  function _computeWorkDuration() { return (cfg.workDuration ?? 25) * 60; }
  function _computeShortBreakDuration() { return (cfg.shortBreakDuration ?? 5) * 60; }
  function _computeLongBreakDuration() { return (cfg.longBreakDuration ?? 15) * 60; }
  function _computeSessionsBeforeLongBreak() { return cfg.sessionsBeforeLongBreak ?? 4; }
  function _computeAutoStartBreaks() { return cfg.autoStartBreaks ?? false; }
  function _computeAutoStartWork() { return cfg.autoStartWork ?? false; }
  function _computeCompactMode() { return cfg.compactMode ?? false; }
  function refresh() { if (current) settingsVersion++; }

  onSettingsVersionChanged: {
    Logger.i("Pomodoro", "Settings updated: autoStartBreaks=" + autoStartBreaks + ", autoStartWork=" + autoStartWork + ", compactMode=" + compactMode)
  }

  function getDurationForMode(mode) {
    if (mode === modeWork) return workDuration;
    if (mode === modeShortBreak) return shortBreakDuration;
    if (mode === modeLongBreak) return longBreakDuration;
    return workDuration;
  }

  Timer {
    id: updateTimer
    interval: 1000
    repeat: true
    running: root.current && root.pomodoroRunning
    triggeredOnStart: false

    onTriggered: {
      if (!root.current || !root.pomodoroRunning)
        return;

      root.pomodoroRemainingSeconds = root.pomodoroRemainingSeconds - 1;

      if (root.pomodoroRemainingSeconds <= 0) {
        root.pomodoroOnFinished();
      }
    }
  }

  // ---  Alarm Limit Timer ---
  Timer {
    id: alarmLimitTimer
    interval: 5000 // 5 seconds
    repeat: false
    running: false
    onTriggered: {
       root.pomodoroStopAlarm();
    }
  }

  function pomodoroStart(stopSound = true) {
    if (!current) return;
    actionGeneration++;
    // Stop any playing alarm sound when starting, unless explicitly asked not to (for auto-start)
    if (stopSound && root.pomodoroSoundPlaying) {
      SoundService.stopSound(root.alarmSoundFile); // Uses variable
      root.pomodoroSoundPlaying = false;
      alarmLimitTimer.stop();
    }

    if (root.pomodoroRemainingSeconds <= 0) {
      root.pomodoroRemainingSeconds = getDurationForMode(root.pomodoroMode);
      root.pomodoroOriginalTotal = root.pomodoroRemainingSeconds;
    } else if (root.pomodoroOriginalTotal <= 0) {
      root.pomodoroOriginalTotal = root.pomodoroRemainingSeconds;
    }

    root.pomodoroTotalSeconds = root.pomodoroRemainingSeconds;
    root.pomodoroRunning = true;
  }

  function pomodoroPause() {
    if (!current) return;
    actionGeneration++;
    root.pomodoroRunning = false;
    SoundService.stopSound(root.alarmSoundFile); // Uses variable
    root.pomodoroSoundPlaying = false;
    alarmLimitTimer.stop();
  }

  function pomodoroResetSession() {
    if (!current) return;
    actionGeneration++;
    root.pomodoroRunning = false;
    root.pomodoroRemainingSeconds = getDurationForMode(root.pomodoroMode);
    root.pomodoroTotalSeconds = 0;
    root.pomodoroOriginalTotal = 0;

    SoundService.stopSound(root.alarmSoundFile); // Uses variable
    root.pomodoroSoundPlaying = false;
    alarmLimitTimer.stop();
  }

  function pomodoroResetAll() {
    if (!current) return;
    actionGeneration++;
    root.pomodoroRunning = false;
    root.pomodoroRemainingSeconds = 0;
    root.pomodoroTotalSeconds = 0;
    root.pomodoroOriginalTotal = 0;
    root.pomodoroCompletedSessions = 0;
    root.pomodoroMode = modeWork;

    SoundService.stopSound(root.alarmSoundFile); // Uses variable
    root.pomodoroSoundPlaying = false;
    alarmLimitTimer.stop();
  }

  function pomodoroSkip() {
    if (!current) return;
    actionGeneration++;
    root.pomodoroRunning = false;
    SoundService.stopSound(root.alarmSoundFile); // Uses variable
    root.pomodoroSoundPlaying = false;
    alarmLimitTimer.stop();

    pomodoroAdvanceToNextPhase();
  }

  function pomodoroStopAlarm() {
    if (!current) return;
    if (root.pomodoroSoundPlaying) {
      SoundService.stopSound(root.alarmSoundFile); // Uses variable
      root.pomodoroSoundPlaying = false;
      alarmLimitTimer.stop();
    }
  }

  function pomodoroSetMode(mode) {
    if (!current) return;
    actionGeneration++;
    if (root.pomodoroRunning) {
      root.pomodoroPause();
    }
    root.pomodoroMode = mode;
    root.pomodoroRemainingSeconds = getDurationForMode(mode);
    root.pomodoroTotalSeconds = 0;
  }

  function pomodoroAdvanceToNextPhase() {
    if (!current) return;
    if (root.pomodoroMode === modeWork) {
      if (root.pomodoroCompletedSessions + 1 >= root.sessionsBeforeLongBreak) {
        root.pomodoroMode = modeLongBreak;
      } else {
        root.pomodoroMode = modeShortBreak;
      }
    } else {
      if (root.pomodoroMode === modeLongBreak) {
        root.pomodoroCompletedSessions = 0;
      } else {
        root.pomodoroCompletedSessions++;
      }
      root.pomodoroMode = modeWork;
    }

    root.pomodoroRemainingSeconds = getDurationForMode(root.pomodoroMode);
    root.pomodoroTotalSeconds = 0;
    root.pomodoroOriginalTotal = 0;
  }

  function pomodoroOnFinished() {
    if (!current) return;
    const generation = ++actionGeneration;
    root.pomodoroRunning = false;
    root.pomodoroRemainingSeconds = 0;
    root.pomodoroSoundPlaying = true;

    // Play Sound (checking toggle setting)
    if (root.playSound) {
      SoundService.playSound(root.alarmSoundFile, { // Uses variable
        repeat: true,
        volume: 0.3
      });
      // Start the alarm limit timer
      alarmLimitTimer.start();
    }

    var toastMessage;
    var shouldAutoStart = false;

    if (root.pomodoroMode === modeWork) {
      toastMessage = pluginApi?.tr("toast.work-finished") || "Work session complete! Time for a break.";
      shouldAutoStart = root.autoStartBreaks;
    } else if (root.pomodoroMode === modeLongBreak) {
      toastMessage = pluginApi?.tr("toast.long-break-finished") || "Long break over! Ready for a new cycle?";
      shouldAutoStart = root.autoStartWork;
    } else {
      toastMessage = pluginApi?.tr("toast.break-finished") || "Break over! Ready to focus?";
      shouldAutoStart = root.autoStartWork;
    }

    ToastService.showNotice(
      pluginApi?.tr("toast.title") || "Pomodoro",
      toastMessage,
      "clock"
    );

    pomodoroAdvanceToNextPhase();

    if (shouldAutoStart) {
      Qt.callLater(() => {
        if (!root.current || generation !== root.actionGeneration) return;
        // Pass false to keep sound playing!
        root.pomodoroStart(false);
      });
    }
  }

  function release() {
    retired = true;
    actionGeneration++;
    updateTimer.stop();
    alarmLimitTimer.stop();
    pomodoroRunning = false;
    if (pomodoroSoundPlaying) SoundService.stopSound(alarmSoundFile);
    pomodoroSoundPlaying = false;
  }
  Timer {
    interval: 100; repeat: true; running: !root.retired
    onTriggered: if (!root.current) { root.release(); root.retire(root); }
  }
  Component.onDestruction: release()
}
