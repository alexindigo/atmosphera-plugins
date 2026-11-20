import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var enabledField: pluginApi?.field("enabled") ?? null
  readonly property var perWorkspaceField: pluginApi?.field("perWorkspace") ?? null
  readonly property var onlyAtMaxField: pluginApi?.field("onlyAtMax") ?? null
  readonly property var maxVisibleField: pluginApi?.field("maxVisible") ?? null
  readonly property var debounceMsField: pluginApi?.field("debounceMs") ?? null
  readonly property var maxEventsPerSecondField: pluginApi?.field("maxEventsPerSecond") ?? null

  readonly property var settings: pluginApi?.pluginSettings ?? ({})

  readonly property bool valueEnabled: root.enabledField?.value ?? true
  readonly property bool valuePerWorkspace: root.perWorkspaceField?.value ?? false
  readonly property bool valueOnlyAtMax: root.onlyAtMaxField?.value ?? true
  readonly property int valueMaxVisible: root.maxVisibleField?.value ?? 4
  readonly property int valueDebounceMs: root.debounceMsField?.value ?? 300
  readonly property int valueMaxEventsPerSecond: root.maxEventsPerSecondField?.value ?? 20
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _restartPending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._restartPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._restartPending = false;
      root.pluginApi.mainInstance?.restartDaemon();
    }
  }

  spacing: Style.marginM

  function saveSettings(restart) {
    if (!pluginApi)
      return;
    if (pluginApi.saveSettings() !== false)
      root._restartPending = root._restartPending || restart === true;
  }

  // ─── Enable / Disable ───
  NPluginSettingsField {
    field: root.enabledField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.enabled")
      description: pluginApi?.tr("settings.enabled-desc")
      checked: root.valueEnabled
      onToggled: checked => {
        root.enabledField.set(checked);
      }
    }
  }

  // ─── Per Workspace ───
  NPluginSettingsField {
    field: root.perWorkspaceField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.per-workspace")
      description: pluginApi?.tr("settings.per-workspace-desc")
      checked: root.valuePerWorkspace
      onToggled: checked => {
        root.perWorkspaceField.set(checked);
        root.saveSettings(true);
      }
    }
  }

  // ─── Only at Max ───
  NPluginSettingsField {
    field: root.onlyAtMaxField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.only-at-max")
      description: pluginApi?.tr("settings.only-at-max-desc")
      checked: root.valueOnlyAtMax
      onToggled: checked => {
        root.onlyAtMaxField.set(checked);
        root.saveSettings(true);
      }
    }
  }

  // ─── Max Visible Columns ───
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.max-visible", {
                             "value": root.valueMaxVisible
                           })
      description: pluginApi?.tr("settings.max-visible-desc")
    }

    NPluginSettingsField {
      field: root.maxVisibleField
      NSlider {
        id: rangeValueMaxVisible
        objectName: "settings-range-valueMaxVisible"
        Layout.fillWidth: true
        from: 1
        to: 8
        value: root.valueMaxVisible
        stepSize: 1
        onMoved: {
          root.maxVisibleField.set(Math.round(value));
          root.saveSettings(true);
        }
      }
    }
  }

  // ─── Debounce ───
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.debounce", {
                             "value": root.valueDebounceMs
                           })
      description: pluginApi?.tr("settings.debounce-desc")
    }

    NPluginSettingsField {
      field: root.debounceMsField
      NSlider {
        id: rangeValueDebounceMs
        objectName: "settings-range-valueDebounceMs"
        Layout.fillWidth: true
        from: 100
        to: 1000
        value: root.valueDebounceMs
        stepSize: 50
        onMoved: {
          root.debounceMsField.set(Math.round(value));
          root.saveSettings(true);
        }
      }
    }
  }

  // ─── Rate Limit ───
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.rate-limit", {
                             "value": root.valueMaxEventsPerSecond
                           })
      description: pluginApi?.tr("settings.rate-limit-desc")
    }

    NPluginSettingsField {
      field: root.maxEventsPerSecondField
      NSlider {
        id: rangeValueMaxEventsPerSecond
        objectName: "settings-range-valueMaxEventsPerSecond"
        Layout.fillWidth: true
        from: 5
        to: 50
        value: root.valueMaxEventsPerSecond
        stepSize: 5
        onMoved: {
          root.maxEventsPerSecondField.set(Math.round(value));
          root.saveSettings(true);
        }
      }
    }
  }

  // ─── Status ───
  RowLayout {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    spacing: Style.marginM

    Rectangle {
      width: Math.round(8 * Style.uiScaleRatio)
      height: Math.round(8 * Style.uiScaleRatio)
      radius: Math.round(4 * Style.uiScaleRatio)
      color: {
        const status = pluginApi?.mainInstance?.status ?? "stopped";
        if (status === "running")
          return AtmoColor.mPrimary;
        if (status === "error")
          return AtmoColor.mError;
        return AtmoColor.mOutline;
      }
    }

    NText {
      text: {
        const status = pluginApi?.mainInstance?.status ?? "stopped";
        if (status === "running")
          return pluginApi?.tr("settings.status-running");
        if (status === "error")
          return pluginApi?.tr("settings.status-error");
        return pluginApi?.tr("settings.status-stopped");
      }
      Layout.fillWidth: true
    }
  }

  // ─── About ───
  ColumnLayout {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    spacing: Style.marginXS

    NText {
      text: pluginApi?.tr("settings.about-title")
      font.bold: true
    }

    NText {
      text: pluginApi?.tr("settings.about-credit")
      opacity: 0.7
      pointSize: Style.fontSizeS
    }

    NText {
      text: pluginApi?.tr("settings.about-date", {
                            "date": "2026-02-19"
                          })
      opacity: 0.5
      pointSize: Style.fontSizeXS
    }

    NText {
      text: "v" + (pluginApi?.manifest?.version ?? "1.1.0")
      opacity: 0.5
      pointSize: Style.fontSizeXS
    }
  }
}
