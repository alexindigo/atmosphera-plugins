import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var hostsField: pluginApi?.field("hosts") ?? null
  readonly property var intervalSecondsField: pluginApi?.field("intervalSeconds") ?? null
  readonly property var thresholdGoodField: pluginApi?.field("thresholdGood") ?? null
  readonly property var thresholdWarningField: pluginApi?.field("thresholdWarning") ?? null
  readonly property var showHostNameField: pluginApi?.field("showHostName") ?? null
  readonly property var barHostField: pluginApi?.field("barHost") ?? null
  readonly property var colorGoodField: pluginApi?.field("colorGood") ?? null
  readonly property var colorWarningField: pluginApi?.field("colorWarning") ?? null
  readonly property var colorCriticalField: pluginApi?.field("colorCritical") ?? null
  readonly property var animationsField: pluginApi?.field("animations") ?? null
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property int valueIntervalSeconds: root.intervalSecondsField?.value ?? defaults.intervalSeconds
  readonly property int valueThresholdGood: root.thresholdGoodField?.value ?? defaults.thresholdGood
  readonly property int valueThresholdWarning: root.thresholdWarningField?.value ?? defaults.thresholdWarning
  readonly property bool valueShowHostName: root.showHostNameField?.value ?? defaults.showHostName
  readonly property string valueBarHost: root.barHostField?.value ?? defaults.barHost
  readonly property string valueColorGood: root.colorGoodField?.value ?? defaults.colorGood
  readonly property string valueColorWarning: root.colorWarningField?.value ?? defaults.colorWarning
  readonly property string valueColorCritical: root.colorCriticalField?.value ?? defaults.colorCritical
  readonly property var valueHosts: root.hostsField?.value ?? defaults.hosts
  readonly property bool valueAnimations: root.animationsField?.value ?? defaults.animations

  spacing: Style.marginL

  NHeader {
    label: pluginApi?.tr("settings.hosts.header")
    description: pluginApi?.tr("settings.hosts.desc")
  }

  Repeater {
    model: valueHosts

    delegate: RowLayout {
      required property var modelData
      required property int index
      Layout.fillWidth: true
      spacing: Style.marginS

      NPluginSettingsField {
        field: root.hostsField
        NTextInput {
          Layout.preferredWidth: 120 * Style.uiScaleRatio
          label: index === 0 ? pluginApi?.tr("settings.hosts.name") : ""
          placeholderText: "Name"
          text: modelData.name
          onEditCommitted: {
            const arr = root.valueHosts.slice();
            arr[index] = {
              name: text,
              address: arr[index].address
            };
            root.hostsField.set(arr);
          }
        }
      }

      NTextInput {
        Layout.fillWidth: true
        label: index === 0 ? pluginApi?.tr("settings.hosts.address") : ""
        placeholderText: "IP / hostname"
        text: modelData.address
        onEditingFinished: {
          const arr = root.valueHosts.slice();
          arr[index] = {
            name: arr[index].name,
            address: text
          };
          root.hostsField.set(arr);
        }
      }

      AtmoIconButton {
        Layout.alignment: Qt.AlignBottom
        Layout.bottomMargin: Style.marginS
        icon: "trash"
        tooltipText: pluginApi?.tr("settings.hosts.remove")
        enabled: root.valueHosts.length > 1
        onClicked: {
          const arr = root.valueHosts.slice();
          arr.splice(index, 1);
          root.hostsField.set(arr);
        }
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NTextInput {
      id: addNameField
      Layout.preferredWidth: 120 * Style.uiScaleRatio
      placeholderText: pluginApi?.tr("settings.hosts.namePlaceholder")
    }

    NTextInput {
      id: addAddrField
      Layout.fillWidth: true
      placeholderText: pluginApi?.tr("settings.hosts.addressPlaceholder")
    }

    AtmoIconButton {
      Layout.alignment: Qt.AlignBottom
      Layout.bottomMargin: Style.marginS
      icon: "plus"
      tooltipText: pluginApi?.tr("settings.hosts.add")
      enabled: addNameField.text.trim() !== "" && addAddrField.text.trim() !== ""
      onClicked: {
        root.hostsField.set(root.valueHosts.concat([
                                                     {
                                                       name: addNameField.text.trim(),
                                                       address: addAddrField.text.trim()
                                                     }
                                                   ]));
        addNameField.text = "";
        addAddrField.text = "";
      }
    }
  }

  NPluginSettingsField {
    field: root.barHostField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.barHost.label")
      description: pluginApi?.tr("settings.barHost.desc")
      currentKey: root.valueBarHost
      model: {
        const base = [
                {
                  key: "worst",
                  name: pluginApi?.tr("settings.barHost.worst")
                }
              ];
        for (const h of root.valueHosts)
          base.push({
                      key: h.name,
                      name: h.name
                    });
        return base;
      }
      onSelected: key => root.barHostField.set(key)
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NHeader {
    label: pluginApi?.tr("settings.interval.header")
    description: pluginApi?.tr("settings.interval.desc")
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NText {
      text: pluginApi?.tr("settings.interval.label")
      pointSize: Style.fontSizeS
      color: AtmoColor.mOnSurface
      Layout.fillWidth: true
    }

    NText {
      text: root.valueIntervalSeconds + " s"
      pointSize: Style.fontSizeS
      color: AtmoColor.mSecondary
      font.family: "monospace"
    }
  }

  NPluginSettingsField {
    field: root.intervalSecondsField
    NSlider {
      id: rangeValueIntervalSeconds
      objectName: "settings-range-valueIntervalSeconds"
      Layout.fillWidth: true
      from: 1
      to: 30
      stepSize: 1
      value: root.valueIntervalSeconds
      onMoved: root.intervalSecondsField.set(Math.round(value))
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NHeader {
    label: pluginApi?.tr("settings.thresholds.header")
    description: pluginApi?.tr("settings.thresholds.desc")
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM
    NText {
      text: pluginApi?.tr("settings.thresholds.good")
      pointSize: Style.fontSizeS
      color: AtmoColor.mOnSurface
      Layout.fillWidth: true
    }
    NText {
      text: root.valueThresholdGood + " ms"
      pointSize: Style.fontSizeS
      color: root.valueColorGood
      font.family: "monospace"
    }
  }
  NPluginSettingsField {
    field: root.thresholdGoodField
    NSlider {
      id: rangeValueThresholdGood
      objectName: "settings-range-valueThresholdGood"
      Layout.fillWidth: true
      from: 5
      to: 100
      stepSize: 5
      value: root.valueThresholdGood
      onMoved: root.thresholdGoodField.set(Math.round(value))
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM
    NText {
      text: pluginApi?.tr("settings.thresholds.warning")
      pointSize: Style.fontSizeS
      color: AtmoColor.mOnSurface
      Layout.fillWidth: true
    }
    NText {
      text: root.valueThresholdWarning + " ms"
      pointSize: Style.fontSizeS
      color: root.valueColorWarning
      font.family: "monospace"
    }
  }
  NPluginSettingsField {
    field: root.thresholdWarningField
    NSlider {
      id: rangeValueThresholdWarning
      objectName: "settings-range-valueThresholdWarning"
      Layout.fillWidth: true
      from: root.valueThresholdGood + 5   // can't go below good threshold
      to: 500
      stepSize: 5
      value: root.valueThresholdWarning
      onMoved: root.thresholdWarningField.set(Math.round(value))
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NHeader {
    label: pluginApi?.tr("settings.display.header")
    Layout.bottomMargin: -Style.marginM
  }

  NPluginSettingsField {
    field: root.showHostNameField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.showHostName.label")
      description: pluginApi?.tr("settings.showHostName.desc")
      checked: root.valueShowHostName
      onToggled: checked => root.showHostNameField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.animationsField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.animations.label")
      description: pluginApi?.tr("settings.animations.desc")
      checked: root.valueAnimations
      onToggled: checked => root.animationsField.set(checked)
    }
  }

  RowLayout {
    NLabel {
      label: pluginApi?.tr("settings.colorGood.label")
      Layout.alignment: Qt.AlignCenter
    }

    NPluginSettingsField {
      field: root.colorGoodField
      NColorPicker {
        selectedColor: root.valueColorGood
        onColorSelected: key => root.colorGoodField.set(key)
      }
    }
  }

  RowLayout {
    NLabel {
      label: pluginApi?.tr("settings.colorWarning.label")
      Layout.alignment: Qt.AlignCenter
    }

    NPluginSettingsField {
      field: root.colorWarningField
      NColorPicker {
        selectedColor: root.valueColorWarning
        onColorSelected: key => root.colorWarningField.set(key)
      }
    }
  }

  RowLayout {
    NLabel {
      label: pluginApi?.tr("settings.colorCritical.label")
      Layout.alignment: Qt.AlignCenter
    }

    NPluginSettingsField {
      field: root.colorCriticalField
      NColorPicker {
        selectedColor: root.valueColorCritical
        onColorSelected: key => root.colorCriticalField.set(key)
      }
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("LatencyMonitor", "Settings saved");
    });
  }
}
