import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var successIconField: pluginApi?.field("successIcon") ?? null
  readonly property var errorIconField: pluginApi?.field("errorIcon") ?? null
  readonly property var loadingIconField: pluginApi?.field("loadingIcon") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string valueIconColor: root.iconColorField?.value ?? defaults.iconColor
  readonly property int valueRefreshInterval: root.refreshIntervalField?.value ?? 300
  readonly property string valueSuccessIcon: root.successIconField?.value ?? "hierarchy-2"
  readonly property string valueErrorIcon: root.errorIconField?.value ?? "alert-circle"
  readonly property string valueLoadingIcon: root.loadingIconField?.value ?? "loader"

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.d("IpMonitor", "Settings UI loaded");
  }

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    // Appearance section
    NText {
      text: pluginApi?.tr("settings.appearance.title")
      font.pointSize: Style.fontSizeM * Style.uiScaleRatio
      font.weight: Font.Medium
      color: AtmoColor.mOnSurface
    }

    NPluginSettingsField {
      field: root.iconColorField
      NComboBox {
        label: pluginApi?.tr("settings.iconColor.label")
        description: pluginApi?.tr("settings.iconColor.desc")
        model: AtmoColor.colorKeyModel
        currentKey: root.valueIconColor
        onSelected: key => root.iconColorField.set(key)
      }
    }

    // State Icons section
    NText {
      text: pluginApi?.tr("settings.stateIcons.title")
      font.pointSize: Style.fontSizeM * Style.uiScaleRatio
      font.weight: Font.Medium
      color: AtmoColor.mOnSurface
      Layout.topMargin: Style.marginM
    }

    RowLayout {
      spacing: Style.marginM

      NLabel {
        label: pluginApi?.tr("settings.successIcon.label")
        description: pluginApi?.tr("settings.successIcon.desc")
      }

      AtmoIcon {
        Layout.alignment: Qt.AlignVCenter
        icon: valueSuccessIcon
        pointSize: Style.fontSizeXXL * 1.5
        visible: valueSuccessIcon !== ""
      }

      NPluginSettingsField {
        field: root.successIconField
        NButton {
          text: pluginApi?.tr("settings.browseIcons")
          onClicked: successIconPicker.open()
        }
      }
    }

    AtmoIconPicker {
      id: successIconPicker
      initialIcon: valueSuccessIcon
      onIconSelected: iconName => {
        root.successIconField.set(iconName);
      }
    }

    RowLayout {
      spacing: Style.marginM

      NLabel {
        label: pluginApi?.tr("settings.errorIcon.label")
        description: pluginApi?.tr("settings.errorIcon.desc")
      }

      AtmoIcon {
        Layout.alignment: Qt.AlignVCenter
        icon: valueErrorIcon
        pointSize: Style.fontSizeXXL * 1.5
        visible: valueErrorIcon !== ""
      }

      NPluginSettingsField {
        field: root.errorIconField
        NButton {
          text: pluginApi?.tr("settings.browseIcons")
          onClicked: errorIconPicker.open()
        }
      }
    }

    AtmoIconPicker {
      id: errorIconPicker
      initialIcon: valueErrorIcon
      onIconSelected: iconName => {
        root.errorIconField.set(iconName);
      }
    }

    RowLayout {
      spacing: Style.marginM

      NLabel {
        label: pluginApi?.tr("settings.loadingIcon.label")
        description: pluginApi?.tr("settings.loadingIcon.desc")
      }

      AtmoIcon {
        Layout.alignment: Qt.AlignVCenter
        icon: valueLoadingIcon
        pointSize: Style.fontSizeXXL * 1.5
        visible: valueLoadingIcon !== ""
      }

      NPluginSettingsField {
        field: root.loadingIconField
        NButton {
          text: pluginApi?.tr("settings.browseIcons")
          onClicked: loadingIconPicker.open()
        }
      }
    }

    AtmoIconPicker {
      id: loadingIconPicker
      initialIcon: valueLoadingIcon
      onIconSelected: iconName => {
        root.loadingIconField.set(iconName);
      }
    }

    // Behavior section
    NText {
      text: pluginApi?.tr("settings.behavior.title")
      font.pointSize: Style.fontSizeM * Style.uiScaleRatio
      font.weight: Font.Medium
      color: AtmoColor.mOnSurface
      Layout.topMargin: Style.marginM
    }

    NPluginSettingsField {
      field: root.refreshIntervalField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.refreshInterval.label")
        description: pluginApi?.tr("settings.refreshInterval.desc")
        placeholderText: pluginApi?.tr("settings.refreshInterval.placeholder")
        text: root.valueRefreshInterval.toString()
        onEditCommitted: {
          var val = parseInt(text);
          if (!isNaN(val) && val >= 0 && val <= 86400) {
            root.refreshIntervalField.set(val);
          }
        }
      }
    }

    // IPC keybinding
    NText {
      text: pluginApi?.tr("settings.commands.title")
      font.pointSize: Style.fontSizeM * Style.uiScaleRatio
      font.weight: Font.Medium
      color: AtmoColor.mOnSurface
      Layout.topMargin: Style.marginM
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: infoCol.implicitHeight + Style.marginM * 2
      color: AtmoColor.mSurfaceVariant
      radius: Style.radiusM

      ColumnLayout {
        id: infoCol
        anchors {
          fill: parent
          margins: Style.marginM
        }
        spacing: Style.marginS

        RowLayout {
          spacing: Style.marginS

          AtmoIcon {
            icon: "info-circle"
            pointSize: Style.fontSizeS
            color: AtmoColor.mPrimary
          }

          NText {
            text: pluginApi?.tr("settings.ipcCommands.title")
            pointSize: Style.fontSizeS
            font.weight: Font.Medium
            color: AtmoColor.mOnSurface
          }
        }

        NText {
          Layout.fillWidth: true
          text: pluginApi?.tr("settings.ipcCommands.refreshIp") + ": qs -c noctalia-shell ipc call plugin:ip-monitor refreshIp"
          pointSize: Style.fontSizeXS
          font.family: Settings.data.ui.fontFixed
          color: AtmoColor.mOnSurfaceVariant
          wrapMode: Text.WrapAnywhere
        }

        NText {
          Layout.fillWidth: true
          text: pluginApi?.tr("settings.ipcCommands.togglePanel") + ": qs -c noctalia-shell ipc call plugin:ip-monitor toggle"
          pointSize: Style.fontSizeXS
          font.family: Settings.data.ui.fontFixed
          color: AtmoColor.mOnSurfaceVariant
          wrapMode: Text.WrapAnywhere
        }
      }
    }
  }

  signal settingsChanged(var settings)
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("IpMonitor", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("IpMonitor", "Settings saved successfully");
    });
  }
}
