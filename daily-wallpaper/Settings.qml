import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var sourceField: pluginApi?.field("source") ?? null
  readonly property var localeField: pluginApi?.field("locale") ?? null
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string systemLocale: Qt.locale().name.replace("_", "-")
  readonly property string configuredLocale: cfg.locale ?? defaults.locale ?? ""

  readonly property string selectedSource: root.sourceField?.value ?? "bing"
  readonly property string localeText: configuredLocale && configuredLocale.trim().length > 0 ? configuredLocale : systemLocale
  property bool _applyEffectPending: false
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._applyEffectPending = false;
      root.pluginApi.mainInstance?.checkAndFetchWallpaper();
    }
  }

  spacing: Style.marginL

  NPluginSettingsField {
    field: root.sourceField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.source.label")
      model: [
        {
          "key": "bing",
          "name": pluginApi.tr("settings.source.options.bing")
        },
        {
          "key": "nasa",
          "name": pluginApi.tr("settings.source.options.nasa")
        }
      ]
      currentKey: root.selectedSource
      onSelected: key => root.sourceField.set(key)
      defaultValue: "bing"
    }
  }

  Loader {
    Layout.fillWidth: true
    active: root.selectedSource === "bing"
    sourceComponent: ColumnLayout {
      spacing: Style.marginS

      NPluginSettingsField {
        field: root.localeField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.locale.label")
          text: root.localeText
          onEditCommitted: {
            if (text !== root.localeText) {
              root.localeField.set(text);
            }
          }
        }
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }

  function saveSettings() {
    if (!pluginApi) {
      return;
    }

    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true;
  }
}
