import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var iconNameField: pluginApi?.field("iconName") ?? null
  readonly property var showTransformInTooltipField: pluginApi?.field("showTransformInTooltip") ?? null
  readonly property var showSuccessToastField: pluginApi?.field("showSuccessToast") ?? null
  readonly property var autoTabletBarDensityField: pluginApi?.field("autoTabletBarDensity") ?? null
  readonly property var exclusiveDockInTabletModeField: pluginApi?.field("exclusiveDockInTabletMode") ?? null
  readonly property var autoRotateInTabletModeField: pluginApi?.field("autoRotateInTabletMode") ?? null
  readonly property var autoRotateOutsideTabletModeField: pluginApi?.field("autoRotateOutsideTabletMode") ?? null
  readonly property var syncHyprTouchTransformField: pluginApi?.field("syncHyprTouchTransform") ?? null
  readonly property var flipVerticalSensorOrientationField: pluginApi?.field("flipVerticalSensorOrientation") ?? null
  readonly property var buttonBehaviorField: pluginApi?.field("buttonBehavior") ?? null
  readonly property var tabletBarDensityField: pluginApi?.field("tabletBarDensity") ?? null

  readonly property string editIconName: root.iconNameField?.value ?? "rotate-cw"
  readonly property bool editShowTransformInTooltip: root.showTransformInTooltipField?.value ?? true
  readonly property bool editShowSuccessToast: root.showSuccessToastField?.value ?? true
  readonly property bool editAutoTabletBarDensity: root.autoTabletBarDensityField?.value ?? false
  readonly property bool editExclusiveDockInTabletMode: root.exclusiveDockInTabletModeField?.value ?? false
  readonly property bool editAutoRotateInTabletMode: root.autoRotateInTabletModeField?.value ?? false
  readonly property bool editAutoRotateOutsideTabletMode: root.autoRotateOutsideTabletModeField?.value ?? false
  readonly property bool editSyncHyprTouchTransform: root.syncHyprTouchTransformField?.value ?? true
  readonly property bool editFlipVerticalSensorOrientation: root.flipVerticalSensorOrientationField?.value ?? false
  readonly property string editButtonBehavior: root.buttonBehaviorField?.value ?? "toggle-auto-rotate-lock"
  readonly property string editTabletBarDensity: root.tabletBarDensityField?.value ?? "default"
  property bool autoRotateDependencyAvailable: true
  readonly property var barDensityModel: [
    {
      key: "mini",
      name: pluginApi?.tr("settings.tabletBarDensity.options.mini")
    },
    {
      key: "compact",
      name: pluginApi?.tr("settings.tabletBarDensity.options.compact")
    },
    {
      key: "default",
      name: pluginApi?.tr("settings.tabletBarDensity.options.default")
    },
    {
      key: "comfortable",
      name: pluginApi?.tr("settings.tabletBarDensity.options.comfortable")
    },
    {
      key: "spacious",
      name: pluginApi?.tr("settings.tabletBarDensity.options.spacious")
    }
  ]
  readonly property var buttonBehaviorModel: [
    {
      key: "toggle-auto-rotate-lock",
      name: pluginApi?.tr("settings.buttonBehavior.options.toggleAutoRotateLock")
    },
    {
      key: "manual-rotate",
      name: pluginApi?.tr("settings.buttonBehavior.options.manualRotate")
    }
  ]

  spacing: Style.marginL

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NLabel {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.iconName.label")
      description: pluginApi?.tr("settings.iconName.description")
    }

    AtmoIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: root.editIconName
      pointSize: Style.fontSizeXXL * 1.5
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NPluginSettingsField {
      field: root.iconNameField
      NTextInput {
        Layout.fillWidth: true
        text: root.editIconName
        onEditCommitted: {
          root.iconNameField.set(text.trim() !== "" ? text.trim() : "rotate-cw");
        }
      }
    }

    NButton {
      text: pluginApi?.tr("settings.iconName.browseLibrary")
      onClicked: iconPicker.open()
    }
  }

  NPluginSettingsField {
    field: root.showTransformInTooltipField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.showTransformInTooltip.label")
      description: pluginApi?.tr("settings.showTransformInTooltip.description")
      checked: root.editShowTransformInTooltip
      onToggled: checked => {
        root.showTransformInTooltipField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.showSuccessToastField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.showSuccessToast.label")
      description: pluginApi?.tr("settings.showSuccessToast.description")
      checked: root.editShowSuccessToast
      onToggled: checked => {
        root.showSuccessToastField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.autoTabletBarDensityField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.autoTabletBarDensity.label")
      description: pluginApi?.tr("settings.autoTabletBarDensity.description")
      checked: root.editAutoTabletBarDensity
      onToggled: checked => {
        root.autoTabletBarDensityField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.exclusiveDockInTabletModeField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.exclusiveDockInTabletMode.label")
      description: pluginApi?.tr("settings.exclusiveDockInTabletMode.description")
      checked: root.editExclusiveDockInTabletMode
      onToggled: checked => {
        root.exclusiveDockInTabletModeField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.autoRotateInTabletModeField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.autoRotateInTabletMode.label")
      description: pluginApi?.tr("settings.autoRotateInTabletMode.description")
      checked: root.editAutoRotateInTabletMode
      onToggled: checked => {
        root.autoRotateInTabletModeField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.autoRotateOutsideTabletModeField
    visible: root.editAutoRotateInTabletMode
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.autoRotateOutsideTabletMode.label")
      description: pluginApi?.tr("settings.autoRotateOutsideTabletMode.description")
      checked: root.editAutoRotateOutsideTabletMode
      onToggled: checked => {
        root.autoRotateOutsideTabletModeField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.syncHyprTouchTransformField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.syncHyprTouchTransform.label")
      description: pluginApi?.tr("settings.syncHyprTouchTransform.description")
      checked: root.editSyncHyprTouchTransform
      onToggled: checked => {
        root.syncHyprTouchTransformField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.buttonBehaviorField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.buttonBehavior.label")
      description: pluginApi?.tr("settings.buttonBehavior.description")
      model: root.buttonBehaviorModel
      currentKey: root.editButtonBehavior
      onSelected: key => {
        root.buttonBehaviorField.set(key);
      }
    }
  }

  NLabel {
    Layout.fillWidth: true
    visible: !root.autoRotateDependencyAvailable
    label: pluginApi?.tr("settings.autoRotateDependency.label")
    description: pluginApi?.tr("settings.autoRotateDependency.description")
  }

  NPluginSettingsField {
    field: root.flipVerticalSensorOrientationField
    visible: root.editAutoRotateInTabletMode
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.flipVerticalSensorOrientation.label")
      description: pluginApi?.tr("settings.flipVerticalSensorOrientation.description")
      checked: root.editFlipVerticalSensorOrientation
      onToggled: checked => {
        root.flipVerticalSensorOrientationField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.tabletBarDensityField
    visible: root.editAutoTabletBarDensity
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.tabletBarDensity.label")
      description: pluginApi?.tr("settings.tabletBarDensity.description")
      model: root.barDensityModel
      currentKey: root.editTabletBarDensity
      onSelected: key => {
        root.tabletBarDensityField.set(key);
      }
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }

  Process {
    id: dependencyCheckProc
    command: ["sh", "-c", "command -v monitor-sensor >/dev/null 2>&1 && [ -x /usr/lib/iio-sensor-proxy ]"]
    onExited: (exitCode, exitStatus) => {
      root.autoRotateDependencyAvailable = exitCode === 0;
    }
    Component.onCompleted: running = true
  }

  AtmoIconPicker {
    id: iconPicker
    initialIcon: root.editIconName
    onIconSelected: iconName => {
      root.iconNameField.set(iconName);
      root.saveSettings();
    }
  }
}
