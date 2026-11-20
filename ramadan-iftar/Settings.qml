import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var cityField: pluginApi?.field("city") ?? null
  readonly property var countryField: pluginApi?.field("country") ?? null
  readonly property var methodField: pluginApi?.field("method") ?? null
  readonly property var showAlwaysField: pluginApi?.field("showAlways") ?? null
  readonly property var showCountdownField: pluginApi?.field("showCountdown") ?? null

  readonly property string valueCity: root.cityField?.value ?? "London"
  readonly property string valueCountry: root.countryField?.value ?? "UK"
  readonly property int valueMethod: root.methodField?.value ?? 3
  readonly property bool valueShowAlways: root.showAlwaysField?.value ?? true
  readonly property bool valueShowCountdown: root.showCountdownField?.value ?? true

  spacing: Style.marginL

  NHeader {
    label: pluginApi?.tr("settings.location.header") || "Location"
    description: pluginApi?.tr("settings.location.desc") || "Used to fetch daily prayer times from Aladhan API."
  }

  NPluginSettingsField {
    field: root.cityField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.city.label") || "City"
      description: pluginApi?.tr("settings.city.desc") || "Enter your city name in English."
      placeholderText: "London"
      text: root.valueCity
      onEditCommitted: root.cityField.set(text.trim())
    }
  }

  NPluginSettingsField {
    field: root.countryField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.country.label") || "Country"
      description: pluginApi?.tr("settings.country.desc") || "Enter your country name or 2-letter code."
      placeholderText: "UK"
      text: root.valueCountry
      onEditCommitted: root.countryField.set(text.trim())
    }
  }

  NPluginSettingsField {
    field: root.methodField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.method.label") || "Calculation Method"
      description: pluginApi?.tr("settings.method.desc") || "Determines how prayer times are calculated."
      currentKey: String(root.valueMethod)
      model: [
        {
          "key": "1",
          "name": "University of Islamic Sciences, Karachi"
        },
        {
          "key": "2",
          "name": "Islamic Society of North America (ISNA)"
        },
        {
          "key": "3",
          "name": "Muslim World League (MWL)"
        },
        {
          "key": "4",
          "name": "Umm Al-Qura University, Makkah"
        },
        {
          "key": "5",
          "name": "Egyptian General Authority of Survey"
        },
        {
          "key": "7",
          "name": "Institute of Geophysics, Tehran"
        },
        {
          "key": "8",
          "name": "Gulf Region"
        },
        {
          "key": "9",
          "name": "Kuwait"
        },
        {
          "key": "10",
          "name": "Qatar"
        },
        {
          "key": "11",
          "name": "Majlis Ugama Islam Singapura"
        },
        {
          "key": "12",
          "name": "Union Organization Islamic de France"
        },
        {
          "key": "13",
          "name": "Diyanet İşleri Başkanlığı, Turkey"
        },
        {
          "key": "14",
          "name": "Spiritual Administration of Muslims of Russia"
        },
        {
          "key": "15",
          "name": "Moonsighting Committee Worldwide"
        }
      ]
      onSelected: key => root.methodField.set(parseInt(key))
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NHeader {
    label: pluginApi?.tr("settings.display.header") || "Display"
  }

  NPluginSettingsField {
    field: root.showCountdownField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.showCountdown.label") || "Show countdown"
      description: pluginApi?.tr("settings.showCountdown.desc") || "Show a countdown to Iftar instead of the static time."
      checked: root.valueShowCountdown
      onToggled: checked => root.showCountdownField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.showAlwaysField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.showAlways.label") || "Show outside Ramadan"
      description: pluginApi?.tr("settings.showAlways.desc") || "Keep the bar widget visible even when it is not Ramadan."
      checked: root.valueShowAlways
      onToggled: checked => root.showAlwaysField.set(checked)
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("RamadanIftar", "Settings saved");
    });
  }
}
