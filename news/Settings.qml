import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  property var pluginApi: null
  readonly property var apiKeyField: pluginApi?.field("apiKey") ?? null
  readonly property var countryField: pluginApi?.field("country") ?? null
  readonly property var languageField: pluginApi?.field("language") ?? null
  readonly property var categoryField: pluginApi?.field("category") ?? null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var maxHeadlinesField: pluginApi?.field("maxHeadlines") ?? null
  readonly property var widgetWidthField: pluginApi?.field("widgetWidth") ?? null
  readonly property var rollingSpeedField: pluginApi?.field("rollingSpeed") ?? null

  // Local state
  readonly property string apiKeyValue: root.apiKeyField?.value ?? "YOUR_API_KEY_HERE"
  readonly property string countryValue: root.countryField?.value ?? "us"
  readonly property string languageValue: root.languageField?.value ?? "en"
  readonly property string categoryValue: root.categoryField?.value ?? "general"
  readonly property int refreshIntervalValue: root.refreshIntervalField?.value ?? 30
  readonly property int maxHeadlinesValue: root.maxHeadlinesField?.value ?? 10
  readonly property int widgetWidthValue: root.widgetWidthField?.value ?? 300
  readonly property int rollingSpeedValue: root.rollingSpeedField?.value ?? 50
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi)
      return;

    pluginApi.saveSettings();
  }

  NPluginSettingsField {
    field: root.apiKeyField
    NTextInput {
      label: "API Key"
      description: "Get your free API key from newsapi.org/register"
      text: apiKeyValue
      onEditCommitted: {
        root.apiKeyField.set(text);
      }
    }
  }

  NButton {
    text: "Get API Key"
    icon: "external-link"
    onClicked: Qt.openUrlExternally("https://newsapi.org/register")
  }

  NPluginSettingsField {
    field: root.countryField
    NComboBox {
      label: "Country/Region"
      description: "Note: NewsAPI free tier only supports US for country-specific top headlines. Other regions use language-based filtering instead."
      minimumWidth: 200
      model: [
        {
          "key": "us",
          "name": "United States (English)"
        },
        {
          "key": "gb",
          "name": "United Kingdom (English)"
        },
        {
          "key": "ca",
          "name": "Canada (English)"
        },
        {
          "key": "au",
          "name": "Australia (English)"
        },
        {
          "key": "de",
          "name": "Germany (German)"
        },
        {
          "key": "fr",
          "name": "France (French)"
        },
        {
          "key": "it",
          "name": "Italy (Italian)"
        },
        {
          "key": "es",
          "name": "Spain (Spanish)"
        },
        {
          "key": "mx",
          "name": "Mexico (Spanish)"
        },
        {
          "key": "br",
          "name": "Brazil (Portuguese)"
        },
        {
          "key": "jp",
          "name": "Japan (Japanese)"
        },
        {
          "key": "kr",
          "name": "South Korea (Korean)"
        },
        {
          "key": "nl",
          "name": "Netherlands (Dutch)"
        },
        {
          "key": "se",
          "name": "Sweden (Swedish)"
        },
        {
          "key": "no",
          "name": "Norway (Norwegian)"
        },
        {
          "key": "in",
          "name": "India (English)"
        }
      ]
      currentKey: countryValue
      onSelected: key => {
        root.countryField.set(key);
      }
    }
  }

  NPluginSettingsField {
    field: root.languageField
    NComboBox {
      label: "Language Override"
      description: "Manually override language (auto-detected from country by default)"
      minimumWidth: 200
      model: [
        {
          "key": "en",
          "name": "English"
        },
        {
          "key": "de",
          "name": "German"
        },
        {
          "key": "fr",
          "name": "French"
        },
        {
          "key": "it",
          "name": "Italian"
        },
        {
          "key": "es",
          "name": "Spanish"
        },
        {
          "key": "pt",
          "name": "Portuguese"
        },
        {
          "key": "nl",
          "name": "Dutch"
        },
        {
          "key": "no",
          "name": "Norwegian"
        },
        {
          "key": "sv",
          "name": "Swedish"
        },
        {
          "key": "ja",
          "name": "Japanese"
        },
        {
          "key": "ko",
          "name": "Korean"
        },
        {
          "key": "ar",
          "name": "Arabic"
        },
        {
          "key": "ru",
          "name": "Russian"
        },
        {
          "key": "zh",
          "name": "Chinese"
        }
      ]
      currentKey: languageValue
      onSelected: key => {
        root.languageField.set(key);
      }
    }
  }

  NPluginSettingsField {
    field: root.categoryField
    NComboBox {
      label: "Category"
      description: "Filter news by category"
      minimumWidth: 200
      model: [
        {
          "key": "general",
          "name": "General"
        },
        {
          "key": "business",
          "name": "Business"
        },
        {
          "key": "entertainment",
          "name": "Entertainment"
        },
        {
          "key": "health",
          "name": "Health"
        },
        {
          "key": "science",
          "name": "Science"
        },
        {
          "key": "sports",
          "name": "Sports"
        },
        {
          "key": "technology",
          "name": "Technology"
        }
      ]
      currentKey: categoryValue
      onSelected: key => {
        root.categoryField.set(key);
      }
    }
  }

  NPluginSettingsField {
    field: root.refreshIntervalField
    NSpinBox {
      label: "Refresh Interval"
      description: "Check for new headlines every " + refreshIntervalValue + " minutes"
      from: 5
      to: 1440
      stepSize: 5
      value: refreshIntervalValue
      requestValue: value => {
        root.refreshIntervalField.set(value);
      }
    }
  }

  NPluginSettingsField {
    field: root.maxHeadlinesField
    NSpinBox {
      label: "Max Headlines"
      description: "Maximum number of headlines to display"
      from: 1
      to: 100
      value: maxHeadlinesValue
      requestValue: value => {
        root.maxHeadlinesField.set(value);
      }
    }
  }

  NPluginSettingsField {
    field: root.widgetWidthField
    NSpinBox {
      label: "Widget Width"
      description: "Widget width in pixels: " + widgetWidthValue + "px"
      from: 100
      to: 1000
      stepSize: 10
      value: widgetWidthValue
      requestValue: value => {
        root.widgetWidthField.set(value);
      }
    }
  }

  NPluginSettingsField {
    field: root.rollingSpeedField
    NSpinBox {
      label: "Scroll Speed"
      description: "Time in ms per pixel (lower = faster): " + rollingSpeedValue + "ms"
      from: 10
      to: 200
      stepSize: 10
      value: rollingSpeedValue
      requestValue: value => {
        root.rollingSpeedField.set(value);
      }
    }
  }
}
