import qs.Commons
import qs.Widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
  id: root

  property int editAnimationCardsDuration: displayBaseline.project("editAnimationCardsDuration")
  property int editAnimationDuration: pluginApi?.pluginSettings?.animation_duration ?? pluginApi?.manifest?.metadata?.defaultSettings?.animation_window_duration
  property int editAnimationWindowDuration: displayBaseline.project("editAnimationWindowDuration")
  property color editBackgroundColor: displayBaseline.editBackgroundColor
  property real editBackgroundOpacity: displayBaseline.project("editBackgroundOpacity")
  property int editCardHeight: displayBaseline.project("editCardHeight")
  property int editCardSpacing: displayBaseline.project("editCardSpacing")
  property int editCardStripWidth: displayBaseline.project("editCardStripWidth")
  property int editCardsShown: displayBaseline.project("editCardsShown")
  property real editCenterWidthRatio: displayBaseline.project("editCenterWidthRatio")
  property bool editHideHelp: displayBaseline.editHideHelp
  property bool editHideTopBar: displayBaseline.editHideTopBar
  property bool editAnimateWindow: displayBaseline.editAnimateWindow
  property string editIconColor: displayBaseline.editIconColor
  property bool editLivePreview: displayBaseline.editLivePreview
  property string editSelectedFilter: displayBaseline.editSelectedFilter
  property real editShearFactor: displayBaseline.project("editShearFactor")
  property int editTopBarHeight: displayBaseline.project("editTopBarHeight")
  property var pluginApi: null

  NSettingsBaseline {
    ranges: [
      NSettingsRange { field: "editCenterWidthRatio"; from: rangeEditCenterWidthRatio.from; to: rangeEditCenterWidthRatio.to },
      NSettingsRange { field: "editCardHeight"; from: rangeEditCardHeight.from; to: rangeEditCardHeight.to },
      NSettingsRange { field: "editCardStripWidth"; from: rangeEditCardStripWidth.from; to: rangeEditCardStripWidth.to },
      NSettingsRange { field: "editCardSpacing"; from: rangeEditCardSpacing.from; to: rangeEditCardSpacing.to },
      NSettingsRange { field: "editCardsShown"; from: rangeEditCardsShown.from; to: rangeEditCardsShown.to },
      NSettingsRange { field: "editShearFactor"; from: rangeEditShearFactor.from; to: rangeEditShearFactor.to },
      NSettingsRange { field: "editAnimationCardsDuration"; from: rangeEditAnimationCardsDuration.from; to: rangeEditAnimationCardsDuration.to },
      NSettingsRange { field: "editBackgroundOpacity"; from: rangeEditBackgroundOpacity.from; to: rangeEditBackgroundOpacity.to },
      NSettingsRange { field: "editAnimationWindowDuration"; from: rangeEditAnimationWindowDuration.from; to: rangeEditAnimationWindowDuration.to },
      NSettingsRange { field: "editTopBarHeight"; from: rangeEditTopBarHeight.from; to: rangeEditTopBarHeight.to }
    ]
    id: displayBaseline
    readonly property int editAnimationCardsDuration: pluginApi?.pluginSettings?.animation_cards_duration ?? pluginApi?.manifest?.metadata?.defaultSettings?.animation_cards_duration
    readonly property int editAnimationWindowDuration: pluginApi?.pluginSettings?.animation_window_duration ?? pluginApi?.manifest?.metadata?.defaultSettings?.animation_window_duration
    readonly property color editBackgroundColor: pluginApi?.pluginSettings?.background_color ?? pluginApi?.manifest?.metadata?.defaultSettings?.background_color
    readonly property real editBackgroundOpacity: pluginApi?.pluginSettings?.background_opacity ?? pluginApi?.manifest?.metadata?.defaultSettings?.background_opacity
    readonly property real editCenterWidthRatio: pluginApi?.pluginSettings?.center_width_ratio ?? pluginApi?.manifest?.metadata?.defaultSettings?.center_width_ratio
    readonly property int editCardHeight: pluginApi?.pluginSettings?.card_height ?? pluginApi?.manifest?.metadata?.defaultSettings?.card_height
    readonly property int editCardSpacing: pluginApi?.pluginSettings?.card_spacing ?? pluginApi?.manifest?.metadata?.defaultSettings?.card_spacing
    readonly property int editCardStripWidth: pluginApi?.pluginSettings?.card_strip_width ?? pluginApi?.manifest?.metadata?.defaultSettings?.card_strip_width
    readonly property int editCardsShown: pluginApi?.pluginSettings?.cards_shown ?? pluginApi?.manifest?.metadata?.defaultSettings?.cards_shown
    readonly property real editShearFactor: pluginApi?.pluginSettings?.shear_factor ?? pluginApi?.manifest?.metadata?.defaultSettings?.shear_factor
    readonly property int editTopBarHeight: pluginApi?.pluginSettings?.top_bar_height ?? pluginApi?.manifest?.metadata?.defaultSettings?.top_bar_height
    readonly property string editIconColor: pluginApi?.pluginSettings?.iconColor ?? pluginApi?.pluginSettings?.icon_color ?? "none"
    readonly property string editSelectedFilter: pluginApi?.pluginSettings?.selected_filter || pluginApi?.manifest?.metadata?.defaultSettings?.selected_filter
    readonly property bool editLivePreview: pluginApi?.pluginSettings?.live_preview ?? pluginApi?.manifest?.metadata?.defaultSettings?.live_preview
    readonly property bool editHideHelp: pluginApi?.pluginSettings?.hide_help ?? pluginApi?.manifest?.metadata?.defaultSettings?.hide_help
    readonly property bool editHideTopBar: pluginApi?.pluginSettings?.hide_top_bar ?? pluginApi?.manifest?.metadata?.defaultSettings?.hide_top_bar ?? false
    readonly property bool editAnimateWindow: pluginApi?.pluginSettings?.animate_window ?? pluginApi?.manifest?.metadata?.defaultSettings?.animate_window ?? true
  }
  readonly property bool settingsDirty: displayBaseline.differs({editAnimationCardsDuration: root.editAnimationCardsDuration, editAnimationWindowDuration: root.editAnimationWindowDuration, editBackgroundColor: root.editBackgroundColor, editBackgroundOpacity: root.editBackgroundOpacity, editCenterWidthRatio: root.editCenterWidthRatio, editCardHeight: root.editCardHeight, editCardSpacing: root.editCardSpacing, editCardStripWidth: root.editCardStripWidth, editCardsShown: root.editCardsShown, editShearFactor: root.editShearFactor, editTopBarHeight: root.editTopBarHeight, editIconColor: root.editIconColor, editSelectedFilter: root.editSelectedFilter, editLivePreview: root.editLivePreview, editHideHelp: root.editHideHelp, editHideTopBar: root.editHideTopBar, editAnimateWindow: root.editAnimateWindow})

  function saveSettings() {
    if (!pluginApi || !pluginApi.pluginSettings) {
      Logger.e("Wallcards", "Cannot save: pluginApi or pluginSettings is null");
      return;
    }

    pluginApi.pluginSettings.animation_cards_duration = root.editAnimationCardsDuration;
    pluginApi.pluginSettings.animation_window_duration = root.editAnimationWindowDuration;
    pluginApi.pluginSettings.background_color = root.editBackgroundColor.toString();
    pluginApi.pluginSettings.background_opacity = root.editBackgroundOpacity;

    pluginApi.pluginSettings.center_width_ratio = root.editCenterWidthRatio;
    pluginApi.pluginSettings.card_height = root.editCardHeight;
    pluginApi.pluginSettings.card_spacing = root.editCardSpacing;
    pluginApi.pluginSettings.card_strip_width = root.editCardStripWidth;
    pluginApi.pluginSettings.cards_shown = root.editCardsShown;

    pluginApi.pluginSettings.shear_factor = root.editShearFactor;

    pluginApi.pluginSettings.top_bar_height = root.editTopBarHeight;

    pluginApi.pluginSettings.iconColor = root.editIconColor;
    pluginApi.pluginSettings.selected_filter = root.editSelectedFilter;
    pluginApi.pluginSettings.live_preview = root.editLivePreview;
    pluginApi.pluginSettings.hide_help = root.editHideHelp;
    pluginApi.pluginSettings.hide_top_bar = root.editHideTopBar;
    pluginApi.pluginSettings.animate_window = root.editAnimateWindow;

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("Wallcards", "Settings saved");
    });
  }

  Layout.rightMargin: Style.marginL
  spacing: Style.marginL

  // ── Icon ──
  NComboBox {
    currentKey: root.editIconColor
    description: I18n.tr("common.select-color-description")
    label: I18n.tr("common.select-icon-color")
    minimumWidth: 200
    model: AtmoColor.colorKeyModel

    onSelected: key => root.editIconColor = key
  }
  NDivider {
    Layout.fillWidth: true
  }

  // ── Behavior ──
  NToggle {
    checked: root.editLivePreview
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.live_preview ?? false
    description: root.pluginApi?.tr("settings.live-preview.description")
    label: root.pluginApi?.tr("settings.live-preview.label")

    onToggled: c => root.editLivePreview = c
  }
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

    onSelected: key => root.editSelectedFilter = key
  }
  NToggle {
    checked: root.editHideHelp
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.hide_help ?? false
    description: root.pluginApi?.tr("settings.hide-shortcuts.description")
    label: root.pluginApi?.tr("settings.hide-shortcuts.label")

    onToggled: c => root.editHideHelp = c
  }
  NToggle {
    checked: root.editHideTopBar
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.hide_top_bar ?? false
    description: root.pluginApi?.tr("settings.hide-top-bar.description")
    label: root.pluginApi?.tr("settings.hide-top-bar.label")

    onToggled: c => root.editHideTopBar = c
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
    NValueSlider {
      id: rangeEditCenterWidthRatio
      objectName: "settings-range-editCenterWidthRatio"
      onValueChanged: root.editCenterWidthRatio = value
      Layout.fillWidth: true
      from: 0.20
      stepSize: 0.01
      text: (root.editCenterWidthRatio * 100).toFixed(0) + "%"
      to: 0.60
      value: root.editCenterWidthRatio

      onMoved: value => root.editCenterWidthRatio = value
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.card-height.description")
      label: root.pluginApi?.tr("settings.card-height.label")
    }
    NValueSlider {
      id: rangeEditCardHeight
      objectName: "settings-range-editCardHeight"
      onValueChanged: root.editCardHeight = value
      Layout.fillWidth: true
      from: 100
      stepSize: 10
      text: root.editCardHeight + "px"
      to: 800
      value: root.editCardHeight

      onMoved: value => root.editCardHeight = value
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.strip-width.description")
      label: root.pluginApi?.tr("settings.strip-width.label")
    }
    NValueSlider {
      id: rangeEditCardStripWidth
      objectName: "settings-range-editCardStripWidth"
      onValueChanged: root.editCardStripWidth = value
      Layout.fillWidth: true
      from: 20
      stepSize: 5
      text: root.editCardStripWidth + "px"
      to: 150
      value: root.editCardStripWidth

      onMoved: value => root.editCardStripWidth = value
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.card-spacing.description")
      label: root.pluginApi?.tr("settings.card-spacing.label")
    }
    NValueSlider {
      id: rangeEditCardSpacing
      objectName: "settings-range-editCardSpacing"
      onValueChanged: root.editCardSpacing = value
      Layout.fillWidth: true
      from: 0
      stepSize: 1
      text: root.editCardSpacing + "px"
      to: 50
      value: root.editCardSpacing

      onMoved: value => root.editCardSpacing = value
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.cards-shown.description")
      label: root.pluginApi?.tr("settings.cards-shown.label")
    }
    NValueSlider {
      id: rangeEditCardsShown
      objectName: "settings-range-editCardsShown"
      onValueChanged: root.editCardsShown = value
      Layout.fillWidth: true
      from: 5
      stepSize: 2
      text: root.editCardsShown
      to: 15
      value: root.editCardsShown

      onMoved: value => root.editCardsShown = value
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
      NValueSlider {
        id: rangeEditShearFactor
        objectName: "settings-range-editShearFactor"
        onValueChanged: root.editShearFactor = value
        Layout.fillWidth: true
        from: -0.3
        stepSize: 0.01
        text: root.editShearFactor.toFixed(2)
        to: 0.3
        value: root.editShearFactor

        onMoved: value => root.editShearFactor = value
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
    NValueSlider {
      id: rangeEditAnimationCardsDuration
      objectName: "settings-range-editAnimationCardsDuration"
      onValueChanged: root.editAnimationCardsDuration = value
      Layout.fillWidth: true
      from: 0
      stepSize: 100
      text: root.editAnimationCardsDuration + "ms"
      to: 1500
      value: root.editAnimationCardsDuration

      onMoved: value => root.editAnimationCardsDuration = value
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
    NColorPicker {
      selectedColor: root.editBackgroundColor

      onColorSelected: color => root.editBackgroundColor = color
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.background-opacity.description")
      label: root.pluginApi?.tr("settings.background-opacity.label")
    }
    NValueSlider {
      id: rangeEditBackgroundOpacity
      objectName: "settings-range-editBackgroundOpacity"
      onValueChanged: root.editBackgroundOpacity = value
      Layout.fillWidth: true
      from: 0
      stepSize: 0.05
      text: (root.editBackgroundOpacity * 100).toFixed(0) + "%"
      to: 1
      value: root.editBackgroundOpacity

      onMoved: value => root.editBackgroundOpacity = value
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      description: root.pluginApi?.tr("settings.window-animation-speed.description")
      label: root.pluginApi?.tr("settings.window-animation-speed.label")
    }
    NValueSlider {
      id: rangeEditAnimationWindowDuration
      objectName: "settings-range-editAnimationWindowDuration"
      onValueChanged: root.editAnimationWindowDuration = value
      Layout.fillWidth: true
      from: 0
      stepSize: 100
      text: root.editAnimationWindowDuration + "ms"
      to: 1500
      value: root.editAnimationWindowDuration

      onMoved: value => root.editAnimationWindowDuration = value
    }
  }
  NToggle {
    checked: root.editAnimateWindow
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.animate_window ?? true
    description: root.pluginApi?.tr("settings.animate-window.description")
    label: root.pluginApi?.tr("settings.animate-window.label")

    onToggled: c => root.editAnimateWindow = c
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
    NValueSlider {
      id: rangeEditTopBarHeight
      objectName: "settings-range-editTopBarHeight"
      onValueChanged: root.editTopBarHeight = value
      Layout.fillWidth: true
      from: 10
      stepSize: 2
      text: root.editTopBarHeight + "px"
      to: 80
      value: root.editTopBarHeight

      onMoved: value => root.editTopBarHeight = value
    }
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS
  }
}
