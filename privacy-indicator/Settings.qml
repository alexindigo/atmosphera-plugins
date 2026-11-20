import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var hideInactiveField: pluginApi?.field("hideInactive") ?? null
  readonly property var enableToastField: pluginApi?.field("enableToast") ?? null
  readonly property var iconSpacingField: pluginApi?.field("iconSpacing") ?? null
  readonly property var removeMarginsField: pluginApi?.field("removeMargins") ?? null
  readonly property var activeColorField: pluginApi?.field("activeColor") ?? null
  readonly property var inactiveColorField: pluginApi?.field("inactiveColor") ?? null
  readonly property var micFilterRegexField: pluginApi?.field("micFilterRegex") ?? null
  readonly property var camFilterRegexField: pluginApi?.field("camFilterRegex") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property bool hideInactive: root.hideInactiveField?.value ?? false
  readonly property bool enableToast: root.enableToastField?.value ?? true
  readonly property bool removeMargins: root.removeMarginsField?.value ?? false
  readonly property int iconSpacing: root.iconSpacingField?.value ?? 4
  readonly property string activeColor: root.activeColorField?.value ?? "primary"
  readonly property string inactiveColor: root.inactiveColorField?.value ?? "none"
  readonly property string micFilterRegex: root.micFilterRegexField?.value ?? defaults.micFilterRegex
  readonly property string camFilterRegex: root.camFilterRegexField?.value ?? defaults.camFilterRegex

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.i("PrivacyIndicator", "Settings UI loaded");
  }

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NPluginSettingsField {
      field: root.hideInactiveField
      NToggle {
        label: pluginApi?.tr("settings.hideInactive.label")
        description: pluginApi?.tr("settings.hideInactive.desc")

        checked: root.hideInactive
        onToggled: checked => {
          root.hideInactiveField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.enableToastField
      NToggle {
        label: pluginApi?.tr("settings.enableToast.label")
        description: pluginApi?.tr("settings.enableToast.desc")

        checked: root.enableToast
        onToggled: checked => {
          root.enableToastField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.removeMarginsField
      NToggle {
        label: pluginApi?.tr("settings.removeMargins.label")
        description: pluginApi?.tr("settings.removeMargins.desc")

        checked: root.removeMargins
        onToggled: checked => {
          root.removeMarginsField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.activeColorField
      NColorChoice {
        label: pluginApi?.tr("settings.activeColor.label")
        description: pluginApi?.tr("settings.activeColor.desc")
        currentKey: root.activeColor
        onSelected: key => root.activeColorField.set(key)
      }
    }

    NPluginSettingsField {
      field: root.inactiveColorField
      NColorChoice {
        label: pluginApi?.tr("settings.inactiveColor.label")
        description: pluginApi?.tr("settings.inactiveColor.desc")
        currentKey: root.inactiveColor
        onSelected: key => root.inactiveColorField.set(key)
        noneColor: Qt.alpha(AtmoColor.mOnSurfaceVariant, 0.3)
        noneOnColor: Qt.alpha(AtmoColor.mOnSurface, 0.7)
      }
    }

    NPluginSettingsField {
      field: root.iconSpacingField
      NComboBox {
        label: pluginApi?.tr("settings.iconSpacing.label")
        description: pluginApi?.tr("settings.iconSpacing.desc")

        model: {
          const labels = ["XXS", "XS", "S", "M", "L", "XL"];
          const values = [Style.marginXXS, Style.marginXS, Style.marginS, Style.marginM, Style.marginL, Style.marginXL];

          const result = [];
          for (var i = 0; i < labels.length; ++i) {
            const v = values[i];
            result.push({
                          key: v.toFixed(0),
                          name: `${labels[i]} (${v}px)`
                        });
          }
          return result;
        }

        // INFO: From my understanding, the toFixed(0) shouldn't be needed here and there, but without the
        // current key does not show when opening the settings window.
        currentKey: root.iconSpacing.toFixed(0)
        onSelected: key => root.iconSpacingField.set(key)
      }
    }

    NPluginSettingsField {
      field: root.micFilterRegexField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.micFilterRegex.label")
        description: pluginApi?.tr("settings.micFilterRegex.desc")
        placeholderText: "effect_input.rnnoise|easyeffects"
        text: root.micFilterRegex
        onEditCommitted: root.micFilterRegexField.set(text)
      }
    }

    NPluginSettingsField {
      field: root.camFilterRegexField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.camFilterRegex.label")
        description: pluginApi?.tr("settings.camFilterRegex.desc")
        placeholderText: "droidcam"
        text: root.camFilterRegex
        onEditCommitted: root.camFilterRegexField.set(text)
      }
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("PrivacyIndicator", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("PrivacyIndicator", "Settings saved successfully");
    });
  }
}
