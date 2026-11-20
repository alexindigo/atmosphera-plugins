import QtQuick
import QtQuick.Layouts

import Quickshell
import "./common/MonitorCommands.js" as Commands

import "./common"
import "./settings"

import qs.Commons
import qs.Portals
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  // One atomic monitors field; member controls submit finite commands into
  // its owned presentation. No form snapshot or opening baseline is saved.
  readonly property var monitorsField: pluginApi?.field("monitors") ?? null
  readonly property var editScreenSettings: monitorsField?.value ?? ({})
  readonly property var monitorCommand: Commands.create(function () {
    return root.editScreenSettings;
  }, function (value) {
    root.monitorsField.set(value);
  }, function (value) {
    return root.pluginApi.copyValue(value);
  }, function () {
    return root.pluginApi?.manifest?.metadata?.defaultSettings;
  })
  readonly property var selectedAutomationSettings: Commands.automationSettings(pluginApi?.pluginSettings, monitorSpecific ? Commands.record(editScreenSettings, monitorTabBar.selectedMonitor) : null, pluginApi?.manifest?.metadata?.defaultSettings)
  property alias currentWallpaper: general.currentWallpaper
  property alias volume: general.volume
  property alias automationEnabled: automation.automation
  property alias automationMode: automation.automationMode
  property alias automationTime: automation.automationTime
  property alias automationCustomTime: automation.automationCustomTime
  property alias customTimeText: automation.customTimeText
  property alias fillMode: advanced.fillMode
  property alias orientation: advanced.orientation
  property alias hardwareAcceleration: advanced.hardwareAcceleration
  property alias profile: advanced.profile
  property alias mpvSocket: advanced.mpvSocket
  readonly property bool settingsDirty: general.settingsDirty || automation.settingsDirty || advanced.settingsDirty

  spacing: Style.marginM

  /***************************
  * PROPERTIES
  ***************************/
  readonly property string activeBackend: pluginApi?.field("activeBackend").value ?? ""
  readonly property bool valueEnabled: pluginApi?.field("enabled").value ?? false
  readonly property bool monitorSpecific: pluginApi?.field("monitorSpecific").value ?? false
  readonly property string wallpapersFolder: pluginApi?.field("wallpapersFolder").value ?? ""

  /***************************
  * FUNCTIONS
  ***************************/
  function saveMonitorProperty(key: string, value: var): void {
    if (pluginApi == null) {
      Logger.e("video-wallpaper", "PluginAPI is null.");
      return;
    }

    // Automation has a global owner as well as per-monitor owners. The
    // selected editor must write the same domain its running timer reads.
    if (!monitorSpecific && ["automation", "automationMode", "automationTime"].includes(key)) {
      pluginApi.field(key).set(value);
      return;
    }

    var names = monitorSpecific ? [monitorTabBar.selectedMonitor] : Array.from(Quickshell.screens).map(screen => screen.name);
    if (names.length)
      monitorCommand.submit(names.map(name => ({
        op: "set",
        screen: name,
        field: key,
        value: value
      })));
  }

  function loadSelectedMonitor() {
    var record = Commands.record(editScreenSettings, monitorTabBar.selectedMonitor) || ({});
    general.loadMonitor(record);
    automation.loadMonitor(selectedAutomationSettings);
    advanced.loadMonitor(record);
  }

  function saveSelectedMonitor() {
    return {
      general: general.saveSettings(),
      automation: automation.saveMonitorSettings(),
      advanced: advanced.saveSettings()
    };
  }

  function selectMonitorDomain(specific) {
    // Settle buffered intent against the old domain before selecting a new
    // projection. Merely changing the selection must never author fields.
    saveSelectedMonitor();
    pluginApi.field("monitorSpecific").set(specific);
    loadSelectedMonitor();
  }

  /***************************
  * COMPONENTS
  ***************************/
  // Active toggle
  NPluginSettingsField {
    field: root.pluginApi?.field("enabled") ?? null
    NToggle {
      label: root.pluginApi?.tr("settings.toggle.label")
      description: root.pluginApi?.tr("settings.toggle.description")
      checked: root.valueEnabled
      onToggled: checked => root.pluginApi.field("enabled").set(checked)
    }
  }

  NPluginSettingsField {
    field: root.pluginApi?.field("monitorSpecific") ?? null
    visible: Quickshell.screens.length > 1
    NToggle {
      visible: Quickshell.screens.length > 1
      label: root.pluginApi?.tr("settings.monitor_specific.label")
      description: root.pluginApi?.tr("settings.monitor_specific.description")
      checked: root.monitorSpecific
      onToggled: checked => root.selectMonitorDomain(checked)
    }
  }

  NPluginSettingsField {
    field: root.pluginApi?.field("activeBackend") ?? null
    NComboBox {
      enabled: root.valueEnabled
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.backend.label")
      description: root.pluginApi?.tr("settings.backend.description")
      defaultValue: "qt6-multimedia"
      model: [
        {
          "key": "qt6-multimedia",
          "name": root.pluginApi?.tr("settings.backend.qt6_multimedia")
        },
        {
          "key": "mpvpaper",
          "name": root.pluginApi?.tr("settings.backend.mpvpaper")
        }
      ]
      currentKey: root.activeBackend
      onSelected: key => root.pluginApi.field("activeBackend").set(key)
    }
  }

  // Wallpapers Folder
  NPluginSettingsField {
    field: root.pluginApi?.field("wallpapersFolder") ?? null
    ColumnLayout {
      spacing: Style.marginS

      NLabel {
        enabled: root.valueEnabled
        label: root.pluginApi?.tr("settings.general.wallpapers_folder.title.label")
        description: root.pluginApi?.tr("settings.general.wallpapers_folder.title.description")
      }

      RowLayout {
        spacing: Style.marginS

        NTextInput {
          enabled: root.valueEnabled
          placeholderText: root.pluginApi?.tr("settings.general.wallpapers_folder.text_input.placeholder")
          text: root.wallpapersFolder
          onEditCommitted: root.pluginApi.field("wallpapersFolder").set(text)
        }

        AtmoIconButton {
          enabled: root.valueEnabled
          icon: "wallpaper-selector"
          tooltipText: root.pluginApi?.tr("settings.general.wallpapers_folder.icon_button.tooltip")
          onClicked: wallpapersFolderPicker.openFilePicker()
        }

        PortalFilePicker {
          id: wallpapersFolderPicker
          title: root.pluginApi?.tr("settings.general.wallpapers_folder.file_picker.title")
          initialPath: root.wallpapersFolder
          selectionMode: "folders"

          onAccepted: paths => {
            if (paths.length > 0) {
              Logger.d("video-wallpaper", "Selected the following wallpaper folder:", paths[0]);
              root.pluginApi.field("wallpapersFolder").set(paths[0]);
            }
          }
        }
      }
    }
  }

  NDivider {}

  MonitorTabBar {
    id: monitorTabBar

    enabled: root.valueEnabled
    monitorSpecific: root.monitorSpecific

    property string selectedMonitor: Quickshell.screens[0].name

    onCurrentIndexChanged: {
      if (general && automation && advanced && selectedMonitor) {
        root.saveSelectedMonitor();
      }
      selectedMonitor = Quickshell.screens[currentIndex]?.name || "";
      if (general && automation && advanced) {
        root.loadSelectedMonitor();
      }
    }
  }

  // Tab bar with all the settings menus
  NTabBar {
    id: tabBar
    Layout.fillWidth: true
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      enabled: root.valueEnabled
      text: pluginApi?.tr("settings.tab_bar.general")
      tabIndex: 0
      checked: tabBar.currentIndex === 0
    }
    NTabButton {
      enabled: root.valueEnabled
      text: pluginApi?.tr("settings.tab_bar.automation")
      tabIndex: 1
      checked: tabBar.currentIndex === 1
    }
    NTabButton {
      enabled: root.valueEnabled
      text: pluginApi?.tr("settings.tab_bar.advanced")
      tabIndex: 2
      checked: tabBar.currentIndex === 2
    }
  }

  // The menu shown
  NPluginSettingsField {
    field: root.monitorsField
    NTabView {
      id: tabView
      currentIndex: tabBar.currentIndex

      GeneralTab {
        id: general
        pluginApi: root.pluginApi
        enabled: root.valueEnabled
        selectedMonitor: monitorTabBar.selectedMonitor
        monitorSettings: Settings.store.copyValue(Commands.record(root.editScreenSettings, selectedMonitor) ?? ({}))
        wallpapersFolder: root.wallpapersFolder
        monitorSpecific: root.monitorSpecific
        toolSettings: ({
                         monitors: root.editScreenSettings,
                         monitorSpecific: root.monitorSpecific
                       })

        onSaveMonitorProperty: (key, value) => root.saveMonitorProperty(key, value)
      }

      AutomationTab {
        id: automation
        pluginApi: root.pluginApi
        enabled: root.valueEnabled
        selectedMonitor: monitorTabBar.selectedMonitor
        monitorSpecific: root.monitorSpecific
        monitorSettings: root.selectedAutomationSettings

        onSaveMonitorProperty: (key, value) => root.saveMonitorProperty(key, value)
      }

      AdvancedTab {
        id: advanced
        pluginApi: root.pluginApi
        activeBackend: root.activeBackend
        enabled: root.valueEnabled
        selectedMonitor: monitorTabBar.selectedMonitor
        monitorSettings: Settings.store.copyValue(Commands.record(root.editScreenSettings, selectedMonitor) ?? ({}))

        onSaveMonitorProperty: (key, value) => root.saveMonitorProperty(key, value)
      }
    }
  }

  /********************************
  * Save settings functionality
  ********************************/
  function saveSettings() {
    if (!pluginApi) {
      Logger.e("video-wallpaper", "Cannot save, pluginApi is null");
      return;
    }

    // The custom-time dialog owns a global draft, not the selected monitor.
    // Validate it only for Apply, before staging any selected form fields.
    automation.prepareSave();
    var captured = saveSelectedMonitor();

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current") {
        general.acknowledgeSettings(captured.general);
        automation.acknowledgeSettings(captured.automation);
        advanced.acknowledgeSettings(captured.advanced);
      }
    });
  }
}
