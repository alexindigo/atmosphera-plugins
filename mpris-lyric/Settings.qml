import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null
  readonly property var playerNameField: pluginApi?.field("playerName") ?? null
  readonly property var updateIntervalField: pluginApi?.field("updateInterval") ?? null
  readonly property var widthField: pluginApi?.field("width") ?? null
  readonly property var hideWhenInactiveField: pluginApi?.field("hideWhenInactive") ?? null

  // Shortcut to settings and defaults
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Editable settings
  readonly property string editPlayerName: root.playerNameField?.value || "musicfox"
  readonly property int editUpdateInterval: root.updateIntervalField?.value || 200
  readonly property int editWidth: root.widthField?.value || 300
  readonly property bool editHideWhenInactive: root.hideWhenInactiveField?.value ?? true
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  Component.onCompleted: {
    Logger.i("MprisLyric", "Settings UI loaded");
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("MprisLyric", "Cannot save: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("MprisLyric", "Settings saved successfully");
    });
  }

  // Player name
  NPluginSettingsField {
    field: root.playerNameField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.player-name")
      description: pluginApi?.tr("settings.player-name-desc")
      text: root.editPlayerName
      placeholderText: "musicfox"
      onEditCommitted: root.playerNameField.set(text)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NPluginSettingsField {
    field: root.hideWhenInactiveField
    NToggle {
      label: pluginApi?.tr("settings.hide-when-inactive")
      description: pluginApi?.tr("settings.hide-when-inactive-desc")
      checked: root.editHideWhenInactive
      onToggled: checked => root.hideWhenInactiveField.set(checked)
    }
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

    NPluginSettingsField {
      field: root.updateIntervalField
      NSlider {
        id: rangeEditUpdateInterval
        objectName: "settings-range-editUpdateInterval"
        Layout.fillWidth: true
        from: 50
        to: 500
        stepSize: 50
        value: root.editUpdateInterval
        onMoved: root.updateIntervalField.set(value)
      }
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

    NPluginSettingsField {
      field: root.widthField
      NSlider {
        id: rangeEditWidth
        objectName: "settings-range-editWidth"
        Layout.fillWidth: true
        from: 100
        to: 600
        stepSize: 50
        value: root.editWidth
        onMoved: root.widthField.set(value)
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
