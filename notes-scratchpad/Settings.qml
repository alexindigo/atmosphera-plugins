import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Portals
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var panelWidthField: pluginApi?.field("panelWidth") ?? null
  readonly property var panelHeightField: pluginApi?.field("panelHeight") ?? null
  readonly property var fontSizeField: pluginApi?.field("fontSize") ?? null
  readonly property var filePathField: pluginApi?.field("filePath") ?? null
  readonly property var useMonospaceField: pluginApi?.field("useMonospace") ?? null

  // Local state
  readonly property int panelWidth: root.panelWidthField?.value ?? 600
  readonly property int panelHeight: root.panelHeightField?.value ?? 400
  readonly property int fontSize: root.fontSizeField?.value ?? 14
  readonly property string filePath: root.filePathField?.value ?? ""
  property bool filePathWritable: true
  readonly property bool useMonospace: root.useMonospaceField?.value ?? false
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  // Check file path writability
  Process {
    id: writeCheckProcess

    onExited: function (exitCode, exitStatus) {
      root.filePathWritable = (exitCode === 0);
    }
  }

  function checkFilePathWritability() {
    if (root.filePath === "") {
      root.filePathWritable = true;
      return;
    }

    // Check if file exists and is writable, or if parent directory is writable
    var testCmd = "if [ -e \"" + root.filePath + "\" ]; then " + "[ -w \"" + root.filePath + "\" ]; " + "else " + "[ -w \"$(dirname \"" + root.filePath + "\")\" ]; " + "fi";
    writeCheckProcess.exec(["sh", "-c", testCmd]);
  }

  function saveSettings() {
    if (pluginApi) {
      pluginApi.saveSettings();
    }
  }

  onFilePathChanged: {
    checkFilePathWritability();
  }

  // UI Components
  NLabel {
    label: pluginApi?.tr("settings.panel_dimensions.title") || "Panel Dimensions"
    description: pluginApi?.tr("settings.panel_dimensions.description") || "Configure the size of the scratchpad panel when it opens."
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginL

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: (pluginApi?.tr("settings.panel_dimensions.width") || "Width") + ": " + root.panelWidth + "px"
        pointSize: Style.fontSizeM
      }

      NPluginSettingsField {
        field: root.panelWidthField
        NSlider {
          id: widthSlider
          objectName: "settings-range-panelWidth"
          Layout.fillWidth: true
          from: 400
          to: 1200
          value: root.panelWidth
          stepSize: 50
          onMoved: {
            root.panelWidthField.set(Math.round(value));
          }
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: (pluginApi?.tr("settings.panel_dimensions.height") || "Height") + ": " + root.panelHeight + "px"
        pointSize: Style.fontSizeM
      }

      NPluginSettingsField {
        field: root.panelHeightField
        NSlider {
          id: heightSlider
          objectName: "settings-range-panelHeight"
          Layout.fillWidth: true
          from: 300
          to: 900
          value: root.panelHeight
          stepSize: 50
          onMoved: {
            root.panelHeightField.set(Math.round(value));
          }
        }
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    Layout.topMargin: Style.marginM

    NPluginSettingsField {
      field: root.filePathField
      NTextInputButton {
        label: pluginApi?.tr("settings.file_storage.title") || "File Storage"
        description: pluginApi?.tr("settings.file_storage.description") || "Optionally save scratchpad content to a file instead of plugin storage. Leave empty to use default storage."
        placeholderText: "/home/user/notes.txt"
        text: root.filePath
        buttonIcon: "file"
        buttonTooltip: pluginApi?.tr("settings.file_storage.select") || "Select file"
        onInputEditCommitted: root.filePathField.set(text)
        onButtonClicked: filePicker.openFilePicker()
      }
    }

    NText {
      visible: root.filePath !== "" && !root.filePathWritable
      text: pluginApi?.tr("settings.file_storage.not_writable") || "⚠ Warning: No write permission for this location"
      pointSize: Style.fontSizeS
      color: AtmoColor.mError
      Layout.fillWidth: true
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    Layout.topMargin: Style.marginM

    NText {
      text: pluginApi?.tr("settings.text_appearance.title") || "Text Appearance"
      pointSize: Style.fontSizeL
      font.weight: Font.DemiBold
    }

    NText {
      text: (pluginApi?.tr("settings.text_appearance.font_size") || "Font Size") + ": " + root.fontSize + "px"
      pointSize: Style.fontSizeM
    }

    NPluginSettingsField {
      field: root.fontSizeField
      NSlider {
        id: fontSizeSlider
        objectName: "settings-range-fontSize"
        Layout.fillWidth: true
        from: 10
        to: 24
        value: root.fontSize
        stepSize: 1
        onMoved: {
          root.fontSizeField.set(Math.round(value));
        }
      }
    }

    NPluginSettingsField {
      field: root.useMonospaceField
      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.text_appearance.monospace") || "Monospace Font"
        description: pluginApi?.tr("settings.text_appearance.monospace_description") || "Use a monospace font for the text area"
        checked: root.useMonospace
        onToggled: checked => root.useMonospaceField.set(checked)
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    Layout.topMargin: Style.marginL

    NLabel {
      label: pluginApi?.tr("settings.keyboard_shortcut.title") || "Keyboard Shortcut"
      description: pluginApi?.tr("settings.keyboard_shortcut.description") || "Toggle the scratchpad panel with this command:"
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: commandText.implicitHeight + Style.marginM * 2
      color: AtmoColor.mSurfaceVariant
      radius: Style.radiusM

      TextEdit {
        id: commandText
        anchors.fill: parent
        anchors.margins: Style.marginM
        text: "qs -c noctalia-shell ipc call plugin:notes-scratchpad togglePanel"
        font.pointSize: Style.fontSizeS
        font.family: Settings.data.ui.fontFixed
        color: AtmoColor.mPrimary
        wrapMode: TextEdit.WrapAnywhere
        readOnly: true
        selectByMouse: true
        selectionColor: AtmoColor.mPrimary
        selectedTextColor: AtmoColor.mOnPrimary
      }
    }
  }

  PortalFilePicker {
    id: filePicker
    selectionMode: "files"
    title: pluginApi?.tr("settings.file_storage.picker_title") || "Choose file for scratchpad"
    initialPath: root.filePath || Quickshell.env("HOME")
    onAccepted: paths => {
      if (paths.length > 0) {
        root.filePathField.set(paths[0]);
      }
    }
  }
}
