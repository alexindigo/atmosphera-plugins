import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null
  readonly property var hoverColorField: pluginApi?.field("hoverColor") ?? null
  readonly property var buttonWidthField: pluginApi?.field("buttonWidth") ?? null
  readonly property var buttonHeightField: pluginApi?.field("buttonHeight") ?? null
  readonly property var buttonSpacingField: pluginApi?.field("buttonSpacing") ?? null
  readonly property var buttonOpacityField: pluginApi?.field("buttonOpacity") ?? null
  readonly property var useOverlayField: pluginApi?.field("useOverlay") ?? null
  readonly property var overlayBlurField: pluginApi?.field("overlayBlur") ?? null
  readonly property var overlayTintField: pluginApi?.field("overlayTint") ?? null
  readonly property var panelTintField: pluginApi?.field("panelTint") ?? null
  readonly property var animationsEnabledField: pluginApi?.field("animationsEnabled") ?? null
  readonly property var lockOnSuspendField: pluginApi?.field("lockOnSuspend") ?? null
  readonly property var hoverDesaturationField: pluginApi?.field("hoverDesaturation") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string editIconColor: root.iconColorField?.value ?? "primary"
  readonly property string editHoverColor: root.hoverColorField?.value ?? "primary"
  readonly property real editBtnWidth: root.buttonWidthField?.value ?? 470
  readonly property real editBtnHeight: root.buttonHeightField?.value ?? 280
  readonly property real editBtnSpacing: root.buttonSpacingField?.value ?? 20
  readonly property real editBtnOpacity: root.buttonOpacityField?.value ?? 0.50
  readonly property bool editUseOverlay: root.useOverlayField?.value ?? true
  readonly property bool editAnimationsEnabled: root.animationsEnabledField?.value ?? true
  readonly property bool editLockOnSuspend: root.lockOnSuspendField?.value ?? true
  readonly property real editHoverDesaturation: root.hoverDesaturationField?.value ?? 0.0
  readonly property real editOverlayBlur: root.overlayBlurField?.value ?? 0.75
  readonly property real editOverlayTint: root.overlayTintField?.value ?? 0.6
  readonly property real editPanelTint: root.panelTintField?.value ?? 0.7

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  NText {
    Layout.fillWidth: true
    visible: root.pluginApi?.scopeKind === "instance"
    text: root.pluginApi?.tr("shared-window-effect") ?? ""
    wrapMode: Text.WordWrap
  }

  NText {
    text: pluginApi?.tr("header.title")
    pointSize: Style.fontSizeXL
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
  }

  NText {
    text: pluginApi?.tr("header.desc")
    pointSize: Style.fontSizeS
    color: AtmoColor.mOnSurfaceVariant
    Layout.bottomMargin: Style.marginM
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    text: pluginApi?.tr("section.barButton")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.iconColorField
    NColorChoice {
      label: pluginApi?.tr("settings.iconColor.label")
      description: pluginApi?.tr("settings.iconColor.desc")
      currentKey: root.editIconColor
      onSelected: key => {
        root.iconColorField.set(key);
      }
      defaultValue: defaults.iconColor || "primary"
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NText {
    text: pluginApi?.tr("section.behavior")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.lockOnSuspendField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.lockOnSuspend.label")
      description: pluginApi?.tr("settings.lockOnSuspend.desc")
      checked: root.editLockOnSuspend
      onToggled: checked => {
        root.lockOnSuspendField.set(checked);
      }
      defaultValue: defaults.lockOnSuspend ?? true
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NText {
    text: pluginApi?.tr("section.buttons")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.buttonWidthField
    NValueSlider {
      id: rangeEditBtnWidth
      objectName: "settings-range-editBtnWidth"
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.buttonWidth.label")
      from: 200
      to: 500
      stepSize: 10
      snapAlways: true
      value: root.editBtnWidth
      text: root.editBtnWidth + "px"
      defaultValue: defaults.buttonWidth ?? 470
      showReset: true
      onMoved: v => {
        root.buttonWidthField.set(v);
      }
    }
  }

  NPluginSettingsField {
    field: root.buttonHeightField
    NValueSlider {
      id: rangeEditBtnHeight
      objectName: "settings-range-editBtnHeight"
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.buttonHeight.label")
      from: 150
      to: 400
      stepSize: 10
      snapAlways: true
      value: root.editBtnHeight
      text: root.editBtnHeight + "px"
      defaultValue: defaults.buttonHeight ?? 280
      showReset: true
      onMoved: v => {
        root.buttonHeightField.set(v);
      }
    }
  }

  NPluginSettingsField {
    field: root.buttonSpacingField
    NValueSlider {
      id: rangeEditBtnSpacing
      objectName: "settings-range-editBtnSpacing"
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.buttonSpacing.label")
      description: pluginApi?.tr("settings.buttonSpacing.desc")
      from: 10
      to: 80
      stepSize: 5
      snapAlways: true
      value: root.editBtnSpacing
      text: root.editBtnSpacing + "px"
      defaultValue: defaults.buttonSpacing ?? 20
      showReset: true
      onMoved: v => {
        root.buttonSpacingField.set(v);
      }
    }
  }

  NPluginSettingsField {
    field: root.buttonOpacityField
    NValueSlider {
      id: rangeEditBtnOpacity
      objectName: "settings-range-editBtnOpacity"
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.buttonOpacity.label")
      from: 0.1
      to: 1.0
      stepSize: 0.05
      snapAlways: true
      value: root.editBtnOpacity
      text: Math.round(root.editBtnOpacity * 100) + "%"
      defaultValue: defaults.buttonOpacity ?? 0.50
      showReset: true
      onMoved: v => {
        root.buttonOpacityField.set(v);
      }
    }
  }

  NPluginSettingsField {
    field: root.hoverColorField
    NColorChoice {
      label: pluginApi?.tr("settings.hoverColor.label")
      description: pluginApi?.tr("settings.hoverColor.desc")
      currentKey: root.editHoverColor
      onSelected: key => {
        root.hoverColorField.set(key);
      }
      defaultValue: defaults.hoverColor || "primary"
    }
  }

  NPluginSettingsField {
    field: root.hoverDesaturationField
    NValueSlider {
      id: rangeEditHoverDesaturation
      objectName: "settings-range-editHoverDesaturation"
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.hoverDesaturation.label")
      description: pluginApi?.tr("settings.hoverDesaturation.desc")
      from: 0
      to: 85
      stepSize: 5
      snapAlways: true
      value: root.editHoverDesaturation * 100
      text: Math.round(root.editHoverDesaturation * 100) + "%"
      defaultValue: defaults.hoverDesaturation ?? 0.0
      showReset: true
      onMoved: v => {
        root.hoverDesaturationField.set(v / 100);
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NText {
    text: pluginApi?.tr("section.background")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.useOverlayField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.useOverlay.label")
      description: pluginApi?.tr("settings.useOverlay.desc")
      checked: root.editUseOverlay
      onToggled: checked => {
        root.useOverlayField.set(checked);
      }
      defaultValue: defaults.useOverlay ?? true
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    visible: root.editUseOverlay
    spacing: Style.marginM

    NPluginSettingsField {
      field: root.overlayBlurField
      NValueSlider {
        id: rangeEditOverlayBlur
        objectName: "settings-range-editOverlayBlur"
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.overlayBlur.label")
        description: pluginApi?.tr("settings.overlayBlur.desc")
        from: 0.0
        to: 1.0
        stepSize: 0.05
        snapAlways: true
        value: root.editOverlayBlur
        text: Math.round(root.editOverlayBlur * 100) + "%"
        defaultValue: defaults.overlayBlur ?? 0.75
        showReset: true
        onMoved: v => {
          root.overlayBlurField.set(v);
        }
      }
    }

    NPluginSettingsField {
      field: root.overlayTintField
      NValueSlider {
        id: rangeEditOverlayTint
        objectName: "settings-range-editOverlayTint"
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.overlayTint.label")
        description: pluginApi?.tr("settings.overlayTint.desc")
        from: 0.0
        to: 1.0
        stepSize: 0.05
        snapAlways: true
        value: root.editOverlayTint
        text: Math.round(root.editOverlayTint * 100) + "%"
        defaultValue: defaults.overlayTint ?? 0.6
        showReset: true
        onMoved: v => {
          root.overlayTintField.set(v);
        }
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    visible: !root.editUseOverlay
    spacing: Style.marginM

    NPluginSettingsField {
      field: root.panelTintField
      NValueSlider {
        id: rangeEditPanelTint
        objectName: "settings-range-editPanelTint"
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.panelTint.label")
        description: pluginApi?.tr("settings.panelTint.desc")
        from: 0.0
        to: 1.0
        stepSize: 0.05
        snapAlways: true
        value: root.editPanelTint
        text: Math.round(root.editPanelTint * 100) + "%"
        defaultValue: defaults.panelTint ?? 0.7
        showReset: true
        onMoved: v => {
          root.panelTintField.set(v);
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NText {
    text: pluginApi?.tr("section.animations")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.animationsEnabledField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.animationsEnabled.label")
      description: pluginApi?.tr("settings.animationsEnabled.desc")
      checked: root.editAnimationsEnabled
      onToggled: checked => {
        root.animationsEnabledField.set(checked);
      }
      defaultValue: defaults.animationsEnabled ?? true
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Somnus", "Cannot save settings: pluginApi is null");
      return;
    }
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("Somnus", "Settings saved successfully");
    });
  }
}
