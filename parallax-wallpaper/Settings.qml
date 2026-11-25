import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var zoomAmountField: pluginApi?.field("zoomAmount") ?? null
  readonly property var parallaxDirectionField: pluginApi?.field("parallaxDirection") ?? null
  readonly property var hParallaxAmountField: pluginApi?.field("hParallaxAmount") ?? null
  readonly property var hParallaxDurationField: pluginApi?.field("hParallaxDuration") ?? null
  readonly property var vParallaxAmountField: pluginApi?.field("vParallaxAmount") ?? null
  readonly property var vParallaxDurationField: pluginApi?.field("vParallaxDuration") ?? null
  readonly property var invertDirectionField: pluginApi?.field("invertDirection") ?? null
  readonly property var autoZoomField: pluginApi?.field("autoZoom") ?? null
  readonly property var parallaxEasingField: pluginApi?.field("parallaxEasing") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property real zoomAmount: root.zoomAmountField?.value ?? 1.1
  readonly property string parallaxDirection: root.parallaxDirectionField?.value ?? "horizontal"
  readonly property real hParallaxAmount: root.hParallaxAmountField?.value ?? 50
  readonly property int hParallaxDuration: root.hParallaxDurationField?.value ?? 400
  readonly property real vParallaxAmount: root.vParallaxAmountField?.value ?? 50
  readonly property int vParallaxDuration: root.vParallaxDurationField?.value ?? 400
  readonly property bool invertDirection: root.invertDirectionField?.value ?? false
  readonly property bool autoZoom: root.autoZoomField?.value ?? false
  readonly property string parallaxEasing: root.parallaxEasingField?.value ?? "OutCubic"
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  readonly property bool showHorizontal: parallaxDirection === "horizontal" || parallaxDirection === "both"
  readonly property bool showVertical: parallaxDirection === "vertical" || parallaxDirection === "both"

  spacing: Style.marginL

  // ── Wallpaper Zoom ──

  NPluginSettingsField {
    field: root.zoomAmountField
    NValueSlider {
      id: rangeZoomAmount
      objectName: "settings-range-zoomAmount"
      label: pluginApi.tr("settings.zoom.label")
      description: pluginApi.tr("settings.zoom.desc")
      text: root.zoomAmount.toFixed(2) + "x"
      from: 1.00
      to: 2.00
      stepSize: 0.01
      value: root.zoomAmount
      defaultValue: root.defaults.zoomAmount
      showReset: true
      onMoved: val => {
        root.zoomAmountField.set(val);
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Parallax Direction ──

  NPluginSettingsField {
    field: root.parallaxDirectionField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi.tr("settings.direction.label")
      description: pluginApi.tr("settings.direction.desc")
      defaultValue: root.defaults.parallaxDirection
      model: [
        {
          "key": "none",
          "name": pluginApi.tr("settings.direction.none")
        },
        {
          "key": "horizontal",
          "name": pluginApi.tr("settings.direction.horizontal")
        },
        {
          "key": "vertical",
          "name": pluginApi.tr("settings.direction.vertical")
        },
        {
          "key": "both",
          "name": pluginApi.tr("settings.direction.both")
        }
      ]
      currentKey: root.parallaxDirection
      onSelected: function (key) {
        root.parallaxDirectionField.set(key);
      }
    }
  }

  // ── Horizontal Parallax Settings ──

  NDivider {
    Layout.fillWidth: true
    visible: root.showHorizontal
  }

  NLabel {
    visible: root.showHorizontal
    label: pluginApi.tr("settings.horizontal.title")
  }

  NPluginSettingsField {
    field: root.hParallaxAmountField
    visible: root.showHorizontal
    NValueSlider {
      id: rangeHParallaxAmount
      objectName: "settings-range-hParallaxAmount"
      label: pluginApi.tr("settings.horizontal.amount")
      text: Math.round(root.hParallaxAmount) + "px"
      from: 1
      to: 200
      stepSize: 1
      value: root.hParallaxAmount
      defaultValue: root.defaults.hParallaxAmount
      showReset: true
      onMoved: val => {
        root.hParallaxAmountField.set(val);
      }
    }
  }

  NPluginSettingsField {
    field: root.hParallaxDurationField
    visible: root.showHorizontal
    NValueSlider {
      id: rangeHParallaxDuration
      objectName: "settings-range-hParallaxDuration"
      label: pluginApi.tr("settings.horizontal.duration")
      text: Math.round(root.hParallaxDuration) + "ms"
      from: 50
      to: 2000
      stepSize: 50
      value: root.hParallaxDuration
      defaultValue: root.defaults.hParallaxDuration
      showReset: true
      onMoved: val => {
        root.hParallaxDurationField.set(val);
      }
    }
  }

  // ── Vertical Parallax Settings ──

  NDivider {
    Layout.fillWidth: true
    visible: root.showVertical
  }

  NLabel {
    visible: root.showVertical
    label: pluginApi.tr("settings.vertical.title")
  }

  NPluginSettingsField {
    field: root.vParallaxAmountField
    visible: root.showVertical
    NValueSlider {
      id: rangeVParallaxAmount
      objectName: "settings-range-vParallaxAmount"
      label: pluginApi.tr("settings.vertical.amount")
      text: Math.round(root.vParallaxAmount) + "px"
      from: 1
      to: 200
      stepSize: 1
      value: root.vParallaxAmount
      defaultValue: root.defaults.vParallaxAmount
      showReset: true
      onMoved: val => {
        root.vParallaxAmountField.set(val);
      }
    }
  }

  NPluginSettingsField {
    field: root.vParallaxDurationField
    visible: root.showVertical
    NValueSlider {
      id: rangeVParallaxDuration
      objectName: "settings-range-vParallaxDuration"
      label: pluginApi.tr("settings.vertical.duration")
      text: Math.round(root.vParallaxDuration) + "ms"
      from: 50
      to: 2000
      stepSize: 50
      value: root.vParallaxDuration
      defaultValue: root.defaults.vParallaxDuration
      showReset: true
      onMoved: val => {
        root.vParallaxDurationField.set(val);
      }
    }
  }

  // ── Invert Direction ──

  NDivider {
    Layout.fillWidth: true
  }

  NPluginSettingsField {
    field: root.invertDirectionField
    NToggle {
      label: pluginApi.tr("settings.invert.label")
      description: pluginApi.tr("settings.invert.desc")
      defaultValue: root.defaults.invertDirection
      checked: root.invertDirection
      onToggled: checked => {
        root.invertDirectionField.set(checked);
      }
    }
  }

  // ── Auto Zoom ──

  NDivider {
    Layout.fillWidth: true
  }

  NPluginSettingsField {
    field: root.autoZoomField
    NToggle {
      label: pluginApi.tr("settings.autoZoom.label")
      description: pluginApi.tr("settings.autoZoom.desc")
      defaultValue: root.defaults.autoZoom
      checked: root.autoZoom
      onToggled: checked => {
        root.autoZoomField.set(checked);
      }
    }
  }

  // ── Easing Curve ──

  NDivider {
    Layout.fillWidth: true
  }

  NPluginSettingsField {
    field: root.parallaxEasingField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi.tr("settings.easing.label")
      description: pluginApi.tr("settings.easing.desc")
      defaultValue: root.defaults.parallaxEasing
      model: [
        {
          "key": "Linear",
          "name": pluginApi.tr("settings.easing.linear")
        },
        {
          "key": "InQuad",
          "name": pluginApi.tr("settings.easing.inQuad")
        },
        {
          "key": "OutQuad",
          "name": pluginApi.tr("settings.easing.outQuad")
        },
        {
          "key": "InOutQuad",
          "name": pluginApi.tr("settings.easing.inOutQuad")
        },
        {
          "key": "InCubic",
          "name": pluginApi.tr("settings.easing.inCubic")
        },
        {
          "key": "OutCubic",
          "name": pluginApi.tr("settings.easing.outCubic")
        },
        {
          "key": "InOutCubic",
          "name": pluginApi.tr("settings.easing.inOutCubic")
        },
        {
          "key": "InQuart",
          "name": pluginApi.tr("settings.easing.inQuart")
        },
        {
          "key": "OutQuart",
          "name": pluginApi.tr("settings.easing.outQuart")
        },
        {
          "key": "InOutQuart",
          "name": pluginApi.tr("settings.easing.inOutQuart")
        },
        {
          "key": "InExpo",
          "name": pluginApi.tr("settings.easing.inExpo")
        },
        {
          "key": "OutExpo",
          "name": pluginApi.tr("settings.easing.outExpo")
        },
        {
          "key": "InOutExpo",
          "name": pluginApi.tr("settings.easing.inOutExpo")
        }
      ]
      currentKey: root.parallaxEasing
      onSelected: function (key) {
        root.parallaxEasingField.set(key);
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Parallax Wallpaper", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings();
  }
}
