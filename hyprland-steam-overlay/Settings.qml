import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  readonly property var autoLaunchSteamField: pluginApi?.field("autoLaunchSteam") ?? null
  readonly property var useCustomLayoutField: pluginApi?.field("useCustomLayout") ?? null
  readonly property var enableChatNotificationsField: pluginApi?.field("enableChatNotifications") ?? null
  readonly property var friendsWidthPercentField: pluginApi?.field("friendsWidthPercent") ?? null
  readonly property var mainWidthPercentField: pluginApi?.field("mainWidthPercent") ?? null
  readonly property var chatWidthPercentField: pluginApi?.field("chatWidthPercent") ?? null
  readonly property var gapSizeField: pluginApi?.field("gapSize") ?? null
  readonly property var topMarginPercentField: pluginApi?.field("topMarginPercent") ?? null
  readonly property var windowHeightPercentField: pluginApi?.field("windowHeightPercent") ?? null

  // Shortcut to settings and defaults
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Local state - track changes before saving
  readonly property bool valueAutoLaunchSteam: root.autoLaunchSteamField?.value ?? true
  readonly property bool valueUseCustomLayout: root.useCustomLayoutField?.value ?? false
  readonly property bool valueEnableChatNotifications: root.enableChatNotificationsField?.value ?? true
  readonly property int valueFriendsWidth: root.friendsWidthPercentField?.value ?? 10
  readonly property int valueMainWidth: root.mainWidthPercentField?.value ?? 60
  readonly property int valueChatWidth: root.chatWidthPercentField?.value ?? 25
  readonly property int valueGapSize: root.gapSizeField?.value ?? 10
  readonly property real valueTopMargin: root.topMarginPercentField?.value ?? 2.5
  readonly property real valueWindowHeight: root.windowHeightPercentField?.value ?? 95

  spacing: Style.marginM

  Component.onCompleted: {
    Logger.i("SteamOverlay", "Settings UI loaded");
  }

  NLabel {
    label: "Steam Overlay Settings"
    description: "Configure the Steam overlay window layout and behavior"
  }

  // Auto-launch Steam toggle
  NPluginSettingsField {
    field: root.autoLaunchSteamField
    NCheckbox {
      Layout.fillWidth: true
      label: "Auto-launch Steam"
      description: "Automatically launch Steam when toggling overlay if it's not running"
      checked: root.valueAutoLaunchSteam
      onToggled: checked => root.autoLaunchSteamField.set(checked)
    }
  }

  // Chat notifications toggle
  NPluginSettingsField {
    field: root.enableChatNotificationsField
    NCheckbox {
      Layout.fillWidth: true
      label: "Chat Notifications"
      description: "Show notification indicator on bar icon when new Steam chat messages arrive"
      checked: root.valueEnableChatNotifications
      onToggled: checked => root.enableChatNotificationsField.set(checked)
    }
  }

  // Custom Hyprland layout toggle
  NPluginSettingsField {
    field: root.useCustomLayoutField
    NCheckbox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.custom-layout-label")
      description: pluginApi?.tr("settings.custom-layout-description")
      checked: root.valueUseCustomLayout
      onToggled: checked => root.useCustomLayoutField.set(checked)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  // Window Layout Section
  NLabel {
    label: "Window Layout (Percentages)"
    description: "Adjust the width distribution of the three main Steam windows"
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: "Friends List Width: " + root.valueFriendsWidth + "%"
      description: "Width of the Friends List window"
    }

    NPluginSettingsField {
      field: root.friendsWidthPercentField
      NSlider {
        id: rangeValueFriendsWidth
        objectName: "settings-range-valueFriendsWidth"
        Layout.fillWidth: true
        from: 5
        to: 30
        value: root.valueFriendsWidth
        stepSize: 1
        onMoved: root.friendsWidthPercentField.set(value)
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: "Main Window Width: " + root.valueMainWidth + "%"
      description: "Width of the main Steam window"
    }

    NPluginSettingsField {
      field: root.mainWidthPercentField
      NSlider {
        id: rangeValueMainWidth
        objectName: "settings-range-valueMainWidth"
        Layout.fillWidth: true
        from: 40
        to: 80
        value: root.valueMainWidth
        stepSize: 1
        onMoved: root.mainWidthPercentField.set(value)
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: "Chat Window Width: " + root.valueChatWidth + "%"
      description: "Width of the chat window"
    }

    NPluginSettingsField {
      field: root.chatWidthPercentField
      NSlider {
        id: rangeValueChatWidth
        objectName: "settings-range-valueChatWidth"
        Layout.fillWidth: true
        from: 10
        to: 40
        value: root.valueChatWidth
        stepSize: 1
        onMoved: root.chatWidthPercentField.set(value)
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  // Spacing Section
  NLabel {
    label: "Spacing & Margins"
    description: "Adjust gaps between windows and screen margins"
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: "Gap Size: " + root.valueGapSize + "px"
      description: "Space between windows in pixels"
    }

    NPluginSettingsField {
      field: root.gapSizeField
      NSlider {
        id: rangeValueGapSize
        objectName: "settings-range-valueGapSize"
        Layout.fillWidth: true
        from: 0
        to: 50
        value: root.valueGapSize
        stepSize: 5
        onMoved: root.gapSizeField.set(value)
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: "Top Margin: " + root.valueTopMargin.toFixed(1) + "%"
      description: "Distance from top of screen"
    }

    NPluginSettingsField {
      field: root.topMarginPercentField
      NSlider {
        id: rangeValueTopMargin
        objectName: "settings-range-valueTopMargin"
        Layout.fillWidth: true
        from: 0
        to: 10
        value: root.valueTopMargin
        stepSize: 0.5
        onMoved: root.topMarginPercentField.set(value)
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: "Window Height: " + root.valueWindowHeight + "%"
      description: "Height of overlay windows"
    }

    NPluginSettingsField {
      field: root.windowHeightPercentField
      NSlider {
        id: rangeValueWindowHeight
        objectName: "settings-range-valueWindowHeight"
        Layout.fillWidth: true
        from: 70
        to: 100
        value: root.valueWindowHeight
        stepSize: 1
        onMoved: root.windowHeightPercentField.set(value)
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  // Info text
  NLabel {
    label: "💡 Tip"
    description: "After changing settings, toggle the overlay off and on (Super+S twice) to apply the new layout."
  }

  Item {
    Layout.fillHeight: true
  }

  // This function is called by the dialog to save settings
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("SteamOverlay", "Cannot save settings: pluginApi is null");
      return;
    }

    // Update the plugin settings object

    // Save to disk
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("SteamOverlay", "Settings saved successfully");
    });
  }
}
