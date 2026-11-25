import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string valueIconColor: root.iconColorField?.value ?? defaults.iconColor

  spacing: Style.marginM

  NPluginSettingsField {
    field: root.iconColorField
    NColorChoice {
      label: pluginApi?.tr("settings.iconColor.label")
      description: pluginApi?.tr("settings.iconColor.desc")
      currentKey: root.valueIconColor
      onSelected: key => root.iconColorField.set(key)
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginS
    Layout.bottomMargin: Style.marginS
  }

  ColumnLayout {
    Layout.fillWidth: true

    NLabel {
      label: pluginApi?.tr("settings.ipcCommands.label")
      description: pluginApi?.tr("settings.ipcCommands.desc")
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: commandText.implicitHeight + Style.marginM * 2
      color: AtmoColor.mSurfaceVariant
      radius: Style.radiusM

      TextEdit {
        id: commandText
        anchors.fill: parent
        anchors.margins: Style.marginM
        text: "qs -c noctalia-shell ipc call plugin:mimeapp-gui openPanel"
        font.pointSize: Style.fontSizeS
        font.family: Settings.data.ui.fontFixed
        color: AtmoColor.mPrimary
        wrapMode: TextEdit.WrapAnywhere
        readOnly: true
        selectByMouse: true
        selectionColor: AtmoColor.mPrimary
        selectedTextColor: AtmoColor.mOnPrimary
      }
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("MimeApp GUI", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.d("MimeApp GUI", "Settings saved");
    });
  }
}
