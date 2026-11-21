import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Portals
import qs.Widgets

ColumnLayout {
  id: root

  // Plugin API (injected by the settings dialog system)
  property var pluginApi: null
  readonly property var enableCrossField: pluginApi?.field("enableCross") ?? null
  readonly property var enableWindowsSelectionField: pluginApi?.field("enableWindowsSelection") ?? null
  readonly property var screenshotEditorField: pluginApi?.field("screenshotEditor") ?? null
  readonly property var keepSourceScreenshotField: pluginApi?.field("keepSourceScreenshot") ?? null
  readonly property var savePathField: pluginApi?.field("savePath") ?? null
  readonly property var recordingSavePathField: pluginApi?.field("recordingSavePath") ?? null
  readonly property var recordingNotificationsField: pluginApi?.field("recordingNotifications") ?? null

  // Local state for editing
  readonly property bool enableCross: root.enableCrossField?.value ?? true

  readonly property bool enableWindowsSelection: root.enableWindowsSelectionField?.value ?? true

  readonly property string screenshotEditor: root.screenshotEditorField?.value ?? "swappy"

  readonly property bool keepSourceScreenshot: root.keepSourceScreenshotField?.value ?? false

  readonly property string savePath: root.savePathField?.value ?? (Quickshell.env("HOME") + "/Pictures/Screenshots")

  readonly property string recordingSavePath: root.recordingSavePathField?.value ?? (Quickshell.env("HOME") + "/Videos")

  readonly property bool recordingNotifications: root.recordingNotificationsField?.value ?? true

  spacing: Style.marginM

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.Wrap
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
  }

  NPluginSettingsField {
    field: root.enableCrossField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.enableCross.label")
      description: pluginApi?.tr("settings.enableCross.description")
      checked: root.enableCross
      onToggled: checked => {
        root.enableCrossField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.enableWindowsSelectionField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.enableWindowsSelection.label")
      description: pluginApi?.tr("settings.enableWindowsSelection.description")
      checked: root.enableWindowsSelection
      onToggled: checked => {
        root.enableWindowsSelectionField.set(checked);
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NLabel {
      label: pluginApi?.tr("settings.screenshotEditor.label")
      description: pluginApi?.tr("settings.screenshotEditor.description")
    }

    NPluginSettingsField {
      field: root.screenshotEditorField
      NComboBox {
        Layout.fillWidth: true
        model: ListModel {
          ListElement {
            name: "Swappy"
            key: "swappy"
          }
          ListElement {
            name: "Satty"
            key: "satty"
          }
        }
        currentKey: root.screenshotEditor
        onSelected: key => {
          Logger.d("ScreenShot", (key));
          root.screenshotEditorField.set(key);
        }
      }
    }
  }

  NPluginSettingsField {
    field: root.keepSourceScreenshotField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.keepSourceScreenshot.label")
      description: pluginApi?.tr("settings.keepSourceScreenshot.description")
      checked: root.keepSourceScreenshot
      onToggled: checked => {
        root.keepSourceScreenshotField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.savePathField
    NTextInputButton {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.savePath.label")
      description: pluginApi?.tr("settings.savePath.description")
      placeholderText: Quickshell.env("HOME") + "/Pictures/Screenshots"
      text: root.savePath
      buttonIcon: "folder-open"
      buttonTooltip: pluginApi?.tr("settings.savePath.label")
      onInputEditCommitted: root.savePathField.set(text)
      onButtonClicked: screenshotFolderPicker.openFilePicker()
    }
  }

  NPluginSettingsField {
    field: root.recordingSavePathField
    NTextInputButton {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.recordingSavePath.label")
      description: pluginApi?.tr("settings.recordingSavePath.description")
      placeholderText: Quickshell.env("HOME") + "/Videos"
      text: root.recordingSavePath
      buttonIcon: "folder-open"
      buttonTooltip: pluginApi?.tr("settings.recordingSavePath.label")
      onInputEditCommitted: root.recordingSavePathField.set(text)
      onButtonClicked: recordingFolderPicker.openFilePicker()
    }
  }

  NPluginSettingsField {
    field: root.recordingNotificationsField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.recordingNotifications.label")
      description: pluginApi?.tr("settings.recordingNotifications.description")
      checked: root.recordingNotifications
      onToggled: checked => {
        root.recordingNotificationsField.set(checked);
      }
    }
  }

  PortalFilePicker {
    id: screenshotFolderPicker
    selectionMode: "folders"
    title: pluginApi?.tr("settings.savePath.label")
    initialPath: root.savePath || Quickshell.env("HOME") + "/Pictures/Screenshots"
    onAccepted: paths => {
      if (paths.length > 0) {
        root.savePathField.set(paths[0]);
      }
    }
  }

  PortalFilePicker {
    id: recordingFolderPicker
    selectionMode: "folders"
    title: pluginApi?.tr("settings.recordingSavePath.label")
    initialPath: root.recordingSavePath || Quickshell.env("HOME") + "/Videos"
    onAccepted: paths => {
      if (paths.length > 0) {
        root.recordingSavePathField.set(paths[0]);
      }
    }
  }

  // Required: Save function called by the dialog
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    pluginApi.saveSettings();
  }
}
