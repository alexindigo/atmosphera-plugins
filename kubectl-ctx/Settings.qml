import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  NText {
    Layout.fillWidth: true
    visible: root.pluginApi?.scopeKind === "instance"
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
    wrapMode: Text.WordWrap
    color: AtmoColor.mOnSurfaceVariant
    pointSize: Style.fontSizeS
  }
  readonly property var kubeconfigPathField: pluginApi?.field("kubeconfigPath") ?? null
  readonly property var terminalField: pluginApi?.field("terminal") ?? null
  readonly property var pollIntervalField: pluginApi?.field("pollInterval") ?? null
  readonly property var showErrorBadgeField: pluginApi?.field("showErrorBadge") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null
  readonly property var panelWidthField: pluginApi?.field("panelWidth") ?? null
  readonly property var panelHeightField: pluginApi?.field("panelHeight") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string valueKubeconfigPath: root.kubeconfigPathField?.value ?? ""
  readonly property int valuePollInterval: root.pollIntervalField?.value ?? 60
  readonly property bool valueShowErrorBadge: root.showErrorBadgeField?.value ?? true
  readonly property string valueTerminal: root.terminalField?.value ?? ""
  readonly property string valueIconColor: root.iconColorField?.value ?? "none"
  readonly property int valuePanelWidth: root.panelWidthField?.value ?? 620
  readonly property int valuePanelHeight: root.panelHeightField?.value ?? 680

  spacing: Style.marginL

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NPluginSettingsField {
      field: root.kubeconfigPathField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.kubeconfigPath.label")
        description: pluginApi?.tr("settings.kubeconfigPath.desc")
        placeholderText: pluginApi?.tr("settings.kubeconfigPath.placeholder")
        text: root.valueKubeconfigPath
        onEditCommitted: root.kubeconfigPathField.set(text)
      }
    }

    NPluginSettingsField {
      field: root.terminalField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.terminal.label")
        description: pluginApi?.tr("settings.terminal.desc")
        placeholderText: pluginApi?.tr("settings.terminal.placeholder")
        text: root.valueTerminal
        onEditCommitted: root.terminalField.set(text)
      }
    }

    NPluginSettingsField {
      field: root.pollIntervalField
      NValueSlider {
        id: rangeValuePollInterval
        objectName: "settings-range-valuePollInterval"
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.pollInterval.label")
        description: pluginApi?.tr("settings.pollInterval.desc")
        from: 10
        to: 120
        stepSize: 10
        value: root.valuePollInterval
        text: root.valuePollInterval + " s"
        onMoved: value => root.pollIntervalField.set(value)
      }
    }

    NPluginSettingsField {
      field: root.showErrorBadgeField
      NToggle {
        label: pluginApi?.tr("settings.showErrorBadge.label")
        description: pluginApi?.tr("settings.showErrorBadge.desc")
        checked: root.valueShowErrorBadge
        onToggled: checked => root.showErrorBadgeField.set(checked)
      }
    }

    NPluginSettingsField {
      field: root.iconColorField
      NComboBox {
        label: pluginApi?.tr("settings.iconColor.label")
        description: pluginApi?.tr("settings.iconColor.desc")
        model: AtmoColor.colorKeyModel
        currentKey: root.valueIconColor
        onSelected: key => root.iconColorField.set(key)
      }
    }

    NPluginSettingsField {
      field: root.panelWidthField
      NValueSlider {
        id: rangeValuePanelWidth
        objectName: "settings-range-valuePanelWidth"
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.panelWidth.label")
        description: pluginApi?.tr("settings.panelWidth.desc")
        from: 400
        to: 1200
        stepSize: 20
        value: root.valuePanelWidth
        defaultValue: defaults.panelWidth ?? 620
        showReset: true
        text: root.valuePanelWidth + " px"
        onMoved: value => root.panelWidthField.set(value)
      }
    }

    NPluginSettingsField {
      field: root.panelHeightField
      NValueSlider {
        id: rangeValuePanelHeight
        objectName: "settings-range-valuePanelHeight"
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.panelHeight.label")
        description: pluginApi?.tr("settings.panelHeight.desc")
        from: 400
        to: 1200
        stepSize: 20
        value: root.valuePanelHeight
        defaultValue: defaults.panelHeight ?? 680
        showReset: true
        text: root.valuePanelHeight + " px"
        onMoved: value => root.panelHeightField.set(value)
      }
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("KubectlCtx", "Cannot save settings: pluginApi is null");
      return;
    }
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("KubectlCtx", "Settings saved");
    });
  }
}
