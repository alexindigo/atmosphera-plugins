import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property int editRefreshInterval: displayBaseline.editRefreshInterval
  property string editConnectedColor: displayBaseline.editConnectedColor
  property string editDisconnectedColor: displayBaseline.editDisconnectedColor
  NSettingsBaseline {
    id: displayBaseline
    readonly property int editRefreshInterval: pluginApi?.pluginSettings?.refreshInterval || pluginApi?.manifest?.metadata?.defaultSettings?.refreshInterval || 5000
    readonly property string editConnectedColor: pluginApi?.pluginSettings?.connectedColor || pluginApi?.manifest?.metadata?.defaultSettings?.connectedColor || "primary"
    readonly property string editDisconnectedColor: pluginApi?.pluginSettings?.disconnectedColor || pluginApi?.manifest?.metadata?.defaultSettings?.disconnectedColor || "none"
  }
  readonly property bool settingsDirty: displayBaseline.differs({editRefreshInterval: root.editRefreshInterval, editConnectedColor: root.editConnectedColor, editDisconnectedColor: root.editDisconnectedColor})

  spacing: Style.marginM

  NText {
    text: pluginApi?.tr("settings.title")
    font.pointSize: Style.fontSizeXL
    font.bold: true
  }

  NText {
    text: pluginApi?.tr("settings.description")
    color: AtmoColor.mSecondary
    Layout.fillWidth: true
    wrapMode: Text.Wrap
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NColorChoice {
    label: pluginApi?.tr("settings.connected-color")
    description: pluginApi?.tr("settings.connected-color-desc")
    currentKey: root.editConnectedColor
    onSelected: key => root.editConnectedColor = key
  }

  NColorChoice {
    label: pluginApi?.tr("settings.disconnected-color")
    description: pluginApi?.tr("settings.disconnected-color-desc")
    currentKey: root.editDisconnectedColor
    onSelected: key => root.editDisconnectedColor = key
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NLabel {
    label: pluginApi?.tr("settings.refresh-interval")
    description: pluginApi?.tr("settings.refresh-interval-desc") + " (" + root.editRefreshInterval + " ms)"
  }

  NSlider {
    Layout.fillWidth: true
    from: 1000
    to: 60000
    stepSize: 1000
    value: root.editRefreshInterval
    onValueChanged: root.editRefreshInterval = value
  }

  function saveSettings() {
    if (!pluginApi) return

    pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval
    pluginApi.pluginSettings.connectedColor = root.editConnectedColor
    pluginApi.pluginSettings.disconnectedColor = root.editDisconnectedColor

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("CloudflareWarp", "Settings saved")
    })
  }
}
