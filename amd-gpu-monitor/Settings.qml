import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var compactModeField: pluginApi?.field("compactMode") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null
  readonly property var textColorField: pluginApi?.field("textColor") ?? null
  readonly property var useMonospaceFontField: pluginApi?.field("useMonospaceFont") ?? null
  readonly property var usePaddingField: pluginApi?.field("usePadding") ?? null
  readonly property var showGpuUseField: pluginApi?.field("showGpuUse") ?? null
  readonly property var showTempJunctionField: pluginApi?.field("showTempJunction") ?? null
  readonly property var showTempEdgeField: pluginApi?.field("showTempEdge") ?? null
  readonly property var showTempMemoryField: pluginApi?.field("showTempMemory") ?? null
  readonly property var showVramField: pluginApi?.field("showVram") ?? null
  readonly property var showVramActivityField: pluginApi?.field("showVramActivity") ?? null
  readonly property var showFanSpeedField: pluginApi?.field("showFanSpeed") ?? null
  readonly property var showPowerField: pluginApi?.field("showPower") ?? null
  readonly property var showSclkField: pluginApi?.field("showSclk") ?? null
  readonly property var showMclkField: pluginApi?.field("showMclk") ?? null
  readonly property var showFclkField: pluginApi?.field("showFclk") ?? null
  readonly property var showSocclkField: pluginApi?.field("showSocclk") ?? null
  readonly property var showDcefclkField: pluginApi?.field("showDcefclk") ?? null
  readonly property var deviceIndexField: pluginApi?.field("deviceIndex") ?? null
  readonly property var mainInstance: pluginApi?.mainInstance?.settingsConsumerFor(pluginApi.runtimeContext)
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})

  readonly property bool valueShowGpuUse: (root.showGpuUseField?.value ?? true)
  readonly property bool valueShowTempJunction: (root.showTempJunctionField?.value ?? true)
  readonly property bool valueShowTempEdge: (root.showTempEdgeField?.value ?? false)
  readonly property bool valueShowTempMemory: (root.showTempMemoryField?.value ?? false)
  readonly property bool valueShowVram: (root.showVramField?.value ?? true)
  readonly property bool valueShowVramActivity: (root.showVramActivityField?.value ?? false)
  readonly property bool valueShowFanSpeed: (root.showFanSpeedField?.value ?? false)
  readonly property bool valueShowPower: (root.showPowerField?.value ?? true)
  readonly property bool valueShowSclk: (root.showSclkField?.value ?? true)
  readonly property bool valueShowMclk: (root.showMclkField?.value ?? true)
  readonly property bool valueShowFclk: (root.showFclkField?.value ?? false)
  readonly property bool valueShowSocclk: (root.showSocclkField?.value ?? false)
  readonly property bool valueShowDcefclk: (root.showDcefclkField?.value ?? false)
  readonly property bool valueCompactMode: (root.compactModeField?.value ?? true)
  readonly property string valueIconColor: root.iconColorField?.value ?? "primary"
  readonly property string valueTextColor: root.textColorField?.value ?? "onSurface"
  readonly property bool valueUseMonospaceFont: (root.useMonospaceFontField?.value ?? true)
  readonly property bool valueUsePadding: (root.usePaddingField?.value ?? false)

  readonly property int valueDeviceIndex: root.deviceIndexField?.value ?? 0

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _applyEffectPending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._applyEffectPending = false;
      root.mainInstance?.refreshNow();
      Logger.i("AmdGpuMonitor", "Settings saved");
    }
  }

  spacing: Style.marginL

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    text: root.pluginApi?.tr("settings.shared-effect") || ""
    wrapMode: Text.WordWrap
    color: AtmoColor.mOnSurfaceVariant
  }

  NText {
    text: pluginApi?.tr("settings.bar_section")
    pointSize: Style.fontSizeL
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.compactModeField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.compact_mode_label")
      description: pluginApi?.tr("settings.compact_mode_description")
      checked: root.valueCompactMode
      onToggled: checked => root.compactModeField.set(checked)
      defaultValue: defaults.compactMode ?? true
    }
  }

  NPluginSettingsField {
    field: root.iconColorField
    NColorChoice {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.icon_color_label")
      currentKey: root.valueIconColor
      onSelected: key => root.iconColorField.set(key)
      defaultValue: defaults.iconColor ?? "primary"
    }
  }

  NPluginSettingsField {
    field: root.textColorField
    visible: !root.valueCompactMode
    NColorChoice {
      Layout.fillWidth: true
      currentKey: root.valueTextColor
      onSelected: key => root.textColorField.set(key)
      defaultValue: defaults.textColor ?? "onSurface"
    }
  }

  NPluginSettingsField {
    field: root.useMonospaceFontField
    visible: !root.valueCompactMode
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.monospace_font_label")
      description: pluginApi?.tr("settings.monospace_font_description")
      checked: root.valueUseMonospaceFont
      onToggled: checked => root.useMonospaceFontField.set(checked)
      defaultValue: defaults.useMonospaceFont ?? true
    }
  }

  NPluginSettingsField {
    field: root.usePaddingField
    visible: !root.valueCompactMode
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.use_padding_label")
      description: pluginApi?.tr("settings.use_padding_description")
      checked: root.valueUsePadding && root.valueUseMonospaceFont
      onToggled: checked => root.usePaddingField.set(checked)
      enabled: root.valueUseMonospaceFont
      defaultValue: defaults.usePadding ?? false
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
  }

  NText {
    text: pluginApi?.tr("settings.metrics_section")
    pointSize: Style.fontSizeL
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }

  NText {
    text: pluginApi?.tr("settings.metrics_description")
    pointSize: Style.fontSizeS
    color: AtmoColor.mOnSurfaceVariant
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  NPluginSettingsField {
    field: root.showGpuUseField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.gpu_use")
      checked: root.valueShowGpuUse
      onToggled: checked => root.showGpuUseField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.showTempJunctionField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.temp_junction")
      checked: root.valueShowTempJunction
      onToggled: checked => root.showTempJunctionField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.showTempEdgeField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.temp_edge")
      checked: root.valueShowTempEdge
      onToggled: checked => root.showTempEdgeField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.showTempMemoryField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.temp_memory")
      checked: root.valueShowTempMemory
      onToggled: checked => root.showTempMemoryField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.showVramField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.vram")
      checked: root.valueShowVram
      onToggled: checked => root.showVramField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.showVramActivityField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.vram_activity")
      checked: root.valueShowVramActivity
      onToggled: checked => root.showVramActivityField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.showFanSpeedField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.fan_speed")
      checked: root.valueShowFanSpeed
      onToggled: checked => root.showFanSpeedField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.showPowerField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.power")
      checked: root.valueShowPower
      onToggled: checked => root.showPowerField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.showSclkField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.sclk")
      checked: root.valueShowSclk
      onToggled: checked => root.showSclkField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.showMclkField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.mclk")
      checked: root.valueShowMclk
      onToggled: checked => root.showMclkField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.showFclkField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.fclk")
      checked: root.valueShowFclk
      onToggled: checked => root.showFclkField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.showSocclkField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.socclk")
      checked: root.valueShowSocclk
      onToggled: checked => root.showSocclkField.set(checked)
    }
  }
  NPluginSettingsField {
    field: root.showDcefclkField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("metrics.dcefclk")
      checked: root.valueShowDcefclk
      onToggled: checked => root.showDcefclkField.set(checked)
    }
  }
  NText {
    text: pluginApi?.tr("settings.display_section")
    pointSize: Style.fontSizeL
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
    Layout.topMargin: Style.marginL
  }

  NPluginSettingsField {
    field: root.deviceIndexField
    NSpinBox {
      id: rangeValueDeviceIndex
      objectName: "settings-range-valueDeviceIndex"
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.device_index")
      description: pluginApi?.tr("settings.device_index_description")
      from: 0
      to: 7
      value: root.valueDeviceIndex
      requestValue: value => root.deviceIndexField.set(value)
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;

    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true;
  }
}
