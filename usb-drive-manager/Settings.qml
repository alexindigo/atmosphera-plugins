import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null
  readonly property var autoMountField: pluginApi?.field("autoMount") ?? null
  readonly property var fileBrowserField: pluginApi?.field("fileBrowser") ?? null
  readonly property var terminalCommandField: pluginApi?.field("terminalCommand") ?? null
  readonly property var showNotificationsField: pluginApi?.field("showNotifications") ?? null
  readonly property var hideWhenEmptyField: pluginApi?.field("hideWhenEmpty") ?? null
  readonly property var showBadgeField: pluginApi?.field("showBadge") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null

  // ===== EDIT STATE =====

  readonly property bool editAutoMount: root.autoMountField?.value ?? false

  readonly property string editFileBrowser: root.fileBrowserField?.value || "yazi"

  readonly property string editTerminalCommand: root.terminalCommandField?.value || "kitty"

  readonly property bool editShowNotifications: root.showNotificationsField?.value ?? true

  readonly property bool editHideWhenEmpty: root.hideWhenEmptyField?.value ?? false

  readonly property bool editShowBadge: root.showBadgeField?.value ?? true

  readonly property string iconColor: root.iconColorField?.value ?? "none"

  // ===== SAVE =====

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings(result => {
      if ((result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        pluginApi.mainInstance?.activatePolicy(pluginApi.runtimeContext);
    });
  }

  // ===== UI =====

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.Wrap
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
  }

  // ── Section: Bar Widget ───────────────────────────────────────────────────
  NText {
    text: pluginApi?.tr("settings.section-bar")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.hideWhenEmptyField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.hide-when-empty")
      description: pluginApi?.tr("settings.hide-when-empty-desc")
      checked: root.editHideWhenEmpty
      onToggled: checked => {
        root.hideWhenEmptyField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.showBadgeField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-badge")
      description: pluginApi?.tr("settings.show-badge-desc")
      checked: root.editShowBadge
      onToggled: checked => {
        root.showBadgeField.set(checked);
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Section: Behavior ─────────────────────────────────────────────────────
  NText {
    text: pluginApi?.tr("settings.section-behavior")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.autoMountField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.auto-mount")
      description: pluginApi?.tr("settings.auto-mount-desc")
      checked: root.editAutoMount
      onToggled: checked => {
        root.autoMountField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.showNotificationsField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.notifications")
      description: pluginApi?.tr("settings.notifications-desc")
      checked: root.editShowNotifications
      onToggled: checked => {
        root.showNotificationsField.set(checked);
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Section: File Browser ─────────────────────────────────────────────────
  NText {
    text: pluginApi?.tr("settings.section-browser")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.fileBrowserField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.file-browser")
      description: pluginApi?.tr("settings.file-browser-desc")
      model: [
        {
          key: "yazi",
          name: "yazi"
        },
        {
          key: "ranger",
          name: "ranger"
        },
        {
          key: "xdg-open",
          name: "xdg-open"
        },
        {
          key: "dolphin",
          name: "dolphin"
        },
        {
          key: "thunar",
          name: "thunar"
        },
        {
          key: "nautilus",
          name: "nautilus"
        }
      ]
      currentKey: root.editFileBrowser
      onSelected: key => {
        root.fileBrowserField.set(key);
      }
    }
  }

  NPluginSettingsField {
    field: root.terminalCommandField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.terminal")
      description: pluginApi?.tr("settings.terminal-desc")
      model: [
        {
          key: "kitty",
          name: "kitty"
        },
        {
          key: "foot",
          name: "foot"
        },
        {
          key: "alacritty",
          name: "alacritty"
        },
        {
          key: "wezterm",
          name: "wezterm"
        },
        {
          key: "ghostty",
          name: "ghostty"
        },
        {
          key: "ptyxis",
          name: "ptyxis"
        }
      ]
      currentKey: root.editTerminalCommand
      onSelected: key => {
        root.terminalCommandField.set(key);
      }
    }
  }
  NDivider {
    Layout.fillWidth: true
  }

  // Section: Colors
  NText {
    text: pluginApi?.tr("settings.icon-color")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }
  NPluginSettingsField {
    field: root.iconColorField
    NColorChoice {
      currentKey: root.iconColor
      description: pluginApi?.tr("settings.icon-color-desc")
      label: pluginApi?.tr("settings.icon-color")
      onSelected: key => root.iconColorField.set(key)
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
