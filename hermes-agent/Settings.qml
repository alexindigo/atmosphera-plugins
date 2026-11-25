import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _savePending: false
  property bool _trimModelPending: false
  property var _probeLifetime: ({alive:true})
  property var _probe: null
  property int _probeGeneration: 0
  readonly property string probeTarget: JSON.stringify([valueBridgeHost,valueBridgePort,valueBridgeTokenManual])
  onProbeTargetChanged: cancelProbe()
  function cancelProbe() {
    _probeGeneration++;
    if (_probe) { _probe.onreadystatechange = null; _probe.abort(); _probe = null; }
    testResult = "";
  }
  Component.onDestruction: { _probeLifetime.alive = false; cancelProbe(); }
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._savePending = false;
      var trim = root._trimModelPending;
      root._trimModelPending = false;
      root.mainInstance?.applySettings(root.pluginApi.runtimeContext, trim);
    }
  }

  property var pluginApi: null
  readonly property var bridgeHostField: pluginApi?.field("bridgeHost") ?? null
  readonly property var bridgePortField: pluginApi?.field("bridgePort") ?? null
  readonly property var stateFileField: pluginApi?.field("stateFile") ?? null
  readonly property var hermesHomeField: pluginApi?.field("hermesHome") ?? null
  readonly property var hermesCommandField: pluginApi?.field("hermesCommand") ?? null
  readonly property var autoStartBridgeField: pluginApi?.field("autoStartBridge") ?? null
  readonly property var autoStartGatewayField: pluginApi?.field("autoStartGateway") ?? null
  readonly property var clientOnlyModeField: pluginApi?.field("clientOnlyMode") ?? null
  readonly property var bridgeTokenManualField: pluginApi?.field("bridgeTokenManual") ?? null
  readonly property var statusPollIntervalSecField: pluginApi?.field("statusPollIntervalSec") ?? null
  readonly property var hideWhenIdleField: pluginApi?.field("hideWhenIdle") ?? null
  readonly property var launcherPrefixField: pluginApi?.field("launcherPrefix") ?? null
  readonly property var panelPinnedField: pluginApi?.field("panelPinned") ?? null
  readonly property var showToolActivityField: pluginApi?.field("showToolActivity") ?? null
  readonly property var defaultProviderField: pluginApi?.field("defaultProvider") ?? null
  readonly property var defaultModelField: pluginApi?.field("defaultModel") ?? null
  property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property var summary: mainInstance?.state?.summary || ({})
  readonly property var detectedModel: summary.model || ({})
  readonly property var availableModels: summary.models || []

  readonly property string valueBridgeHost: root.bridgeHostField?.value ?? "127.0.0.1"
  readonly property int valueBridgePort: root.bridgePortField?.value ?? 19777
  readonly property string valueStateFile: root.stateFileField?.value ?? "~/.cache/noctalia-hermes/state.json"
  readonly property string valueHermesHome: root.hermesHomeField?.value ?? "~/.hermes"
  readonly property string valueHermesCommand: root.hermesCommandField?.value ?? "hermes"
  readonly property bool valueAutoStartBridge: root.autoStartBridgeField?.value ?? true
  readonly property bool valueAutoStartGateway: root.autoStartGatewayField?.value ?? true
  readonly property bool valueClientOnlyMode: root.clientOnlyModeField?.value ?? false
  readonly property string valueBridgeTokenManual: root.bridgeTokenManualField?.value ?? ""
  readonly property int valueStatusPollIntervalSec: root.statusPollIntervalSecField?.value ?? 30
  readonly property bool valueHideWhenIdle: root.hideWhenIdleField?.value ?? false
  readonly property string valueLauncherPrefix: root.launcherPrefixField?.value ?? ">hermes"
  readonly property bool valuePanelPinned: root.panelPinnedField?.value ?? false
  readonly property bool valueShowToolActivity: root.showToolActivityField?.value ?? false
  readonly property string valueDefaultProvider: root.defaultProviderField?.value ?? ""
  readonly property string valueDefaultModel: root.defaultModelField?.value ?? ""
  readonly property string selectedModelKey: modelKey(valueDefaultProvider, valueDefaultModel)
  property bool showAdvanced: false
  property string testResult: ""
  property color testResultColor: AtmoColor.mOnSurface

  spacing: Style.marginL

  NText {
    text: pluginApi?.tr("settings.title")
    pointSize: Style.fontSizeXL
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
    Layout.fillWidth: true
  }

  NText {
    objectName: "hermes-shared-effect"
    Layout.fillWidth: true
    wrapMode: Text.Wrap
    text: pluginApi?.tr("settings.sharedEffect")
  }
  NText {
    objectName: "hermes-pending-restart"
    Layout.fillWidth: true
    wrapMode: Text.Wrap
    visible: root.mainInstance?.pendingRestart ?? false
    text: pluginApi?.tr("settings.pendingRestart")
    color: AtmoColor.mOnSurface
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NPluginSettingsField {
      field: root.defaultProviderField
      NPluginSettingsField {
        field: root.defaultModelField
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          NComboBox {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.providerSelect")
            model: root.providerOptions()
            currentKey: root.valueDefaultProvider
            minimumWidth: 180
            onSelected: function (key) {
              root.defaultProviderField.set(key);
              if (root.valueDefaultModel !== "" && root.findModel(root.valueDefaultProvider, root.valueDefaultModel) === null) {
                var first = root.firstModelForProvider(key);
                if (first)
                  root.defaultModelField.set(first.model);
              }
            }
          }

          NComboBox {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.modelSelect")
            model: root.modelOptions(root.valueDefaultProvider)
            currentKey: root.selectedModelKey
            minimumWidth: 320
            onSelected: function (key) {
              var item = root.findModelByKey(key);
              if (!item)
                return;
              root.defaultProviderField.set(item.provider || "");
              root.defaultModelField.set(item.model || "");
            }
          }
        }
      }
    }

    NButton {
      text: pluginApi?.tr("settings.applyModel")
      icon: "refresh"
      enabled: root.valueDefaultModel.trim() !== ""
      onClicked: root.applyModel()
    }

    NPluginSettingsField {
      field: root.hideWhenIdleField
      NToggle {
        label: pluginApi?.tr("settings.hideWhenIdle")
        description: pluginApi?.tr("settings.hideWhenIdleDescription")
        checked: root.valueHideWhenIdle
        onToggled: checked => root.hideWhenIdleField.set(checked)
      }
    }

    NPluginSettingsField {
      field: root.panelPinnedField
      NToggle {
        label: pluginApi?.tr("settings.panelPinned")
        description: pluginApi?.tr("settings.panelPinnedDescription")
        checked: root.valuePanelPinned
        onToggled: checked => root.panelPinnedField.set(checked)
      }
    }

    NPluginSettingsField {
      field: root.showToolActivityField
      NToggle {
        label: pluginApi?.tr("settings.showToolActivity")
        description: pluginApi?.tr("settings.showToolActivityDescription")
        checked: root.valueShowToolActivity
        onToggled: checked => root.showToolActivityField.set(checked)
      }
    }

    NButton {
      text: root.showAdvanced ? pluginApi?.tr("settings.advancedHide") : pluginApi?.tr("settings.advancedShow")
      icon: root.showAdvanced ? "chevron-up" : "chevron-down"
      outlined: true
      onClicked: root.showAdvanced = !root.showAdvanced
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginM
      visible: root.showAdvanced

      NPluginSettingsField {
        field: root.clientOnlyModeField
        NToggle {
          label: pluginApi?.tr("settings.clientOnlyMode")
          description: pluginApi?.tr("settings.clientOnlyModeDescription")
          checked: root.valueClientOnlyMode
          onToggled: checked => root.clientOnlyModeField.set(checked)
        }
      }

      NPluginSettingsField {
        field: root.bridgeTokenManualField
        visible: root.valueClientOnlyMode
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.bridgeToken")
          description: pluginApi?.tr("settings.bridgeTokenDescription")
          text: root.valueBridgeTokenManual
          onEditCommitted: {
            // Guard: only update when visible. Some QML components clear text
            // when hidden, which would wipe the saved token on toggle OFF.
            if (root.valueClientOnlyMode)
              root.bridgeTokenManualField.set(text);
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        visible: root.valueClientOnlyMode
        spacing: Style.marginM

        NButton {
          text: pluginApi?.tr("settings.testConnection")
          onClicked: root.testConnection()
        }

        NLabel {
          label: root.testResult
          labelColor: root.testResultColor
        }
      }

      NPluginSettingsField {
        field: root.bridgeHostField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.bridgeHost")
          text: root.valueBridgeHost
          onEditCommitted: root.bridgeHostField.set(text)
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXS

          NText {
            text: pluginApi?.tr("settings.bridgePort")
            pointSize: Style.fontSizeM
            font.weight: Style.fontWeightSemiBold
            color: AtmoColor.mOnSurface
          }

          NPluginSettingsField {
            field: root.bridgePortField
            NSpinBox {
              id: rangeValueBridgePort
              objectName: "settings-range-valueBridgePort"
              from: 1024
              to: 65535
              value: root.valueBridgePort
              stepSize: 1
              requestValue: value => root.bridgePortField.set(value)
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXS

          NText {
            text: pluginApi?.tr("settings.statusPollIntervalSec")
            pointSize: Style.fontSizeM
            font.weight: Style.fontWeightSemiBold
            color: AtmoColor.mOnSurface
          }

          NPluginSettingsField {
            field: root.statusPollIntervalSecField
            NSpinBox {
              id: rangeValueStatusPollIntervalSec
              objectName: "settings-range-valueStatusPollIntervalSec"
              from: 5
              to: 300
              value: root.valueStatusPollIntervalSec
              stepSize: 5
              requestValue: value => root.statusPollIntervalSecField.set(value)
            }
          }
        }
      }

      NPluginSettingsField {
        field: root.stateFileField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.stateFile")
          text: root.valueStateFile
          onEditCommitted: root.stateFileField.set(text)
        }
      }

      NPluginSettingsField {
        field: root.hermesHomeField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.hermesHome")
          text: root.valueHermesHome
          onEditCommitted: root.hermesHomeField.set(text)
        }
      }

      NPluginSettingsField {
        field: root.hermesCommandField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.hermesCommand")
          text: root.valueHermesCommand
          onEditCommitted: root.hermesCommandField.set(text)
        }
      }

      NPluginSettingsField {
        field: root.launcherPrefixField
        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.launcherPrefix")
          text: root.valueLauncherPrefix
          onEditCommitted: root.launcherPrefixField.set(text)
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.defaultProvider")
          text: root.valueDefaultProvider
          onEditCommitted: root.defaultProviderField.set(text)
        }

        NTextInput {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.defaultModel")
          text: root.valueDefaultModel
          onEditCommitted: root.defaultModelField.set(text)
        }
      }

      NPluginSettingsField {
        field: root.autoStartBridgeField
        visible: !root.valueClientOnlyMode
        NToggle {
          label: pluginApi?.tr("settings.autoStartBridge")
          description: pluginApi?.tr("settings.autoStartBridgeDescription")
          checked: root.valueAutoStartBridge
          onToggled: checked => root.autoStartBridgeField.set(checked)
        }
      }

      NPluginSettingsField {
        field: root.autoStartGatewayField
        visible: !root.valueClientOnlyMode
        NToggle {
          label: pluginApi?.tr("settings.autoStartGateway")
          description: pluginApi?.tr("settings.autoStartGatewayDescription")
          checked: root.valueAutoStartGateway
          onToggled: checked => root.autoStartGatewayField.set(checked)
        }
      }
    }
  }

  function applyModel() {
    root._trimModelPending = true;
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    Logger.i("hermes-agent", "saveSettings: tokenManual len:", root.valueBridgeTokenManual.length, "clientOnlyMode:", root.valueClientOnlyMode);
    if (pluginApi.saveSettings() !== false)
      root._savePending = true;
  }

  function testConnection() {
    cancelProbe();
    root.testResult = pluginApi?.tr("settings.testing");
    root.testResultColor = AtmoColor.mOnSurface;
    var host = root.valueBridgeHost;
    var port = root.valueBridgePort;
    var token = root.valueBridgeTokenManual;
    var url = "http://" + host + ":" + port + "/health";
    var xhr = new XMLHttpRequest();
    _probe = xhr;
    const life = _probeLifetime;
    const generation = _probeGeneration;
    xhr.onreadystatechange = function () {
      if (!life.alive || xhr.readyState !== XMLHttpRequest.DONE)
        return;
      if (generation !== root._probeGeneration || root._probe !== xhr) return;
      root._probe = null;
      if (xhr.status === 0) {
        root.testResult = pluginApi?.tr("settings.testFailedUnreachable");
        root.testResultColor = AtmoColor.mError;
      } else if (xhr.status === 403) {
        root.testResult = pluginApi?.tr("settings.testFailedAuth");
        root.testResultColor = AtmoColor.mError;
      } else if (xhr.status >= 200 && xhr.status < 300) {
        root.testResult = pluginApi?.tr("settings.testSuccess");
        root.testResultColor = AtmoColor.mPrimary;
      } else {
        root.testResult = pluginApi?.tr("settings.testFailed") + " " + xhr.status;
        root.testResultColor = AtmoColor.mError;
      }
    };
    xhr.open("GET", url);
    if (token)
      xhr.setRequestHeader("X-Bridge-Token", token);
    xhr.send();
  }

  function modelKey(provider, model) {
    return (provider || "") + "::" + (model || "");
  }

  function providerOptions() {
    var seen = {};
    var items = [
          {
            "key": "",
            "name": pluginApi?.tr("settings.providerCurrent")
          }
        ];
    for (var i = 0; i < root.availableModels.length; i++) {
      var provider = root.availableModels[i].provider || "";
      if (provider === "" || seen[provider])
        continue;
      seen[provider] = true;
      items.push({
                   "key": provider,
                   "name": provider
                 });
    }
    if (root.valueDefaultProvider !== "" && !seen[root.valueDefaultProvider]) {
      items.push({
                   "key": root.valueDefaultProvider,
                   "name": root.valueDefaultProvider
                 });
    }
    return items;
  }

  function modelOptions(provider) {
    var items = [];
    for (var i = 0; i < root.availableModels.length; i++) {
      var item = root.availableModels[i];
      if (provider !== "" && item.provider !== provider)
        continue;
      items.push({
                   "key": root.modelKey(item.provider || "", item.model || ""),
                   "name": item.name || item.model || ""
                 });
    }
    if (root.valueDefaultModel !== "" && root.findModel(root.valueDefaultProvider, root.valueDefaultModel) === null) {
      items.unshift({
                      "key": root.selectedModelKey,
                      "name": root.valueDefaultModel + (root.valueDefaultProvider ? " (" + root.valueDefaultProvider + ")" : "")
                    });
    }
    return items;
  }

  function findModel(provider, model) {
    for (var i = 0; i < root.availableModels.length; i++) {
      var item = root.availableModels[i];
      if ((item.provider || "") === (provider || "") && (item.model || "") === (model || ""))
        return item;
    }
    return null;
  }

  function findModelByKey(key) {
    for (var i = 0; i < root.availableModels.length; i++) {
      var item = root.availableModels[i];
      if (root.modelKey(item.provider || "", item.model || "") === key)
        return item;
    }
    return null;
  }

  function firstModelForProvider(provider) {
    for (var i = 0; i < root.availableModels.length; i++) {
      var item = root.availableModels[i];
      if (provider === "" || item.provider === provider)
        return item;
    }
    return null;
  }
}
