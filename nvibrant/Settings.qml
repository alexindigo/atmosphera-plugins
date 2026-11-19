import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  readonly property var cfg: pluginApi?.pluginSettings ?? ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})

  property alias editVibranceValue: vibranceSpinBox.value
  property alias editDisplayIndex: displayIndexSpinBox.value
  NSettingsBaseline {
    id: displayBaseline
    readonly property int editVibranceValue: root.cfg.vibranceValue ?? root.defaults.vibranceValue ?? 512
    readonly property int editDisplayIndex: root.cfg.displayIndex ?? root.defaults.displayIndex ?? 1
  }
  readonly property bool settingsDirty: displayBaseline.differs({editVibranceValue: root.editVibranceValue, editDisplayIndex: root.editDisplayIndex})

  spacing: Style.marginM

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.vibrance-value")
      description: pluginApi?.tr("settings.vibrance-value-desc")
    }

    NSpinBox {
      id: vibranceSpinBox
      from: 0
      to: 1023
      stepSize: 64
      value: displayBaseline.editVibranceValue
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.display-index")
      description: pluginApi?.tr("settings.display-index-desc")
    }

    NSpinBox {
      id: displayIndexSpinBox
      from: 1
      to: 8
      stepSize: 1
      value: displayBaseline.editDisplayIndex
    }
  }

  function saveSettings() {
    if (!pluginApi) return
    pluginApi.pluginSettings.vibranceValue = vibranceSpinBox.value
    pluginApi.pluginSettings.displayIndex  = displayIndexSpinBox.value
    pluginApi.saveSettings()
  }
}
