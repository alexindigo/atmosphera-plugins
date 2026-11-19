import qs.Commons
import qs.Widgets
import qs.Services.System
import QtQuick
import QtQuick as Quick
import QtQuick.Layouts

ColumnLayout {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // ── Options ──

  readonly property var slotOptions: [
    {
      key: "txIcon",
      name: pluginApi?.tr("settings.slot.txIcon")
    },
    {
      key: "rxIcon",
      name: pluginApi?.tr("settings.slot.rxIcon")
    },
    {
      key: "txSpeed",
      name: pluginApi?.tr("settings.slot.txSpeed")
    },
    {
      key: "rxSpeed",
      name: pluginApi?.tr("settings.slot.rxSpeed")
    },
    {
      key: "none",
      name: pluginApi?.tr("settings.slot.none")
    }
  ]

  readonly property var layoutOptions: [
    {
      key: "horizontal",
      name: pluginApi?.tr("settings.layout.horizontal")
    },
    {
      key: "vertical",
      name: pluginApi?.tr("settings.layout.vertical")
    }
  ]

  readonly property var iconNames: ["arrow", "arrow-bar", "arrow-big", "arrow-narrow", "caret", "chevron", "chevron-compact", "fold"]

  // ── Edit state ──

  property string editLayout: displayBaseline.editLayout
  property var editSlots: displayBaseline.editSlots
  property string editIconType: displayBaseline.editIconType
  property int editByteThresholdActive: displayBaseline.editByteThresholdActive
  property real editFontSizeModifier: displayBaseline.project("editFontSizeModifier")
  property real editIconSizeModifier: displayBaseline.project("editIconSizeModifier")
  property real editPaddingLeft: displayBaseline.editPaddingLeft
  property real editPaddingRight: displayBaseline.editPaddingRight
  property real editColumnSpacing: displayBaseline.editColumnSpacing
  property real editRowSpacing: displayBaseline.editRowSpacing
  property bool editUseCustomFont: displayBaseline.editUseCustomFont
  property string editCustomFontFamily: displayBaseline.editCustomFontFamily
  property bool editCustomFontBold: displayBaseline.editCustomFontBold
  property bool editCustomFontItalic: displayBaseline.editCustomFontItalic
  property bool editUseCustomColors: displayBaseline.editUseCustomColors
  property color editColorTx: displayBaseline.editColorTx
  property color editColorRx: displayBaseline.editColorRx
  property color editColorSilent: displayBaseline.editColorSilent
  property color editColorText: displayBaseline.editColorText

  NSettingsBaseline {
    ranges: [NSettingsRange { field: "editFontSizeModifier"; from: rangeEditFontSizeModifier.from; to: rangeEditFontSizeModifier.to }, NSettingsRange { field: "editIconSizeModifier"; from: rangeEditIconSizeModifier.from; to: rangeEditIconSizeModifier.to }]
    id: displayBaseline
    readonly property string editLayout: cfg.layout ?? defaults.layout
    readonly property var editSlots: cfg.slots ?? defaults.slots
    readonly property string editIconType: cfg.iconType ?? defaults.iconType
    readonly property int editByteThresholdActive: cfg.byteThresholdActive ?? defaults.byteThresholdActive
    readonly property real editFontSizeModifier: cfg.fontSizeModifier ?? defaults.fontSizeModifier
    readonly property real editIconSizeModifier: cfg.iconSizeModifier ?? defaults.iconSizeModifier
    readonly property real editPaddingLeft: cfg.paddingLeft ?? defaults.paddingLeft
    readonly property real editPaddingRight: cfg.paddingRight ?? defaults.paddingRight
    readonly property real editColumnSpacing: cfg.columnSpacing ?? defaults.columnSpacing
    readonly property real editRowSpacing: cfg.rowSpacing ?? defaults.rowSpacing
    readonly property bool editUseCustomFont: cfg.useCustomFont ?? defaults.useCustomFont
    readonly property string editCustomFontFamily: cfg.customFontFamily ?? defaults.customFontFamily
    readonly property bool editCustomFontBold: cfg.customFontBold ?? defaults.customFontBold
    readonly property bool editCustomFontItalic: cfg.customFontItalic ?? defaults.customFontItalic
    readonly property bool editUseCustomColors: cfg.useCustomColors ?? defaults.useCustomColors
    readonly property color editColorTx: root.editUseCustomColors && cfg.colorTx || AtmoColor.mSecondary
    readonly property color editColorRx: root.editUseCustomColors && cfg.colorRx || AtmoColor.mPrimary
    readonly property color editColorSilent: root.editUseCustomColors && cfg.colorSilent || AtmoColor.mSurfaceVariant
    readonly property color editColorText: root.editUseCustomColors && cfg.colorText || AtmoColor.mOnSurfaceVariant
  }
  readonly property bool settingsDirty: displayBaseline.differs({editLayout: root.editLayout, editSlots: root.editSlots, editIconType: root.editIconType, editByteThresholdActive: root.editByteThresholdActive, editFontSizeModifier: root.editFontSizeModifier, editIconSizeModifier: root.editIconSizeModifier, editPaddingLeft: root.editPaddingLeft, editPaddingRight: root.editPaddingRight, editColumnSpacing: root.editColumnSpacing, editRowSpacing: root.editRowSpacing, editUseCustomFont: root.editUseCustomFont, editCustomFontFamily: root.editCustomFontFamily, editCustomFontBold: root.editCustomFontBold, editCustomFontItalic: root.editCustomFontItalic, editUseCustomColors: root.editUseCustomColors, editColorTx: root.editColorTx, editColorRx: root.editColorRx, editColorSilent: root.editColorSilent, editColorText: root.editColorText})

  // ── Helpers ──

  readonly property bool isVerticalLayout: editLayout === "vertical"

  function slotLabel(idx) {
    if (root.isVerticalLayout) {
      return ["Top Left", "Top Right", "Bottom Left", "Bottom Right"][idx];
    }
    return ["Left", "Center Left", "Center Right", "Right"][idx];
  }

  function updateSlot(index, value) {
    let copy = root.editSlots.slice();
    copy[index] = value;
    root.editSlots = copy;
  }

  function toIntOr(defaultValue, text) {
    const v = parseInt(String(text).trim(), 10);
    return isNaN(v) ? defaultValue : v;
  }

  // ── Save ──

  function saveSettings() {
    if (!pluginApi || !pluginApi.pluginSettings) {
      Logger.e("NetworkIndicator", "Cannot save: pluginApi or pluginSettings is null");
      return;
    }

    const s = pluginApi.pluginSettings;

    s.layout = root.editLayout;
    s.slots = root.editSlots;
    s.iconType = root.editIconType;
    s.byteThresholdActive = root.editByteThresholdActive;

    s.fontSizeModifier = root.editFontSizeModifier;
    s.iconSizeModifier = root.editIconSizeModifier;

    s.paddingLeft = root.editPaddingLeft;
    s.paddingRight = root.editPaddingRight;
    s.columnSpacing = root.editColumnSpacing;
    s.rowSpacing = root.editRowSpacing;

    s.useCustomFont = root.editUseCustomFont;
    s.customFontFamily = root.editCustomFontFamily;
    s.customFontBold = root.editCustomFontBold;
    s.customFontItalic = root.editCustomFontItalic;

    s.useCustomColors = root.editUseCustomColors;
    if (root.editUseCustomColors) {
      s.colorTx = root.editColorTx.toString();
      s.colorRx = root.editColorRx.toString();
      s.colorSilent = root.editColorSilent.toString();
      s.colorText = root.editColorText.toString();
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("NetworkIndicator", "Settings saved");
    });
  }

  // ── UI ──

  Layout.rightMargin: Style.marginL
  spacing: Style.marginL

  // ── Layout ──

  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.layout.label")
    description: pluginApi?.tr("settings.layout.desc")
    currentKey: root.editLayout
    model: root.layoutOptions
    onSelected: key => root.editLayout = key
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Slot assignment ──

  NLabel {
    label: pluginApi?.tr("settings.slots.label")
    description: pluginApi?.tr("settings.slots.desc")
  }

  Repeater {
    model: 4

    NComboBox {
      Layout.fillWidth: true
      label: root.slotLabel(index)
      currentKey: root.editSlots[index] ?? "none"
      model: root.slotOptions
      onSelected: key => root.updateSlot(index, key)
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Icon style ──

  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.iconType.label")
    description: pluginApi?.tr("settings.iconType.desc")
    currentKey: root.editIconType
    model: root.iconNames.map(n => ({
          key: n,
          name: n
        }))
    onSelected: key => root.editIconType = key
  }

  // ── Activity threshold ──

  NTextInput {
    label: pluginApi?.tr("settings.byteThresholdActive.label")
    description: pluginApi?.tr("settings.byteThresholdActive.desc")
    placeholderText: root.editByteThresholdActive + " bytes"
    text: String(root.editByteThresholdActive)
    onTextChanged: root.editByteThresholdActive = root.toIntOr(0, text)
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Size modifiers ──

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      label: pluginApi?.tr("settings.fontSizeModifier.label")
      description: pluginApi?.tr("settings.fontSizeModifier.desc")
    }

    NValueSlider {
      id: rangeEditFontSizeModifier
      objectName: "settings-range-editFontSizeModifier"
      onValueChanged: root.editFontSizeModifier = value
      Layout.fillWidth: true
      from: 0.5
      to: 1.5
      stepSize: 0.05
      text: root.editFontSizeModifier.toFixed(2)
      value: root.editFontSizeModifier
      onMoved: value => root.editFontSizeModifier = value
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      label: pluginApi?.tr("settings.iconSizeModifier.label")
      description: pluginApi?.tr("settings.iconSizeModifier.desc")
    }

    NValueSlider {
      id: rangeEditIconSizeModifier
      objectName: "settings-range-editIconSizeModifier"
      onValueChanged: root.editIconSizeModifier = value
      Layout.fillWidth: true
      from: 0.5
      to: 1.5
      stepSize: 0.05
      text: root.editIconSizeModifier.toFixed(2)
      value: root.editIconSizeModifier
      onMoved: value => root.editIconSizeModifier = value
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Content padding ──

  NTextInput {
    label: pluginApi?.tr("settings.rowSpacing.label")
    description: pluginApi?.tr("settings.rowSpacing.desc")
    placeholderText: root.editRowSpacing + " px"
    text: String(root.editRowSpacing)
    onTextChanged: root.editRowSpacing = root.toIntOr(0, text)
  }

  NTextInput {
    label: pluginApi?.tr("settings.columnSpacing.label")
    description: pluginApi?.tr("settings.columnSpacing.desc")
    placeholderText: root.editColumnSpacing + " px"
    text: String(root.editColumnSpacing)
    onTextChanged: root.editColumnSpacing = root.toIntOr(0, text)
  }

  NTextInput {
    label: pluginApi?.tr("settings.paddingLeft.label")
    description: pluginApi?.tr("settings.paddingLeft.desc")
    placeholderText: root.editPaddingLeft + " px"
    text: String(root.editPaddingLeft)
    onTextChanged: root.editPaddingLeft = root.toIntOr(0, text)
  }

  NTextInput {
    label: pluginApi?.tr("settings.paddingRight.label")
    description: pluginApi?.tr("settings.paddingRight.desc")
    placeholderText: root.editPaddingRight + " px"
    text: String(root.editPaddingRight)
    onTextChanged: root.editPaddingRight = root.toIntOr(0, text)
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Custom Font ──

  NToggle {
    checked: root.editUseCustomFont
    defaultValue: defaults.useCustomFont ?? false
    description: pluginApi?.tr("settings.useCustomFont.desc")
    label: pluginApi?.tr("settings.useCustomFont.label")
    onToggled: c => root.editUseCustomFont = c
  }

  ColumnLayout {
    visible: root.editUseCustomFont
    Layout.fillWidth: true
    spacing: Style.marginL

    NSearchableComboBox {
      label: pluginApi?.tr("settings.customFontFamily.label")
      description: pluginApi?.tr("settings.customFontFamily.desc")
      model: FontService.availableFonts
      currentKey: root.editCustomFontFamily || Quick.Application.font.family
      placeholder: pluginApi?.tr("settings.customFontFamily.placeholder")
      searchPlaceholder: pluginApi?.tr("settings.customFontFamily.searchPlaceholder")
      popupHeight: 420
      onSelected: key => {
        root.editCustomFontFamily = (key === Quick.Application.font.family) ? "" : key;
      }
    }

    NToggle {
      checked: root.editCustomFontBold
      defaultValue: defaults.customFontBold ?? false
      description: pluginApi?.tr("settings.customFontBold.desc")
      label: pluginApi?.tr("settings.customFontBold.label")
      onToggled: c => root.editCustomFontBold = c
    }

    NToggle {
      checked: root.editCustomFontItalic
      defaultValue: defaults.customFontItalic ?? false
      description: pluginApi?.tr("settings.customFontItalic.desc")
      label: pluginApi?.tr("settings.customFontItalic.label")
      onToggled: c => root.editCustomFontItalic = c
    }
  }

  // ── Custom Colors ──

  NToggle {
    checked: root.editUseCustomColors
    defaultValue: defaults.useCustomColors ?? false
    description: pluginApi?.tr("settings.useCustomColors.desc")
    label: pluginApi?.tr("settings.useCustomColors.label")
    onToggled: c => root.editUseCustomColors = c
  }

  ColumnLayout {
    visible: root.editUseCustomColors

    RowLayout {
      NLabel {
        Layout.alignment: Qt.AlignTop
        label: pluginApi?.tr("settings.colorTx.label")
        description: pluginApi?.tr("settings.colorTx.desc")
      }
      NColorPicker {
        selectedColor: root.editColorTx
        onColorSelected: color => root.editColorTx = color
      }
    }

    RowLayout {
      NLabel {
        Layout.alignment: Qt.AlignTop
        label: pluginApi?.tr("settings.colorRx.label")
        description: pluginApi?.tr("settings.colorRx.desc")
      }
      NColorPicker {
        selectedColor: root.editColorRx
        onColorSelected: color => root.editColorRx = color
      }
    }

    RowLayout {
      NLabel {
        Layout.alignment: Qt.AlignTop
        label: pluginApi?.tr("settings.colorSilent.label")
        description: pluginApi?.tr("settings.colorSilent.desc")
      }
      NColorPicker {
        selectedColor: root.editColorSilent
        onColorSelected: color => root.editColorSilent = color
      }
    }

    RowLayout {
      NLabel {
        Layout.alignment: Qt.AlignTop
        label: pluginApi?.tr("settings.colorText.label")
        description: pluginApi?.tr("settings.colorText.desc")
      }
      NColorPicker {
        selectedColor: root.editColorText
        onColorSelected: color => root.editColorText = color
      }
    }
  }
}
