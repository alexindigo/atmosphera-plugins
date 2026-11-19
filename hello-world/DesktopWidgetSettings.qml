import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  property var widgetSettings: null
  signal settingsChanged(var settings)

  readonly property var cfg: pluginApi?.pluginSettings ?? ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
  readonly property var widget: widgetSettings?.data ?? ({})

  property string valueMessage: widget.message ?? cfg.message ?? defaults.message

  spacing: Style.marginM

  Component.onCompleted: {
    Logger.d("HelloWorld", "Desktop Widget Settings UI loaded");
  }

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.message.label")
      description: pluginApi?.tr("settings.message.desc")
      placeholderText: pluginApi?.tr("settings.message.placeholder")
      text: root.valueMessage
      onTextEdited: {
        root.valueMessage = text;
        root.saveSettings({message: root.valueMessage});
      }
    }
  }

  function saveSettings(fields) {
    if (fields)
      settingsChanged(fields);
  }
}
