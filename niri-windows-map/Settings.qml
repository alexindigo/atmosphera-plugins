import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  readonly property var audioIndicatorsField: pluginApi?.field("audioIndicators") ?? null

  readonly property var browserIconsField: pluginApi?.field("browserIcons") ?? null

  readonly property var hideIconsField: pluginApi?.field("hideIcons") ?? null

  readonly property var hideOnClickField: pluginApi?.field("hideOnClick") ?? null

  readonly property var hoverInfoField: pluginApi?.field("hoverInfo") ?? null

  readonly property var terminalIconsField: pluginApi?.field("terminalIcons") ?? null
  readonly property var panelSizeField: pluginApi?.field("panelSize") ?? null
  readonly property var cornerField: pluginApi?.field("corner") ?? null

  readonly property string editPanelSize: root.panelSizeField?.value || "regular"
  readonly property string editCorner: root.cornerField?.value || "bottomRight"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  NText {
    text: "Panel"
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.panelSizeField
    NComboBox {
      Layout.fillWidth: true
      label: "Size"
      description: "Panel size limit — the map still shrinks to fit its content below the limit"
      model: [
        {
          "key": "compact",
          "name": "Compact"
        },
        {
          "key": "regular",
          "name": "Regular"
        },
        {
          "key": "large",
          "name": "Large"
        }
      ]
      currentKey: root.editPanelSize
      defaultValue: "regular"
      onSelected: function (key) {
        root.panelSizeField.set(key);
      }
    }
  }

  NPluginSettingsField {
    field: root.cornerField
    NComboBox {
      Layout.fillWidth: true
      label: "Corner"
      description: "Which screen corner the map anchors to"
      model: [
        {
          "key": "topLeft",
          "name": "Top left"
        },
        {
          "key": "topCenter",
          "name": "Top center"
        },
        {
          "key": "topRight",
          "name": "Top right"
        },
        {
          "key": "bottomLeft",
          "name": "Bottom left"
        },
        {
          "key": "bottomCenter",
          "name": "Bottom center"
        },
        {
          "key": "bottomRight",
          "name": "Bottom right"
        }
      ]
      currentKey: root.editCorner
      defaultValue: "bottomRight"
      onSelected: function (key) {
        root.cornerField.set(key);
      }
    }
  }

  NPluginSettingsField {
    field: root.hideIconsField
    NToggle {
      label: "Hide icons"
      description: "Don't draw app icons on the map tiles"
      checked: root.hideIconsField?.value ?? false
      onToggled: checked => {
        root.hideIconsField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.hideOnClickField
    NToggle {
      label: "Hide on click"
      description: "Close the map after clicking a window tile"
      checked: root.hideOnClickField?.value ?? false
      onToggled: checked => {
        root.hideOnClickField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.terminalIconsField
    NToggle {
      label: "Show terminal process icon (if available)"
      description: "On terminal tiles, show the icon of the app running in the foreground instead of the terminal's icon"
      checked: root.terminalIconsField?.value ?? true
      onToggled: checked => {
        root.terminalIconsField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.browserIconsField
    NToggle {
      label: "Browser tab favicons"
      description: "On browser tiles, show the current tab's site favicon (resolved locally from browser history — no network access)"
      checked: root.browserIconsField?.value ?? true
      onToggled: checked => {
        root.browserIconsField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.audioIndicatorsField
    NToggle {
      label: "Audio indicators"
      description: "Show a speaker badge on windows producing sound, with a mute/unmute button on the tile"
      checked: root.audioIndicatorsField?.value ?? true
      onToggled: checked => {
        root.audioIndicatorsField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.hoverInfoField
    NToggle {
      label: "Hover info line"
      description: "Show the hovered window's details (path, page title, app) in the empty bottom workspace row"
      checked: root.hoverInfoField?.value ?? true
      onToggled: checked => {
        root.hoverInfoField.set(checked);
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("NiriWindowsMap", "Cannot save settings: pluginApi is null");
      return;
    }
  }
}
