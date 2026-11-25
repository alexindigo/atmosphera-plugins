import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var search_engineField: pluginApi?.field("search_engine") ?? null
  readonly property var direct_urlField: pluginApi?.field("direct_url") ?? null
  readonly property var show_suggestionsField: pluginApi?.field("show_suggestions") ?? null
  readonly property var max_resultsField: pluginApi?.field("max_results") ?? null

  readonly property string valueSearchEngine: root.search_engineField?.value ?? "Google"
  readonly property bool valueDirectUrl: root.direct_urlField?.value ?? true
  readonly property bool valueShowSuggestions: root.show_suggestionsField?.value ?? true
  readonly property int valueMaxResults: root.max_resultsField?.value ?? 5

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.d("WebSearch", "Settings UI loaded");
  }

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NPluginSettingsField {
      field: root.search_engineField
      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.engine.label")
        description: pluginApi?.tr("settings.engine.description")
        model: ["Google", "DuckDuckGo", "Bing", "Brave", "Yandex"].map(function (n) {
          return {
            key: n,
            name: n
          };
        })

        currentKey: root.valueSearchEngine
        onSelected: key => root.search_engineField.set(key)
      }
    }

    NPluginSettingsField {
      field: root.direct_urlField
      NToggle {
        label: pluginApi?.tr("settings.directUrl.label")
        description: pluginApi?.tr("settings.directUrl.description")
        checked: root.valueDirectUrl
        onToggled: checked => root.direct_urlField.set(checked)
      }
    }

    NPluginSettingsField {
      field: root.show_suggestionsField
      NToggle {
        label: pluginApi?.tr("settings.suggestions.label")
        description: pluginApi?.tr("settings.suggestions.description")
        checked: root.valueShowSuggestions
        onToggled: checked => root.show_suggestionsField.set(checked)
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    RowLayout {
      Layout.fillWidth: true

      NText {
        text: pluginApi?.tr("settings.maxResults.label")
        font.pointSize: Style.fontSizeL
        font.weight: Font.Medium
        color: AtmoColor.mOnSurface
        Layout.fillWidth: true
      }

      NText {
        text: root.valueMaxResults.toString()
        font.pointSize: Style.fontSizeM
        font.weight: Font.Medium
        color: AtmoColor.mPrimary
      }
    }

    NText {
      text: pluginApi?.tr("settings.maxResults.description")
      font.pointSize: Style.fontSizeS
      color: AtmoColor.mOnSurfaceVariant
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    NPluginSettingsField {
      field: root.max_resultsField
      NSlider {
        id: rangeValueMaxResults
        objectName: "settings-range-valueMaxResults"
        Layout.fillWidth: true
        from: 1
        to: 10
        stepSize: 1
        value: root.valueMaxResults
        onMoved: root.max_resultsField.set(Math.round(value))
      }
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("WebSearch", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("WebSearch", "Settings saved successfully");
    });
  }
}
