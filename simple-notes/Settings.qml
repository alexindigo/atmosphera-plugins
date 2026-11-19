import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  // Local state
  property bool showCount: displayBaseline.showCount

  spacing: Style.marginM

  NToggle {
    label: pluginApi?.tr("settings.show_count.label") || "Show Note Count"
    description: pluginApi?.tr("settings.show_count.description") || "Show the number of notes in the bar widget"
    checked: root.showCount
    onToggled: (checked) => {
      root.showCount = checked;
    }
  }

  NSettingsBaseline {
    id: displayBaseline
    readonly property bool showCount: pluginApi?.pluginSettings?.showCountInBar ?? true
  }
  readonly property bool settingsDirty: displayBaseline.differs({showCount: root.showCount})

  function saveSettings() {
    if (pluginApi) {
      pluginApi.pluginSettings.showCountInBar = root.showCount;
      pluginApi.saveSettings();
    }
  }
}
