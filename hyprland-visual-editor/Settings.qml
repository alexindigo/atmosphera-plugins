import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var overlayPathField: pluginApi?.field("overlayPath") ?? null
  readonly property var autoApplyField: pluginApi?.field("autoApply") ?? null
  readonly property var iconField: pluginApi?.field("icon") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null

  // Settings and default values (Official Noctalia pattern)
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // 1. Local state ('edit' convention to avoid unnecessary disk writes)
  readonly property string editOverlayPath: root.overlayPathField?.value ?? "~/.cache/noctalia/HVE/overlay.conf"
  readonly property bool editAutoApply: root.autoApplyField?.value ?? true
  readonly property string editIcon: root.iconField?.value ?? "adjustments-horizontal"
  readonly property string editIconColor: root.iconColorField?.value ?? "primary"

  spacing: Style.marginM

  // ── Preview ──────────────────────────────────────────────────────────
  RowLayout {
    spacing: Style.marginM
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: Style.marginL
    Layout.bottomMargin: Style.marginL

    AtmoIcon {
      icon: root.editIcon
      pointSize: Style.fontSizeXXL * 2
      color: {
        let res = AtmoColor.resolveColorKeyOptional(root.editIconColor);
        return res.a > 0 ? res : AtmoColor.mOnSurface;
      }
    }

    NText {
      text: pluginApi?.tr("settings.preview_label")
      font.weight: Font.Bold
    }
  }

  // ── Icon Configuration ────────────────────────────────────────────────
  NPluginSettingsField {
    field: root.iconField
    NButton {
      Layout.fillWidth: true
      text: pluginApi?.tr("settings.change_icon_button")
      icon: "search"
      onClicked: iconPicker.open()
    }
  }

  AtmoIconPicker {
    id: iconPicker
    initialIcon: root.editIcon
    onIconSelected: iconName => {
      root.iconField.set(iconName);
    }
  }

  NPluginSettingsField {
    field: root.iconColorField
    NColorChoice {
      label: pluginApi?.tr("settings.icon_color_label")
      currentKey: root.editIconColor
      onSelected: key => {
        root.iconColorField.set(key);
      }
      defaultValue: defaults.iconColor || "primary"
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Files and Application Configuration ────────────────────────────────
  NPluginSettingsField {
    field: root.overlayPathField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.path_label")
      description: pluginApi?.tr("settings.path_desc")
      text: root.editOverlayPath
      onEditCommitted: root.overlayPathField.set(text)
      readOnly: true
    }
  }

  NPluginSettingsField {
    field: root.autoApplyField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.autoapply_label")
      description: pluginApi?.tr("settings.autoapply_description")
      checked: root.editAutoApply
      onToggled: checked => {
        root.autoApplyField.set(checked);
      }
    }
  }

  // ── Save Function (Required by the Shell) ──────────────────────────
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("HVE", "Settings saved");
    });
  }
}
