import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Portals
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var animationsFolderField: pluginApi?.field("animationsFolder") ?? null
  readonly property var targetFileField: pluginApi?.field("targetFile") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null

  readonly property string valueAnimationsFolder: root.animationsFolderField?.value ?? "~/.config/niri/animations"
  readonly property string valueTargetFile: root.targetFileField?.value ?? "~/.config/niri/animations.kdl"
  readonly property string valueIconColor: root.iconColorField?.value ?? "none"

  spacing: Style.marginL

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    // Animations folder — use file picker to select a folder
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NLabel {
        label: pluginApi?.tr("settings.animationsFolder.label")
        description: pluginApi?.tr("settings.animationsFolder.description")
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NText {
          text: root.valueAnimationsFolder
          color: AtmoColor.mOnSurfaceVariant
          pointSize: Style.fontSizeS
          elide: Text.ElideLeft
          Layout.fillWidth: true
        }

        NPluginSettingsField {
          field: root.animationsFolderField
          NButton {
            text: pluginApi?.tr("settings.browse")
            onClicked: animFolderPicker.openFilePicker()
          }
        }
      }

      PortalFilePicker {
        id: animFolderPicker
        title: pluginApi?.tr("settings.animationsFolder.pickerTitle")
        initialPath: root.valueAnimationsFolder
        selectionMode: "folders"
        onAccepted: paths => {
          if (paths.length > 0) {
            root.animationsFolderField.set(paths[0]);
          }
        }
      }
    }

    // Target KDL file — plain text input since the file may not exist yet
    NPluginSettingsField {
      field: root.targetFileField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.targetFile.label")
        description: pluginApi?.tr("settings.targetFile.description")
        placeholderText: "~/.config/niri/animations.kdl"
        text: root.valueTargetFile
        onEditCommitted: root.targetFileField.set(text)
      }
    }

    // Icon color
    NPluginSettingsField {
      field: root.iconColorField
      NColorChoice {
        label: pluginApi?.tr("settings.iconColor.label")
        description: pluginApi?.tr("settings.iconColor.description")
        currentKey: root.valueIconColor
        onSelected: key => root.iconColorField.set(key)
      }
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("NiriAnimationPicker", "Cannot save settings: pluginApi is null");
      return;
    }
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("NiriAnimationPicker", "Settings saved");
    });
  }
}
