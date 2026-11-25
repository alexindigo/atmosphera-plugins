import QtQuick
import QtQuick as Quick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var layoutField: pluginApi?.field("layout") ?? null
  readonly property var slotsField: pluginApi?.field("slots") ?? null
  readonly property var iconTypeField: pluginApi?.field("iconType") ?? null
  readonly property var byteThresholdActiveField: pluginApi?.field("byteThresholdActive") ?? null
  readonly property var fontSizeModifierField: pluginApi?.field("fontSizeModifier") ?? null
  readonly property var iconSizeModifierField: pluginApi?.field("iconSizeModifier") ?? null
  readonly property var paddingLeftField: pluginApi?.field("paddingLeft") ?? null
  readonly property var paddingRightField: pluginApi?.field("paddingRight") ?? null
  readonly property var columnSpacingField: pluginApi?.field("columnSpacing") ?? null
  readonly property var rowSpacingField: pluginApi?.field("rowSpacing") ?? null
  readonly property var useCustomFontField: pluginApi?.field("useCustomFont") ?? null
  readonly property var customFontFamilyField: pluginApi?.field("customFontFamily") ?? null
  readonly property var customFontBoldField: pluginApi?.field("customFontBold") ?? null
  readonly property var customFontItalicField: pluginApi?.field("customFontItalic") ?? null
  readonly property var useCustomColorsField: pluginApi?.field("useCustomColors") ?? null
  readonly property var colorTxField: pluginApi?.field("colorTx") ?? null
  readonly property var colorRxField: pluginApi?.field("colorRx") ?? null
  readonly property var colorSilentField: pluginApi?.field("colorSilent") ?? null
  readonly property var colorTextField: pluginApi?.field("colorText") ?? null

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

  readonly property string editLayout: root.layoutField?.value ?? defaults.layout
  readonly property var editSlots: root.slotsField?.value ?? defaults.slots
  readonly property string editIconType: root.iconTypeField?.value ?? defaults.iconType
  readonly property int editByteThresholdActive: root.byteThresholdActiveField?.value ?? defaults.byteThresholdActive
  readonly property real editFontSizeModifier: root.fontSizeModifierField?.value ?? defaults.fontSizeModifier
  readonly property real editIconSizeModifier: root.iconSizeModifierField?.value ?? defaults.iconSizeModifier
  readonly property real editPaddingLeft: root.paddingLeftField?.value ?? defaults.paddingLeft
  readonly property real editPaddingRight: root.paddingRightField?.value ?? defaults.paddingRight
  readonly property real editColumnSpacing: root.columnSpacingField?.value ?? defaults.columnSpacing
  readonly property real editRowSpacing: root.rowSpacingField?.value ?? defaults.rowSpacing
  readonly property bool editUseCustomFont: root.useCustomFontField?.value ?? defaults.useCustomFont
  readonly property string editCustomFontFamily: root.customFontFamilyField?.value ?? defaults.customFontFamily
  readonly property bool editCustomFontBold: root.customFontBoldField?.value ?? defaults.customFontBold
  readonly property bool editCustomFontItalic: root.customFontItalicField?.value ?? defaults.customFontItalic
  readonly property bool editUseCustomColors: root.useCustomColorsField?.value ?? defaults.useCustomColors
  readonly property color editColorTx: root.editUseCustomColors && root.colorTxField?.value || AtmoColor.mSecondary
  readonly property color editColorRx: root.editUseCustomColors && root.colorRxField?.value || AtmoColor.mPrimary
  readonly property color editColorSilent: root.editUseCustomColors && root.colorSilentField?.value || AtmoColor.mSurfaceVariant
  readonly property color editColorText: root.editUseCustomColors && root.colorTextField?.value || AtmoColor.mOnSurfaceVariant

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

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
    root.slotsField.set(copy);
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

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("NetworkIndicator", "Settings saved");
    });
  }

  // ── UI ──

  Layout.rightMargin: Style.marginL
  spacing: Style.marginL

  // ── Layout ──

  NPluginSettingsField {
    field: root.layoutField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.layout.label")
      description: pluginApi?.tr("settings.layout.desc")
      currentKey: root.editLayout
      model: root.layoutOptions
      onSelected: key => root.layoutField.set(key)
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Slot assignment ──

  NLabel {
    label: pluginApi?.tr("settings.slots.label")
    description: pluginApi?.tr("settings.slots.desc")
  }

  NPluginSettingsField {
    field: root.slotsField
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
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Icon style ──

  NPluginSettingsField {
    field: root.iconTypeField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.iconType.label")
      description: pluginApi?.tr("settings.iconType.desc")
      currentKey: root.editIconType
      model: root.iconNames.map(n => ({
        key: n,
        name: n
      }))
      onSelected: key => root.iconTypeField.set(key)
    }
  }

  // ── Activity threshold ──

  NPluginSettingsField {
    field: root.byteThresholdActiveField
    NTextInput {
      label: pluginApi?.tr("settings.byteThresholdActive.label")
      description: pluginApi?.tr("settings.byteThresholdActive.desc")
      placeholderText: root.editByteThresholdActive + " bytes"
      text: String(root.editByteThresholdActive)
      onEditCommitted: root.byteThresholdActiveField.set(root.toIntOr(0, text))
    }
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

    NPluginSettingsField {
      field: root.fontSizeModifierField
      NValueSlider {
        id: rangeEditFontSizeModifier
        objectName: "settings-range-editFontSizeModifier"
        Layout.fillWidth: true
        from: 0.5
        to: 1.5
        stepSize: 0.05
        text: root.editFontSizeModifier.toFixed(2)
        value: root.editFontSizeModifier
        onMoved: value => root.fontSizeModifierField.set(value)
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginXXS

    NLabel {
      label: pluginApi?.tr("settings.iconSizeModifier.label")
      description: pluginApi?.tr("settings.iconSizeModifier.desc")
    }

    NPluginSettingsField {
      field: root.iconSizeModifierField
      NValueSlider {
        id: rangeEditIconSizeModifier
        objectName: "settings-range-editIconSizeModifier"
        Layout.fillWidth: true
        from: 0.5
        to: 1.5
        stepSize: 0.05
        text: root.editIconSizeModifier.toFixed(2)
        value: root.editIconSizeModifier
        onMoved: value => root.iconSizeModifierField.set(value)
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Content padding ──

  NPluginSettingsField {
    field: root.rowSpacingField
    NTextInput {
      label: pluginApi?.tr("settings.rowSpacing.label")
      description: pluginApi?.tr("settings.rowSpacing.desc")
      placeholderText: root.editRowSpacing + " px"
      text: String(root.editRowSpacing)
      onEditCommitted: root.rowSpacingField.set(root.toIntOr(0, text))
    }
  }

  NPluginSettingsField {
    field: root.columnSpacingField
    NTextInput {
      label: pluginApi?.tr("settings.columnSpacing.label")
      description: pluginApi?.tr("settings.columnSpacing.desc")
      placeholderText: root.editColumnSpacing + " px"
      text: String(root.editColumnSpacing)
      onEditCommitted: root.columnSpacingField.set(root.toIntOr(0, text))
    }
  }

  NPluginSettingsField {
    field: root.paddingLeftField
    NTextInput {
      label: pluginApi?.tr("settings.paddingLeft.label")
      description: pluginApi?.tr("settings.paddingLeft.desc")
      placeholderText: root.editPaddingLeft + " px"
      text: String(root.editPaddingLeft)
      onEditCommitted: root.paddingLeftField.set(root.toIntOr(0, text))
    }
  }

  NPluginSettingsField {
    field: root.paddingRightField
    NTextInput {
      label: pluginApi?.tr("settings.paddingRight.label")
      description: pluginApi?.tr("settings.paddingRight.desc")
      placeholderText: root.editPaddingRight + " px"
      text: String(root.editPaddingRight)
      onEditCommitted: root.paddingRightField.set(root.toIntOr(0, text))
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Custom Font ──

  NPluginSettingsField {
    field: root.useCustomFontField
    NToggle {
      checked: root.editUseCustomFont
      defaultValue: defaults.useCustomFont ?? false
      description: pluginApi?.tr("settings.useCustomFont.desc")
      label: pluginApi?.tr("settings.useCustomFont.label")
      onToggled: c => root.useCustomFontField.set(c)
    }
  }

  ColumnLayout {
    visible: root.editUseCustomFont
    Layout.fillWidth: true
    spacing: Style.marginL

    NPluginSettingsField {
      field: root.customFontFamilyField
      NSearchableComboBox {
        label: pluginApi?.tr("settings.customFontFamily.label")
        description: pluginApi?.tr("settings.customFontFamily.desc")
        model: FontService.availableFonts
        currentKey: root.editCustomFontFamily || Quick.Application.font.family
        placeholder: pluginApi?.tr("settings.customFontFamily.placeholder")
        searchPlaceholder: pluginApi?.tr("settings.customFontFamily.searchPlaceholder")
        popupHeight: 420
        onSelected: key => {
          root.customFontFamilyField.set((key === Quick.Application.font.family) ? "" : key);
        }
      }
    }

    NPluginSettingsField {
      field: root.customFontBoldField
      NToggle {
        checked: root.editCustomFontBold
        defaultValue: defaults.customFontBold ?? false
        description: pluginApi?.tr("settings.customFontBold.desc")
        label: pluginApi?.tr("settings.customFontBold.label")
        onToggled: c => root.customFontBoldField.set(c)
      }
    }

    NPluginSettingsField {
      field: root.customFontItalicField
      NToggle {
        checked: root.editCustomFontItalic
        defaultValue: defaults.customFontItalic ?? false
        description: pluginApi?.tr("settings.customFontItalic.desc")
        label: pluginApi?.tr("settings.customFontItalic.label")
        onToggled: c => root.customFontItalicField.set(c)
      }
    }
  }

  // ── Custom Colors ──

  NPluginSettingsField {
    field: root.useCustomColorsField
    NToggle {
      checked: root.editUseCustomColors
      defaultValue: defaults.useCustomColors ?? false
      description: pluginApi?.tr("settings.useCustomColors.desc")
      label: pluginApi?.tr("settings.useCustomColors.label")
      onToggled: c => root.useCustomColorsField.set(c)
    }
  }

  ColumnLayout {
    visible: root.editUseCustomColors

    RowLayout {
      NLabel {
        Layout.alignment: Qt.AlignTop
        label: pluginApi?.tr("settings.colorTx.label")
        description: pluginApi?.tr("settings.colorTx.desc")
      }
      NPluginSettingsField {
        field: root.colorTxField
        NColorPicker {
          selectedColor: root.editColorTx
          onColorSelected: color => root.colorTxField.set(color.toString())
        }
      }
    }

    RowLayout {
      NLabel {
        Layout.alignment: Qt.AlignTop
        label: pluginApi?.tr("settings.colorRx.label")
        description: pluginApi?.tr("settings.colorRx.desc")
      }
      NPluginSettingsField {
        field: root.colorRxField
        NColorPicker {
          selectedColor: root.editColorRx
          onColorSelected: color => root.colorRxField.set(color.toString())
        }
      }
    }

    RowLayout {
      NLabel {
        Layout.alignment: Qt.AlignTop
        label: pluginApi?.tr("settings.colorSilent.label")
        description: pluginApi?.tr("settings.colorSilent.desc")
      }
      NPluginSettingsField {
        field: root.colorSilentField
        NColorPicker {
          selectedColor: root.editColorSilent
          onColorSelected: color => root.colorSilentField.set(color.toString())
        }
      }
    }

    RowLayout {
      NLabel {
        Layout.alignment: Qt.AlignTop
        label: pluginApi?.tr("settings.colorText.label")
        description: pluginApi?.tr("settings.colorText.desc")
      }
      NPluginSettingsField {
        field: root.colorTextField
        NColorPicker {
          selectedColor: root.editColorText
          onColorSelected: color => root.colorTextField.set(color.toString())
        }
      }
    }
  }
}
