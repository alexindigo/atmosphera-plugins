import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null
  readonly property var compactModeField: pluginApi?.field("compactMode") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null
  readonly property var textColorField: pluginApi?.field("textColor") ?? null

  readonly property bool editCompactMode: root.compactModeField?.value ?? false
  readonly property string editIconColor: root.iconColorField?.value ?? "none"
  readonly property string editTextColor: root.textColorField?.value ?? "none"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Timer", "Cannot save: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("Timer", "Settings saved successfully");
    });
  }

  // Icon Color
  NPluginSettingsField {
    field: root.iconColorField
    NColorChoice {
      label: I18n.tr("common.select-icon-color")
      description: I18n.tr("common.select-color-description")
      currentKey: root.editIconColor
      onSelected: key => root.iconColorField.set(key)
    }
  }

  // Text Color
  NPluginSettingsField {
    field: root.textColorField
    NColorChoice {
      currentKey: root.editTextColor
      onSelected: key => root.textColorField.set(key)
    }
  }

  // Compact Mode
  NPluginSettingsField {
    field: root.compactModeField
    NToggle {
      label: pluginApi?.tr("settings.compact-mode") || "Compact Mode"
      description: pluginApi?.tr("settings.compact-mode-desc") || "Hide the circular progress bar for a cleaner look"
      checked: root.editCompactMode
      onToggled: checked => root.compactModeField.set(checked)
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.compactMode ?? false
    }
  }
}
