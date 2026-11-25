import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Widgets

// Noctalia settings page
ColumnLayout {
  id: root
  spacing: 12

  property var pluginApi: null
  readonly property var wallpaperDirectoryField: pluginApi?.field("wallpaperDirectory") ?? null
  readonly property var carouselModeField: pluginApi?.field("carouselMode") ?? null
  readonly property var expandSelectedField: pluginApi?.field("expandSelected") ?? null
  readonly property var enableHoldExpandField: pluginApi?.field("enableHoldExpand") ?? null
  readonly property var overlayOpacityField: pluginApi?.field("overlayOpacity") ?? null
  readonly property var borderWidthField: pluginApi?.field("borderWidth") ?? null
  readonly property var cornerRadiusField: pluginApi?.field("cornerRadius") ?? null
  readonly property var itemWidthField: pluginApi?.field("itemWidth") ?? null
  readonly property var itemHeightField: pluginApi?.field("itemHeight") ?? null
  readonly property var selectedScaleField: pluginApi?.field("selectedScale") ?? null
  readonly property var expandMultiplierField: pluginApi?.field("expandMultiplier") ?? null
  readonly property var holdExpandRatioField: pluginApi?.field("holdExpandRatio") ?? null
  readonly property var holdDelayField: pluginApi?.field("holdDelay") ?? null
  readonly property string editWallpaperDirectory: root.wallpaperDirectoryField?.value ?? ""
  readonly property string editCarouselMode: root.carouselModeField?.value ?? "wrap"
  readonly property string editExpandSelected: root.expandSelectedField?.value ?? "false"
  readonly property string editEnableHoldExpand: root.enableHoldExpandField?.value ?? "false"
  readonly property real editOverlayOpacity: root.overlayOpacityField?.value ?? 80
  readonly property real editBorderWidth: root.borderWidthField?.value ?? 3
  readonly property real editCornerRadius: root.cornerRadiusField?.value ?? 0
  readonly property real editItemWidth: root.itemWidthField?.value ?? 300
  readonly property real editItemHeight: root.itemHeightField?.value ?? 420
  readonly property real editSelectedScale: root.selectedScaleField?.value ?? 108
  readonly property real editExpandMultiplier: root.expandMultiplierField?.value ?? 120
  readonly property real editHoldExpandRatio: root.holdExpandRatioField?.value ?? 35
  readonly property real editHoldDelay: root.holdDelayField?.value ?? 1500
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    pluginApi.saveSettings();
  }

  // ── Reusable slider row ───────────────────────────────────────────────────
  component SettingSlider: ColumnLayout {
    id: sl
    property string label: ""
    property string description: ""
    property real value: 0
    property string rangeName: ""
    signal valueEdited(real value)
    property real min: 0
    property real max: 100
    property real defaultValue: 0
    property string unit: ""

    Layout.fillWidth: true
    spacing: 2

    RowLayout {
      Layout.fillWidth: true
      Label {
        textFormat: Text.PlainText
        text: sl.label
        font.bold: true
        Layout.fillWidth: true
      }
      Label {
        textFormat: Text.PlainText
        text: Math.round(sl.value) + sl.unit
        font.pixelSize: 12
        opacity: 0.7
      }
    }
    Slider {
      objectName: sl.rangeName
      Layout.fillWidth: true
      from: sl.min
      to: sl.max
      stepSize: 1
      value: sl.value
      onMoved: sl.valueEdited(Math.round(value))
    }
    Label {
      textFormat: Text.PlainText
      text: sl.description
      font.pixelSize: 12
      opacity: 0.6
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }

  // ── Reusable combo row ────────────────────────────────────────────────────
  component SettingCombo: ColumnLayout {
    id: cb
    property string label: ""
    property string description: ""
    property string value: ""
    signal valueEdited(string value)
    property var options: []
    property string defaultValue: ""

    Layout.fillWidth: true
    spacing: 2

    Label {
      textFormat: Text.PlainText
      text: cb.label
      font.bold: true
    }
    ComboBox {
      Layout.fillWidth: true
      model: cb.options
      textRole: "text"
      valueRole: "value"
      currentIndex: {
        const v = cb.value;
        for (let i = 0; i < cb.options.length; i++)
          if (cb.options[i].value === v)
            return i;
        return 0;
      }
      onActivated: cb.valueEdited(model[currentIndex].value)
    }
    Label {
      textFormat: Text.PlainText
      text: cb.description
      font.pixelSize: 12
      opacity: 0.6
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }

  // ── General ───────────────────────────────────────────────────────────────
  Label {
    text: "General"
    font.bold: true
    font.pixelSize: 14
  }

  Label {
    text: "Wallpaper Directory"
    font.bold: true
  }
  NPluginSettingsField {
    field: root.wallpaperDirectoryField
    TextField {
      Layout.fillWidth: true
      placeholderText: "/home/user/Pictures/Wallpapers"
      text: root.editWallpaperDirectory
      onTextEdited: root.wallpaperDirectoryField.set(text)
    }
  }
  Label {
    text: "Override the wallpaper directory. Leave empty to follow the current wallpaper's directory."
    font.pixelSize: 12
    opacity: 0.6
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  NPluginSettingsField {
    field: root.carouselModeField
    SettingCombo {
      label: "Carousel Mode"
      description: "Standard stops at the edges. Wrap loops the index. Infinite shows a seamless repeating view."
      value: root.editCarouselMode
      onValueEdited: value => root.carouselModeField.set(value)
      options: [
        {
          text: "Standard",
          value: "standard"
        },
        {
          text: "Wrap",
          value: "wrap"
        },
        {
          text: "Infinite",
          value: "infinite"
        }
      ]
    }
  }

  // ── Visual ────────────────────────────────────────────────────────────────
  Label {
    text: "Visual"
    font.bold: true
    font.pixelSize: 14
    Layout.topMargin: 8
  }

  NPluginSettingsField {
    field: root.overlayOpacityField
    SettingSlider {
      id: overlayInput
      rangeName: "settings-range-editOverlayOpacity"
      label: "Background Dimming"
      description: "Opacity of the dark overlay behind the carousel."
      value: root.editOverlayOpacity
      min: 0
      max: 100
      unit: "%"
      onValueEdited: value => root.overlayOpacityField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.borderWidthField
    SettingSlider {
      id: borderInput
      rangeName: "settings-range-editBorderWidth"
      label: "Border Width"
      description: "Width of the skewed border around thumbnails."
      value: root.editBorderWidth
      min: 0
      max: 20
      unit: "px"
      onValueEdited: value => root.borderWidthField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.cornerRadiusField
    SettingSlider {
      id: cornerInput
      rangeName: "settings-range-editCornerRadius"
      label: "Corner Radius"
      description: "Corner radius of thumbnails. Set to 0 to disable."
      value: root.editCornerRadius
      min: 0
      max: 60
      unit: "px"
      onValueEdited: value => root.cornerRadiusField.set(value)
    }
  }

  // ── Size ──────────────────────────────────────────────────────────────────
  Label {
    text: "Size"
    font.bold: true
    font.pixelSize: 14
    Layout.topMargin: 8
  }

  NPluginSettingsField {
    field: root.itemWidthField
    SettingSlider {
      id: widthInput
      rangeName: "settings-range-editItemWidth"
      label: "Item Width"
      description: "Width of each wallpaper thumbnail."
      value: root.editItemWidth
      min: 100
      max: 1000
      unit: "px"
      onValueEdited: value => root.itemWidthField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.itemHeightField
    SettingSlider {
      id: heightInput
      rangeName: "settings-range-editItemHeight"
      label: "Item Height"
      description: "Height of each wallpaper thumbnail."
      value: root.editItemHeight
      min: 100
      max: 1440
      unit: "px"
      onValueEdited: value => root.itemHeightField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.selectedScaleField
    SettingSlider {
      id: scaleInput
      rangeName: "settings-range-editSelectedScale"
      label: "Center Tile Zoom"
      description: "Size of the centered tile relative to the surrounding tiles."
      value: root.editSelectedScale
      min: 100
      max: 150
      unit: "%"
      onValueEdited: value => root.selectedScaleField.set(value)
    }
  }

  // ── Expansion ─────────────────────────────────────────────────────────────
  Label {
    text: "Expansion"
    font.bold: true
    font.pixelSize: 14
    Layout.topMargin: 8
  }

  NPluginSettingsField {
    field: root.expandSelectedField
    SettingCombo {
      label: "Expand Selected"
      description: "Expand the centered tile's width to reveal more of the image."
      value: root.editExpandSelected
      onValueEdited: value => root.expandSelectedField.set(value)
      options: [
        {
          text: "Disabled",
          value: "false"
        },
        {
          text: "Enabled",
          value: "true"
        }
      ]
    }
  }

  NPluginSettingsField {
    field: root.expandMultiplierField
    SettingSlider {
      id: expandInput
      rangeName: "settings-range-editExpandMultiplier"
      label: "Expansion Amount"
      description: "Width multiplier applied when the centered tile is expanded."
      value: root.editExpandMultiplier
      min: 100
      max: 300
      unit: "%"
      onValueEdited: value => root.expandMultiplierField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.enableHoldExpandField
    SettingCombo {
      label: "Hold to Expand"
      description: "Dwell on a tile to trigger a large immersive preview."
      value: root.editEnableHoldExpand
      onValueEdited: value => root.enableHoldExpandField.set(value)
      options: [
        {
          text: "Disabled",
          value: "false"
        },
        {
          text: "Enabled",
          value: "true"
        }
      ]
    }
  }

  NPluginSettingsField {
    field: root.holdExpandRatioField
    SettingSlider {
      id: coverageInput
      rangeName: "settings-range-editHoldExpandRatio"
      label: "Hold Coverage"
      description: "Screen coverage for the hold preview."
      value: root.editHoldExpandRatio
      min: 30
      max: 100
      unit: "%"
      onValueEdited: value => root.holdExpandRatioField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.holdDelayField
    SettingSlider {
      id: delayInput
      rangeName: "settings-range-editHoldDelay"
      label: "Hold Delay"
      description: "Time to dwell on a tile before the preview activates."
      value: root.editHoldDelay
      min: 200
      max: 10000
      unit: "ms"
      onValueEdited: value => root.holdDelayField.set(value)
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
