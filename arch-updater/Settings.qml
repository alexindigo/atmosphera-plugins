import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Portals
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  // Explicit field intent only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  readonly property var systemCmdField: pluginApi?.field("systemCmd") ?? null
  readonly property var aurCmdField: pluginApi?.field("aurCmd") ?? null
  readonly property var updateCmdField: pluginApi?.field("updateCmd") ?? null
  readonly property var aurHomepageCmdField: pluginApi?.field("aurHomepageCmd") ?? null
  readonly property var flatpakField: pluginApi?.field("flatpak") ?? null
  readonly property var toastField: pluginApi?.field("toast") ?? null
  readonly property var refreshTimerField: pluginApi?.field("refreshTimer") ?? null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var noctaliaField: pluginApi?.field("noctalia") ?? null
  readonly property var tooltipField: pluginApi?.field("tooltip") ?? null
  readonly property var hideOnEmptyField: pluginApi?.field("hideOnEmpty") ?? null
  readonly property var boldTextField: pluginApi?.field("boldText") ?? null
  readonly property var useDistroLogoField: pluginApi?.field("useDistroLogo") ?? null
  readonly property var enableColorizationField: pluginApi?.field("enableColorization") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null
  readonly property var iconNameField: pluginApi?.field("iconName") ?? null
  readonly property var customIconPathField: pluginApi?.field("customIconPath") ?? null
  readonly property var boldVerPanelField: pluginApi?.field("boldVerPanel") ?? null
  readonly property var panelTooltipField: pluginApi?.field("panelTooltip") ?? null
  readonly property var panelContextField: pluginApi?.field("panelContext") ?? null
  readonly property var closeButtonField: pluginApi?.field("closeButton") ?? null
  readonly property var closeOnSettingsField: pluginApi?.field("closeOnSettings") ?? null
  readonly property var boldVerDesktopField: pluginApi?.field("boldVerDesktop") ?? null
  readonly property var hoverTipField: pluginApi?.field("hoverTip") ?? null

  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      // Refresh the client of the selected configuration, never shared Main.
      root.pluginApi.mainInstance?.settingsConsumerFor(root.pluginApi.runtimeContext)?.refresh();
      Logger.i("Arch Updater", "Settings saved successfully");
    }
  }

  spacing: Style.marginM

  // Runs when the plugin settings are loaded
  Component.onCompleted: {
    Logger.i("Arch Updater", "Settings UI loaded");
  }

  // Tab Bar
  NTabBar {
    id: tabBar
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      icon: "settings"
      text: pluginApi.tr("settings.tabs.general")
      pointSize: Style.fontSizeL
      tabIndex: 0
      checked: tabBar.currentIndex === 0
    }

    NTabButton {
      icon: "crop-16-9"
      text: pluginApi.tr("settings.tabs.bar")
      pointSize: Style.fontSizeL
      tabIndex: 1
      checked: tabBar.currentIndex === 1
    }

    NTabButton {
      icon: "table"
      text: pluginApi.tr("settings.tabs.panel")
      pointSize: Style.fontSizeL
      tabIndex: 2
      checked: tabBar.currentIndex === 2
    }

    NTabButton {
      icon: "clock"
      text: pluginApi.tr("settings.tabs.desktop")
      pointSize: Style.fontSizeL
      tabIndex: 3
      checked: tabBar.currentIndex === 3
    }
  }

  NTabView {
    id: tabView
    currentIndex: tabBar.currentIndex

    ColumnLayout { // General Tab
      spacing: Style.marginM

      NText { // General Title
        text: pluginApi.tr("settings.general.title")
        pointSize: Style.fontSizeXL
        font.weight: Font.Bold
        color: AtmoColor.mOnSurface
      }

      NLabel { // General Description
        description: pluginApi.tr("settings.general.desc")
      }

      NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
      }

      NPluginSettingsField { // System Command
        field: root.systemCmdField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi.tr("settings.general.systemCmd.text")
          description: pluginApi.tr("settings.general.systemCmd.desc")
          placeholderText: pluginApi.manifest.metadata.defaultSettings.systemCmd
          text: root.systemCmdField?.value ?? ""
          onEditCommitted: root.systemCmdField.set(text)
        }
      }

      NPluginSettingsField { // AUR Command
        field: root.aurCmdField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi.tr("settings.general.aurCmd.text")
          description: pluginApi.tr("settings.general.aurCmd.desc")
          placeholderText: pluginApi.manifest.metadata.defaultSettings.aurCmd
          text: root.aurCmdField?.value ?? ""
          onEditCommitted: root.aurCmdField.set(text)
        }
      }

      NPluginSettingsField { // Update Command
        field: root.updateCmdField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi.tr("settings.general.updateCmd.text")
          description: pluginApi.tr("settings.general.updateCmd.desc")
          placeholderText: pluginApi.manifest.metadata.defaultSettings.updateCmd
          text: root.updateCmdField?.value ?? ""
          onEditCommitted: root.updateCmdField.set(text)
        }
      }

      NPluginSettingsField { // AUR Homepage Command
        field: root.aurHomepageCmdField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi.tr("settings.general.aurHomepageCmd.text")
          description: pluginApi.tr("settings.general.aurHomepageCmd.desc")
          placeholderText: pluginApi.manifest.metadata.defaultSettings.aurHomepageCmd
          text: root.aurHomepageCmdField?.value ?? ""
          onEditCommitted: root.aurHomepageCmdField.set(text)
        }
      }

      NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
      }

      // Flatpak Toggle
      NPluginSettingsField {
        field: root.flatpakField
        NToggle {
          id: flatpakToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.general.flatpak.text")
          description: pluginApi.tr("settings.general.flatpak.desc")
          checked: root.flatpakField?.value ?? false
          onToggled: checked => root.flatpakField.set(checked)
        }
      }

      // Toast Toggle
      NPluginSettingsField {
        field: root.toastField
        NToggle {
          id: toastToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.general.toast.text")
          description: pluginApi.tr("settings.general.toast.desc")
          checked: root.toastField?.value ?? false
          onToggled: checked => root.toastField.set(checked)
        }
      }

      // Refresh Interval Toggle
      NPluginSettingsField {
        field: root.refreshTimerField
        NToggle {
          id: refreshTimerToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.general.refresh.text")
          description: pluginApi.tr("settings.general.refresh.desc")
          checked: root.refreshTimerField?.value ?? false
          onToggled: checked => root.refreshTimerField.set(checked)
        }
      }

      // Refresh Interval
      NPluginSettingsField {
        field: root.refreshIntervalField
        visible: root.refreshTimerField?.value ?? false
        NLabel {
          description: pluginApi.tr("settings.general.interval.desc") + rangeRefreshInterval.value
        }
        NSlider {
          id: rangeRefreshInterval
          objectName: "settings-range-refreshInterval"
          Layout.fillWidth: true
          from: 30
          to: 720
          stepSize: 10
          value: root.refreshIntervalField?.value ?? 120
          onMoved: root.refreshIntervalField.set(value)
        }
      }
    }

    ColumnLayout { // Bar Tab
      spacing: Style.marginM

      NText { // Bar Title
        text: pluginApi.tr("settings.bar.title")
        pointSize: Style.fontSizeXL
        font.weight: Font.Bold
        color: AtmoColor.mOnSurface
      }

      NLabel { // Bar Description
        description: pluginApi.tr("settings.bar.desc")
      }

      NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
      }

      // Noctalia Toggle
      NPluginSettingsField {
        field: root.noctaliaField
        NToggle {
          id: noctaliaToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.bar.noctalia.text")
          description: pluginApi.tr("settings.bar.noctalia.desc")
          checked: root.noctaliaField?.value ?? false
          onToggled: checked => root.noctaliaField.set(checked)
        }
      }

      // Tooltip Toggle
      NPluginSettingsField {
        field: root.tooltipField
        NToggle {
          id: tooltipToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.bar.tooltip.text")
          description: pluginApi.tr("settings.bar.tooltip.desc")
          checked: root.tooltipField?.value ?? false
          onToggled: checked => root.tooltipField.set(checked)
        }
      }

      // Hide On Empty Toggle
      NPluginSettingsField {
        field: root.hideOnEmptyField
        NToggle {
          id: hideOnEmptyToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.bar.hideOnEmpty.text")
          description: pluginApi.tr("settings.bar.hideOnEmpty.desc")
          checked: root.hideOnEmptyField?.value ?? false
          onToggled: checked => root.hideOnEmptyField.set(checked)
        }
      }

      // Bold Text Toggle
      NPluginSettingsField {
        field: root.boldTextField
        NToggle {
          id: boldTextToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.bar.boldCount.text")
          description: pluginApi.tr("settings.bar.boldCount.desc")
          checked: root.boldTextField?.value ?? false
          onToggled: checked => root.boldTextField.set(checked)
        }
      }

      // Use Distro Logo Toggle
      NPluginSettingsField {
        field: root.useDistroLogoField
        NToggle {
          id: distroLogoToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.bar.useDistroLogo.text")
          description: pluginApi.tr("settings.bar.useDistroLogo.desc")
          checked: root.useDistroLogoField?.value ?? false
          onToggled: checked => root.useDistroLogoField.set(checked)
        }
      }

      // Enable Colorization Toggle
      NPluginSettingsField {
        field: root.enableColorizationField
        NToggle {
          id: colorizeToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.bar.enableColorization.text")
          description: pluginApi.tr("settings.bar.enableColorization.desc")
          checked: root.enableColorizationField?.value ?? false
          onToggled: checked => root.enableColorizationField.set(checked)
        }
      }

      // Icon Color (only visible when colorization is enabled)
      NPluginSettingsField {
        field: root.iconColorField
        visible: root.enableColorizationField?.value ?? false
        NColorChoice {
          label: pluginApi.tr("settings.bar.iconColor.text")
          description: pluginApi.tr("settings.bar.iconColor.desc")
          currentKey: root.iconColorField?.value ?? "none"
          onSelected: key => root.iconColorField.set(key)
        }
      }

      // Icon preview and selection
      NPluginSettingsField {
        field: root.iconNameField
        RowLayout {
          spacing: Style.marginM

          NLabel {
            label: pluginApi.tr("settings.bar.iconName.text")
            description: pluginApi.tr("settings.bar.iconName.desc")
          }

          NImageRounded {
            Layout.preferredWidth: Style.fontSizeXL * 2
            Layout.preferredHeight: Style.fontSizeXL * 2
            Layout.alignment: Qt.AlignVCenter
            radius: Math.min(Style.radiusL, Layout.preferredWidth / 2)
            imagePath: root.customIconPathField?.value ?? ""
            visible: (root.customIconPathField?.value ?? "") !== "" && !(root.useDistroLogoField?.value ?? false)
          }

          AtmoIcon {
            Layout.alignment: Qt.AlignVCenter
            icon: root.iconNameField?.value ?? ""
            pointSize: Style.fontSizeXXL * 1.5
            visible: (root.iconNameField?.value ?? "") !== "" && (root.customIconPathField?.value ?? "") === "" && !(root.useDistroLogoField?.value ?? false)
          }
        }
        NButton {
          enabled: !(root.useDistroLogoField?.value ?? false)
          text: pluginApi.tr("settings.bar.iconName.browseLibrary")
          onClicked: iconPicker.open()
        }
      }

      NPluginSettingsField {
        field: root.customIconPathField
        NButton {
          enabled: !(root.useDistroLogoField?.value ?? false)
          text: pluginApi.tr("settings.bar.iconName.browseFile")
          onClicked: imagePicker.openFilePicker()
        }
      }

      AtmoIconPicker {
        id: iconPicker
        initialIcon: root.iconNameField?.value ?? ""
        onIconSelected: iconName => {
          root.iconNameField.set(iconName);
          root.customIconPathField.set("");
        }
      }

      PortalFilePicker {
        id: imagePicker
        title: pluginApi.tr("settings.bar.iconName.selectCustomIcon")
        selectionMode: "files"
        nameFilters: ImageCacheService.basicImageFilters.concat(["*.svg"])
        initialPath: Quickshell.env("HOME")
        onAccepted: paths => {
          if (paths.length > 0) {
            root.customIconPathField.set(paths[0]);
          }
        }
      }
    }

    ColumnLayout { // Panel Tab
      spacing: Style.marginM

      NText { // Panel Title
        text: pluginApi.tr("settings.panel.title")
        pointSize: Style.fontSizeXL
        font.weight: Font.Bold
        color: AtmoColor.mOnSurface
      }

      NLabel { // Panel Description
        description: pluginApi.tr("settings.panel.desc")
      }

      NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
      }

      // Bold New Version Column Toggle
      NPluginSettingsField {
        field: root.boldVerPanelField
        NToggle {
          id: boldVerPanelToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.panel.boldVer.text")
          description: pluginApi.tr("settings.panel.boldVer.desc")
          checked: root.boldVerPanelField?.value ?? false
          onToggled: checked => root.boldVerPanelField.set(checked)
        }
      }

      // Tooltip Toggle
      NPluginSettingsField {
        field: root.panelTooltipField
        NToggle {
          id: panelTooltipToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.panel.tooltip.text")
          description: pluginApi.tr("settings.panel.tooltip.desc")
          checked: root.panelTooltipField?.value ?? false
          onToggled: checked => root.panelTooltipField.set(checked)
        }
      }

      // Context Menu Toggle
      NPluginSettingsField {
        field: root.panelContextField
        NToggle {
          id: panelContextToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.panel.context.text")
          description: pluginApi.tr("settings.panel.context.desc")
          checked: root.panelContextField?.value ?? false
          onToggled: checked => root.panelContextField.set(checked)
        }
      }

      // Close Button Toggle
      NPluginSettingsField {
        field: root.closeButtonField
        NToggle {
          id: closeButtonToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.panel.closeButton.text")
          description: pluginApi.tr("settings.panel.closeButton.desc")
          checked: root.closeButtonField?.value ?? false
          onToggled: checked => root.closeButtonField.set(checked)
        }
      }

      // Close On Settings Toggle
      NPluginSettingsField {
        field: root.closeOnSettingsField
        NToggle {
          id: closeOnSettingsToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.panel.closeOnSettings.text")
          description: pluginApi.tr("settings.panel.closeOnSettings.desc")
          checked: root.closeOnSettingsField?.value ?? false
          onToggled: checked => root.closeOnSettingsField.set(checked)
        }
      }
    }

    ColumnLayout { // Desktop Widget Tab
      spacing: Style.marginM

      NText { // Desktop Widget Title
        text: pluginApi.tr("settings.desktop.title")
        pointSize: Style.fontSizeXL
        font.weight: Font.Bold
        color: AtmoColor.mOnSurface
      }

      NLabel { // Desktop Widget Description
        description: pluginApi.tr("settings.desktop.desc")
      }

      NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
      }

      // Bold New Version Column Toggle
      NPluginSettingsField {
        field: root.boldVerDesktopField
        NToggle {
          id: boldVerDesktopToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.desktop.boldVer.text")
          description: pluginApi.tr("settings.desktop.boldVer.desc")
          checked: root.boldVerDesktopField?.value ?? false
          onToggled: checked => root.boldVerDesktopField.set(checked)
        }
      }

      // Desktop Hover Tip Toggle
      NPluginSettingsField {
        field: root.hoverTipField
        NToggle {
          id: hoverTipToggle
          Layout.fillWidth: true
          label: pluginApi.tr("settings.desktop.hoverTip.text")
          description: pluginApi.tr("settings.desktop.hoverTip.desc")
          checked: root.hoverTipField?.value ?? false
          onToggled: checked => root.hoverTipField.set(checked)
        }
      }
    }
  }

  // Completion observer only; native publication belongs to the session.
  function saveSettings() {
    pluginApi?.saveSettings();
  }
}
