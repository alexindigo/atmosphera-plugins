import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property string valueKubeconfigPath: displayBaseline.valueKubeconfigPath
  property int valuePollInterval: displayBaseline.project("valuePollInterval")
  property bool valueShowErrorBadge: displayBaseline.valueShowErrorBadge
  property string valueTerminal: displayBaseline.valueTerminal
  property string valueIconColor: displayBaseline.valueIconColor
  property int valuePanelWidth: displayBaseline.project("valuePanelWidth")
  property int valuePanelHeight: displayBaseline.project("valuePanelHeight")

  spacing: Style.marginL

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.kubeconfigPath.label")
      description: pluginApi?.tr("settings.kubeconfigPath.desc")
      placeholderText: pluginApi?.tr("settings.kubeconfigPath.placeholder")
      text: root.valueKubeconfigPath
      onTextChanged: root.valueKubeconfigPath = text
    }

    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.terminal.label")
      description: pluginApi?.tr("settings.terminal.desc")
      placeholderText: pluginApi?.tr("settings.terminal.placeholder")
      text: root.valueTerminal
      onTextChanged: root.valueTerminal = text
    }

    NValueSlider {
      id: rangeValuePollInterval
      objectName: "settings-range-valuePollInterval"
      onValueChanged: root.valuePollInterval = value
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.pollInterval.label")
      description: pluginApi?.tr("settings.pollInterval.desc")
      from: 10
      to: 120
      stepSize: 10
      value: root.valuePollInterval
      text: root.valuePollInterval + " s"
      onMoved: value => root.valuePollInterval = value
    }

    NToggle {
      label: pluginApi?.tr("settings.showErrorBadge.label")
      description: pluginApi?.tr("settings.showErrorBadge.desc")
      checked: root.valueShowErrorBadge
      onToggled: checked => root.valueShowErrorBadge = checked
    }

    NComboBox {
      label: pluginApi?.tr("settings.iconColor.label")
      description: pluginApi?.tr("settings.iconColor.desc")
      model: AtmoColor.colorKeyModel
      currentKey: root.valueIconColor
      onSelected: key => root.valueIconColor = key
    }

    NValueSlider {
      id: rangeValuePanelWidth
      objectName: "settings-range-valuePanelWidth"
      onValueChanged: root.valuePanelWidth = value
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
      onMoved: value => root.valuePanelWidth = value
    }

    NValueSlider {
      id: rangeValuePanelHeight
      objectName: "settings-range-valuePanelHeight"
      onValueChanged: root.valuePanelHeight = value
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
      onMoved: value => root.valuePanelHeight = value
    }
  }

  NSettingsBaseline {
    ranges: [NSettingsRange { field: "valuePollInterval"; from: rangeValuePollInterval.from; to: rangeValuePollInterval.to }, NSettingsRange { field: "valuePanelWidth"; from: rangeValuePanelWidth.from; to: rangeValuePanelWidth.to }, NSettingsRange { field: "valuePanelHeight"; from: rangeValuePanelHeight.from; to: rangeValuePanelHeight.to }]
    id: displayBaseline
    readonly property string valueKubeconfigPath: cfg.kubeconfigPath ?? defaults.kubeconfigPath ?? ""
    readonly property string valueTerminal: cfg.terminal ?? defaults.terminal ?? ""
    readonly property int valuePollInterval: cfg.pollInterval ?? defaults.pollInterval ?? 60
    readonly property bool valueShowErrorBadge: cfg.showErrorBadge ?? defaults.showErrorBadge ?? true
    readonly property string valueIconColor: cfg.iconColor ?? defaults.iconColor ?? "none"
    readonly property int valuePanelWidth: cfg.panelWidth ?? defaults.panelWidth ?? 620
    readonly property int valuePanelHeight: cfg.panelHeight ?? defaults.panelHeight ?? 680
  }
  readonly property bool settingsDirty: displayBaseline.differs({valueKubeconfigPath: root.valueKubeconfigPath, valueTerminal: root.valueTerminal, valuePollInterval: root.valuePollInterval, valueShowErrorBadge: root.valueShowErrorBadge, valueIconColor: root.valueIconColor, valuePanelWidth: root.valuePanelWidth, valuePanelHeight: root.valuePanelHeight})

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("KubectlCtx", "Cannot save settings: pluginApi is null");
      return;
    }
    pluginApi.pluginSettings.kubeconfigPath = root.valueKubeconfigPath;
    pluginApi.pluginSettings.terminal = root.valueTerminal;
    pluginApi.pluginSettings.pollInterval = root.valuePollInterval;
    pluginApi.pluginSettings.showErrorBadge = root.valueShowErrorBadge;
    pluginApi.pluginSettings.iconColor = root.valueIconColor;
    pluginApi.pluginSettings.panelWidth = root.valuePanelWidth;
    pluginApi.pluginSettings.panelHeight = root.valuePanelHeight;
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("KubectlCtx", "Settings saved");
    });
  }
}
