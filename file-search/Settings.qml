import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var showHiddenField: pluginApi?.field("showHidden") ?? null
  readonly property var maxResultsField: pluginApi?.field("maxResults") ?? null
  readonly property var fileOpenerField: pluginApi?.field("fileOpener") ?? null
  readonly property var searchDirectoryField: pluginApi?.field("searchDirectory") ?? null
  readonly property var fdCommandField: pluginApi?.field("fdCommand") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property bool valueShowHidden: root.showHiddenField?.value ?? defaults.showHidden
  readonly property int valueMaxResults: root.maxResultsField?.value ?? defaults.maxResults
  readonly property string valueFileOpener: root.fileOpenerField?.value ?? defaults.fileOpener
  readonly property string valueFdCommand: root.fdCommandField?.value ?? defaults.fdCommand
  readonly property string valueSearchDirectory: root.searchDirectoryField?.value ?? defaults.searchDirectory

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.d("FileSearch", "Settings UI loaded");
  }

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    // Show Hidden Files Toggle
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NText {
          text: pluginApi?.tr("settings.showHidden.label")
          font.pointSize: Style.fontSizeL
          font.weight: Font.Medium
          color: AtmoColor.mOnSurface
          Layout.fillWidth: true
        }
      }

      NPluginSettingsField {
        field: root.showHiddenField
        NToggle {
          checked: root.valueShowHidden
          onToggled: checked => root.showHiddenField.set(checked)
        }
      }
    }

    // File Opener Input
    NPluginSettingsField {
      field: root.fileOpenerField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.fileOpener.label")
        description: pluginApi?.tr("settings.fileOpener.description")
        placeholderText: pluginApi?.tr("settings.fileOpener.placeholder")
        text: root.valueFileOpener
        onEditCommitted: root.fileOpenerField.set(text)
      }
    }

    // Search Directory Input
    NPluginSettingsField {
      field: root.searchDirectoryField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.searchDirectory.label")
        description: pluginApi?.tr("settings.searchDirectory.description")
        placeholderText: pluginApi?.tr("settings.searchDirectory.placeholder")
        text: root.valueSearchDirectory
        onEditCommitted: root.searchDirectoryField.set(text)
      }
    }

    // fd Command Path Input
    NPluginSettingsField {
      field: root.fdCommandField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.fdCommand.label")
        description: pluginApi?.tr("settings.fdCommand.description")
        placeholderText: pluginApi?.tr("settings.fdCommand.placeholder")
        text: root.valueFdCommand
        onEditCommitted: root.fdCommandField.set(text)
      }
    }
  }

  // Max Results Slider
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
        text: root.valueMaxResults === 0 ? pluginApi?.tr("settings.maxResults.unlimited") : root.valueMaxResults.toString()
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
      field: root.maxResultsField
      NSlider {
        id: rangeValueMaxResults
        objectName: "settings-range-valueMaxResults"
        Layout.fillWidth: true
        from: 0
        to: 1000
        stepSize: 10
        value: root.valueMaxResults
        onMoved: root.maxResultsField.set(Math.round(value))
      }
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("FileSearch", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("FileSearch", "Settings saved successfully");
    });
  }
}
