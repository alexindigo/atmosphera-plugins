import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Portals
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var profilesDirField: pluginApi?.field("profilesDir") ?? null
  readonly property var iconField: pluginApi?.field("icon") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null
  readonly property var includeWallpapersField: pluginApi?.field("includeWallpapers") ?? null
  readonly property var backupEnabledField: pluginApi?.field("backupEnabled") ?? null
  readonly property var backupCountField: pluginApi?.field("backupCount") ?? null

  // Local state
  readonly property string editProfilesDir: root.profilesDirField?.value || ""

  readonly property string editIcon: root.iconField?.value || "bookmark"

  readonly property bool editIncludeWallpapers: root.includeWallpapersField?.value ?? true

  readonly property string editIconColor: root.iconColorField?.value || "primary"

  readonly property bool editBackupEnabled: root.backupEnabledField?.value ?? true

  readonly property int editBackupCount: root.backupCountField?.value ?? 5

  spacing: Style.marginM

  // ── Profiles directory ──────────────────────────────────────────────────

  NPluginSettingsField {
    field: root.profilesDirField
    NTextInputButton {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.dir-label")
      description: pluginApi?.tr("settings.dir-description")
      placeholderText: Settings.configDir + "profiles/"
      text: root.editProfilesDir
      buttonIcon: "folder"
      buttonTooltip: pluginApi?.tr("settings.dir-select")
      onInputEditCommitted: root.profilesDirField.set(text.trim())
      onButtonClicked: dirPicker.openFilePicker()
    }
  }

  PortalFilePicker {
    id: dirPicker
    selectionMode: "folders"
    title: pluginApi?.tr("settings.dir-select")
    initialPath: root.editProfilesDir || (Settings.configDir + "profiles/")
    onAccepted: paths => {
      if (paths.length > 0)
        root.profilesDirField.set(paths[0]);
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXS
    Layout.bottomMargin: Style.marginXS
  }

  // ── Widget icon ──────────────────────────────────────────────────────────

  RowLayout {
    spacing: Style.marginM

    NLabel {
      label: pluginApi?.tr("settings.icon-label")
      description: pluginApi?.tr("settings.icon-description")
    }

    AtmoIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: root.editIcon || "bookmark"
      pointSize: Style.fontSizeXXXL
      color: AtmoColor.resolveColorKeyOptional(root.editIconColor).a > 0 ? AtmoColor.resolveColorKeyOptional(root.editIconColor) : AtmoColor.mOnSurface
    }
  }

  NPluginSettingsField {
    field: root.iconField
    NButton {
      text: I18n.tr("bar.control-center.browse-library")
      onClicked: iconPicker.open()
    }
  }

  AtmoIconPicker {
    id: iconPicker
    initialIcon: root.editIcon
    onIconSelected: iconName => {
      root.iconField.set(iconName.trim() || "bookmark");
    }
  }

  NPluginSettingsField {
    field: root.iconColorField
    NColorChoice {
      label: pluginApi?.tr("settings.icon-color-label")
      currentKey: root.editIconColor
      onSelected: key => {
        root.iconColorField.set(key);
      }
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.iconColor || "primary"
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXS
    Layout.bottomMargin: Style.marginXS
  }

  // ── Include wallpapers toggle ────────────────────────────────────────────

  NPluginSettingsField {
    field: root.includeWallpapersField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.wallpapers-label")
      description: pluginApi?.tr("settings.wallpapers-description")
      checked: root.editIncludeWallpapers
      onToggled: checked => {
        root.includeWallpapersField.set(checked);
      }
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.includeWallpapers ?? true
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginXS
    Layout.bottomMargin: Style.marginXS
  }

  // ── Auto-backup ──────────────────────────────────────────────────────────

  NPluginSettingsField {
    field: root.backupEnabledField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.backup-label")
      description: pluginApi?.tr("settings.backup-description")
      checked: root.editBackupEnabled
      onToggled: checked => {
        root.backupEnabledField.set(checked);
      }
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.backupEnabled ?? true
    }
  }

  NPluginSettingsField {
    field: root.backupCountField
    NValueSlider {
      id: rangeEditBackupCount
      objectName: "settings-range-editBackupCount"
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.backup-count-label")
      description: pluginApi?.tr("settings.backup-count-description")
      from: 1
      to: 20
      stepSize: 1
      snapAlways: true
      value: root.editBackupCount
      text: String(Math.round(root.editBackupCount))
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.backupCount ?? 5
      showReset: true
      enabled: root.editBackupEnabled
      onMoved: function (v) {
        root.backupCountField.set(Math.round(v));
      }
    }
  }

  // ── Save ────────────────────────────────

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("ShellProfiles", "Settings saved");
    });
  }
}
