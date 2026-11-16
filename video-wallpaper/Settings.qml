import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.Commons
import qs.Widgets
import qs.Portals

import "./common"
import "./settings"
import "./common/MonitorCommands.js" as Commands

ColumnLayout {
    id: root
    property var pluginApi: null
    NSettingsBaseline {
        id: displayBaseline
        readonly property string activeBackend: root.pluginApi?.initialSettings?.activeBackend ?? root.pluginApi?.manifest?.metadata?.defaultSettings?.activeBackend ?? ""
        readonly property bool valueEnabled: root.pluginApi?.initialSettings?.enabled ?? false
        readonly property bool monitorSpecific: root.pluginApi?.initialSettings?.monitorSpecific ?? false
        readonly property string wallpapersFolder: root.pluginApi?.initialSettings?.wallpapersFolder ?? root.pluginApi?.manifest?.metadata?.defaultSettings?.wallpapersFolder ?? ""
        readonly property var editScreenSettings: root.pluginApi?.initialSettings?.monitors || ({})
    }
    // The display baseline is not a persistence source. Edit an owned native
    // copy of the actual draft, retaining opaque keys and exact numeric atoms.
    property var editScreenSettings: Settings.store.copyValue(pluginApi?.pluginSettings?.monitors ?? ({}))
    readonly property var monitorCommand: Commands.create(function () { return root.editScreenSettings; },
        function (value) { root.editScreenSettings = value; }, function (value) { return Settings.store.copyValue(value); },
        function () { return root.pluginApi?.manifest?.metadata?.defaultSettings; })
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
    readonly property bool settingsDirty: displayBaseline.differs({activeBackend: activeBackend, valueEnabled: valueEnabled, monitorSpecific: monitorSpecific, wallpapersFolder: wallpapersFolder, editScreenSettings: editScreenSettings}) || general.settingsDirty || automation.settingsDirty || advanced.settingsDirty

    spacing: Style.marginM


    /***************************
    * PROPERTIES
    ***************************/
    property string activeBackend: displayBaseline.activeBackend
    property bool valueEnabled: displayBaseline.valueEnabled
    property bool monitorSpecific: displayBaseline.monitorSpecific
    property string wallpapersFolder: displayBaseline.wallpapersFolder


    /***************************
    * FUNCTIONS
    ***************************/
    function saveMonitorProperty(key: string, value: var): void {
        if(pluginApi == null) {
            Logger.e("video-wallpaper", "PluginAPI is null.");
            return;
        }

        var names = monitorSpecific ? [monitorTabBar.selectedMonitor] : Array.from(Quickshell.screens).map(screen => screen.name);
        if (names.length) monitorCommand.submit(names.map(name => ({op: "set", screen: name, field: key, value: value})));
    }


    /***************************
    * COMPONENTS
    ***************************/
    // Active toggle
    NToggle {
        label:       root.pluginApi?.tr("settings.toggle.label")
        description: root.pluginApi?.tr("settings.toggle.description")
        checked: root.valueEnabled
        onToggled: checked => root.valueEnabled = checked
    }

    NToggle {
        visible: Quickshell.screens.length > 1
        label:       root.pluginApi?.tr("settings.monitor_specific.label")
        description: root.pluginApi?.tr("settings.monitor_specific.description")
        checked: root.monitorSpecific
        onToggled: checked => root.monitorSpecific = checked
    }

    NComboBox {
        enabled: root.valueEnabled
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("settings.backend.label")
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
        onSelected: key => root.activeBackend = key
    }

    // Wallpapers Folder
    ColumnLayout {
        spacing: Style.marginS

        NLabel {
            enabled: root.valueEnabled
            label:       root.pluginApi?.tr("settings.general.wallpapers_folder.title.label")
            description: root.pluginApi?.tr("settings.general.wallpapers_folder.title.description")
        }

        RowLayout {
            spacing: Style.marginS

            NTextInput {
                enabled: root.valueEnabled
                placeholderText: root.pluginApi?.tr("settings.general.wallpapers_folder.text_input.placeholder")
                text: root.wallpapersFolder
                onTextChanged: root.wallpapersFolder = text
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
                        root.wallpapersFolder = paths[0];
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
                general.saveSettings(); automation.saveSettings(); advanced.saveSettings();
            }
            selectedMonitor = Quickshell.screens[currentIndex]?.name || ""
            if (general && automation && advanced) {
                var record = Commands.record(root.editScreenSettings, selectedMonitor) || ({});
                general.loadMonitor(record); automation.loadMonitor(record); advanced.loadMonitor(record);
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
            toolSettings: ({monitors: root.editScreenSettings, monitorSpecific: root.monitorSpecific})

            onSaveMonitorProperty: (key, value) => root.saveMonitorProperty(key, value);
        }

        AutomationTab {
            id: automation
            pluginApi: root.pluginApi
            enabled: root.valueEnabled
            selectedMonitor: monitorTabBar.selectedMonitor
            monitorSettings: Settings.store.copyValue(Commands.record(root.editScreenSettings, selectedMonitor) ?? ({}))

            onSaveMonitorProperty: (key, value) => root.saveMonitorProperty(key, value);
        }

        AdvancedTab {
            id: advanced
            pluginApi: root.pluginApi
            activeBackend: root.activeBackend
            enabled: root.valueEnabled
            selectedMonitor: monitorTabBar.selectedMonitor
            monitorSettings: Settings.store.copyValue(Commands.record(root.editScreenSettings, selectedMonitor) ?? ({}))

            onSaveMonitorProperty: (key, value) => root.saveMonitorProperty(key, value);
        }
    }

    /********************************
    * Save settings functionality
    ********************************/
    function saveSettings() {
        if(!pluginApi) {
            Logger.e("video-wallpaper", "Cannot save, pluginApi is null");
            return;
        }

        general.saveSettings();
        automation.saveSettings();
        advanced.saveSettings();

        pluginApi.pluginSettings.monitors = editScreenSettings;
        pluginApi.pluginSettings.activeBackend = activeBackend;
        pluginApi.pluginSettings.enabled = valueEnabled;
        pluginApi.pluginSettings.monitorSpecific = monitorSpecific;
        pluginApi.pluginSettings.wallpapersFolder = wallpapersFolder;
        pluginApi.pluginSettings.automationCustomTime = Array.from(automationCustomTime);
        pluginApi.pluginSettings.mpvSocket = mpvSocket;

        pluginApi.saveSettings();
    }
}
