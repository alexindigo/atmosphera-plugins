import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  // Plugin API (injected by the settings dialog system)
  property var pluginApi: null

  // Local state for editing
  property string editLauncher: displayBaseline.editLauncher
  property bool editForceGrid: displayBaseline.editForceGrid
  property int editRecentlyOpenedMax: displayBaseline.project("editRecentlyOpenedMax")

  NSettingsBaseline {
    ranges: [NSettingsRange { field: "editRecentlyOpenedMax"; from: rangeEditRecentlyOpenedMax.from; to: rangeEditRecentlyOpenedMax.to }]
    id: displayBaseline
    readonly property string editLauncher: pluginApi?.pluginSettings?.launcher || pluginApi?.manifest?.metadata?.defaultSettings?.launcher || "xdg-open"
    readonly property bool editForceGrid: pluginApi?.pluginSettings?.forceGrid ?? pluginApi?.manifest?.metadata?.defaultSettings?.editForceGrid ?? false
    readonly property int editRecentlyOpenedMax: pluginApi?.pluginSettings?.recentlyOpenedMax ?? pluginApi?.manifest?.metadata?.defaultSettings?.recentlyOpenedMax ?? 36
  }
  readonly property bool settingsDirty: displayBaseline.differs({editLauncher: root.editLauncher, editForceGrid: root.editForceGrid, editRecentlyOpenedMax: root.editRecentlyOpenedMax})

  spacing: Style.marginM

  // Calibre db
  ColumnLayout {
      spacing: Style.marginL

      NLabel {
          label: pluginApi?.tr("settings.launcher.title") || "Launcher"
          description: pluginApi?.tr("settings.launcher.description") || "The program used to open book files"
      }

      NTextInput {
          Layout.fillWidth: true
          placeholderText: "xdg-open"
          text: root.editLauncher
          onTextChanged: root.editLauncher = text
      }

      NCheckbox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.forcegrid.label") || "Force grid view"
        description: pluginApi?.tr("settings.forcegrid.description") || "Always use grid view to display results. If disabled, use current launcher configuration"
        checked: root.editForceGrid
        onToggled: (checked) => root.editForceGrid = checked
      }

      ColumnLayout {
        spacing: Style.marginM

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          NLabel {
            label: pluginApi?.tr("settings.recentlyOpened.label") || "Recently opened count"
            description: pluginApi?.tr("settings.recentlyOpened.description") || "How many recently opened entries to remember"
          }

          NText {
            text: root.editRecentlyOpenedMax.toString()
          }
        }

        NSlider {
          id: rangeEditRecentlyOpenedMax
          objectName: "settings-range-editRecentlyOpenedMax"
          Layout.fillWidth: true
          from: 1
          to: 100
          value: root.editRecentlyOpenedMax
          stepSize: 1
          onValueChanged: {
            root.editRecentlyOpenedMax = value;
          }
        }
      }
  }


  // Required: Save function called by the dialog
  function saveSettings() {
    pluginApi.pluginSettings.launcher = root.editLauncher;
    pluginApi.pluginSettings.forceGrid = root.editForceGrid;
    pluginApi.pluginSettings.recentlyOpenedMax = root.editRecentlyOpenedMax;
    const mru = (pluginApi.pluginSettings.recentlyOpenedFiles ?? []).slice();
    mru.length = Math.min(
        mru.length,
        pluginApi.pluginSettings.recentlyOpenedMax
    );
    pluginApi.pluginSettings.recentlyOpenedFiles = mru;
    pluginApi.saveSettings();
  }
}
