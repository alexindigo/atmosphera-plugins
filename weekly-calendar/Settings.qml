import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var panelModeField: pluginApi?.field("panelMode") ?? null
  readonly property var weekStartField: pluginApi?.field("weekStart") ?? null
  readonly property var timeFormatField: pluginApi?.field("timeFormat") ?? null
  readonly property var lineColorTypeField: pluginApi?.field("lineColorType") ?? null
  readonly property var hourLineOpacityField: pluginApi?.field("hourLineOpacity") ?? null
  readonly property var dayLineOpacityField: pluginApi?.field("dayLineOpacity") ?? null

  readonly property string weekStart: root.weekStartField?.value || "1"
  readonly property string timeFormat: root.timeFormatField?.value || "24h"
  readonly property string lineColorType: root.lineColorTypeField?.value || "mOutline"
  readonly property string panelMode: root.panelModeField?.value || "attached"
  readonly property real hourLineOpacity: root.hourLineOpacityField?.value || 0.5
  readonly property real dayLineOpacity: root.dayLineOpacityField?.value || 0.9

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.i("WeeklyCalendar", "Settings UI loaded");
  }

  // Time Format toggle
  NPluginSettingsField {
    field: root.timeFormatField
    NToggle {
      label: pluginApi.tr("settings.timeFormat")
      description: pluginApi.tr("settings.timeFormat_description")
      checked: root.timeFormat === pluginApi.tr("settings.12h")
      onToggled: checked => root.timeFormatField.set(checked ? pluginApi.tr("settings.12h") : pluginApi.tr("settings.24h"))
    }
  }

  // Week Start selector
  NPluginSettingsField {
    field: root.weekStartField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi.tr("settings.weekStart")
      description: pluginApi.tr("settings.weekStart_description")
      model: [
        {
          "key": "1",
          "name": pluginApi.tr("settings.monday")
        },
        {
          "key": "0",
          "name": pluginApi.tr("settings.sunday")
        },
        {
          "key": "6",
          "name": pluginApi.tr("settings.saturday")
        }
      ]
      currentKey: root.weekStart
      onSelected: key => root.weekStartField.set(key)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  // Line color type selector
  NPluginSettingsField {
    field: root.lineColorTypeField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi.tr("settings.gridColor")
      description: pluginApi.tr("settings.gridColor_description")
      model: [
        {
          "key": "mOutline",
          "name": pluginApi.tr("settings.colorOutline")
        },
        {
          "key": "mOnSurfaceVariant",
          "name": pluginApi.tr("settings.colorOnSurfaceVariant")
        }
      ]
      currentKey: root.lineColorType
      onSelected: key => root.lineColorTypeField.set(key)
    }
  }

  // Hour line opacity slider
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    NLabel {
      label: pluginApi.tr("settings.hourLineOpacity")
    }
    RowLayout {
      Layout.fillWidth: true
      NText {
        text: pluginApi.tr("settings.hourLineOpacity_description")
        font.pointSize: Style.fontSizeS
        color: AtmoColor.mOnSurfaceVariant
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
      Item {
        Layout.fillWidth: true
      }
      NText {
        text: Math.round(root.hourLineOpacity * 100) + "%"
        font.pointSize: Style.fontSizeS
        color: AtmoColor.mOnSurfaceVariant
      }
    }

    NPluginSettingsField {
      field: root.hourLineOpacityField
      NSlider {
        id: rangeHourLineOpacity
        objectName: "settings-range-hourLineOpacity"
        Layout.fillWidth: true
        from: 0.1
        to: 1
        stepSize: 0.1
        value: root.hourLineOpacity
        onMoved: root.hourLineOpacityField.set(value)
      }
    }
  }

  // Day line opacity slider
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    NLabel {
      label: pluginApi.tr("settings.dayLineOpacity")
    }
    RowLayout {
      Layout.fillWidth: true
      NText {
        text: pluginApi.tr("settings.dayLineOpacity_description")
        font.pointSize: Style.fontSizeS
        color: AtmoColor.mOnSurfaceVariant
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
      Item {
        Layout.fillWidth: true
      }
      NText {
        text: Math.round(root.dayLineOpacity * 100) + "%"
        font.pointSize: Style.fontSizeS
        color: AtmoColor.mOnSurfaceVariant
      }
    }

    NPluginSettingsField {
      field: root.dayLineOpacityField
      NSlider {
        id: rangeDayLineOpacity
        objectName: "settings-range-dayLineOpacity"
        Layout.fillWidth: true
        from: 0.1
        to: 1
        stepSize: 0.1
        value: root.dayLineOpacity
        onMoved: root.dayLineOpacityField.set(value)
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  NPluginSettingsField {
    field: root.panelModeField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi.tr("settings.panelMode")
      description: pluginApi.tr("settings.panelMode_description")
      model: [
        {
          "key": "attached",
          "name": pluginApi.tr("settings.panelAttach")
        },
        {
          "key": "centered",
          "name": pluginApi.tr("settings.panelCenter")
        },
      ]
      currentKey: root.panelMode
      onSelected: key => root.panelModeField.set(key)
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("WeeklyCalendar", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings();
  }
}
