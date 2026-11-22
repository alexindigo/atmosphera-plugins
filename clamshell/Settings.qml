import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var enabledField: pluginApi?.field("enabled") ?? null
  readonly property var alwaysShowBarWidgetField: pluginApi?.field("alwaysShowBarWidget") ?? null
  readonly property var notifyField: pluginApi?.field("notify") ?? null
  readonly property var internalConnectorRegexField: pluginApi?.field("internalConnectorRegex") ?? null
  readonly property var inhibitorWhoField: pluginApi?.field("inhibitorWho") ?? null
  readonly property var main: pluginApi?.mainInstance ?? null

  readonly property bool editEnabled: root.enabledField?.value ?? true
  readonly property bool editAlwaysShowBarWidget: root.alwaysShowBarWidgetField?.value ?? false
  readonly property bool editNotify: root.notifyField?.value ?? true
  readonly property string editInternalConnectorRegex: root.internalConnectorRegexField?.value ?? "^(eDP|LVDS|DSI)"
  readonly property string editInhibitorWho: root.inhibitorWhoField?.value ?? "noctalia-clamshell"
  property bool _applyEffectPending: false
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._applyEffectPending = false;
      if (root.main?.applySettings)
        root.main.applySettings(root.pluginApi.runtimeContext);
      Logger.i("Clamshell", "Settings saved successfully");
    }
  }

  spacing: Style.marginL

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    text: root.pluginApi?.tr("settings.shared-effect")
    wrapMode: Text.WordWrap
  }

  Component.onCompleted: {
    Logger.d("Clamshell", "Settings UI loaded");
  }

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NPluginSettingsField {
      field: root.enabledField
      NToggle {
        label: pluginApi?.tr("settings.enabled")
        checked: root.editEnabled
        onToggled: checked => root.enabledField.set(checked)
      }
    }

    NPluginSettingsField {
      field: root.alwaysShowBarWidgetField
      NToggle {
        label: pluginApi?.tr("settings.alwaysShowBarWidget")
        checked: root.editAlwaysShowBarWidget
        onToggled: checked => root.alwaysShowBarWidgetField.set(checked)
      }
    }

    NPluginSettingsField {
      field: root.notifyField
      NToggle {
        label: pluginApi?.tr("settings.notify")
        checked: root.editNotify
        onToggled: checked => root.notifyField.set(checked)
      }
    }

    NPluginSettingsField {
      field: root.internalConnectorRegexField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.internalConnectorRegex")
        placeholderText: "^(eDP|LVDS|DSI)"
        text: root.editInternalConnectorRegex
        onEditCommitted: root.internalConnectorRegexField.set(text)
      }
    }

    NPluginSettingsField {
      field: root.inhibitorWhoField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.inhibitorWho")
        placeholderText: "noctalia-clamshell"
        text: root.editInhibitorWho
        onEditCommitted: root.inhibitorWhoField.set(text)
      }
    }
  }

  NText {
    visible: root.main?.inhibitorAvailable === false
    Layout.fillWidth: true
    text: pluginApi?.tr("error.noInhibit")
    color: AtmoColor.mError
    pointSize: Style.fontSizeM
    wrapMode: Text.WordWrap
  }

  ColumnLayout {
    spacing: Style.marginS
    Layout.fillWidth: true

    NText {
      text: pluginApi?.tr("status.title")
      color: AtmoColor.mOnSurface
      pointSize: Style.fontSizeL
      font.weight: Font.DemiBold
    }

    NText {
      Layout.fillWidth: true
      text: pluginApi?.tr("status.state", {
                            "value": root.main?.stateLabel ? root.main.stateLabel() : pluginApi?.tr("status.unknown")
                          })
      color: AtmoColor.mOnSurfaceVariant
      wrapMode: Text.WordWrap
    }

    NText {
      Layout.fillWidth: true
      text: pluginApi?.tr("status.inhibitorPid", {
                            "value": (root.main?.inhibitorPid ?? 0) > 0 ? String(root.main.inhibitorPid) : "-"
                          })
      color: AtmoColor.mOnSurfaceVariant
      wrapMode: Text.WordWrap
    }

    Repeater {
      model: root.main?.outputs || []

      NText {
        Layout.fillWidth: true
        text: modelData.name + ": " + (modelData.internal ? "internal" : "external") + ", " + (modelData.active ? "active" : (modelData.connected ? "connected" : "disconnected"))
        color: AtmoColor.mOnSurfaceVariant
        wrapMode: Text.WordWrap
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Clamshell", "Cannot save settings: pluginApi is null");
      return;
    }

    if (pluginApi.saveSettings() !== false)
      root._applyEffectPending = true;
  }
}
