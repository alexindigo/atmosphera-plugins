pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "DurationLanguage.js" as DurationLanguage
import "LauncherModel.js" as LauncherModel
import "SettingsModel.js" as SettingsModel
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var aliasField: pluginApi?.field("alias") ?? null
  readonly property var presetsField: pluginApi?.field("presets") ?? null
  readonly property var includeIndefinitePresetField: pluginApi?.field("includeIndefinitePreset") ?? null
  readonly property var hideInactiveWidgetField: pluginApi?.field("hideInactiveWidget") ?? null
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _savePending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._savePending = false;
      Logger.i("Caffeinate", pluginApi?.tr("settings.saved"));
    }
  }

  // Presentation-only default markers on controls.
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property string editAlias: aliasField?.value ?? "c"
  readonly property bool editIncludeIndefinite: includeIndefinitePresetField?.value ?? true
  readonly property bool editHideInactive: hideInactiveWidgetField?.value ?? false
  // The list editor buffers rows; it follows the field value (Reset, Apply)
  // and every explicit row operation submits the whole atomic list.
  readonly property var presetsValue: presetsField?.value ?? []
  onPresetsValueChanged: {
    if (JSON.stringify(presetExpressions()) !== JSON.stringify(SettingsModel.copyPresets(presetsValue)))
      replacePresets(presetsValue);
  }
  property real preferredWidth: 720 * Style.uiScaleRatio

  spacing: Style.marginL

  Component.onCompleted: replacePresets(presetsValue)

  ListModel {
    id: presetsModel
  }

  property int _presetsRevision: 0
  Connections {
    target: presetsModel
    function onDataChanged() {
      root._presetsRevision++;
    }
    function onRowsMoved() {
      root._presetsRevision++;
    }
  }

  function submitPresets() {
    return root.presetsField.set(root.presetExpressions());
  }
  function setPreset(index, expression) {
    presetsModel.setProperty(index, "expression", expression);
    submitPresets();
  }
  function movePreset(from, to) {
    presetsModel.move(from, to, 1);
    submitPresets();
  }
  function removePreset(index) {
    presetsModel.remove(index);
    submitPresets();
  }
  function addPreset(expression) {
    presetsModel.append({
                          expression: expression
                        });
    submitPresets();
  }

  function replacePresets(source) {
    const presets = SettingsModel.copyPresets(source);
    presetsModel.clear();
    for (let index = 0; index < presets.length; index++) {
      presetsModel.append({
                            "expression": presets[index]
                          });
    }
  }

  function presetExpressions() {
    const presets = [];
    for (let index = 0; index < presetsModel.count; index++)
      presets.push(presetsModel.get(index).expression);
    return presets;
  }

  // The page's own Reset control is one multi-field Reset of these leaves.
  function resetDefaults() {
    return pluginApi.resetFields(["alias", "presets", "includeIndefinitePreset", "hideInactiveWidget"]);
  }

  function aliasValidation() {
    return LauncherModel.validateAlias(editAlias, "caffeinate");
  }

  function aliasFeedback() {
    const validation = aliasValidation();
    if (validation.state === "invalid") {
      return pluginApi?.tr(validation.code === "alias-duplicates-canonical" ? "settings.alias.duplicateError" : "settings.alias.formatError");
    }
    if (validation.normalized === "")
      return pluginApi?.tr("settings.alias.disabled");
    return pluginApi?.tr("settings.alias.valid", {
                           "alias": validation.normalized
                         });
  }

  function durationFeedback(expression) {
    const parsed = DurationLanguage.parse(expression);
    if (parsed.state === "valid") {
      return pluginApi?.tr("settings.presets.valid", {
                             "duration": parsed.normalized
                           });
    }

    return pluginApi?.tr("feedback." + parsed.state + "." + parsed.code);
  }

  function settingsAreValid() {
    return validatedSettings().valid;
  }

  function validatedSettings() {
    return SettingsModel.validate(editAlias, presetExpressions(), "caffeinate", LauncherModel.validateAlias, DurationLanguage.parse);
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Caffeinate", "Cannot save settings: pluginApi is null");
      return;
    }

    const validated = validatedSettings();
    if (!validated.valid) {
      Logger.w("Caffeinate", pluginApi?.tr("settings.invalidSave"));
      throw new Error("invalid-settings");
    }

    // Normalize only the user's own pending intents; untouched leaves inherit.
    if (root.aliasField.pendingIntent === "set" && validated.alias !== root.aliasField.value)
      root.aliasField.set(validated.alias);
    if (root.presetsField.pendingIntent === "set" && JSON.stringify(validated.presets) !== JSON.stringify(root.presetsField.value))
      root.presetsField.set(validated.presets);
    if (pluginApi.saveSettings() !== false)
      root._savePending = true;
  }

  NText {
    text: pluginApi?.tr("settings.title")
    pointSize: Style.fontSizeL
    font.weight: Style.fontWeightBold
  }

  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.description")
    color: AtmoColor.mOnSurfaceVariant
    wrapMode: Text.Wrap
  }

  NDivider {
    Layout.fillWidth: true
  }

  NPluginSettingsField {
    field: root.aliasField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.alias.label")
      description: pluginApi?.tr("settings.alias.description")
      placeholderText: pluginApi?.tr("settings.alias.placeholder")
      defaultValue: defaults.alias ?? "c"
      text: root.editAlias
      onEditCommitted: root.aliasField.set(text)
    }
  }

  NText {
    Layout.fillWidth: true
    text: root.aliasFeedback()
    color: root.aliasValidation().state === "valid" ? AtmoColor.mOnSurfaceVariant : AtmoColor.mError
    wrapMode: Text.Wrap
  }

  NDivider {
    Layout.fillWidth: true
  }

  NLabel {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.bar.title")
    description: pluginApi?.tr("settings.bar.description")
  }

  NPluginSettingsField {
    field: root.hideInactiveWidgetField
    NToggle {
      label: pluginApi?.tr("settings.bar.hideInactive.label")
      description: pluginApi?.tr("settings.bar.hideInactive.description")
      checked: root.editHideInactive
      defaultValue: defaults.hideInactiveWidget ?? false
      onToggled: checked => root.hideInactiveWidgetField.set(checked)
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NLabel {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.presets.title")
    description: pluginApi?.tr("settings.presets.description")
  }

  NPluginSettingsField {
    field: root.presetsField
    NScrollView {
      id: presetsScroll

      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(presetsColumn.implicitHeight, 360 * Style.uiScaleRatio)
      horizontalPolicy: ScrollBar.AlwaysOff
      showScrollbarWhenScrollable: true
      gradientColor: AtmoColor.mSurfaceVariant

      ColumnLayout {
        id: presetsColumn

        width: presetsScroll.availableWidth
        spacing: Style.marginM

        Repeater {
          model: presetsModel

          delegate: ColumnLayout {
            id: presetDelegate

            required property int index
            required property string expression

            Layout.fillWidth: true
            spacing: Style.marginXS

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              NTextInput {
                id: presetInput

                Layout.fillWidth: true
                placeholderText: pluginApi?.tr("settings.presets.placeholder")
                text: presetDelegate.expression
                onEditCommitted: {
                  if (presetDelegate.expression !== text)
                    root.setPreset(presetDelegate.index, text);
                }
              }

              AtmoIconButton {
                icon: "arrow-up"
                tooltipText: pluginApi?.tr("settings.presets.moveUp")
                enabled: presetDelegate.index > 0
                onClicked: root.movePreset(presetDelegate.index, presetDelegate.index - 1)
              }

              AtmoIconButton {
                icon: "arrow-down"
                tooltipText: pluginApi?.tr("settings.presets.moveDown")
                enabled: presetDelegate.index < presetsModel.count - 1
                onClicked: root.movePreset(presetDelegate.index, presetDelegate.index + 1)
              }

              AtmoIconButton {
                icon: "trash"
                tooltipText: pluginApi?.tr("settings.presets.remove")
                onClicked: root.removePreset(presetDelegate.index)
              }
            }

            readonly property var parsed: DurationLanguage.parse(presetInput.text)

            NText {
              Layout.fillWidth: true
              text: root.durationFeedback(presetInput.text)
              color: presetDelegate.parsed.state === "valid" ? AtmoColor.mOnSurfaceVariant : AtmoColor.mError
              wrapMode: Text.Wrap
            }
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NButton {
        text: pluginApi?.tr("settings.presets.add")
        icon: "plus"
        onClicked: root.addPreset("")
      }

      Item {
        Layout.fillWidth: true
      }

      NButton {
        text: pluginApi?.tr("settings.reset")
        icon: "restore"
        outlined: true
        onClicked: root.resetDefaults()
      }
    }
  }

  NPluginSettingsField {
    field: root.includeIndefinitePresetField
    NToggle {
      label: pluginApi?.tr("settings.indefinite.label")
      description: pluginApi?.tr("settings.indefinite.description")
      checked: root.editIncludeIndefinite
      defaultValue: defaults.includeIndefinitePreset ?? true
      onToggled: checked => root.includeIndefinitePresetField.set(checked)
    }
  }
}
