import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var textField: pluginApi?.field("text") ?? null
  readonly property var fortuneEnabledField: pluginApi?.field("fortuneEnabled") ?? null
  readonly property var fortuneOffensiveField: pluginApi?.field("fortuneOffensive") ?? null
  readonly property var fortuneEqualField: pluginApi?.field("fortuneEqual") ?? null
  readonly property var fortuneCategoryField: pluginApi?.field("fortuneCategory") ?? null
  readonly property var fortuneMaxLengthField: pluginApi?.field("fortuneMaxLength") ?? null
  readonly property var listEnabledField: pluginApi?.field("listEnabled") ?? null
  readonly property var textFileField: pluginApi?.field("textFile") ?? null
  readonly property var refreshOnWallpaperField: pluginApi?.field("refreshOnWallpaper") ?? null

  readonly property string editText: root.textField?.value ?? ""
  readonly property bool editFortuneEnabled: root.fortuneEnabledField?.value ?? false
  readonly property bool editFortuneOffensive: root.fortuneOffensiveField?.value ?? false
  readonly property bool editFortuneEqual: root.fortuneEqualField?.value ?? false
  readonly property string editFortuneCategory: root.fortuneCategoryField?.value ?? ""
  readonly property int editFortuneMaxLength: root.fortuneMaxLengthField?.value ?? 60
  readonly property bool editListEnabled: root.listEnabledField?.value ?? false
  readonly property string editTextFile: root.textFileField?.value ?? ""
  readonly property bool editRefreshOnWallpaper: root.refreshOnWallpaperField?.value ?? true
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  NPluginSettingsField {
    field: root.fortuneEnabledField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.fortune.label")
      description: pluginApi?.tr("settings.fortune.desc")
      checked: root.editFortuneEnabled
      onToggled: checked => {
        root.fortuneEnabledField.set(checked);
        if (checked)
          root.listEnabledField.set(false);
      }
    }
  }

  NPluginSettingsField {
    field: root.listEnabledField
    visible: !root.editFortuneEnabled
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.list.label")
      description: pluginApi?.tr("settings.list.desc")
      checked: root.editListEnabled
      onToggled: checked => root.listEnabledField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.textFileField
    visible: root.editListEnabled && !root.editFortuneEnabled
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.textFile.label")
      description: pluginApi?.tr("settings.textFile.desc")
      placeholderText: "~/.config/noctalia/plugins/not-just-text/examples.txt"
      text: root.editTextFile
      onEditCommitted: root.textFileField.set(text)
    }
  }

  NPluginSettingsField {
    field: root.textField
    visible: !root.editFortuneEnabled && !root.editListEnabled
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.text.label")
      description: pluginApi?.tr("settings.text.desc")
      text: root.editText
      onEditCommitted: root.textField.set(text)
    }
  }

  NPluginSettingsField {
    field: root.fortuneCategoryField
    visible: root.editFortuneEnabled
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.fortuneCategory.label")
      description: pluginApi?.tr("settings.fortuneCategory.desc")
      placeholderText: "computers"
      text: root.editFortuneCategory
      onEditCommitted: root.fortuneCategoryField.set(text)
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    visible: root.editFortuneEnabled
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.fortuneMaxLength.label", {
                             "value": root.editFortuneMaxLength
                           })
      description: pluginApi?.tr("settings.fortuneMaxLength.desc")
    }

    NPluginSettingsField {
      field: root.fortuneMaxLengthField
      NSlider {
        id: rangeEditFortuneMaxLength
        objectName: "settings-range-editFortuneMaxLength"
        Layout.fillWidth: true
        from: 10
        to: 200
        value: root.editFortuneMaxLength
        stepSize: 5
        onMoved: root.fortuneMaxLengthField.set(Math.round(value))
      }
    }
  }

  NPluginSettingsField {
    field: root.fortuneOffensiveField
    visible: root.editFortuneEnabled
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.fortuneOffensive.label")
      description: pluginApi?.tr("settings.fortuneOffensive.desc")
      checked: root.editFortuneOffensive
      onToggled: checked => root.fortuneOffensiveField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.fortuneEqualField
    visible: root.editFortuneEnabled
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.fortuneEqual.label")
      description: pluginApi?.tr("settings.fortuneEqual.desc")
      checked: root.editFortuneEqual
      onToggled: checked => root.fortuneEqualField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.refreshOnWallpaperField
    visible: root.editFortuneEnabled || root.editListEnabled
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.refreshOnWallpaper.label")
      description: pluginApi?.tr("settings.refreshOnWallpaper.desc")
      checked: root.editRefreshOnWallpaper
      onToggled: checked => root.refreshOnWallpaperField.set(checked)
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }
}
