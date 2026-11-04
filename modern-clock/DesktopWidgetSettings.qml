import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property var widgetSettings: null
    signal settingsChanged(var settings)
    property bool valueShowBackground: false

    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    property string pluginName: "Modern Clock"

    property bool valueColourChoice: widgetSettings?.data?.colourChoice ?? defaults.colourChoice
    property real valueTextOpacity: widgetSettings?.data?.textOpacity ?? defaults.textOpacity

    // Day
    property string valueCustomDayFont: widgetSettings?.data?.customDayFont ?? defaults.customDayFont
    property string valueDayColourChoice: widgetSettings?.data?.dayColourChoice ?? defaults.dayColourChoice
    property string valueDayColourPicker: widgetSettings?.data?.dayColourPicker ?? defaults.dayColourPicker
    property real valueDayFontSize: widgetSettings?.data?.dayFontSize ?? 1.0

    // Date
    property string valueCustomDateFont: widgetSettings?.data?.customDateFont ?? defaults.customDateFont
    property string valueDateColourChoice: widgetSettings?.data?.dateColourChoice ?? defaults.dateColourChoice
    property string valueDateColourPicker: widgetSettings?.data?.dateColourPicker ?? defaults.dateColourPicker
    property real valueDateFontSize: widgetSettings?.data?.dateFontSize ?? 1.0

    // Time
    property string valueCustomTimeFont: widgetSettings?.data?.customTimeFont ?? defaults.customTimeFont
    property string valueTimeColourChoice: widgetSettings?.data?.timeColourChoice ?? defaults.timeColourChoice
    property string valueTimeColourPicker: widgetSettings?.data?.timeColourPicker ?? defaults.timeColourPicker
    property real valueTimeFontSize: widgetSettings?.data?.timeFontSize ?? 1.0

    function saveSettings(fields) {
        if (fields)
            settingsChanged(fields);
    }

    spacing: Style.marginM
    width: 700

    Component.onCompleted: {
        Logger.i(pluginName, "Settings UI loaded");
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        // General Settings
        NHeader {
            label: pluginApi?.tr("settings.menu.header")
            visible: true
        }
        NToggle {
            checked: valueColourChoice
            defaultValue: valueColourChoice
            description: pluginApi?.tr("settings.menu.colourToggle.description")
            label: pluginApi?.tr("settings.menu.colourToggle.label")

            onToggled: checked => {
                valueColourChoice = checked;
                saveSettings({colourChoice: root.valueColourChoice});
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NLabel {
                label: pluginApi?.tr("settings.font.fontOpacity")
            }
            NValueSlider {
                from: 0
                to: 1
                value: valueTextOpacity

                onMoved: function (value) {
                    valueTextOpacity = value;
                    saveSettings({textOpacity: root.valueTextOpacity});
                }
            }
        }

        // End General Settings

        NDivider {
            Layout.fillWidth: true
            visible: true
        }

        // Day Settings
        NHeader {
            label: pluginApi?.tr("settings.font.day.header")
            visible: true
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            visible: !valueColourChoice

            NLabel {
                description: pluginApi?.tr("settings.font.day.colour.description")
                label: pluginApi?.tr("settings.font.day.colour.label")
            }
            NColorPicker {
                Layout.preferredHeight: Style.baseWidgetSize
                Layout.preferredWidth: Style.sliderWidth
                selectedColor: valueDayColourPicker

                onColorSelected: function (color) {
                    valueDayColourPicker = color;
                    saveSettings({dayColourPicker: root.valueDayColourPicker.toUpperCase()});
                }
            }
        }
        NColorChoice {
            currentKey: valueDayColourChoice
            defaultValue: widgetSettings?.data?.dayColourChoice
            description: pluginApi?.tr("settings.font.day.colour.description")
            label: pluginApi?.tr("settings.font.day.colour.label")
            visible: valueColourChoice

            onSelected: function (color) {
                valueDayColourChoice = color;
                saveSettings({dayColourChoice: root.valueDayColourChoice});
            }
        }
        NSearchableComboBox {
            Layout.fillWidth: true
            currentKey: valueCustomDayFont
            description: I18n.tr("bar.clock.custom-font-description")
            label: I18n.tr("bar.clock.custom-font-label")
            minimumWidth: 300
            model: FontService.availableFonts
            placeholder: I18n.tr("bar.clock.custom-font-placeholder")
            popupHeight: 420
            searchPlaceholder: I18n.tr("bar.clock.custom-font-search-placeholder")
            visible: true

            onSelected: function (key) {
                valueCustomDayFont = key;
                saveSettings({customDayFont: root.valueCustomDayFont});
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NLabel {
                label: I18n.tr("panels.bar.appearance-font-scale-label") + ": " + valueDayFontSize.toFixed(1)
            }
            NValueSlider {
                from: 0.1
                to: 10
                value: valueDayFontSize
                stepSize: 0.1

                onMoved: function (value) {
                    valueDayFontSize = value;
                    saveSettings({dayFontSize: root.valueDayFontSize});
                }
            }
        }

        // End Day Settings

        NDivider {
            Layout.fillWidth: true
            visible: true
        }

        // Date Settings
        NHeader {
            label: pluginApi?.tr("settings.font.date.header")
            visible: true
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            visible: !valueColourChoice

            NLabel {
                description: pluginApi?.tr("settings.font.date.colour.description")
                label: pluginApi?.tr("settings.font.date.colour.label")
            }
            NColorPicker {
                Layout.preferredHeight: Style.baseWidgetSize
                Layout.preferredWidth: Style.sliderWidth
                selectedColor: valueDateColourPicker

                onColorSelected: function (color) {
                    valueDateColourPicker = color;
                    saveSettings({dateColourPicker: root.valueDateColourPicker.toUpperCase()});
                }
            }
        }
        NColorChoice {
            currentKey: valueDateColourChoice
            defaultValue: widgetSettings?.data?.dateColourChoice
            description: pluginApi?.tr("settings.font.day.colour.description")
            label: pluginApi?.tr("settings.font.day.colour.label")
            visible: valueColourChoice

            onSelected: function (color) {
                valueDateColourChoice = color;
                saveSettings({dateColourChoice: root.valueDateColourChoice});
            }
        }
        NSearchableComboBox {
            Layout.fillWidth: true
            currentKey: valueCustomDateFont
            description: I18n.tr("bar.clock.custom-font-description")
            label: I18n.tr("bar.clock.custom-font-label")
            minimumWidth: 300
            model: FontService.availableFonts
            placeholder: I18n.tr("bar.clock.custom-font-placeholder")
            popupHeight: 420
            searchPlaceholder: I18n.tr("bar.clock.custom-font-search-placeholder")
            visible: true

            onSelected: function (key) {
                valueCustomDateFont = key;
                saveSettings({customDateFont: root.valueCustomDateFont});
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NLabel {
                label: I18n.tr("panels.bar.appearance-font-scale-label") + ": " + valueDateFontSize.toFixed(1)
            }
            NValueSlider {
                from: 0.1
                to: 10
                value: valueDateFontSize
                stepSize: 0.1

                onMoved: function (value) {
                    valueDateFontSize = value;
                    saveSettings({dateFontSize: root.valueDateFontSize});
                }
            }
        }

        // End Date Settings

        NDivider {
            Layout.fillWidth: true
            visible: true
        }

        // Time Settings
        NHeader {
            label: pluginApi?.tr("settings.font.time.header")
            visible: true
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            visible: !valueColourChoice

            NLabel {
                description: pluginApi?.tr("settings.font.time.colour.description")
                label: pluginApi?.tr("settings.font.time.colour.label")
            }
            NColorPicker {
                Layout.preferredHeight: Style.baseWidgetSize
                Layout.preferredWidth: Style.sliderWidth
                selectedColor: valueTimeColourPicker

                onColorSelected: function (color) {
                    valueTimeColourPicker = color;
                    saveSettings({timeColourPicker: root.valueTimeColourPicker.toUpperCase()});
                }
            }
        }
        NColorChoice {
            currentKey: valueTimeColourChoice
            defaultValue: widgetSettings?.data?.timeColourChoice
            description: pluginApi?.tr("settings.font.day.colour.description")
            label: pluginApi?.tr("settings.font.day.colour.label")
            visible: valueColourChoice

            onSelected: function (color) {
                valueTimeColourChoice = color;
                saveSettings({timeColourChoice: root.valueTimeColourChoice});
            }
        }
        NSearchableComboBox {
            Layout.fillWidth: true
            currentKey: valueCustomTimeFont
            description: I18n.tr("bar.clock.custom-font-description")
            label: I18n.tr("bar.clock.custom-font-label")
            minimumWidth: 300
            model: FontService.availableFonts
            placeholder: I18n.tr("bar.clock.custom-font-placeholder")
            popupHeight: 420
            searchPlaceholder: I18n.tr("bar.clock.custom-font-search-placeholder")
            visible: true

            onSelected: function (key) {
                valueCustomTimeFont = key;
                saveSettings({customTimeFont: root.valueCustomTimeFont});
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NLabel {
                label: I18n.tr("panels.bar.appearance-font-scale-label") + ": " + valueTimeFontSize.toFixed(1)
            }
            NValueSlider {
                from: 0.1
                to: 10
                value: valueTimeFontSize
                stepSize: 0.1

                onMoved: function (value) {
                    valueTimeFontSize = value;
                    saveSettings({timeFontSize: root.valueTimeFontSize});
                }
            }
        }

        // End Time Settings
    }
}
