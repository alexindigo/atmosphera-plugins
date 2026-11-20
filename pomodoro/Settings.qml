import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var workDurationField: pluginApi?.field("workDuration") ?? null
  readonly property var shortBreakDurationField: pluginApi?.field("shortBreakDuration") ?? null
  readonly property var longBreakDurationField: pluginApi?.field("longBreakDuration") ?? null
  readonly property var sessionsBeforeLongBreakField: pluginApi?.field("sessionsBeforeLongBreak") ?? null
  readonly property var autoStartBreaksField: pluginApi?.field("autoStartBreaks") ?? null
  readonly property var autoStartWorkField: pluginApi?.field("autoStartWork") ?? null
  readonly property var compactModeField: pluginApi?.field("compactMode") ?? null
  readonly property var playSoundField: pluginApi?.field("playSound") ?? null
  readonly property int editWorkDuration: root.workDurationField?.value ?? 25
  readonly property int editShortBreakDuration: root.shortBreakDurationField?.value ?? 5
  readonly property int editLongBreakDuration: root.longBreakDurationField?.value ?? 15
  readonly property int editSessionsBeforeLongBreak: root.sessionsBeforeLongBreakField?.value ?? 4

  readonly property bool editAutoStartBreaks: root.autoStartBreaksField?.value ?? false
  readonly property bool editAutoStartWork: root.autoStartWorkField?.value ?? false
  readonly property bool editCompactMode: root.compactModeField?.value ?? false

  // --- : Sound Property ---
  readonly property bool editPlaySound: root.playSoundField?.value ?? true

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _applyEffectPending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._applyEffectPending = false;
      if (root.pluginApi.mainInstance)
        root.pluginApi.mainInstance.settingsVersion++;
    }
  }

  spacing: Style.marginM

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.work-duration") || "Work Duration"
      description: pluginApi?.tr("settings.work-duration-desc") || "Duration of each work session in minutes"
    }

    NPluginSettingsField {
      field: root.workDurationField
      NSpinBox {
        id: workDurationSpinBox
        objectName: "settings-range-editWorkDuration"
        from: 5
        to: 180
        stepSize: 5
        value: root.editWorkDuration
        onValueModified: value => {
          if (value !== root.editWorkDuration)
            root.workDurationField.set(value);
        }
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.short-break-duration") || "Short Break Duration"
      description: pluginApi?.tr("settings.short-break-duration-desc") || "Duration of short breaks in minutes"
    }

    NPluginSettingsField {
      field: root.shortBreakDurationField
      NSpinBox {
        id: shortBreakSpinBox
        objectName: "settings-range-editShortBreakDuration"
        from: 1
        to: 60
        stepSize: 1
        value: root.editShortBreakDuration
        onValueModified: value => {
          if (value !== root.editShortBreakDuration)
            root.shortBreakDurationField.set(value);
        }
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.long-break-duration") || "Long Break Duration"
      description: pluginApi?.tr("settings.long-break-duration-desc") || "Duration of long breaks in minutes"
    }

    NPluginSettingsField {
      field: root.longBreakDurationField
      NSpinBox {
        id: longBreakSpinBox
        objectName: "settings-range-editLongBreakDuration"
        from: 5
        to: 120
        stepSize: 5
        value: root.editLongBreakDuration
        onValueModified: value => {
          if (value !== root.editLongBreakDuration)
            root.longBreakDurationField.set(value);
        }
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.sessions-before-long-break") || "Sessions Before Long Break"
      description: pluginApi?.tr("settings.sessions-before-long-break-desc") || "Number of work sessions before a long break"
    }

    NPluginSettingsField {
      field: root.sessionsBeforeLongBreakField
      NSpinBox {
        id: sessionsSpinBox
        objectName: "settings-range-editSessionsBeforeLongBreak"
        from: 1
        to: 10
        stepSize: 1
        value: root.editSessionsBeforeLongBreak
        onValueModified: value => {
          if (value !== root.editSessionsBeforeLongBreak)
            root.sessionsBeforeLongBreakField.set(value);
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  // The control's own toggled signal carries mouse, keyboard and
  // accessibility activation alike; no pointer-only overlay writer.
  NPluginSettingsField {
    field: root.autoStartBreaksField
    NToggle {
      id: autoStartBreaksToggle
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.auto-start-breaks") || "Auto-start Breaks"
      description: pluginApi?.tr("settings.auto-start-breaks-desc") || "Automatically start break timer after work session"
      checked: root.editAutoStartBreaks
      onToggled: checked => root.autoStartBreaksField.set(checked)
    }
  }

  // The control's own toggled signal carries mouse, keyboard and
  // accessibility activation alike; no pointer-only overlay writer.
  NPluginSettingsField {
    field: root.autoStartWorkField
    NToggle {
      id: autoStartWorkToggle
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.auto-start-work") || "Auto-start Work"
      description: pluginApi?.tr("settings.auto-start-work-desc") || "Automatically start work timer after break"
      checked: root.editAutoStartWork
      onToggled: checked => root.autoStartWorkField.set(checked)
    }
  }

  // The control's own toggled signal carries mouse, keyboard and
  // accessibility activation alike; no pointer-only overlay writer.
  NPluginSettingsField {
    field: root.compactModeField
    NToggle {
      id: compactModeToggle
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.compact-mode") || "Compact Mode"
      description: pluginApi?.tr("settings.compact-mode-desc") || "Hide the circular progress bar for a cleaner look"
      checked: root.editCompactMode
      onToggled: checked => root.compactModeField.set(checked)
    }
  }

  // --- : Play Sound Toggle ---
  // The control's own toggled signal carries mouse, keyboard and
  // accessibility activation alike; no pointer-only overlay writer.
  NPluginSettingsField {
    field: root.playSoundField
    NToggle {
      id: playSoundToggle
      Layout.fillWidth: true
      label: "Play Alarm Sound"
      description: "Play a sound when the timer finishes"
      checked: root.editPlaySound
      onToggled: checked => root.playSoundField.set(checked)
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Pomodoro", "Cannot save settings: pluginApi is null");
      return;
    }

    // --- : Save Sound Setting ---

    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true;
  }
}
