import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Settings page for the clipboard plugin. Rendered inside the
// Noctalia Settings dialog when the user navigates to this plugin's entry.
//
// Contracts followed:
//   - docs/specs/settings-panel.md (behavior, constraints, acceptance criteria)
//   - docs/specs/plugin-entry-point-contracts.md §Settings.qml
//     (ColumnLayout root, injected pluginApi, mandatory saveSettings())
//   - docs/specs/plugin-qml-idioms.md (two-phase save pattern,
//     null-guarding, widget library, i18n via pluginApi?.tr)
//
// Three controls stacked vertically map to the keys in
// manifest.json metadata.defaultSettings:
//   maxHistorySize     — NSpinBox, 20–500, default 100
//   showImagePreviews  — NToggle, default true
//   density            — NComboBox (compact/comfortable/spacious), default "comfortable"
//
// Controls submit explicit field intent. The selected host owns Apply/Reset;
// this page never reconstructs or publishes a preference snapshot.
ColumnLayout {
  id: root
  spacing: Style.marginM

  // Injected by the shell after instantiation. Always null-guard every
  // access with optional chaining (?.) — per docs/specs/plugin-qml-idioms.md.
  property var pluginApi: null
  readonly property var maxHistorySizeField: pluginApi?.field("maxHistorySize") ?? null
  readonly property var showImagePreviewsField: pluginApi?.field("showImagePreviews") ?? null
  readonly property var densityField: pluginApi?.field("density") ?? null

  // --- Pending state ------------------------------------------------------
  //
  // Read-only presentation of the selected native field handles.
  readonly property int valueMaxHistorySize: root.maxHistorySizeField?.value ?? 100
  readonly property bool valueShowImagePreviews: root.showImagePreviewsField?.value ?? true
  readonly property string valueDensity: root.densityField?.value ?? "comfortable"

  // --- Controls -----------------------------------------------------------
  NText {
    Layout.fillWidth: true
    visible: root.pluginApi?.scopeKind === "instance"
    text: root.pluginApi?.tr("settings.shared-effect")
    wrapMode: Text.WordWrap
    color: AtmoColor.mOnSurfaceVariant
  }

  // maxHistorySize limits this context's projection, not shared content.
  NPluginSettingsField {
    field: root.maxHistorySizeField
    NSpinBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.max-history-size")
      description: pluginApi?.tr("settings.max-history-size-description")
      from: 20
      to: 500
      stepSize: 10
      value: root.valueMaxHistorySize
      requestValue: value => root.maxHistorySizeField.set(value)
    }
  }

  // showImagePreviews — guards the whole image-decode path in Main.qml
  // (getImage() short-circuits when this is false — see Main.qml).
  NPluginSettingsField {
    field: root.showImagePreviewsField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-image-previews")
      description: pluginApi?.tr("settings.show-image-previews-description")
      checked: root.valueShowImagePreviews
      onToggled: checked => {
        root.showImagePreviewsField.set(checked);
      }
    }
  }

  // density — enum of "compact" / "comfortable" / "spacious". The
  // NComboBox model uses { key, name } entries; we bind selection through
  // currentKey so the stored value is the enum string itself (matching
  // manifest.json's "comfortable" default) rather than a numeric index.
  NPluginSettingsField {
    field: root.densityField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.density")
      description: pluginApi?.tr("settings.density-description")
      model: [
        {
          "key": "compact",
          "name": pluginApi?.tr("settings.density-compact")
        },
        {
          "key": "comfortable",
          "name": pluginApi?.tr("settings.density-comfortable")
        },
        {
          "key": "spacious",
          "name": pluginApi?.tr("settings.density-spacious")
        }
      ]
      currentKey: root.valueDensity
      onSelected: key => {
        root.densityField.set(key);
      }
    }
  }

  // --- Save contract ------------------------------------------------------
  //
  // Observe the selected host's eventual completion. No direct publication.
  //
  // Null-guard matches the idiom used in every other entry point — if the
  // shell calls saveSettings() before injecting pluginApi (edge case on
  // rapid open/close), silently return rather than throwing.
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      return;
    }
    pluginApi.saveSettings();
  }
}
