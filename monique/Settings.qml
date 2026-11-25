import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var activeColorField: pluginApi?.field("activeColor") ?? null
  readonly property var showProfileLabelField: pluginApi?.field("showProfileLabel") ?? null

  readonly property int editRefreshInterval: root.refreshIntervalField?.value || 3000
  readonly property bool editShowProfileLabel: root.showProfileLabelField?.value ?? false
  readonly property string editActiveColor: root.activeColorField?.value || "primary"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
    text: root.pluginApi?.tr("settings.shared-observation") ?? ""
  }

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

  NPluginSettingsField {
    field: root.showProfileLabelField
    NToggle {
      label: pluginApi?.tr("settings.show-profile-label")
      description: pluginApi?.tr("settings.show-profile-label-desc")
      checked: root.editShowProfileLabel
      onToggled: checked => root.showProfileLabelField.set(checked)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NPluginSettingsField {
    field: root.activeColorField
    NColorChoice {
      label: pluginApi?.tr("settings.active-color")
      description: pluginApi?.tr("settings.active-color-desc")
      currentKey: root.editActiveColor
      onSelected: key => root.activeColorField.set(key)
    }
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

  NPluginSettingsField {
    field: root.refreshIntervalField
    NSlider {
      id: rangeEditRefreshInterval
      objectName: "settings-range-editRefreshInterval"
      Layout.fillWidth: true
      from: 1000
      to: 30000
      stepSize: 1000
      value: root.editRefreshInterval
      onMoved: root.refreshIntervalField.set(value)
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("Monique", "Settings saved");
    });
  }
}
