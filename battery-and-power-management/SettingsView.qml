import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null
  readonly property var colorizeByProfileField: pluginApi?.field("colorizeByProfile") ?? null
  readonly property var colorPowerSaverField: pluginApi?.field("colorPowerSaver") ?? null
  readonly property var colorPerformanceField: pluginApi?.field("colorPerformance") ?? null
  readonly property var showProfileField: pluginApi?.field("showProfile") ?? null
  readonly property var showBalancedIconField: pluginApi?.field("showBalancedIcon") ?? null

  readonly property bool editColorizeByProfile: root.colorizeByProfileField?.value ?? true
  readonly property string editColorPowerSaver: root.colorPowerSaverField?.value ?? AtmoColor.mSecondary
  readonly property string editColorPerformance: root.colorPerformanceField?.value ?? AtmoColor.mError
  readonly property bool editShowProfile: root.showProfileField?.value ?? true
  readonly property bool editShowBalancedIcon: root.showBalancedIconField?.value ?? false

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }

  // All palette colors
  readonly property var noctaliaPalette: [AtmoColor.mPrimary, AtmoColor.mSecondary, AtmoColor.mTertiary, AtmoColor.mError, AtmoColor.mSurface, AtmoColor.mSurfaceVariant, AtmoColor.mOutline]

  Component.onCompleted: {
    Logger.d("BatterySettings", "editColorPowerSaver: " + editColorPowerSaver);
    Logger.d("BatterySettings", "editColorPerformance: " + editColorPerformance);
  }

  //Dynamic coloring based on selected profile
  NPluginSettingsField {
    field: root.colorizeByProfileField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.dynamic-coloring")
      description: pluginApi?.tr("settings.dynamic-coloring-desc")
      checked: root.editColorizeByProfile
      onToggled: checked => {
        root.colorizeByProfileField.set(checked);
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginM
    enabled: root.editColorizeByProfile
    opacity: enabled ? 1.0 : 0.5

    // Power saver color
    NPluginSettingsField {
      field: root.colorPowerSaverField
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NText {
          text: pluginApi?.tr("settings.color-powersaver")
          font.weight: Font.Bold
        }
        NText {
          text: pluginApi?.tr("settings.color-powersaver-desc")
          font.pointSize: Style.fontSizeS
          color: AtmoColor.mOnSurfaceVariant
        }

        RowLayout {
          spacing: Style.marginS

          Repeater {
            id: powerSaverColor
            model: root.noctaliaPalette

            Rectangle {
              //width: 28
              //height: 28
              radius: Style.radiusL
              color: modelData
              border.color: Qt.colorEqual(root.editColorPowerSaver, modelData) ? AtmoColor.mOnSurface : AtmoColor.mOutline
              border.width: Qt.colorEqual(root.editColorPowerSaver, modelData) ? 3 : 1

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Logger.d("BatterySettings", "Power Saver selected: " + modelData);
                  root.colorPowerSaverField.set(modelData);
                }
              }
            }
          }
        }
      }
    }

    // Space separator
    Item {
      Layout.preferredHeight: Style.marginS
    }

    // Performance color
    NPluginSettingsField {
      field: root.colorPerformanceField
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NText {
          text: pluginApi?.tr("settings.color-performance")
          font.weight: Font.Bold
        }
        NText {
          text: pluginApi?.tr("settings.color-performance-desc")
          font.pointSize: Style.fontSizeS
          color: AtmoColor.mOnSurfaceVariant
        }

        RowLayout {
          spacing: Style.marginS

          Repeater {
            id: performanceColor
            model: root.noctaliaPalette

            Rectangle {
              //width: 28
              //height: 28
              radius: Style.radiusL
              color: modelData
              border.color: Qt.colorEqual(root.editColorPerformance, modelData) ? AtmoColor.mOnSurface : AtmoColor.mOutline
              border.width: Qt.colorEqual(root.editColorPerformance, modelData) ? 3 : 1

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Logger.d("BatterySettings", "Performance selected: " + modelData);
                  root.colorPerformanceField.set(modelData);
                }
              }
            }
          }
        }
      }
    }
  }

  //Show profile in widget
  NPluginSettingsField {
    field: root.showProfileField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-profile")
      description: pluginApi?.tr("settings.show-profile-desc")
      checked: root.editShowProfile
      onToggled: checked => {
        root.showProfileField.set(checked);
      }
    }
  }

  //Show balanced icon
  NPluginSettingsField {
    field: root.showBalancedIconField
    NToggle {
      enabled: root.editShowProfile
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.show-balanced")
      description: pluginApi?.tr("settings.show-balanced-desc")
      checked: root.editShowBalancedIcon
      onToggled: checked => {
        Logger.d("BatterySettings", "showBalancedIcon checked: " + checked);
        root.showBalancedIconField.set(checked);
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
