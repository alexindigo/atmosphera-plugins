import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var habiticaUserIdField: pluginApi?.field("habiticaUserId") ?? null
  readonly property var habiticaApiTokenField: pluginApi?.field("habiticaApiToken") ?? null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var maxDailiesField: pluginApi?.field("maxDailies") ?? null
  readonly property var maxTodosField: pluginApi?.field("maxTodos") ?? null
  readonly property var maxHabitsField: pluginApi?.field("maxHabits") ?? null
  readonly property var showHabitsField: pluginApi?.field("showHabits") ?? null
  readonly property var showChecklistItemsField: pluginApi?.field("showChecklistItems") ?? null
  readonly property var enableTagFilterField: pluginApi?.field("enableTagFilter") ?? null
  readonly property var selectedTagIdField: pluginApi?.field("selectedTagId") ?? null
  readonly property var showNotificationBadgeField: pluginApi?.field("showNotificationBadge") ?? null
  readonly property var colorizationEnabledField: pluginApi?.field("colorizationEnabled") ?? null
  readonly property var colorizationIconField: pluginApi?.field("colorizationIcon") ?? null
  readonly property var colorizationBadgeField: pluginApi?.field("colorizationBadge") ?? null
  readonly property var colorizationBadgeTextField: pluginApi?.field("colorizationBadgeText") ?? null

  readonly property string editHabiticaUserId: root.habiticaUserIdField?.value ?? ""
  readonly property string editHabiticaApiToken: root.habiticaApiTokenField?.value ?? ""
  readonly property int editRefreshInterval: root.refreshIntervalField?.value ?? 300
  readonly property int editMaxDailies: root.maxDailiesField?.value ?? 8
  readonly property int editMaxTodos: root.maxTodosField?.value ?? 8
  readonly property int editMaxHabits: root.maxHabitsField?.value ?? 8
  readonly property bool editShowHabits: root.showHabitsField?.value ?? false
  readonly property bool editShowChecklistItems: root.showChecklistItemsField?.value ?? false
  readonly property bool editEnableTagFilter: root.enableTagFilterField?.value ?? false
  readonly property string editSelectedTagId: root.selectedTagIdField?.value ?? ""
  readonly property bool editShowNotificationBadge: root.showNotificationBadgeField?.value ?? true
  readonly property bool editColorizationEnabled: root.colorizationEnabledField?.value ?? false
  readonly property string editColorizationIcon: root.colorizationIconField?.value ?? "Primary"
  readonly property string editColorizationBadge: root.colorizationBadgeField?.value ?? "Error"
  readonly property string editColorizationBadgeText: root.colorizationBadgeTextField?.value ?? "Primary"

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  spacing: Style.marginM

  NLabel {
    visible: root.pluginApi?.scopeKind === "instance"
    label: root.pluginApi?.tr("settings.shared-effect-label")
    description: root.pluginApi?.tr("settings.shared-effect")
  }

  NLabel {
    label: pluginApi?.tr("settings.account.label")
    description: pluginApi?.tr("settings.account.description")
  }

  NPluginSettingsField {
    field: root.habiticaUserIdField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.userId.label")
      description: pluginApi?.tr("settings.userId.description")
      placeholderText: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      text: root.editHabiticaUserId
      onEditCommitted: root.habiticaUserIdField.set(text.trim())
    }
  }

  NPluginSettingsField {
    field: root.habiticaApiTokenField
    NTextInput {
      id: apiTokenInput
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.apiToken.label")
      description: pluginApi?.tr("settings.apiToken.description")
      placeholderText: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      text: root.editHabiticaApiToken
      onEditCommitted: root.habiticaApiTokenField.set(text.trim())

      Component.onCompleted: {
        if (apiTokenInput.inputItem) {
          apiTokenInput.inputItem.echoMode = TextInput.Password;
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NLabel {
    label: pluginApi?.tr("settings.basicUi.label")
    description: pluginApi?.tr("settings.basicUi.description")
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.refreshInterval.label")
      description: pluginApi?.tr("settings.refreshInterval.descriptionPrefix") + Math.floor(root.editRefreshInterval / 60) + pluginApi?.tr("settings.refreshInterval.descriptionSuffix")
    }

    NPluginSettingsField {
      field: root.refreshIntervalField
      NSlider {
        id: rangeEditRefreshInterval
        objectName: "settings-range-editRefreshInterval"
        Layout.fillWidth: true
        from: 60
        to: 3600
        stepSize: 60
        value: root.editRefreshInterval
        onMoved: root.refreshIntervalField.set(value)
      }
    }
  }

  GridLayout {
    Layout.fillWidth: true
    columns: 2
    columnSpacing: Style.marginM
    rowSpacing: Style.marginS

    ColumnLayout {
      Layout.fillWidth: true

      NLabel {
        label: pluginApi?.tr("settings.dailies.label")
        description: pluginApi?.tr("settings.dailies.descriptionPrefix") + root.editMaxDailies
      }

      NPluginSettingsField {
        field: root.maxDailiesField
        NSlider {
          id: rangeEditMaxDailies
          objectName: "settings-range-editMaxDailies"
          Layout.fillWidth: true
          from: 1
          to: 25
          stepSize: 1
          value: root.editMaxDailies
          onMoved: root.maxDailiesField.set(value)
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true

      NLabel {
        label: pluginApi?.tr("settings.todos.label")
        description: pluginApi?.tr("settings.todos.descriptionPrefix") + root.editMaxTodos
      }

      NPluginSettingsField {
        field: root.maxTodosField
        NSlider {
          id: rangeEditMaxTodos
          objectName: "settings-range-editMaxTodos"
          Layout.fillWidth: true
          from: 1
          to: 25
          stepSize: 1
          value: root.editMaxTodos
          onMoved: root.maxTodosField.set(value)
        }
      }
    }
  }

  NPluginSettingsField {
    field: root.showNotificationBadgeField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.notificationBadge.label")
      description: pluginApi?.tr("settings.notificationBadge.description")
      checked: root.editShowNotificationBadge
      onToggled: checked => root.showNotificationBadgeField.set(checked)
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NLabel {
    label: pluginApi?.tr("settings.advancedUi.label")
    description: pluginApi?.tr("settings.advancedUi.description")
  }

  NPluginSettingsField {
    field: root.showHabitsField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.showHabits.label")
      description: pluginApi?.tr("settings.showHabits.description")
      checked: root.editShowHabits
      onToggled: checked => root.showHabitsField.set(checked)
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    visible: root.editShowHabits

    NLabel {
      label: pluginApi?.tr("settings.habits.label")
      description: pluginApi?.tr("settings.habits.descriptionPrefix") + root.editMaxHabits
    }

    NPluginSettingsField {
      field: root.maxHabitsField
      NSlider {
        id: rangeEditMaxHabits
        objectName: "settings-range-editMaxHabits"
        Layout.fillWidth: true
        from: 1
        to: 25
        stepSize: 1
        value: root.editMaxHabits
        onMoved: root.maxHabitsField.set(value)
      }
    }
  }

  NPluginSettingsField {
    field: root.showChecklistItemsField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.checklist.label")
      description: pluginApi?.tr("settings.checklist.description")
      checked: root.editShowChecklistItems
      onToggled: checked => root.showChecklistItemsField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.enableTagFilterField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.tagFilter.label")
      description: pluginApi?.tr("settings.tagFilter.description")
      checked: root.editEnableTagFilter
      onToggled: checked => root.enableTagFilterField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.selectedTagIdField
    visible: root.editEnableTagFilter
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.selectedTag.label")
      description: pluginApi?.tr("settings.selectedTag.description")
      placeholderText: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      text: root.editSelectedTagId
      onEditCommitted: root.selectedTagIdField.set(text.trim())
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NLabel {
    label: pluginApi?.tr("settings.colors.label")
  }

  NPluginSettingsField {
    field: root.colorizationEnabledField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.colorization.label")
      description: pluginApi?.tr("settings.colorization.description")
      checked: root.editColorizationEnabled
      onToggled: checked => root.colorizationEnabledField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.colorizationIconField
    visible: root.editColorizationEnabled
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.iconColor.label")
      model: colorModel
      currentKey: root.editColorizationIcon
      onSelected: key => root.colorizationIconField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.colorizationBadgeField
    visible: root.editColorizationEnabled
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.badgeColor.label")
      model: colorModel
      currentKey: root.editColorizationBadge
      onSelected: key => root.colorizationBadgeField.set(key)
    }
  }

  NPluginSettingsField {
    field: root.colorizationBadgeTextField
    visible: root.editColorizationEnabled
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.badgeTextColor.label")
      model: colorModel
      currentKey: root.editColorizationBadgeText
      onSelected: key => root.colorizationBadgeTextField.set(key)
    }
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: infoColumn.implicitHeight + Style.marginM * 2
    color: AtmoColor.mSurfaceVariant
    radius: Style.radiusM

    ColumnLayout {
      id: infoColumn
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginS

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.ipc.title")
        pointSize: Style.fontSizeS
        font.weight: Font.Bold
        color: AtmoColor.mOnSurface
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.ipc.refresh")
        pointSize: Style.fontSizeXS
        font.family: Settings.data.ui.fontFixed
        color: AtmoColor.mOnSurfaceVariant
        wrapMode: Text.WrapAnywhere
      }
    }
  }

  property var colorModel: [
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

  function saveSettings() {
    if (!pluginApi)
      return;

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current") {
        Logger.i("Habitica", "Settings saved");
        ToastService.showNotice(pluginApi?.tr("settings.saved"));
      }
    });
  }
}
