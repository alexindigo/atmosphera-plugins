import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Widgets

// Noctalia settings page
ColumnLayout {
    id: root
    spacing: 12

    property var pluginApi: null
    readonly property var initial: pluginApi?.initialSettings || pluginApi?.manifest?.metadata?.defaultSettings || ({})
    NSettingsBaseline {
        id: displayBaseline
        readonly property string editWallpaperDirectory: root.initial.wallpaperDirectory ?? ""
        readonly property string editCarouselMode: root.initial.carouselMode ?? "wrap"
        readonly property string editExpandSelected: root.initial.expandSelected ?? "false"
        readonly property string editEnableHoldExpand: root.initial.enableHoldExpand ?? "false"
        readonly property real editOverlayOpacity: root.initial.overlayOpacity ?? 80
        readonly property real editBorderWidth: root.initial.borderWidth ?? 3
        readonly property real editCornerRadius: root.initial.cornerRadius ?? 0
        readonly property real editItemWidth: root.initial.itemWidth ?? 300
        readonly property real editItemHeight: root.initial.itemHeight ?? 420
        readonly property real editSelectedScale: root.initial.selectedScale ?? 108
        readonly property real editExpandMultiplier: root.initial.expandMultiplier ?? 120
        readonly property real editHoldExpandRatio: root.initial.holdExpandRatio ?? 35
        readonly property real editHoldDelay: root.initial.holdDelay ?? 1500
        ranges: [NSettingsRange { field: "editOverlayOpacity"; from: overlayInput.min; to: overlayInput.max }, NSettingsRange { field: "editBorderWidth"; from: borderInput.min; to: borderInput.max }, NSettingsRange { field: "editCornerRadius"; from: cornerInput.min; to: cornerInput.max }, NSettingsRange { field: "editItemWidth"; from: widthInput.min; to: widthInput.max }, NSettingsRange { field: "editItemHeight"; from: heightInput.min; to: heightInput.max }, NSettingsRange { field: "editSelectedScale"; from: scaleInput.min; to: scaleInput.max }, NSettingsRange { field: "editExpandMultiplier"; from: expandInput.min; to: expandInput.max }, NSettingsRange { field: "editHoldExpandRatio"; from: coverageInput.min; to: coverageInput.max }, NSettingsRange { field: "editHoldDelay"; from: delayInput.min; to: delayInput.max }]
    }
    property string editWallpaperDirectory: displayBaseline.editWallpaperDirectory
    property string editCarouselMode: displayBaseline.editCarouselMode
    property string editExpandSelected: displayBaseline.editExpandSelected
    property string editEnableHoldExpand: displayBaseline.editEnableHoldExpand
    property real editOverlayOpacity: displayBaseline.project("editOverlayOpacity")
    property real editBorderWidth: displayBaseline.project("editBorderWidth")
    property real editCornerRadius: displayBaseline.project("editCornerRadius")
    property real editItemWidth: displayBaseline.project("editItemWidth")
    property real editItemHeight: displayBaseline.project("editItemHeight")
    property real editSelectedScale: displayBaseline.project("editSelectedScale")
    property real editExpandMultiplier: displayBaseline.project("editExpandMultiplier")
    property real editHoldExpandRatio: displayBaseline.project("editHoldExpandRatio")
    property real editHoldDelay: displayBaseline.project("editHoldDelay")
    readonly property bool settingsDirty: displayBaseline.differs({editWallpaperDirectory: editWallpaperDirectory, editCarouselMode: editCarouselMode, editExpandSelected: editExpandSelected, editEnableHoldExpand: editEnableHoldExpand, editOverlayOpacity: editOverlayOpacity, editBorderWidth: editBorderWidth, editCornerRadius: editCornerRadius, editItemWidth: editItemWidth, editItemHeight: editItemHeight, editSelectedScale: editSelectedScale, editExpandMultiplier: editExpandMultiplier, editHoldExpandRatio: editHoldExpandRatio, editHoldDelay: editHoldDelay})

    function saveSettings() {
        pluginApi.pluginSettings = Object.assign({}, pluginApi.pluginSettings, {wallpaperDirectory: editWallpaperDirectory, carouselMode: editCarouselMode, expandSelected: editExpandSelected, enableHoldExpand: editEnableHoldExpand, overlayOpacity: editOverlayOpacity, borderWidth: editBorderWidth, cornerRadius: editCornerRadius, itemWidth: editItemWidth, itemHeight: editItemHeight, selectedScale: editSelectedScale, expandMultiplier: editExpandMultiplier, holdExpandRatio: editHoldExpandRatio, holdDelay: editHoldDelay});
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
            Label { text: sl.label; font.bold: true; Layout.fillWidth: true }
            Label {
                text: Math.round(sl.value) + sl.unit
                font.pixelSize: 12; opacity: 0.7
            }
        }
        Slider {
            objectName: sl.rangeName
            Layout.fillWidth: true
            from: sl.min; to: sl.max; stepSize: 1
            value: sl.value
            onMoved: sl.valueEdited(Math.round(value))
        }
        Label {
            text: sl.description
            font.pixelSize: 12; opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
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

        Label { text: cb.label; font.bold: true }
        ComboBox {
            Layout.fillWidth: true
            model: cb.options
            textRole: "text"
            valueRole: "value"
            currentIndex: {
                const v = cb.value;
                for (let i = 0; i < cb.options.length; i++)
                    if (cb.options[i].value === v) return i;
                return 0;
            }
            onActivated: cb.valueEdited(model[currentIndex].value)
        }
        Label {
            text: cb.description
            font.pixelSize: 12; opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
        }
    }

    // ── General ───────────────────────────────────────────────────────────────
    Label { text: "General"; font.bold: true; font.pixelSize: 14 }

    Label { text: "Wallpaper Directory"; font.bold: true }
    TextField {
        Layout.fillWidth: true
        placeholderText: "/home/user/Pictures/Wallpapers"
        text: root.editWallpaperDirectory
        onTextEdited: root.editWallpaperDirectory = text
    }
    Label {
        text: "Override the wallpaper directory. Leave empty to follow the current wallpaper's directory."
        font.pixelSize: 12; opacity: 0.6; wrapMode: Text.WordWrap; Layout.fillWidth: true
    }

    SettingCombo {
        label: "Carousel Mode"
        description: "Standard stops at the edges. Wrap loops the index. Infinite shows a seamless repeating view."
        value: root.editCarouselMode
        onValueEdited: value => root.editCarouselMode = value
        options: [
            { text: "Standard", value: "standard" },
            { text: "Wrap",     value: "wrap"     },
            { text: "Infinite", value: "infinite" }
        ]
    }

    // ── Visual ────────────────────────────────────────────────────────────────
    Label { text: "Visual"; font.bold: true; font.pixelSize: 14; Layout.topMargin: 8 }

    SettingSlider {
        id: overlayInput
        rangeName: "settings-range-editOverlayOpacity"
        label: "Background Dimming"; description: "Opacity of the dark overlay behind the carousel."
        value: root.editOverlayOpacity; min: 0; max: 100; unit: "%"
        onValueEdited: value => root.editOverlayOpacity = value
    }

    SettingSlider {
        id: borderInput
        rangeName: "settings-range-editBorderWidth"
        label: "Border Width"; description: "Width of the skewed border around thumbnails."
        value: root.editBorderWidth; min: 0; max: 20; unit: "px"
        onValueEdited: value => root.editBorderWidth = value
    }

    SettingSlider {
        id: cornerInput
        rangeName: "settings-range-editCornerRadius"
        label: "Corner Radius"; description: "Corner radius of thumbnails. Set to 0 to disable."
        value: root.editCornerRadius; min: 0; max: 60; unit: "px"
        onValueEdited: value => root.editCornerRadius = value
    }

    // ── Size ──────────────────────────────────────────────────────────────────
    Label { text: "Size"; font.bold: true; font.pixelSize: 14; Layout.topMargin: 8 }

    SettingSlider {
        id: widthInput
        rangeName: "settings-range-editItemWidth"
        label: "Item Width"; description: "Width of each wallpaper thumbnail."
        value: root.editItemWidth; min: 100; max: 1000; unit: "px"
        onValueEdited: value => root.editItemWidth = value
    }

    SettingSlider {
        id: heightInput
        rangeName: "settings-range-editItemHeight"
        label: "Item Height"; description: "Height of each wallpaper thumbnail."
        value: root.editItemHeight; min: 100; max: 1440; unit: "px"
        onValueEdited: value => root.editItemHeight = value
    }

    SettingSlider {
        id: scaleInput
        rangeName: "settings-range-editSelectedScale"
        label: "Center Tile Zoom"; description: "Size of the centered tile relative to the surrounding tiles."
        value: root.editSelectedScale; min: 100; max: 150; unit: "%"
        onValueEdited: value => root.editSelectedScale = value
    }

    // ── Expansion ─────────────────────────────────────────────────────────────
    Label { text: "Expansion"; font.bold: true; font.pixelSize: 14; Layout.topMargin: 8 }

    SettingCombo {
        label: "Expand Selected"
        description: "Expand the centered tile's width to reveal more of the image."
        value: root.editExpandSelected
        onValueEdited: value => root.editExpandSelected = value
        options: [
            { text: "Disabled", value: "false" },
            { text: "Enabled",  value: "true"  }
        ]
    }

    SettingSlider {
        id: expandInput
        rangeName: "settings-range-editExpandMultiplier"
        label: "Expansion Amount"; description: "Width multiplier applied when the centered tile is expanded."
        value: root.editExpandMultiplier; min: 100; max: 300; unit: "%"
        onValueEdited: value => root.editExpandMultiplier = value
    }

    SettingCombo {
        label: "Hold to Expand"
        description: "Dwell on a tile to trigger a large immersive preview."
        value: root.editEnableHoldExpand
        onValueEdited: value => root.editEnableHoldExpand = value
        options: [
            { text: "Disabled", value: "false" },
            { text: "Enabled",  value: "true"  }
        ]
    }

    SettingSlider {
        id: coverageInput
        rangeName: "settings-range-editHoldExpandRatio"
        label: "Hold Coverage"; description: "Screen coverage for the hold preview."
        value: root.editHoldExpandRatio; min: 30; max: 100; unit: "%"
        onValueEdited: value => root.editHoldExpandRatio = value
    }

    SettingSlider {
        id: delayInput
        rangeName: "settings-range-editHoldDelay"
        label: "Hold Delay"; description: "Time to dwell on a tile before the preview activates."
        value: root.editHoldDelay; min: 200; max: 10000; unit: "ms"
        onValueEdited: value => root.editHoldDelay = value
    }

    Item { Layout.fillHeight: true }
}
