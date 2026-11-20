import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var showCityNameField: pluginApi?.field("showCityName") ?? null
  readonly property var showIpField: pluginApi?.field("showIp") ?? null
  readonly property var compactModeField: pluginApi?.field("compactMode") ?? null
  readonly property var clickActionField: pluginApi?.field("clickAction") ?? null
  readonly property var relayClickConnectsField: pluginApi?.field("relayClickConnects") ?? null
  readonly property var confirmDisconnectInLockdownField: pluginApi?.field("confirmDisconnectInLockdown") ?? null
  readonly property var expiryWarningDaysField: pluginApi?.field("expiryWarningDays") ?? null
  readonly property var favoriteCountriesField: pluginApi?.field("favoriteCountries") ?? null
  spacing: Style.marginS

  // cfg -> defaults -> hardcoded fallback chain (per AGENTS.md)
  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property int refreshInterval: root.refreshIntervalField?.value ?? 3000
  property bool showCountryFlag: cfg.showCountryFlag ?? defaults.showCountryFlag ?? false
  readonly property bool showCityName: root.showCityNameField?.value ?? false
  readonly property bool showIp: root.showIpField?.value ?? false
  readonly property bool compactMode: root.compactModeField?.value ?? false
  readonly property string clickAction: root.clickActionField?.value ?? "panel"
  readonly property bool relayClickConnects: root.relayClickConnectsField?.value ?? true
  readonly property bool confirmDisconnectInLockdown: root.confirmDisconnectInLockdownField?.value ?? true
  readonly property int expiryWarningDays: root.expiryWarningDaysField?.value ?? 7
  readonly property string favoriteCountriesText: (root.favoriteCountriesField?.value ?? []).join(",")

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Mullvad", "Cannot save: pluginApi is null");
      return;
    }
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("Mullvad", "Settings saved");
    });
  }

  NPluginSettingsField {
    field: root.refreshIntervalField
    NSpinBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.refresh-interval")
      from: 1000
      to: 60000
      stepSize: 500
      value: root.refreshInterval
      onValueModified: value => root.refreshIntervalField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.showCityNameField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-city")
      checked: root.showCityName
      onToggled: checked => root.showCityNameField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.showIpField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-ip")
      checked: root.showIp
      onToggled: checked => root.showIpField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.compactModeField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.compact-mode")
      checked: root.compactMode
      onToggled: checked => root.compactModeField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.clickActionField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.click-action")
      model: [
        {
          key: "toggle",
          name: pluginApi?.tr("settings.click-toggle")
        },
        {
          key: "panel",
          name: pluginApi?.tr("settings.click-panel")
        }
      ]
      currentKey: root.clickAction
      onSelected: key => root.clickActionField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.relayClickConnectsField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.relay-click-connects")
      checked: root.relayClickConnects
      onToggled: checked => root.relayClickConnectsField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.confirmDisconnectInLockdownField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.confirm-disconnect-lockdown")
      checked: root.confirmDisconnectInLockdown
      onToggled: checked => root.confirmDisconnectInLockdownField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.expiryWarningDaysField
    NSpinBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.expiry-warning-days")
      from: 0
      to: 90
      value: root.expiryWarningDays
      onValueModified: value => root.expiryWarningDaysField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.favoriteCountriesField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.favorite-countries")
      text: root.favoriteCountriesText
      onEditCommitted: root.favoriteCountriesField.set(text.split(",").map(function (s) {
        return s.trim().toLowerCase();
      }).filter(function (s) {
        return s.length === 2;
      }))
    }
  }
}
