import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null
  readonly property var colorizeByStatusField: pluginApi?.field("colorizeByStatus") ?? null
  readonly property var allowPopupOpeningField: pluginApi?.field("allowPopupOpening") ?? null
  readonly property var colorActiveField: pluginApi?.field("colorActive") ?? null
  readonly property var colorLevel0Field: pluginApi?.field("colorLevel0") ?? null
  readonly property var colorAutoField: pluginApi?.field("colorAuto") ?? null

  // ===== EDIT STATE =====
  readonly property bool editColorizeByStatus: root.colorizeByStatusField?.value ?? true
  readonly property bool editAllowPopupOpening: root.allowPopupOpeningField?.value ?? true
  readonly property string editColorLevel0: root.colorLevel0Field?.value ?? AtmoColor.mError
  readonly property string editColorActive: root.colorActiveField?.value ?? AtmoColor.mPrimary

  // Empty = unset → automatic mode stays neutral
  readonly property string editColorAuto: root.colorAutoField?.value ?? ""

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  // ===== SAVE =====
  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }

  // ===== UI =====

  // Color swatch sizing
  readonly property int swatchSize: 28
  readonly property int swatchBorderSelected: 3
  readonly property int swatchBorderDefault: 1

  // All palette colors
  readonly property var noctaliaPalette: [AtmoColor.mPrimary, AtmoColor.mSecondary, AtmoColor.mTertiary, AtmoColor.mError, AtmoColor.mSurface, AtmoColor.mSurfaceVariant, AtmoColor.mOutline]

  // Reusable palette picker: a "neutral" (no-color) swatch followed by the theme palette.
  // `selected` is the current value (empty = neutral); `picked` fires with the chosen value.
  component ColorSwatchRow: RowLayout {
    id: swatchRow
    property string selected: ""
    signal picked(string value)
    spacing: Style.marginS

    // Neutral / no-color option
    Rectangle {
      width: root.swatchSize
      height: root.swatchSize
      radius: root.swatchSize / 2
      color: Style.capsuleColor
      border.color: !swatchRow.selected ? AtmoColor.mOnSurface : AtmoColor.mOutline
      border.width: !swatchRow.selected ? root.swatchBorderSelected : root.swatchBorderDefault

      AtmoIcon {
        anchors.centerIn: parent
        icon: "close"
        color: AtmoColor.mOnSurfaceVariant
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: swatchRow.picked("")
      }
    }

    Repeater {
      model: root.noctaliaPalette

      Rectangle {
        width: root.swatchSize
        height: root.swatchSize
        radius: root.swatchSize / 2
        color: modelData
        border.color: (swatchRow.selected && Qt.colorEqual(swatchRow.selected, modelData)) ? AtmoColor.mOnSurface : AtmoColor.mOutline
        border.width: (swatchRow.selected && Qt.colorEqual(swatchRow.selected, modelData)) ? root.swatchBorderSelected : root.swatchBorderDefault

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: swatchRow.picked(String(modelData))
        }
      }
    }
  }

  // Option 1: Dynamic coloring based on fan status
  NPluginSettingsField {
    field: root.colorizeByStatusField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.dynamic-coloring")
      description: pluginApi?.tr("settings.dynamic-coloring-desc")
      checked: root.editColorizeByStatus
      onToggled: checked => {
        root.colorizeByStatusField.set(checked);
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginM
    enabled: root.editColorizeByStatus
    opacity: enabled ? 1.0 : 0.5

    // Level 0 color
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: pluginApi?.tr("settings.color-level0")
        font.weight: Font.Bold
      }
      NText {
        text: pluginApi?.tr("settings.color-level0-desc")
        font.pointSize: Style.fontSizeS
        color: AtmoColor.mOnSurfaceVariant
      }

      NPluginSettingsField {
        field: root.colorLevel0Field
        ColorSwatchRow {
          selected: root.editColorLevel0
          onPicked: value => {
            root.colorLevel0Field.set(value);
          }
        }
      }
    }

    // Space separator
    Item {
      Layout.preferredHeight: Style.marginS
    }

    // Active (forced speed) color
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: pluginApi?.tr("settings.color-active")
        font.weight: Font.Bold
      }
      NText {
        text: pluginApi?.tr("settings.color-active-desc")
        font.pointSize: Style.fontSizeS
        color: AtmoColor.mOnSurfaceVariant
      }

      NPluginSettingsField {
        field: root.colorActiveField
        ColorSwatchRow {
          selected: root.editColorActive
          onPicked: value => {
            root.colorActiveField.set(value);
          }
        }
      }
    }

    // Space separator
    Item {
      Layout.preferredHeight: Style.marginS
    }

    // Automatic mode color (optional, neutral by default)
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: pluginApi?.tr("settings.color-auto")
        font.weight: Font.Bold
      }
      NText {
        text: pluginApi?.tr("settings.color-auto-desc")
        font.pointSize: Style.fontSizeS
        color: AtmoColor.mOnSurfaceVariant
      }

      NPluginSettingsField {
        field: root.colorAutoField
        ColorSwatchRow {
          selected: root.editColorAuto
          onPicked: value => {
            root.colorAutoField.set(value);
          }
        }
      }
    }
  }

  // Option 2: Left Click Interaction Toggle
  NPluginSettingsField {
    field: root.allowPopupOpeningField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.allow-popup")
      description: pluginApi?.tr("settings.allow-popup-desc")
      checked: root.editAllowPopupOpening
      onToggled: checked => {
        root.allowPopupOpeningField.set(checked);
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
