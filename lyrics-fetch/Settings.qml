import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  NText {
    Layout.fillWidth: true
    visible: root.pluginApi?.scopeKind === "instance"
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
    wrapMode: Text.WordWrap
    color: AtmoColor.mOnSurfaceVariant
    pointSize: Style.fontSizeS
  }
  readonly property var widgetWidthField: pluginApi?.field("widgetWidth") ?? null
  readonly property var scrollSpeedField: pluginApi?.field("scrollSpeed") ?? null
  readonly property var scrollModeField: pluginApi?.field("scrollMode") ?? null
  readonly property var adaptScrollSpeedField: pluginApi?.field("adaptScrollSpeed") ?? null
  readonly property var hideWhenPausedField: pluginApi?.field("hideWhenPaused") ?? null
  readonly property var verticalRotationDirectionField: pluginApi?.field("verticalRotationDirection") ?? null
  readonly property var fontSizeField: pluginApi?.field("fontSize") ?? null
  readonly property var hideWhenEmptyField: pluginApi?.field("hideWhenEmpty") ?? null
  readonly property var fontFamilyField: pluginApi?.field("fontFamily") ?? null

  readonly property int draftWidth: root.widgetWidthField?.value ?? 215
  readonly property int draftSpeed: root.scrollSpeedField?.value ?? 70
  readonly property string draftMode: root.scrollModeField?.value ?? "always"
  readonly property int draftFontSize: root.fontSizeField?.value ?? 10
  readonly property bool draftHideWhenEmpty: root.hideWhenEmptyField?.value ?? true
  readonly property string draftFontFamily: root.fontFamilyField?.value ?? "Inter"
  readonly property bool draftAdaptScrollSpeed: root.adaptScrollSpeedField?.value ?? true
  readonly property bool draftHideWhenPaused: root.hideWhenPausedField?.value ?? true
  readonly property string draftVerticalRotationDirection: root.displayedRotation()

  readonly property bool isBarVertical: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function displayedRotation() {
    const value = pluginApi?.pluginSettings?.verticalRotationDirection;
    return value === "auto" || value === "cw" || value === "ccw" ? value : "auto";
  }

  spacing: Style.marginM

  function saveSettings() {
    if (pluginApi) {
      // Save the selected font
      pluginApi.saveSettings();
    }
  }

  NPluginSettingsField {
    field: root.fontFamilyField
    NSearchableComboBox {
      label: pluginApi?.tr("settings.font.title")
      description: pluginApi?.tr("settings.font.desc")
      Layout.fillWidth: true

      model: FontService.availableFonts

      currentKey: draftFontFamily
      placeholder: pluginApi?.tr("settings.font.placeholder")
      searchPlaceholder: pluginApi?.tr("settings.font.search-placeholder")
      popupHeight: 300

      onSelected: key => root.fontFamilyField.set(key)
    }
  }

  NLabel {
    label: pluginApi?.tr("settings.font.size")
    description: pluginApi?.tr("settings.font.size-desc")
  }

  RowLayout {
    Layout.fillWidth: true
    NPluginSettingsField {
      field: root.fontSizeField
      NSlider {
        id: rangeDraftFontSize
        objectName: "settings-range-draftFontSize"
        Layout.fillWidth: true
        from: 8
        to: 32
        value: draftFontSize
        onMoved: root.fontSizeField.set(value)
      }
    }
    NText {
      text: Math.round(draftFontSize) + "pt"
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NLabel {
    label: pluginApi?.tr("settings.width")
  }
  RowLayout {
    Layout.fillWidth: true
    NPluginSettingsField {
      field: root.widgetWidthField
      NSlider {
        id: rangeDraftWidth
        objectName: "settings-range-draftWidth"
        Layout.fillWidth: true
        from: 100
        to: 500
        value: draftWidth
        onMoved: root.widgetWidthField.set(value)
      }
    }
    NText {
      text: Math.round(draftWidth) + "px"
    }
  }

  NLabel {
    label: pluginApi?.tr("settings.scroll.speed")
  }
  RowLayout {
    Layout.fillWidth: true
    NPluginSettingsField {
      field: root.scrollSpeedField
      NSlider {
        id: rangeDraftSpeed
        objectName: "settings-range-draftSpeed"
        Layout.fillWidth: true
        from: 10
        to: 200
        value: draftSpeed
        onMoved: root.scrollSpeedField.set(value)
      }
    }
    NText {
      text: Math.round(draftSpeed) + " px/s"
    }
  }

  NPluginSettingsField {
    field: root.scrollModeField
    NComboBox {
      label: pluginApi?.tr("settings.scroll.mode.title")
      Layout.fillWidth: true
      model: [
        {
          name: pluginApi?.tr("settings.scroll.mode.always"),
          key: "always"
        },
        {
          name: pluginApi?.tr("settings.scroll.mode.hover"),
          key: "hover"
        },
        {
          name: pluginApi?.tr("settings.scroll.mode.never"),
          key: "none"
        }
      ]
      currentKey: draftMode
      onSelected: key => root.scrollModeField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.adaptScrollSpeedField
    NToggle {
      label: pluginApi?.tr("settings.scroll.adapt")
      description: pluginApi?.tr("settings.scroll.adapt-desc")
      checked: draftAdaptScrollSpeed
      onToggled: newState => {
        root.adaptScrollSpeedField.set(newState);
      }
    }
  }

  NPluginSettingsField {
    field: root.hideWhenEmptyField
    NToggle {
      label: pluginApi?.tr("settings.hide-when-empty")
      checked: draftHideWhenEmpty
      onToggled: newState => {
        root.hideWhenEmptyField.set(newState);
      }
    }
  }

  NPluginSettingsField {
    field: root.verticalRotationDirectionField
    visible: root.isBarVertical
    NComboBox {
      label: pluginApi?.tr("settings.vertical-rotation.title")
      description: pluginApi?.tr("settings.vertical-rotation.description")
      Layout.fillWidth: true
      model: [
        {
          name: pluginApi?.tr("settings.vertical-rotation.auto"),
          key: "auto"
        },
        {
          name: pluginApi?.tr("settings.vertical-rotation.ccw"),
          key: "ccw"
        },
        {
          name: pluginApi?.tr("settings.vertical-rotation.cw"),
          key: "cw"
        }
      ]
      currentKey: draftVerticalRotationDirection
      onSelected: key => root.verticalRotationDirectionField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.hideWhenPausedField
    NToggle {
      label: pluginApi?.tr("settings.hide-when-paused")
      checked: draftHideWhenPaused
      onToggled: newState => {
        root.hideWhenPausedField.set(newState);
      }
    }
  }
}
