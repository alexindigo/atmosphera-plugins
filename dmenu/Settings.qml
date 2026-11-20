import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var resultFileField: pluginApi?.field("resultFile") ?? null
  readonly property var showToastOnSelectField: pluginApi?.field("showToastOnSelect") ?? null
  readonly property var maxResultsField: pluginApi?.field("maxResults") ?? null
  readonly property var panelPositionField: pluginApi?.field("panelPosition") ?? null
  readonly property var showMatchCountField: pluginApi?.field("showMatchCount") ?? null
  readonly property var showFooterField: pluginApi?.field("showFooter") ?? null

  // ── Edit state ──
  readonly property string editResultFile: root.resultFileField?.value ?? "/tmp/noctalia-dmenu-result"
  readonly property bool editShowToast: root.showToastOnSelectField?.value ?? false
  readonly property int editMaxResults: root.maxResultsField?.value || 200
  readonly property string editPanelPosition: root.panelPositionField?.value || "follow_launcher"
  readonly property bool editShowMatchCount: root.showMatchCountField?.value ?? true
  readonly property bool editShowFooter: root.showFooterField?.value ?? true
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  // Position options
  readonly property var positionOptions: [
    {
      key: "follow_launcher",
      name: root.pluginApi?.tr("settings.positionFollowLauncher")
    },
    {
      key: "center",
      name: root.pluginApi?.tr("settings.positionCenter")
    },
    {
      key: "top_center",
      name: root.pluginApi?.tr("settings.positionTopCenter")
    },
    {
      key: "bottom_center",
      name: root.pluginApi?.tr("settings.positionBottomCenter")
    },
    {
      key: "top_left",
      name: root.pluginApi?.tr("settings.positionTopLeft")
    },
    {
      key: "top_right",
      name: root.pluginApi?.tr("settings.positionTopRight")
    },
    {
      key: "bottom_left",
      name: root.pluginApi?.tr("settings.positionBottomLeft")
    },
    {
      key: "bottom_right",
      name: root.pluginApi?.tr("settings.positionBottomRight")
    },
    {
      key: "center_left",
      name: root.pluginApi?.tr("settings.positionCenterLeft")
    },
    {
      key: "center_right",
      name: root.pluginApi?.tr("settings.positionCenterRight")
    }
  ]

  spacing: Style.marginM

  // ═══════════════════════════════════════
  // Panel position
  // ═══════════════════════════════════════

  NPluginSettingsField {
    field: root.panelPositionField
    NComboBox {
      label: root.pluginApi?.tr("settings.panelPosition")
      description: root.pluginApi?.tr("settings.panelPositionDesc")
      Layout.fillWidth: true
      model: root.positionOptions
      currentKey: root.editPanelPosition
      onSelected: function (key) {
        root.panelPositionField.set(key);
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  // ═══════════════════════════════════════
  // Display
  // ═══════════════════════════════════════

  NLabel {
    label: root.pluginApi?.tr("settings.display")
  }

  NPluginSettingsField {
    field: root.showMatchCountField
    NToggle {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.showMatchCount")
      description: root.pluginApi?.tr("settings.showMatchCountDesc")
      checked: root.editShowMatchCount
      onToggled: function (v) {
        root.showMatchCountField.set(v);
      }
    }
  }

  NPluginSettingsField {
    field: root.showFooterField
    NToggle {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.showFooter")
      description: root.pluginApi?.tr("settings.showFooterDesc")
      checked: root.editShowFooter
      onToggled: function (v) {
        root.showFooterField.set(v);
      }
    }
  }

  NPluginSettingsField {
    field: root.showToastOnSelectField
    NToggle {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.showToast")
      description: root.pluginApi?.tr("settings.showToastDesc")
      checked: root.editShowToast
      onToggled: function (v) {
        root.showToastOnSelectField.set(v);
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  // ═══════════════════════════════════════
  // Advanced
  // ═══════════════════════════════════════

  NLabel {
    label: root.pluginApi?.tr("settings.advanced")
  }

  NPluginSettingsField {
    field: root.resultFileField
    NTextInput {
      Layout.fillWidth: true
      label: root.pluginApi?.tr("settings.resultFile")
      description: root.pluginApi?.tr("settings.resultFileDesc")
      placeholderText: "/tmp/noctalia-dmenu-result"
      text: root.editResultFile
      onEditCommitted: root.resultFileField.set(text)
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: root.pluginApi?.tr("settings.maxResultsLabel", {
                                  count: root.editMaxResults
                                })
      description: root.pluginApi?.tr("settings.maxResultsDesc", {
                                        count: root.editMaxResults
                                      })
    }

    NPluginSettingsField {
      field: root.maxResultsField
      NSlider {
        id: rangeEditMaxResults
        objectName: "settings-range-editMaxResults"
        Layout.fillWidth: true
        from: 50
        to: 1000
        stepSize: 50
        value: root.editMaxResults
        onMoved: root.maxResultsField.set(value)
      }
    }
  }

  // ── Save ──
  function saveSettings() {
    if (!pluginApi) {
      Logger.e("DmenuProvider", "Cannot save: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("DmenuProvider", "Settings saved");
    });
  }
}
