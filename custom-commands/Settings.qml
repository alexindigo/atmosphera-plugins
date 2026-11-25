import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var commandsField: pluginApi?.field("commands") ?? null
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _savePending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._savePending = false;
      Logger.i("CustomCommands", "Settings saved");
    }
  }

  // Row editor buffer: unfinished empty rows stay local; every explicit row
  // operation submits the complete list of valid rows as one atomic intent.
  property var commands: []
  property int commandsRevision: 0
  readonly property var commandsValue: commandsField?.value ?? []
  onCommandsValueChanged: {
    if (JSON.stringify(root.validRows(root.commands)) !== JSON.stringify(root.validRows(root.displayCommands())))
      root.loadCommands();
  }

  property real preferredWidth: 800 * Style.uiScaleRatio
  spacing: Style.marginL

  Component.onCompleted: {
    loadCommands();
  }

  function loadCommands() {
    commands = root.displayCommands();
    commandsRevision++;
  }

  function displayCommands() {
    return Array.prototype.map.call(root.commandsValue, function (row) {
      return Object.assign(Object.create(null), row, {
                             name: row.name || "",
                             command: row.command || "",
                             icon: row.icon || "terminal-2"
                           });
    });
  }

  function validRows(rows) {
    var valid = [];
    for (var i = 0; i < rows.length; i++) {
      var name = rows[i].name.trim();
      var command = rows[i].command.trim();
      if (name !== "" || command !== "")
        valid.push(Object.assign(Object.create(null), rows[i], {
                                   "name": name,
                                   "command": command,
                                   "icon": rows[i].icon || "terminal-2"
                                 }));
    }
    return valid;
  }

  function submit() {
    return root.commandsField.set(root.validRows(root.commands));
  }

  function moveCommand(from, to) {
    if (from < 0 || to < 0 || from >= root.commands.length || to >= root.commands.length || from === to)
      return;
    var rows = root.commands.slice();
    rows.splice(to, 0, rows.splice(from, 1)[0]);
    root.commands = rows;
    root.commandsRevision++;
    root.submit();
  }
  function removeCommand(index) {
    if (index < 0 || index >= root.commands.length)
      return;
    var rows = root.commands.slice();
    rows.splice(index, 1);
    root.commands = rows;
    root.commandsRevision++;
    root.submit();
  }
  function addCommand() {
    root.commands = root.commands.concat([
                                           {
                                             name: "",
                                             command: "",
                                             icon: "terminal-2"
                                           }
                                         ]);
    root.commandsRevision++;
  }

  function setCommandField(index, key, value) {
    if (index < 0 || index >= root.commands.length)
      return;
    var rows = root.commands.slice();
    rows[index] = Object.assign(Object.create(null), rows[index], {
                                  [key]: value
                                });
    root.commands = rows;
    root.commandsRevision++;
    root.submit();
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("CustomCommands", "Cannot save settings: pluginApi is null");
      return;
    }
    if (pluginApi.saveSettings() !== false)
      root._savePending = true;
  }

  NText {
    text: pluginApi.tr("settings.title")
    pointSize: Style.fontSizeL
    font.bold: true
  }

  NText {
    text: pluginApi.tr("settings.description")
    color: AtmoColor.mOnSurfaceVariant
    Layout.fillWidth: true
    wrapMode: Text.Wrap
  }

  NDivider {
    Layout.fillWidth: true
  }

  // Command list (scrollable)
  NPluginSettingsField {
    field: root.commandsField
    NScrollView {
      id: commandsScrollView
      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(commandsColumn.implicitHeight, 400)
      showScrollbarWhenScrollable: true
      gradientColor: "transparent"

      ColumnLayout {
        id: commandsColumn
        width: commandsScrollView.availableWidth
        spacing: Style.marginS

        Repeater {
          model: {
            void root.commandsRevision;
            return root.commands.length;
          }

          delegate: ColumnLayout {
            id: cmdDelegate
            required property int index

            Layout.fillWidth: true
            spacing: Style.marginS

            readonly property var cmd: {
              void root.commandsRevision;
              return index >= 0 && index < root.commands.length ? root.commands[index] : null;
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginM

              AtmoIconButton {
                icon: cmdDelegate.cmd ? cmdDelegate.cmd.icon : "terminal-2"
                tooltipText: pluginApi.tr("settings.chooseIcon")
                onClicked: {
                  iconPicker.activeIndex = cmdDelegate.index;
                  iconPicker.initialIcon = cmdDelegate.cmd ? cmdDelegate.cmd.icon : "terminal-2";
                  iconPicker.query = cmdDelegate.cmd ? cmdDelegate.cmd.icon : "";
                  iconPicker.open();
                }
              }

              NTextInput {
                Layout.fillWidth: true
                Layout.preferredWidth: 200
                placeholderText: pluginApi.tr("settings.commandName")
                text: cmdDelegate.cmd ? cmdDelegate.cmd.name : ""
                onEditCommitted: {
                  if (cmdDelegate.cmd && text !== cmdDelegate.cmd.name) {
                    root.setCommandField(cmdDelegate.index, "name", text);
                  }
                }
              }

              NTextInput {
                Layout.fillWidth: true
                Layout.preferredWidth: 300
                placeholderText: pluginApi.tr("settings.shellCommand")
                text: cmdDelegate.cmd ? cmdDelegate.cmd.command : ""
                onEditCommitted: {
                  if (cmdDelegate.cmd && text !== cmdDelegate.cmd.command) {
                    root.setCommandField(cmdDelegate.index, "command", text);
                  }
                }
              }

              AtmoIconButton {
                icon: "arrow-up"
                tooltipText: pluginApi.tr("settings.moveUp")
                enabled: cmdDelegate.index > 0
                onClicked: {
                  root.moveCommand(cmdDelegate.index, cmdDelegate.index - 1);
                }
              }

              AtmoIconButton {
                icon: "arrow-down"
                tooltipText: pluginApi.tr("settings.moveDown")
                enabled: cmdDelegate.index < root.commands.length - 1
                onClicked: {
                  root.moveCommand(cmdDelegate.index, cmdDelegate.index + 1);
                }
              }

              AtmoIconButton {
                icon: "trash"
                tooltipText: pluginApi.tr("settings.remove")
                onClicked: {
                  root.removeCommand(cmdDelegate.index);
                }
              }
            }
          }
        }
      }
    }

    AtmoIconPicker {
      id: iconPicker
      property int activeIndex: -1
      initialIcon: "terminal-2"
      onIconSelected: function (iconName) {
        if (activeIndex >= 0 && activeIndex < root.commands.length) {
          root.setCommandField(activeIndex, "icon", iconName);
        }
      }
    }

    NButton {
      text: pluginApi.tr("settings.add")
      icon: "plus"
      onClicked: {
        root.addCommand();
      }
    }
  }
}
