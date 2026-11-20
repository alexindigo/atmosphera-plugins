import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var defaultScopeField: pluginApi?.field("defaultScope") ?? null
  readonly property var showRemainingTextField: pluginApi?.field("showRemainingText") ?? null
  readonly property var activateOnLeftClickField: pluginApi?.field("activateOnLeftClick") ?? null
  readonly property var quickExtendMinutesField: pluginApi?.field("quickExtendMinutes") ?? null
  readonly property var includeUnlimitedField: pluginApi?.field("includeUnlimited") ?? null
  readonly property var durationsField: pluginApi?.field("durations") ?? null

  readonly property string defaultScope: root.defaultScopeField?.value ?? "partial"
  readonly property bool showRemainingText: root.showRemainingTextField?.value ?? true
  readonly property bool activateOnLeftClick: root.activateOnLeftClickField?.value ?? false
  readonly property int quickExtendMinutes: root.quickExtendMinutesField?.value ?? 30
  readonly property bool includeUnlimited: root.includeUnlimitedField?.value ?? true
  readonly property string durationsCsv: (root.durationsField?.value ?? []).join(", ")

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginL

  NPluginSettingsField {
    field: root.defaultScopeField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.default-scope.label")
      description: pluginApi?.tr("settings.default-scope.desc")
      model: [
        {
          key: "partial",
          name: pluginApi?.tr("settings.scope-partial")
        },
        {
          key: "full",
          name: pluginApi?.tr("settings.scope-full")
        }
      ]
      currentKey: root.defaultScope
      onSelected: key => root.defaultScopeField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.showRemainingTextField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-remaining.label")
      checked: root.showRemainingText
      onToggled: checked => root.showRemainingTextField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.activateOnLeftClickField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.activate-on-left-click.label")
      description: pluginApi?.tr("settings.activate-on-left-click.desc")
      checked: root.activateOnLeftClick
      onToggled: checked => root.activateOnLeftClickField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.quickExtendMinutesField
    NSpinBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.quick-extend.label")
      from: 5
      to: 240
      stepSize: 5
      value: root.quickExtendMinutes
      onValueModified: value => root.quickExtendMinutesField.set(value)
    }
  }

  NPluginSettingsField {
    field: root.durationsField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.durations.label")
      text: root.durationsCsv
      onEditCommitted: {
        // The committed text is one list intent; invalid entries are dropped.
        const arr = text.split(/\s*,\s*/).map(s => parseInt(s, 10)).filter(n => !isNaN(n) && n > 0);
        if (arr.length > 0)
          root.durationsField.set(arr);
      }
    }
  }

  NPluginSettingsField {
    field: root.includeUnlimitedField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.include-unlimited.label")
      checked: root.includeUnlimited
      onToggled: checked => root.includeUnlimitedField.set(checked)
    }
  }

  // Called by Noctalia's settings framework when the dialog closes.
  function saveSettings() {
    if (!pluginApi) {
      Logger.e("keep-awake-plus", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("keep-awake-plus", "Settings saved");
    });
  }
}
