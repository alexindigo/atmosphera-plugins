import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _savePending: false
  property bool _refreshPending: false
  property bool _feedbackPending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._savePending = false;
      var refresh = root._refreshPending, feedback = root._feedbackPending;
      root._refreshPending = false;
      root._feedbackPending = false;
      if (refresh)
        root.mainInst?.requestPoll(true);
      if (feedback) {
        saveStatus.text = root.tr("settings.saved");
        saveStatusTimer.restart();
      }
    }
  }

  property var pluginApi: null
  readonly property var enabledField: pluginApi?.field("enabled") ?? null
  readonly property var apiUrlField: pluginApi?.field("apiUrl") ?? null
  readonly property var apiKeyField: pluginApi?.field("apiKey") ?? null
  readonly property var configPathField: pluginApi?.field("configPath") ?? null
  readonly property var verifyTlsField: pluginApi?.field("verifyTls") ?? null
  readonly property var pollIntervalMsField: pluginApi?.field("pollIntervalMs") ?? null
  readonly property var folderIdsField: pluginApi?.field("folderIds") ?? null
  readonly property var mainInst: pluginApi?.mainInstance?.settingsConsumerFor(pluginApi.runtimeContext) ?? null

  readonly property bool valueEnabled: root.enabledField?.value ?? true
  readonly property string valueApiUrl: root.apiUrlField?.value ?? ""
  readonly property string valueApiKey: root.apiKeyField?.value ?? ""
  readonly property string valueConfigPath: root.configPathField?.value ?? ""
  readonly property bool valueVerifyTls: root.verifyTlsField?.value ?? false
  readonly property int valuePollIntervalMs: root.pollIntervalMsField?.value ?? 10000
  readonly property var valueFolderIds: {
    const raw = root.folderIdsField?.value ?? [];
    try {
      return Array.from(raw);
    } catch (e) {
      return [];
    }
  }

  function tr(key, params) {
    return pluginApi?.tr(key, params);
  }

  function sourceLabel(code) {
    return mainInst?.sourceLabel(code);
  }

  function isFolderSelected(folderId) {
    return valueFolderIds.indexOf(folderId) >= 0;
  }

  function toggleFolder(folderId) {
    const updated = Array.from(valueFolderIds);
    const index = updated.indexOf(folderId);
    if (index >= 0) {
      updated.splice(index, 1);
    } else {
      updated.push(folderId);
    }
    root.folderIdsField.set(updated);
  }

  function requestRefresh() {
    root.saveSettings(true, true);
  }

  function saveSettings(triggerRefresh, feedback) {
    if (!pluginApi)
      return;
    if (pluginApi.saveSettings() !== false) {
      root._savePending = true;
      root._refreshPending = root._refreshPending || triggerRefresh === true;
      root._feedbackPending = root._feedbackPending || feedback === true;
    }
  }

  spacing: Style.marginM

  NPluginSettingsField {
    field: root.enabledField
    NToggle {
      Layout.fillWidth: true
      label: tr("settings.enabled")
      description: tr("settings.enabled-desc")
      checked: root.valueEnabled
      onToggled: checked => root.enabledField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.apiUrlField
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NLabel {
        label: tr("settings.url")
        description: tr("settings.url-desc")
      }

      Rectangle {
        Layout.fillWidth: true
        height: Math.round(36 * Style.uiScaleRatio)
        radius: Style.radiusM
        color: AtmoColor.mSurfaceVariant
        border.color: urlField.activeFocus ? AtmoColor.mPrimary : AtmoColor.mOutline
        border.width: Style.borderS

        TextInput {
          id: urlField
          anchors.fill: parent
          anchors.margins: Style.marginM
          verticalAlignment: TextInput.AlignVCenter
          color: AtmoColor.mOnSurface
          selectionColor: AtmoColor.mPrimary
          selectedTextColor: AtmoColor.mOnPrimary
          clip: true
          text: root.valueApiUrl
          // Focused typing is user intent; binding updates are not.
          onTextChanged: if (activeFocus)
                           root.apiUrlField.set(text)
          onEditingFinished: {
            let url = text.trim();
            if (url && !url.startsWith("http://") && !url.startsWith("https://"))
              url = "http://" + url;
            root.apiUrlField.set(url);
          }

          NText {
            anchors.verticalCenter: parent.verticalCenter
            text: "http://127.0.0.1:8384"
            visible: !urlField.text && !urlField.activeFocus
            opacity: 0.4
          }
        }
      }
    }
  }

  NPluginSettingsField {
    field: root.apiKeyField
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NLabel {
        label: tr("settings.api-key")
        description: tr("settings.api-key-desc")
      }

      Rectangle {
        Layout.fillWidth: true
        height: Math.round(36 * Style.uiScaleRatio)
        radius: Style.radiusM
        color: AtmoColor.mSurfaceVariant
        border.color: apiField.activeFocus ? AtmoColor.mPrimary : AtmoColor.mOutline
        border.width: Style.borderS

        TextInput {
          id: apiField
          anchors.fill: parent
          anchors.margins: Style.marginM
          verticalAlignment: TextInput.AlignVCenter
          color: AtmoColor.mOnSurface
          selectionColor: AtmoColor.mPrimary
          selectedTextColor: AtmoColor.mOnPrimary
          clip: true
          echoMode: TextInput.Password
          text: root.valueApiKey
          onTextChanged: if (activeFocus)
                           root.apiKeyField.set(text)
          onEditingFinished: root.apiKeyField.set(text.trim())

          NText {
            anchors.verticalCenter: parent.verticalCenter
            text: "X-API-Key"
            visible: !apiField.text && !apiField.activeFocus
            opacity: 0.4
          }
        }
      }
    }
  }

  NPluginSettingsField {
    field: root.configPathField
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NLabel {
        label: tr("settings.config-path")
        description: tr("settings.config-path-desc")
      }

      Rectangle {
        Layout.fillWidth: true
        height: Math.round(36 * Style.uiScaleRatio)
        radius: Style.radiusM
        color: AtmoColor.mSurfaceVariant
        border.color: pathField.activeFocus ? AtmoColor.mPrimary : AtmoColor.mOutline
        border.width: Style.borderS

        TextInput {
          id: pathField
          anchors.fill: parent
          anchors.margins: Style.marginM
          verticalAlignment: TextInput.AlignVCenter
          color: AtmoColor.mOnSurface
          selectionColor: AtmoColor.mPrimary
          selectedTextColor: AtmoColor.mOnPrimary
          clip: true
          text: root.valueConfigPath
          onTextChanged: if (activeFocus)
                           root.configPathField.set(text)
          onEditingFinished: root.configPathField.set(text.trim())

          NText {
            anchors.verticalCenter: parent.verticalCenter
            text: "~/.local/state/syncthing/config.xml"
            visible: !pathField.text && !pathField.activeFocus
            opacity: 0.4
          }
        }
      }
    }
  }

  NPluginSettingsField {
    field: root.verifyTlsField
    NToggle {
      Layout.fillWidth: true
      label: tr("settings.verify-tls")
      description: tr("settings.verify-tls-desc")
      checked: root.valueVerifyTls
      onToggled: checked => root.verifyTlsField.set(checked)
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: tr("settings.poll-interval-label", {
                  "value": Math.round(root.valuePollIntervalMs / 1000)
                })
      description: tr("settings.poll-interval-desc")
    }

    NPluginSettingsField {
      field: root.pollIntervalMsField
      NSlider {
        id: rangeValuePollIntervalMs
        objectName: "settings-range-valuePollIntervalMs"
        Layout.fillWidth: true
        from: 2000
        to: 60000
        value: root.valuePollIntervalMs
        stepSize: 1000
        onMoved: root.pollIntervalMsField.set(Math.round(value))
      }
    }
  }

  NPluginSettingsField {
    field: root.folderIdsField
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NLabel {
        label: tr("settings.folders")
        description: tr("settings.folders-desc")
      }

      Flow {
        Layout.fillWidth: true
        spacing: Style.marginS

        Repeater {
          model: mainInst?.availableFolders ?? []

          delegate: Rectangle {
            required property var modelData
            readonly property bool isSelected: root.isFolderSelected(modelData.id)

            width: chipLabel.implicitWidth + Math.round(22 * Style.uiScaleRatio)
            height: Math.round(30 * Style.uiScaleRatio)
            radius: height / 2
            color: isSelected ? Qt.alpha(AtmoColor.mPrimary, 0.15) : AtmoColor.mSurfaceVariant
            border.color: isSelected ? AtmoColor.mPrimary : AtmoColor.mOutline
            border.width: Style.borderS

            NText {
              id: chipLabel
              anchors.centerIn: parent
              text: modelData.label
              font.bold: parent.isSelected
              color: parent.isSelected ? AtmoColor.mPrimary : AtmoColor.mOnSurface
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleFolder(parent.modelData.id)
            }
          }
        }
      }

      NText {
        text: tr("settings.no-folders")
        visible: (mainInst?.availableFolders?.length ?? 0) === 0
        wrapMode: Text.Wrap
        color: Qt.alpha(AtmoColor.mOnSurface, 0.65)
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    Rectangle {
      Layout.preferredWidth: saveLabel.width + Math.round(24 * Style.uiScaleRatio)
      Layout.preferredHeight: Math.round(32 * Style.uiScaleRatio)
      radius: Style.radiusM
      color: saveMouse.containsMouse ? Qt.darker(AtmoColor.mPrimary, 1.1) : AtmoColor.mPrimary

      NText {
        id: saveLabel
        anchors.centerIn: parent
        text: tr("settings.save")
        color: AtmoColor.mOnPrimary
      }

      MouseArea {
        id: saveMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          root.saveSettings(false, true);
        }
      }
    }

    Rectangle {
      Layout.preferredWidth: refreshLabel.width + Math.round(24 * Style.uiScaleRatio)
      Layout.preferredHeight: Math.round(32 * Style.uiScaleRatio)
      radius: Style.radiusM
      color: refreshMouse.containsMouse ? AtmoColor.mOutline : AtmoColor.mSurfaceVariant
      border.color: AtmoColor.mOutline
      border.width: Style.borderS

      NText {
        id: refreshLabel
        anchors.centerIn: parent
        text: tr("settings.refresh")
      }

      MouseArea {
        id: refreshMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          root.requestRefresh();
        }
      }
    }

    NText {
      id: saveStatus
      text: ""
      opacity: 0.7
    }
  }

  Timer {
    id: saveStatusTimer
    interval: 2000
    onTriggered: saveStatus.text = ""
  }

  ColumnLayout {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    spacing: Style.marginXS

    NText {
      text: tr("settings.status")
      font.bold: true
    }

    NText {
      text: mainInst?.stateLabel(mainInst.enabled ? mainInst.state : "disabled") ?? ""
      color: mainInst ? mainInst.statusColor(mainInst.enabled ? mainInst.state : "disabled") : AtmoColor.mOutline
    }

    NText {
      text: mainInst?.statusSummary() ?? ""
      wrapMode: Text.Wrap
      color: Qt.alpha(AtmoColor.mOnSurface, 0.75)
    }

    NText {
      text: tr("settings.url-info", {
                 "value": mainInst?.resolvedUrl || "-"
               })
      pointSize: Style.fontSizeS
      color: Qt.alpha(AtmoColor.mOnSurface, 0.6)
      elide: Text.ElideRight
    }

    NText {
      text: tr("settings.api-source-info", {
                 "value": root.sourceLabel(mainInst?.apiKeySource ?? "none")
               })
      pointSize: Style.fontSizeS
      color: Qt.alpha(AtmoColor.mOnSurface, 0.6)
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    spacing: Style.marginXS

    NText {
      text: tr("settings.about")
      font.bold: true
    }

    NText {
      text: tr("settings.developer")
      wrapMode: Text.Wrap
      color: Qt.alpha(AtmoColor.mOnSurface, 0.75)
    }

    NText {
      text: "v" + (pluginApi?.manifest?.version ?? "1.0.0")
      color: Qt.alpha(AtmoColor.mOnSurface, 0.5)
    }
  }
}
