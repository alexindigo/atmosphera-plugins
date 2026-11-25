import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var saveWidgetsField: pluginApi?.field("saveWidgets") ?? null
  readonly property var loadWidgetsField: pluginApi?.field("loadWidgets") ?? null

  readonly property bool saveWidgets: root.saveWidgetsField?.value ?? true
  readonly property bool loadWidgets: root.loadWidgetsField?.value ?? true
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  // Saved snapshots are shared content: only the plugin scope may manage them,
  // through the explicit content capability; instance configuration cannot.
  readonly property bool sharedContent: pluginApi?.scopeKind === "plugin"
  readonly property var wallpaperMonitorWidgets: pluginApi?.pluginSettings?.monitorWidgets ?? ({})
  function setSnapshots(next) {
    return root.sharedContent && !!root.pluginApi.contentField("monitorWidgets")?.set(next);
  }

  NPluginSettingsField {
    field: root.saveWidgetsField
    NToggle {
      label: pluginApi?.tr("settings.save_widgets.label")
      description: pluginApi?.tr("settings.save_widgets.description")
      checked: root.saveWidgets
      onToggled: checked => root.saveWidgetsField.set(checked)
      defaultValue: true
    }
  }

  NPluginSettingsField {
    field: root.loadWidgetsField
    NToggle {
      label: pluginApi?.tr("settings.load_widgets.label")
      description: pluginApi?.tr("settings.load_widgets.description")
      checked: root.loadWidgets
      onToggled: checked => root.loadWidgetsField.set(checked)
      defaultValue: true
    }
  }

  NText {
    Layout.fillWidth: true
    visible: !root.sharedContent
    text: pluginApi?.tr("settings.list.shared")
    color: AtmoColor.mOnSurfaceVariant
    wrapMode: Text.WordWrap
  }

  NBox {
    Layout.fillWidth: true
    Layout.preferredHeight: listView.implicitHeight

    NListView {
      id: listView
      anchors.fill: parent
      anchors.margins: Style.marginS
      model: Object.keys(root.wallpaperMonitorWidgets)

      spacing: Style.marginL

      delegate: RowLayout {
        id: wallpaperField
        required property var modelData

        width: listView.availableWidth

        // Remove the whole path first and also remove the extension.
        property string fileName: modelData.split('/').pop().split('.').slice(0, -1).join('.')

        NText {
          text: wallpaperField.fileName
        }

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true
        }

        AtmoIconButton {
          icon: "x"
          enabled: root.sharedContent
          tooltipText: root.pluginApi?.tr("settings.list.remove")

          onClicked: {
            if (!root.pluginApi) {
              Logger.e("SavedDesktopWidgets", "Could not save, pluginApi is null");
              return;
            }

            let monitorWidgets = JSON.parse(JSON.stringify(root.wallpaperMonitorWidgets));

            delete monitorWidgets[wallpaperField.modelData];

            root.setSnapshots(monitorWidgets);
          }
        }
      }
    }
  }

  NButton {
    text: pluginApi?.tr("settings.tool_row.nuke.text")
    icon: "x"
    tooltipText: pluginApi?.tr("settings.tool_row.nuke.tooltip")
    backgroundColor: AtmoColor.mError
    enabled: root.sharedContent

    onClicked: {
      if (!root.pluginApi) {
        Logger.e("SavedDesktopWidgets", "Could not save, pluginApi is null");
        return;
      }

      root.setSnapshots({});
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("SavedDesktopWidgets", "Cannot save: pluginApi is null");
      return;
    }

    pluginApi.saveSettings();
  }
}
