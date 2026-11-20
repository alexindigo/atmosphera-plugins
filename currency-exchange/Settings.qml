import QtQuick
import QtQuick.Layouts
import "CurrencyData.js" as CurrencyData
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  // Currency model with translated names
  property var currencyModel: pluginApi ? buildTranslatedCurrencyModel() : CurrencyData.buildComboModel(false)
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Display mode options
  property var displayModeModel: [
    {
      "key": "icon",
      "name": pluginApi?.tr("settings.display_modes.icon") || "Icon only"
    },
    {
      "key": "compact",
      "name": pluginApi?.tr("settings.display_modes.compact") || "Compact (rate number)"
    },
    {
      "key": "full",
      "name": pluginApi?.tr("settings.display_modes.full") || "Currency pair"
    }
  ]
  property var pluginApi: null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null

  // Refresh interval options (in minutes)
  property var refreshIntervalModel: [
    {
      "key": "15",
      "name": pluginApi?.tr("settings.intervals.15") || "15 minutes"
    },
    {
      "key": "30",
      "name": pluginApi?.tr("settings.intervals.30") || "30 minutes"
    },
    {
      "key": "60",
      "name": pluginApi?.tr("settings.intervals.60") || "1 hour"
    },
    {
      "key": "180",
      "name": pluginApi?.tr("settings.intervals.180") || "3 hours"
    },
    {
      "key": "360",
      "name": pluginApi?.tr("settings.intervals.360") || "6 hours"
    },
    {
      "key": "720",
      "name": pluginApi?.tr("settings.intervals.720") || "12 hours"
    }
  ]
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  readonly property var sourceCurrencyField: pluginApi?.field("sourceCurrency") ?? null
  readonly property var targetCurrencyField: pluginApi?.field("targetCurrency") ?? null
  readonly property string valueRefreshInterval: String(root.refreshIntervalField?.value ?? 60)

  // Global currency settings (used by launcher, widget, and panel)
  readonly property string valueSourceCurrency: root.sourceCurrencyField?.value || "USD"
  readonly property string valueTargetCurrency: root.targetCurrencyField?.value || "EUR"

  // Widget settings
  readonly property string valueWidgetDisplayMode: root.widgetDisplayModeField?.value || "icon"
  readonly property var widgetDisplayModeField: pluginApi?.field("widgetDisplayMode") ?? null

  function buildTranslatedCurrencyModel() {
    var model = [];
    for (var i = 0; i < CurrencyData.currencies.length; i++) {
      var code = CurrencyData.currencies[i];
      var translatedName = pluginApi?.tr("currencies." + code) || CurrencyData.currencyNames[code];
      model.push({
                   "key": code,
                   "name": translatedName + " (" + code + ")"
                 });
    }
    return model;
  }
  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }

  spacing: Style.marginL

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      Layout.bottomMargin: Style.marginS
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.general") || "General Settings"
    }
    NPluginSettingsField {
      field: root.sourceCurrencyField

      NComboBox {
        Layout.fillWidth: true
        currentKey: valueSourceCurrency
        description: pluginApi?.tr("settings.source_currency_description") || "Default currency to convert from"
        label: pluginApi?.tr("settings.source_currency") || "Source Currency"
        minimumWidth: 280
        model: currencyModel

        onSelected: key => {
          root.sourceCurrencyField.set(key);
        }
      }
    }
    NPluginSettingsField {
      field: root.targetCurrencyField

      NComboBox {
        Layout.fillWidth: true
        currentKey: valueTargetCurrency
        description: pluginApi?.tr("settings.target_currency_description") || "Default currency to convert to"
        label: pluginApi?.tr("settings.target_currency") || "Target Currency"
        minimumWidth: 280
        model: currencyModel

        onSelected: key => {
          root.targetCurrencyField.set(key);
        }
      }
    }
  }
  NDivider {
    Layout.bottomMargin: Style.marginM
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
  }
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      Layout.bottomMargin: Style.marginS
      // description: "Configure the bar widget appearance and behavior"
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.widget") || "Widget Settings"
    }
    NPluginSettingsField {
      field: root.widgetDisplayModeField

      NComboBox {
        Layout.fillWidth: true
        currentKey: valueWidgetDisplayMode
        description: pluginApi?.tr("settings.display_mode_description") || "How much information to show in the bar widget"
        label: pluginApi?.tr("settings.display_mode") || "Display Mode"
        minimumWidth: 240
        model: displayModeModel

        onSelected: key => {
          root.widgetDisplayModeField.set(key);
        }
      }
    }
    NPluginSettingsField {
      field: root.refreshIntervalField

      NComboBox {
        Layout.fillWidth: true
        currentKey: valueRefreshInterval
        defaultValue: defaults.refreshInterval
        description: pluginApi?.tr("settings.refresh_interval_description") || "How often to refresh exchange rates automatically"
        label: pluginApi?.tr("settings.refresh_interval") || "Auto-refresh Interval"
        minimumWidth: 240
        model: refreshIntervalModel

        onSelected: key => root.refreshIntervalField.set(parseInt(key))
      }
    }
  }
  Item {
    Layout.fillHeight: true
  }
}
