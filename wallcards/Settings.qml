import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  readonly property int editAnimationCardsDuration: root.animation_cards_durationField?.value
  readonly property int editAnimationWindowDuration: root.animation_window_durationField?.value
  readonly property color editBackgroundColor: root.background_colorField?.value
  readonly property real editBackgroundOpacity: root.background_opacityField?.value
  readonly property int editCardHeight: root.card_heightField?.value
  readonly property int editCardSpacing: root.card_spacingField?.value
  readonly property int editCardStripWidth: root.card_strip_widthField?.value
  readonly property int editCardsShown: root.cards_shownField?.value
  readonly property real editCenterWidthRatio: root.center_width_ratioField?.value
  readonly property bool editHideHelp: root.hide_helpField?.value
  readonly property bool editHideTopBar: root.hide_top_barField?.value ?? false
  readonly property bool editAnimateWindow: root.animate_windowField?.value ?? true
  readonly property string editIconColor: root.iconColorField?.value ?? "none"
  readonly property bool editLivePreview: root.live_previewField?.value
  readonly property string editSelectedFilter: root.selected_filterField?.value
  readonly property real editShearFactor: root.shear_factorField?.value
  readonly property int editTopBarHeight: root.top_bar_heightField?.value
  property var pluginApi: null
  readonly property var animation_cards_durationField: pluginApi?.field("animation_cards_duration") ?? null
  readonly property var animation_window_durationField: pluginApi?.field("animation_window_duration") ?? null
  readonly property var background_colorField: pluginApi?.field("background_color") ?? null
  readonly property var background_opacityField: pluginApi?.field("background_opacity") ?? null
  readonly property var center_width_ratioField: pluginApi?.field("center_width_ratio") ?? null
  readonly property var card_heightField: pluginApi?.field("card_height") ?? null
  readonly property var card_spacingField: pluginApi?.field("card_spacing") ?? null
  readonly property var card_strip_widthField: pluginApi?.field("card_strip_width") ?? null
  readonly property var cards_shownField: pluginApi?.field("cards_shown") ?? null
  readonly property var shear_factorField: pluginApi?.field("shear_factor") ?? null
  readonly property var top_bar_heightField: pluginApi?.field("top_bar_height") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null
  readonly property var selected_filterField: pluginApi?.field("selected_filter") ?? null
  readonly property var live_previewField: pluginApi?.field("live_preview") ?? null
  readonly property var hide_helpField: pluginApi?.field("hide_help") ?? null
  readonly property var hide_top_barField: pluginApi?.field("hide_top_bar") ?? null
  readonly property var animate_windowField: pluginApi?.field("animate_window") ?? null

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi || !pluginApi.pluginSettings) {
      Logger.e("Wallcards", "Cannot save: pluginApi or pluginSettings is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("Wallcards", "Settings saved");
    });
  }

  Layout.rightMargin: Style.marginL
  spacing: Style.marginL

  // ── Icon ──
  NPluginSettingsField {
    field: root.iconColorField
    NComboBox {
      currentKey: root.editIconColor
      description: I18n.tr("common.select-color-description")
      label: I18n.tr("common.select-icon-color")
      minimumWidth: 200
      model: AtmoColor.colorKeyModel

      onSelected: key => root.iconColorField.set(key)
    }
  }
  NDivider {
    Layout.fillWidth: true
  }

  // ── Behavior ──
  NPluginSettingsField {
    field: root.live_previewField
    NToggle {
      checked: root.editLivePreview
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.live_preview ?? false
      description: root.pluginApi?.tr("settings.live-preview.description")
      label: root.pluginApi?.tr("settings.live-preview.label")

      onToggled: c => root.live_previewField.set(c)
    }
  }
  NPluginSettingsField {
    field: root.selected_filterField
    NComboBox {
      currentKey: root.editSelectedFilter
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.selected_filter || "all"
      description: root.pluginApi?.tr("settings.default-filter.description")
      label: root.pluginApi?.tr("settings.default-filter.label")
      model: [
        {
          "key": "all",
          "name": root.pluginApi?.tr("buttons.all")
        },
        {
          "key": "images",
          "name": root.pluginApi?.tr("buttons.images")
        },
        {
          "key": "videos",
          "name": root.pluginApi?.tr("buttons.videos")
        }
      ]

      onSelected: key => root.selected_filterField.set(key)
    }
  }
  NPluginSettingsField {
    field: root.hide_helpField
    NToggle {
      checked: root.editHideHelp
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.hide_help ?? false
      description: root.pluginApi?.tr("settings.hide-shortcuts.description")
      label: root.pluginApi?.tr("settings.hide-shortcuts.label")

      onToggled: c => root.hide_helpField.set(c)
    }
  }
  NPluginSettingsField {
    field: root.hide_top_barField
    NToggle {
      checked: root.editHideTopBar
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.hide_top_bar ?? false
      description: root.pluginApi?.tr("settings.hide-top-bar.description")
      label: root.pluginApi?.tr("settings.hide-top-bar.label")

      onToggled: c => root.hide_top_barField.set(c)
    }
  }
  NDivider {
    Layout.fillWidth: true
  }

  // ── Card Layout ──
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.center-card-width.description")
      label: root.pluginApi?.tr("settings.center-card-width.label")
    }
    NPluginSettingsField {
      field: root.center_width_ratioField
      NValueSlider {
        id: rangeEditCenterWidthRatio
        objectName: "settings-range-editCenterWidthRatio"
        Layout.fillWidth: true
        from: 0.20
        stepSize: 0.01
        text: (root.editCenterWidthRatio * 100).toFixed(0) + "%"
        to: 0.60
        value: root.editCenterWidthRatio

        onMoved: value => root.center_width_ratioField.set(value)
      }
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.card-height.description")
      label: root.pluginApi?.tr("settings.card-height.label")
    }
    NPluginSettingsField {
      field: root.card_heightField
      NValueSlider {
        id: rangeEditCardHeight
        objectName: "settings-range-editCardHeight"
        Layout.fillWidth: true
        from: 100
        stepSize: 10
        text: root.editCardHeight + "px"
        to: 800
        value: root.editCardHeight

        onMoved: value => root.card_heightField.set(value)
      }
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.strip-width.description")
      label: root.pluginApi?.tr("settings.strip-width.label")
    }
    NPluginSettingsField {
      field: root.card_strip_widthField
      NValueSlider {
        id: rangeEditCardStripWidth
        objectName: "settings-range-editCardStripWidth"
        Layout.fillWidth: true
        from: 20
        stepSize: 5
        text: root.editCardStripWidth + "px"
        to: 150
        value: root.editCardStripWidth

        onMoved: value => root.card_strip_widthField.set(value)
      }
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.card-spacing.description")
      label: root.pluginApi?.tr("settings.card-spacing.label")
    }
    NPluginSettingsField {
      field: root.card_spacingField
      NValueSlider {
        id: rangeEditCardSpacing
        objectName: "settings-range-editCardSpacing"
        Layout.fillWidth: true
        from: 0
        stepSize: 1
        text: root.editCardSpacing + "px"
        to: 50
        value: root.editCardSpacing

        onMoved: value => root.card_spacingField.set(value)
      }
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.cards-shown.description")
      label: root.pluginApi?.tr("settings.cards-shown.label")
    }
    NPluginSettingsField {
      field: root.cards_shownField
      NValueSlider {
        id: rangeEditCardsShown
        objectName: "settings-range-editCardsShown"
        Layout.fillWidth: true
        from: 5
        stepSize: 2
        text: root.editCardsShown
        to: 15
        value: root.editCardsShown

        onMoved: value => root.cards_shownField.set(value)
      }
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXXS

      NLabel {
        description: root.pluginApi?.tr("settings.shear-factor.description")
        label: root.pluginApi?.tr("settings.shear-factor.label")
      }
      NPluginSettingsField {
        field: root.shear_factorField
        NValueSlider {
          id: rangeEditShearFactor
          objectName: "settings-range-editShearFactor"
          Layout.fillWidth: true
          from: -0.3
          stepSize: 0.01
          text: root.editShearFactor.toFixed(2)
          to: 0.3
          value: root.editShearFactor

          onMoved: value => root.shear_factorField.set(value)
        }
      }
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.card-animation.description")
      label: root.pluginApi?.tr("settings.card-animation.label")
    }
    NPluginSettingsField {
      field: root.animation_cards_durationField
      NValueSlider {
        id: rangeEditAnimationCardsDuration
        objectName: "settings-range-editAnimationCardsDuration"
        Layout.fillWidth: true
        from: 0
        stepSize: 100
        text: root.editAnimationCardsDuration + "ms"
        to: 1500
        value: root.editAnimationCardsDuration

        onMoved: value => root.animation_cards_durationField.set(value)
      }
    }
  }
  NDivider {
    Layout.fillWidth: true
  }

  // ── Appearance ──
  RowLayout {
    NLabel {
      Layout.alignment: Qt.AlignTop
      description: root.pluginApi?.tr("settings.background-color.description")
      label: root.pluginApi?.tr("settings.background-color.label")
    }
    NPluginSettingsField {
      field: root.background_colorField
      NColorPicker {
        selectedColor: root.editBackgroundColor

        onColorSelected: color => root.background_colorField.set(color.toString())
      }
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.background-opacity.description")
      label: root.pluginApi?.tr("settings.background-opacity.label")
    }
    NPluginSettingsField {
      field: root.background_opacityField
      NValueSlider {
        id: rangeEditBackgroundOpacity
        objectName: "settings-range-editBackgroundOpacity"
        Layout.fillWidth: true
        from: 0
        stepSize: 0.05
        text: (root.editBackgroundOpacity * 100).toFixed(0) + "%"
        to: 1
        value: root.editBackgroundOpacity

        onMoved: value => root.background_opacityField.set(value)
      }
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.window-animation-speed.description")
      label: root.pluginApi?.tr("settings.window-animation-speed.label")
    }
    NPluginSettingsField {
      field: root.animation_window_durationField
      NValueSlider {
        id: rangeEditAnimationWindowDuration
        objectName: "settings-range-editAnimationWindowDuration"
        Layout.fillWidth: true
        from: 0
        stepSize: 100
        text: root.editAnimationWindowDuration + "ms"
        to: 1500
        value: root.editAnimationWindowDuration

        onMoved: value => root.animation_window_durationField.set(value)
      }
    }
  }
  NPluginSettingsField {
    field: root.animate_windowField
    NToggle {
      checked: root.editAnimateWindow
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.animate_window ?? true
      description: root.pluginApi?.tr("settings.animate-window.description")
      label: root.pluginApi?.tr("settings.animate-window.label")

      onToggled: c => root.animate_windowField.set(c)
    }
  }
  NDivider {
    Layout.fillWidth: true
  }

  // ── Top Bar ──
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.top-bar-height.description")
      label: root.pluginApi?.tr("settings.top-bar-height.label")
    }
    NPluginSettingsField {
      field: root.top_bar_heightField
      NValueSlider {
        id: rangeEditTopBarHeight
        objectName: "settings-range-editTopBarHeight"
        Layout.fillWidth: true
        from: 10
        stepSize: 2
        text: root.editTopBarHeight + "px"
        to: 80
        value: root.editTopBarHeight

        onMoved: value => root.top_bar_heightField.set(value)
      }
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS
  }
}
