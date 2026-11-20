import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var storePathField: pluginApi?.field("storePath") ?? null
  readonly property var typeDelayField: pluginApi?.field("typeDelay") ?? null
  readonly property var wtypeDelayField: pluginApi?.field("wtypeDelay") ?? null
  readonly property var clipTimeoutField: pluginApi?.field("clipTimeout") ?? null

  readonly property string editStorePath: root.storePathField?.value ?? ""
  readonly property string editTypeDelay: String(root.typeDelayField?.value ?? 500)
  readonly property string editWtypeDelay: String(root.wtypeDelayField?.value ?? 12)
  readonly property string editClipTimeout: root.clipTimeoutField?.value ?? ""
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  readonly property string envClipTimeout: Quickshell.env("PASSWORD_STORE_CLIP_TIME") || ""

  spacing: Style.marginL

  NTabBar {
    id: tabBar
    Layout.fillWidth: true
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      text: pluginApi?.tr("settings.tab.general")
      tabIndex: 0
      checked: tabBar.currentIndex === 0
    }

    NTabButton {
      text: pluginApi?.tr("settings.tab.advanced")
      tabIndex: 1
      checked: tabBar.currentIndex === 1
    }
  }

  NTabView {
    id: tabView
    Layout.fillWidth: true
    Layout.fillHeight: true
    currentIndex: tabBar.currentIndex

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginL

      NPluginSettingsField {
        field: root.storePathField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.storePath.label")
          description: pluginApi?.tr("settings.storePath.desc")
          text: root.editStorePath
          onEditCommitted: root.storePathField.set(text)
        }
      }

      NPluginSettingsField {
        field: root.clipTimeoutField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.clipTimeout.label")
          description: pluginApi?.tr("settings.clipTimeout.desc", {
                                       value: root.envClipTimeout
                                     })
          text: root.editClipTimeout
          onEditCommitted: root.clipTimeoutField.set(text)
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginL

      NPluginSettingsField {
        field: root.typeDelayField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.typeDelay.label")
          description: pluginApi?.tr("settings.typeDelay.desc")
          text: root.editTypeDelay
          onEditCommitted: {
            var value = parseFloat(text);
            root.typeDelayField.set(isNaN(value) || value < 0 ? 500 : value);
          }
        }
      }

      NPluginSettingsField {
        field: root.wtypeDelayField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.wtypeDelay.label")
          description: pluginApi?.tr("settings.wtypeDelay.desc")
          text: root.editWtypeDelay
          onEditCommitted: {
            var value = parseInt(text);
            root.wtypeDelayField.set(isNaN(value) || value < 0 ? 12 : value);
          }
        }
      }
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;

    pluginApi.saveSettings();
  }
}
