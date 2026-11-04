import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM

    property var pluginApi: null
    property var widgetSettings: null
    signal settingsChanged(var settings)

    property string valueDirection:       widgetSettings?.data?.direction             ?? "up"
    property string valueMode:            widgetSettings?.data?.mode                  ?? "bars"
    property int    valueBarCount:        widgetSettings?.data?.barCount              ?? 32
    property int    valueFps:             widgetSettings?.data?.fps                   ?? 60
    property real   valueSensitivity:     widgetSettings?.data?.sensitivity           ?? 1.5
    property real   valueSmoothing:       widgetSettings?.data?.smoothing             ?? 0.18
    property bool   valueUseGradient:     widgetSettings?.data?.useGradient           ?? true
    property bool   valueFadeWhenIdle:    widgetSettings?.data?.fadeWhenIdle          ?? true
    property bool   valueUseCustomColors: widgetSettings?.data?.useCustomColors       ?? false
    property color  valueCustomPrimary:   widgetSettings?.data?.customPrimaryColor    ?? "#6750A4"
    property color  valueCustomSecondary: widgetSettings?.data?.customSecondaryColor  ?? "#625B71"
    property int    valueCustomWidth:     widgetSettings?.data?.customWidth           ?? 0
    property int    valueCustomHeight:    widgetSettings?.data?.customHeight          ?? 0

    // ── Direction ─────────────────────────────────────────────────────────────
    NComboBox {
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("desktopWidgetSettings.direction-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.direction-description")
        model: [
            { "key": "up",    "name": "Up"    },
            { "key": "down",  "name": "Down"  },
            { "key": "left",  "name": "Left"  },
            { "key": "right", "name": "Right" }
        ]
        currentKey: root.valueDirection
        onSelected: key => {
            root.valueDirection = key
            root.saveSettings({direction: root.valueDirection})
        }
    }

    // ── Visualizer mode ───────────────────────────────────────────────────────
    NComboBox {
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("desktopWidgetSettings.mode-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.mode-description")
        model: [
            { "key": "bars",     "name": "Linear"   },
            { "key": "mirror",   "name": "Mirrored" },
            { "key": "wave",     "name": "Wave"     }
        ]
        currentKey: root.valueMode
        onSelected: key => {
            root.valueMode = key
            root.saveSettings({mode: root.valueMode})
        }
    }

    // ── Bar count (bars + mirror only) ────────────────────────────────────────
    NValueSlider {
        property int _value: root.valueBarCount
        Layout.fillWidth: true
        visible: root.valueMode !== "wave"
        label:       root.pluginApi?.tr("desktopWidgetSettings.bar-count-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.bar-count-description")
        value: _value
        text: String(_value)
        from: 8
        to: 64
        stepSize: 1
        defaultValue: 32
        onMoved: value => _value = Math.round(value)
        onPressedChanged: (pressed, value) => {
            if (!pressed) { root.valueBarCount = Math.round(value); root.saveSettings({barCount: root.valueBarCount}) }
        }
    }

    // ── Sensitivity ───────────────────────────────────────────────────────────
    NValueSlider {
        property real _value: root.valueSensitivity
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("desktopWidgetSettings.sensitivity-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.sensitivity-description")
        value: _value
        text: _value.toFixed(1) + "x"
        from: 0.5
        to: 3.0
        stepSize: 0.1
        defaultValue: 1.5
        onMoved: value => _value = value
        onPressedChanged: (pressed, value) => {
            if (!pressed) { root.valueSensitivity = value; root.saveSettings({sensitivity: root.valueSensitivity}) }
        }
    }

    // ── Smoothing ─────────────────────────────────────────────────────────────
    NValueSlider {
        property real _value: root.valueSmoothing
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("desktopWidgetSettings.smoothing-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.smoothing-description")
        value: _value
        text: Math.round(_value * 100) + "%"
        from: 0.02
        to: 0.5
        stepSize: 0.01
        defaultValue: 0.18
        onMoved: value => _value = value
        onPressedChanged: (pressed, value) => {
            if (!pressed) { root.valueSmoothing = value; root.saveSettings({smoothing: root.valueSmoothing}) }
        }
    }

    // ── FPS ───────────────────────────────────────────────────────────────────
    NComboBox {
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("desktopWidgetSettings.fps-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.fps-description")
        model: [
            { "key": "24",  "name": "24 fps"  },
            { "key": "30",  "name": "30 fps"  },
            { "key": "60",  "name": "60 fps"  },
            { "key": "120", "name": "120 fps" },
            { "key": "144", "name": "144 fps" },
            { "key": "165", "name": "165 fps" },
            { "key": "180", "name": "180 fps" },
            { "key": "240", "name": "240 fps" }
        ]
        currentKey: String(root.valueFps)
        onSelected: key => {
            root.valueFps = parseInt(key)
            root.saveSettings({fps: root.valueFps})
        }
    }

    // ── Size ──────────────────────────────────────────────────────────────────
    NValueSlider {
        property int _value: root.valueCustomWidth
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("desktopWidgetSettings.custom-width-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.custom-width-description")
        value: _value
        text: _value === 0 ? "auto" : _value + "px"
        from: 0
        to: Screen.width
        stepSize: 10
        defaultValue: 0
        onMoved: value => _value = Math.round(value)
        onPressedChanged: (pressed, value) => {
            if (!pressed) { root.valueCustomWidth = Math.round(value); root.saveSettings({customWidth: root.valueCustomWidth}) }
        }
    }

    NValueSlider {
        property int _value: root.valueCustomHeight
        Layout.fillWidth: true
        label:       root.pluginApi?.tr("desktopWidgetSettings.custom-height-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.custom-height-description")
        value: _value
        text: _value === 0 ? "auto" : _value + "px"
        from: 0
        to: Screen.height
        stepSize: 10
        defaultValue: 0
        onMoved: value => _value = Math.round(value)
        onPressedChanged: (pressed, value) => {
            if (!pressed) { root.valueCustomHeight = Math.round(value); root.saveSettings({customHeight: root.valueCustomHeight}) }
        }
    }

    // ── Toggles ───────────────────────────────────────────────────────────────
    NToggle {
        label:       root.pluginApi?.tr("desktopWidgetSettings.gradient-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.gradient-description")
        checked: root.valueUseGradient
        defaultValue: true
        onToggled: checked => {
            root.valueUseGradient = checked
            root.saveSettings({useGradient: root.valueUseGradient})
        }
    }

    NToggle {
        label:       root.pluginApi?.tr("desktopWidgetSettings.fade-idle-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.fade-idle-description")
        checked: root.valueFadeWhenIdle
        defaultValue: true
        onToggled: checked => {
            root.valueFadeWhenIdle = checked
            root.saveSettings({fadeWhenIdle: root.valueFadeWhenIdle})
        }
    }

    NToggle {
        label:       root.pluginApi?.tr("desktopWidgetSettings.custom-colors-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.custom-colors-description")
        checked: root.valueUseCustomColors
        defaultValue: false
        onToggled: checked => {
            root.valueUseCustomColors = checked
            root.saveSettings({useCustomColors: root.valueUseCustomColors})
        }
    }

    // ── Custom color pickers ──────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        visible: root.valueUseCustomColors
        spacing: Style.marginM
        NText { text: root.pluginApi?.tr("desktopWidgetSettings.primary-color-label"); Layout.fillWidth: true }
        NColorPicker {
            screen: Screen
            selectedColor: root.valueCustomPrimary
            onColorSelected: color => {
                root.valueCustomPrimary = color
                root.saveSettings({customPrimaryColor: root.valueCustomPrimary.toString()})
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.valueUseCustomColors
        spacing: Style.marginM
        NText { text: root.pluginApi?.tr("desktopWidgetSettings.secondary-color-label"); Layout.fillWidth: true }
        NColorPicker {
            screen: Screen
            selectedColor: root.valueCustomSecondary
            onColorSelected: color => {
                root.valueCustomSecondary = color
                root.saveSettings({customSecondaryColor: root.valueCustomSecondary.toString()})
            }
        }
    }

    // ── Save ──────────────────────────────────────────────────────────────────
    function saveSettings(fields) {
        if (fields)
            settingsChanged(fields);
    }
}
