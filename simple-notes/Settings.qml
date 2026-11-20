import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var showCountInBarField: pluginApi?.field("showCountInBar") ?? null

  // Local state
  readonly property bool showCount: root.showCountInBarField?.value ?? true

  spacing: Style.marginM

  NPluginSettingsField {
    field: root.showCountInBarField
    NToggle {
      label: pluginApi?.tr("settings.show_count.label") || "Show Note Count"
      description: pluginApi?.tr("settings.show_count.description") || "Show the number of notes in the bar widget"
      checked: root.showCount
      onToggled: checked => {
        root.showCountInBarField.set(checked);
      }
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (pluginApi) {
      pluginApi.saveSettings();
    }
  }
}
