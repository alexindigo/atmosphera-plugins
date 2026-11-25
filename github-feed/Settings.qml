import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var usernameField: pluginApi?.field("username") ?? null
  readonly property var tokenField: pluginApi?.field("token") ?? null
  readonly property var githubUrlField: pluginApi?.field("githubUrl") ?? null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var maxEventsField: pluginApi?.field("maxEvents") ?? null
  readonly property var showStarsField: pluginApi?.field("showStars") ?? null
  readonly property var showForksField: pluginApi?.field("showForks") ?? null
  readonly property var showPRsField: pluginApi?.field("showPRs") ?? null
  readonly property var showRepoCreationsField: pluginApi?.field("showRepoCreations") ?? null
  readonly property var showMyRepoStarsField: pluginApi?.field("showMyRepoStars") ?? null
  readonly property var showMyRepoForksField: pluginApi?.field("showMyRepoForks") ?? null
  readonly property var showNotificationBadgeField: pluginApi?.field("showNotificationBadge") ?? null
  readonly property var colorizationEnabledField: pluginApi?.field("colorizationEnabled") ?? null
  readonly property var colorizationIconField: pluginApi?.field("colorizationIcon") ?? null
  readonly property var colorizationBadgeField: pluginApi?.field("colorizationBadge") ?? null
  readonly property var colorizationBadgeTextField: pluginApi?.field("colorizationBadgeText") ?? null
  readonly property var defaultTabField: pluginApi?.field("defaultTab") ?? null
  readonly property var openInBrowserField: pluginApi?.field("openInBrowser") ?? null
  readonly property var enableSystemNotificationsField: pluginApi?.field("enableSystemNotifications") ?? null
  readonly property var notifyGitHubNotificationsField: pluginApi?.field("notifyGitHubNotifications") ?? null
  readonly property var notifyStarsField: pluginApi?.field("notifyStars") ?? null
  readonly property var notifyForksField: pluginApi?.field("notifyForks") ?? null
  readonly property var notifyPRsField: pluginApi?.field("notifyPRs") ?? null
  readonly property var notifyRepoCreationsField: pluginApi?.field("notifyRepoCreations") ?? null
  readonly property var notifyMyRepoStarsField: pluginApi?.field("notifyMyRepoStars") ?? null
  readonly property var notifyMyRepoForksField: pluginApi?.field("notifyMyRepoForks") ?? null

  readonly property string editUsername: root.usernameField?.value || ""
  readonly property string editToken: root.tokenField?.value || ""
  readonly property string editGithubUrl: root.githubUrlField?.value || ""
  readonly property int editRefreshInterval: root.refreshIntervalField?.value || 1800
  readonly property int editMaxEvents: root.maxEventsField?.value || 50
  readonly property bool editShowStars: root.showStarsField?.value ?? true
  readonly property bool editShowForks: root.showForksField?.value ?? true
  readonly property bool editShowPRs: root.showPRsField?.value ?? true
  readonly property bool editShowRepoCreations: root.showRepoCreationsField?.value ?? true
  readonly property bool editShowMyRepoStars: root.showMyRepoStarsField?.value ?? true
  readonly property bool editShowMyRepoForks: root.showMyRepoForksField?.value ?? true
  readonly property bool editShowNotificationBadge: root.showNotificationBadgeField?.value ?? true
  readonly property bool editColorizationEnabled: root.colorizationEnabledField?.value ?? false
  readonly property string editColorizationIcon: root.colorizationIconField?.value || "Primary"
  readonly property string editColorizationBadge: root.colorizationBadgeField?.value || "Primary"
  readonly property string editColorizationBadgeText: root.colorizationBadgeTextField?.value || "Primary"
  readonly property int editDefaultTab: root.defaultTabField?.value ?? 0
  readonly property bool editOpenInBrowser: root.openInBrowserField?.value ?? true
  readonly property bool editEnableSystemNotifications: root.enableSystemNotificationsField?.value ?? false
  readonly property bool editNotifyGitHubNotifications: root.notifyGitHubNotificationsField?.value ?? true
  readonly property bool editNotifyStars: root.notifyStarsField?.value ?? true
  readonly property bool editNotifyForks: root.notifyForksField?.value ?? true
  readonly property bool editNotifyPRs: root.notifyPRsField?.value ?? true
  readonly property bool editNotifyRepoCreations: root.notifyRepoCreationsField?.value ?? true
  readonly property bool editNotifyMyRepoStars: root.notifyMyRepoStarsField?.value ?? true
  readonly property bool editNotifyMyRepoForks: root.notifyMyRepoForksField?.value ?? true

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
    wrapMode: Text.WordWrap
  }

  NLabel {
    label: "Account"
  }

  NPluginSettingsField {
    field: root.usernameField
    NTextInput {
      Layout.fillWidth: true
      label: "GitHub Username"
      description: "Your GitHub username to fetch activity feed"
      placeholderText: "e.g., linuxmobile"
      text: root.editUsername
      onEditCommitted: root.usernameField.set(text.trim())
    }
  }

  NPluginSettingsField {
    field: root.tokenField
    NTextInput {
      Layout.fillWidth: true
      label: "Personal Access Token (Required)"
      description: "Required for GraphQL API. Create at github.com/settings/tokens with 'read:user' scope"
      placeholderText: "ghp_xxxxxxxxxxxx"
      text: root.editToken
      onEditCommitted: root.tokenField.set(text.trim())
    }
  }

  NPluginSettingsField {
    field: root.githubUrlField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.githubUrl.label")
      description: pluginApi?.tr("settings.githubUrl.description")
      placeholderText: "https://github.mycompany.com"
      text: root.editGithubUrl
      onEditCommitted: root.githubUrlField.set(text.trim())
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NLabel {
    label: "Refresh Settings"
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: "Refresh Interval"
      description: {
        var minutes = Math.floor(root.editRefreshInterval / 60);
        if (minutes < 60) {
          return "Check for new events every " + minutes + " minutes";
        } else {
          var hours = Math.floor(minutes / 60);
          var remainingMins = minutes % 60;
          if (remainingMins === 0) {
            return "Check for new events every " + hours + " hour" + (hours > 1 ? "s" : "");
          }
          return "Check for new events every " + hours + "h " + remainingMins + "m";
        }
      }
    }

    NPluginSettingsField {
      field: root.refreshIntervalField
      NSlider {
        id: rangeEditRefreshInterval
        objectName: "settings-range-editRefreshInterval"
        Layout.fillWidth: true
        from: 300
        to: 7200
        stepSize: 300
        value: root.editRefreshInterval
        onMoved: root.refreshIntervalField.set(value)
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: "Maximum Events"
      description: "Show up to " + root.editMaxEvents + " events in the feed"
    }

    NPluginSettingsField {
      field: root.maxEventsField
      NSlider {
        id: rangeEditMaxEvents
        objectName: "settings-range-editMaxEvents"
        Layout.fillWidth: true
        from: 10
        to: 100
        stepSize: 10
        value: root.editMaxEvents
        onMoved: root.maxEventsField.set(value)
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NLabel {
    label: "Activity from Followed Users"
    description: "Events from people you follow"
  }

  GridLayout {
    Layout.fillWidth: true
    columns: 2
    columnSpacing: Style.marginM
    rowSpacing: Style.marginS

    NPluginSettingsField {
      field: root.showStarsField
      NToggle {
        Layout.fillWidth: true
        label: "Stars"
        description: "Repos they starred"
        checked: root.editShowStars
        onToggled: checked => {
          root.showStarsField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.showForksField
      NToggle {
        Layout.fillWidth: true
        label: "Forks"
        description: "Repos they forked"
        checked: root.editShowForks
        onToggled: checked => {
          root.showForksField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.showPRsField
      NToggle {
        Layout.fillWidth: true
        label: "Pull Requests"
        description: "PRs they opened"
        checked: root.editShowPRs
        onToggled: checked => {
          root.showPRsField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.showRepoCreationsField
      NToggle {
        Layout.fillWidth: true
        label: "Repo Creations"
        description: "Repos they created"
        checked: root.editShowRepoCreations
        onToggled: checked => {
          root.showRepoCreationsField.set(checked);
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NLabel {
    label: "Activity on Your Repos"
    description: "Events on repositories you own"
  }

  GridLayout {
    Layout.fillWidth: true
    columns: 2
    columnSpacing: Style.marginM
    rowSpacing: Style.marginS

    NPluginSettingsField {
      field: root.showMyRepoStarsField
      NToggle {
        Layout.fillWidth: true
        label: "Stars on Your Repos"
        description: "When someone stars your repo"
        checked: root.editShowMyRepoStars
        onToggled: checked => {
          root.showMyRepoStarsField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.showMyRepoForksField
      NToggle {
        Layout.fillWidth: true
        label: "Forks of Your Repos"
        description: "When someone forks your repo"
        checked: root.editShowMyRepoForks
        onToggled: checked => {
          root.showMyRepoForksField.set(checked);
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NLabel {
    label: "Behavior"
  }

  NPluginSettingsField {
    field: root.defaultTabField
    NComboBox {
      Layout.fillWidth: true
      label: "Default Tab"
      description: "Choose which tab to show when opening the panel"
      model: [
        {
          key: "0",
          name: "Activity"
        },
        {
          key: "1",
          name: "Notifications"
        }
      ]
      currentKey: root.editDefaultTab.toString()
      onSelected: key => root.defaultTabField.set(parseInt(key))
    }
  }

  NPluginSettingsField {
    field: root.openInBrowserField
    NToggle {
      Layout.fillWidth: true
      label: "Open in Browser"
      description: "Click on events to open them in your default browser"
      checked: root.editOpenInBrowser
      onToggled: checked => {
        root.openInBrowserField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.showNotificationBadgeField
    NToggle {
      Layout.fillWidth: true
      label: "Show Notification Badge"
      description: "Show a count of unread notifications on the bar icon"
      checked: root.editShowNotificationBadge
      onToggled: checked => {
        root.showNotificationBadgeField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.colorizationEnabledField
    NToggle {
      Layout.fillWidth: true
      label: "Enable colorization"
      description: "Enable colorization for the icon and badge, applying theme colors"
      checked: root.editColorizationEnabled
      onToggled: checked => {
        root.colorizationEnabledField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.colorizationIconField
    visible: root.editColorizationEnabled
    NComboBox {
      Layout.fillWidth: true
      label: "Icon Color"
      description: "Apply theme colors to the GitHub icon"
      model: [
        {
          key: "None",
          name: "None"
        },
        {
          key: "Primary",
          name: "Primary"
        },
        {
          key: "Secondary",
          name: "Secondary"
        },
        {
          key: "Tertiary",
          name: "Tertiary"
        },
        {
          key: "Error",
          name: "Error"
        }
      ]
      currentKey: root.editColorizationIcon
      onSelected: key => root.colorizationIconField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.colorizationBadgeField
    visible: root.editColorizationEnabled
    NComboBox {
      Layout.fillWidth: true
      label: "Badge Color"
      description: "Apply theme colors to the badge background"
      model: [
        {
          key: "None",
          name: "None"
        },
        {
          key: "Primary",
          name: "Primary"
        },
        {
          key: "Secondary",
          name: "Secondary"
        },
        {
          key: "Tertiary",
          name: "Tertiary"
        },
        {
          key: "Error",
          name: "Error"
        }
      ]
      currentKey: root.editColorizationBadge
      onSelected: key => root.colorizationBadgeField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.colorizationBadgeTextField
    visible: root.editColorizationEnabled
    NComboBox {
      Layout.fillWidth: true
      label: "Badge Text Color"
      description: "Apply theme colors to the badge text"
      model: [
        {
          key: "None",
          name: "None"
        },
        {
          key: "Primary",
          name: "Primary"
        },
        {
          key: "Secondary",
          name: "Secondary"
        },
        {
          key: "Tertiary",
          name: "Tertiary"
        },
        {
          key: "Error",
          name: "Error"
        }
      ]
      currentKey: root.editColorizationBadgeText
      onSelected: key => root.colorizationBadgeTextField.set(key)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  NLabel {
    label: "System Notifications"
    description: "Get notified when new events occur"
  }

  NPluginSettingsField {
    field: root.enableSystemNotificationsField
    NToggle {
      Layout.fillWidth: true
      label: "Enable System Notifications"
      description: "Send desktop notifications for new events"
      checked: root.editEnableSystemNotifications
      onToggled: checked => {
        root.enableSystemNotificationsField.set(checked);
      }
    }
  }

  GridLayout {
    Layout.fillWidth: true
    visible: root.editEnableSystemNotifications
    columns: 2
    columnSpacing: Style.marginM
    rowSpacing: Style.marginS

    NPluginSettingsField {
      field: root.notifyGitHubNotificationsField
      NToggle {
        Layout.fillWidth: true
        label: "GitHub Notifications"
        description: "New notifications in your inbox"
        checked: root.editNotifyGitHubNotifications
        onToggled: checked => {
          root.notifyGitHubNotificationsField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.notifyStarsField
      NToggle {
        Layout.fillWidth: true
        label: "Stars"
        description: "When someone you follow stars a repo"
        checked: root.editNotifyStars
        onToggled: checked => {
          root.notifyStarsField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.notifyForksField
      NToggle {
        Layout.fillWidth: true
        label: "Forks"
        description: "When someone you follow forks a repo"
        checked: root.editNotifyForks
        onToggled: checked => {
          root.notifyForksField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.notifyPRsField
      NToggle {
        Layout.fillWidth: true
        label: "Pull Requests"
        description: "When someone you follow opens/merges a PR"
        checked: root.editNotifyPRs
        onToggled: checked => {
          root.notifyPRsField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.notifyRepoCreationsField
      NToggle {
        Layout.fillWidth: true
        label: "Repo Creations"
        description: "When someone you follow creates a repo"
        checked: root.editNotifyRepoCreations
        onToggled: checked => {
          root.notifyRepoCreationsField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.notifyMyRepoStarsField
      NToggle {
        Layout.fillWidth: true
        label: "Stars (My Repos)"
        description: "When someone stars one of your repos"
        checked: root.editNotifyMyRepoStars
        onToggled: checked => {
          root.notifyMyRepoStarsField.set(checked);
        }
      }
    }

    NPluginSettingsField {
      field: root.notifyMyRepoForksField
      NToggle {
        Layout.fillWidth: true
        label: "Forks (My Repos)"
        description: "When someone forks one of your repos"
        checked: root.editNotifyMyRepoForks
        onToggled: checked => {
          root.notifyMyRepoForksField.set(checked);
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
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
          text: "IPC Commands"
          pointSize: Style.fontSizeS
          font.weight: Font.Medium
          color: AtmoColor.mOnSurface
        }
      }

      NText {
        Layout.fillWidth: true
        text: "Refresh: qs -c noctalia-shell ipc call plugin:github-feed refresh"
        pointSize: Style.fontSizeXS
        font.family: Settings.data.ui.fontFixed
        color: AtmoColor.mOnSurfaceVariant
        wrapMode: Text.WrapAnywhere
      }

      NText {
        Layout.fillWidth: true
        text: "Toggle panel: qs -c noctalia-shell ipc call plugin:github-feed toggle"
        pointSize: Style.fontSizeXS
        font.family: Settings.data.ui.fontFixed
        color: AtmoColor.mOnSurfaceVariant
        wrapMode: Text.WrapAnywhere
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("GitHubFeed", "Cannot save: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current") {
        Logger.i("GitHubFeed", "Settings saved");
        ToastService.showNotice("GitHub Feed settings saved");
      }
    });
  }

  Component.onCompleted: Logger.i("GitHubFeed", "Settings UI loaded")
}
