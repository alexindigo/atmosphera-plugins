import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var showGovernorField: pluginApi?.field("showGovernor") ?? null
  readonly property var showTurboField: pluginApi?.field("showTurbo") ?? null
  readonly property var compactModeField: pluginApi?.field("compactMode") ?? null

  // Edit copies
  readonly property int editRefreshInterval: root.refreshIntervalField?.value ?? 3000
  readonly property bool editShowGovernor: root.showGovernorField?.value ?? true
  readonly property bool editShowTurbo: root.showTurboField?.value ?? true
  readonly property bool editCompactMode: root.compactModeField?.value ?? false
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  NPluginSettingsField {
    field: root.compactModeField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.compact.label")
      description: pluginApi?.tr("settings.compact.desc")
      checked: root.editCompactMode
      onToggled: checked => root.compactModeField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.showGovernorField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-governor.label")
      description: pluginApi?.tr("settings.show-governor.desc")
      checked: root.editShowGovernor
      onToggled: checked => root.showGovernorField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.showTurboField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-turbo.label")
      description: pluginApi?.tr("settings.show-turbo.desc")
      checked: root.editShowTurbo
      onToggled: checked => root.showTurboField.set(checked)
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NText {
      text: pluginApi?.tr("settings.refresh.label")
      pointSize: Style.fontSizeS
      font.weight: Font.Medium
      color: AtmoColor.mOnSurface
    }

    NText {
      text: pluginApi?.tr("settings.refresh.desc")
      pointSize: Style.fontSizeXS
      color: AtmoColor.mOnSurfaceVariant
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NPluginSettingsField {
        field: root.refreshIntervalField
        NSlider {
          id: rangeEditRefreshInterval
          objectName: "settings-range-editRefreshInterval"
          Layout.fillWidth: true
          from: 1000
          to: 10000
          stepSize: 500
          value: root.editRefreshInterval
          onMoved: root.refreshIntervalField.set(value)
        }
      }

      NText {
        text: (root.editRefreshInterval / 1000).toFixed(1) + "s"
        pointSize: Style.fontSizeS
        font.family: Settings.data?.ui?.fontFixed ?? "monospace"
        color: AtmoColor.mOnSurface
        Layout.preferredWidth: 36 * Style.uiScaleRatio
        horizontalAlignment: Text.AlignRight
      }
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }
}
