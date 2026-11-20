import QtQuick
import QtQuick.Layouts

import "./common"
import "./settings"
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var activeField: pluginApi?.field("active") ?? null
  readonly property var isPlayingField: pluginApi?.field("isPlaying") ?? null
  readonly property var isMutedField: pluginApi?.field("isMuted") ?? null

  readonly property bool active: root.activeField?.value || false
  readonly property bool isPlaying: root.isPlayingField?.value || false
  readonly property bool isMuted: root.isMutedField?.value || false
  property alias wallpapersFolder: playback.wallpapersFolder
  property alias currentWallpaper: playback.currentWallpaper
  property alias volume: audio.volume
  property alias automation: automationTab.automation
  property alias automationMode: automationTab.automationMode
  property alias automationTime: automationTab.automationTime
  property alias hardwareAcceleration: advanced.hardwareAcceleration
  property alias mpvSocket: advanced.mpvSocket
  property alias profile: advanced.profile
  property alias fillMode: advanced.fillMode
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  // Active toggle
  NPluginSettingsField {
    field: root.activeField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.toggle.label") || "Enable mpvpaper"
      description: pluginApi?.tr("settings.toggle.description") || "Enable the mpvpaper integration"
      checked: root.active
      onToggled: checked => root.activeField.set(checked)
    }
  }

  NDivider {}

  NPluginSettingsField {
    field: root.isPlayingField
    NPluginSettingsField {
      field: root.isMutedField
      ToolRow {
        objectName: "mpv-settings-tools"
        pluginApi: root.pluginApi
        enabled: root.active
        isPlaying: root.isPlaying
        isMuted: root.isMuted
        playingWriter: value => root.isPlayingField.set(value)
        muteWriter: value => root.isMutedField.set(value)
      }
    }
  }

  NDivider {}

  NTabBar {
    id: subTabBar
    Layout.fillWidth: true
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      enabled: root.active
      text: pluginApi?.tr("settings.tab_bar.playback") || "Playback"
      tabIndex: 0
      checked: subTabBar.currentIndex === 0
    }
    NTabButton {
      enabled: root.active
      text: pluginApi?.tr("settings.tab_bar.audio") || "Audio"
      tabIndex: 1
      checked: subTabBar.currentIndex === 1
    }
    NTabButton {
      enabled: root.active
      text: pluginApi?.tr("settings.tab_bar.automation") || "Automation"
      tabIndex: 2
      checked: subTabBar.currentIndex === 2
    }
    NTabButton {
      enabled: root.active
      text: pluginApi?.tr("settings.tab_bar.advanced") || "Advanced"
      tabIndex: 3
      checked: subTabBar.currentIndex === 3
    }
  }

  NTabView {
    id: tabView
    currentIndex: subTabBar.currentIndex

    PlaybackTab {
      id: playback
      pluginApi: root.pluginApi
      active: root.active
    }

    AudioTab {
      id: audio
      pluginApi: root.pluginApi
      active: root.active
      isMuted: root.isMuted
    }

    AutomationTab {
      id: automationTab
      pluginApi: root.pluginApi
      active: root.active
    }

    AdvancedTab {
      id: advanced
      pluginApi: root.pluginApi
      active: root.active
    }
  }

  /********************************
  * Save settings functionality
  ********************************/
  function saveSettings() {
    if (!pluginApi) {
      Logger.e("mpvpaper", "Cannot save: pluginApi is null");
      return;
    }

    playback.saveSettings();
    audio.saveSettings();
    advanced.saveSettings();
    automationTab.saveSettings();

    pluginApi.saveSettings();
  }
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if ((result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("mpvpaper", "Settings saved");
    }
  }
}
