import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null

  // Shortcut to settings and defaults
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Editable settings
  property string editPlayerName: displayBaseline.editPlayerName
  property int editUpdateInterval: displayBaseline.project("editUpdateInterval")
  property int editWidth: displayBaseline.project("editWidth")
  property bool editHideWhenInactive: displayBaseline.editHideWhenInactive
  NSettingsBaseline {
    ranges: [NSettingsRange { field: "editUpdateInterval"; from: rangeEditUpdateInterval.from; to: rangeEditUpdateInterval.to }, NSettingsRange { field: "editWidth"; from: rangeEditWidth.from; to: rangeEditWidth.to }]
    id: displayBaseline
    readonly property string editPlayerName: cfg.playerName || defaults.playerName || "musicfox"
    readonly property int editUpdateInterval: cfg.updateInterval || defaults.updateInterval || 200
    readonly property int editWidth: cfg.width || defaults.width || 300
    readonly property bool editHideWhenInactive: cfg.hideWhenInactive ?? defaults.hideWhenInactive ?? true
  }
  readonly property bool settingsDirty: displayBaseline.differs({editPlayerName: root.editPlayerName, editUpdateInterval: root.editUpdateInterval, editWidth: root.editWidth, editHideWhenInactive: root.editHideWhenInactive})

  Component.onCompleted: {
    Logger.i("MprisLyric", "Settings UI loaded")
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("MprisLyric", "Cannot save: pluginApi is null")
      return
    }

    pluginApi.pluginSettings.playerName = root.editPlayerName
    pluginApi.pluginSettings.updateInterval = root.editUpdateInterval
    pluginApi.pluginSettings.width = root.editWidth
    pluginApi.pluginSettings.hideWhenInactive = root.editHideWhenInactive

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("MprisLyric", "Settings saved successfully")
    })
  }

  // Player name
  NTextInput {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.player-name")
    description: pluginApi?.tr("settings.player-name-desc")
    text: root.editPlayerName
    placeholderText: "musicfox"
    onTextChanged: root.editPlayerName = text
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NToggle {
    label: pluginApi?.tr("settings.hide-when-inactive")
    description: pluginApi?.tr("settings.hide-when-inactive-desc")
    checked: root.editHideWhenInactive
    onToggled: checked => root.editHideWhenInactive = checked
  }

  // Update interval
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.update-interval", {
        value: root.editUpdateInterval
      })
      description: pluginApi?.tr("settings.update-interval-desc")
    }

    NSlider {
      id: rangeEditUpdateInterval
      objectName: "settings-range-editUpdateInterval"
      Layout.fillWidth: true
      from: 50
      to: 500
      stepSize: 50
      value: root.editUpdateInterval
      onValueChanged: root.editUpdateInterval = value
    }
  }

  // Width
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.width", {
        value: root.editWidth
      })
      description: pluginApi?.tr("settings.width-desc")
    }

    NSlider {
      id: rangeEditWidth
      objectName: "settings-range-editWidth"
      Layout.fillWidth: true
      from: 100
      to: 600
      stepSize: 50
      value: root.editWidth
      onValueChanged: root.editWidth = value
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
