import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var colorField: pluginApi?.field("color") ?? null
  readonly property var colorIconField: pluginApi?.field("colorIcon") ?? null
  readonly property var hideOnEmptyField: pluginApi?.field("hideOnEmpty") ?? null
  readonly property var recentColorsField: pluginApi?.field("recentColors") ?? null

  readonly property string valueColor: root.colorField?.value ?? "#0064ff"
  readonly property bool valueColorIcon: root.colorIconField?.value ?? false
  readonly property bool valueHideOnEmpty: root.hideOnEmptyField?.value ?? false
  readonly property var valueRecentColors: root.recentColorsField?.value ?? []
  // One explicit color choice: the color and its recent-colors entry.
  function chooseColor(color) {
    var value = String(color);
    if (!root.colorField.set(value))
      return false;
    return root.recentColorsField.set([value].concat(root.valueRecentColors.filter(c => c !== value)).slice(0, 8));
  }
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _applyEffectPending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._applyEffectPending = false;
      root.pluginApi.mainInstance?.applyColors();
    }
  }

  spacing: Style.marginL

  NText {
    text: pluginApi?.tr("settings.lightbar_color")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.colorField
    NPluginSettingsField {
      field: root.colorField
      NColorPicker {
        Layout.fillWidth: true
        selectedColor: root.valueColor
        onColorSelected: color => root.chooseColor(color)
      }
    }
  }

  // Recent colors swatches — only shown when there is history
  NPluginSettingsField {
    field: root.recentColorsField
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS
      visible: root.valueRecentColors.length > 0

      NText {
        text: pluginApi?.tr("settings.recent_colors")
        pointSize: Style.fontSizeS
        font.weight: Font.Bold
        color: AtmoColor.mOnSurface
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 8
        rowSpacing: Style.marginS
        columnSpacing: Style.marginS

        Repeater {
          model: root.valueRecentColors
          delegate: Rectangle {
            required property string modelData
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: Style.radiusS
            color: modelData
            border.color: root.valueColor === modelData ? AtmoColor.mPrimary : AtmoColor.mOutline
            border.width: root.valueColor === modelData ? Style.borderS * 2 : Style.borderS

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.chooseColor(modelData)
            }
          }
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    text: pluginApi?.tr("settings.widget_settings")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.colorIconField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.color_icon.label")
      description: pluginApi?.tr("settings.color_icon.desc")
      checked: root.valueColorIcon
      onToggled: checked => root.colorIconField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.hideOnEmptyField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.hide_empty.label")
      description: pluginApi?.tr("settings.hide_empty.desc")
      checked: root.valueHideOnEmpty
      onToggled: checked => root.hideOnEmptyField.set(checked)
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    text: pluginApi?.tr("settings.info")
    pointSize: Style.fontSizeM
    font.weight: Font.Bold
    color: AtmoColor.mOnSurface
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: infoColumn.implicitHeight + Style.marginXL

    ColumnLayout {
      id: infoColumn

      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginM
      spacing: Style.marginS

      NText {
        text: pluginApi?.tr("settings.info_desc1")
        pointSize: Style.fontSizeS
        color: AtmoColor.mOnSurface
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }

      NText {
        text: pluginApi?.tr("settings.info_desc2")
        pointSize: Style.fontSizeS
        color: AtmoColor.mSecondary
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }
    }
  }

  // Called by the shell when the user clicks "Save"
  function saveSettings() {
    if (!pluginApi)
      return;
    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true;
  }
}
