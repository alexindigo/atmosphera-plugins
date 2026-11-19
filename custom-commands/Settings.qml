import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

  NSettingsBaseline {
    id: displayBaseline
    readonly property var commands: root.displayCommands()
  }
  readonly property bool settingsDirty: { root.commandsRevision; return displayBaseline.differs({commands: root.commands}); }
  property bool _savePending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current") return;
      root._savePending = false;
      Logger.i("CustomCommands", "Settings saved");
    }
  }

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    // Local mutable copy for editing
    property var commands: displayBaseline.commands
    property int commandsRevision: 0

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
        var source = cfg.commands ?? defaults.commands ?? [];
        return Array.prototype.map.call(source, function (row) {
            return Object.assign(Object.create(null), row, {name: row.name || "", command: row.command || "", icon: row.icon || "terminal-2"});
        });
    }

    function moveCommand(from, to) {
        if (from < 0 || to < 0 || from >= root.commands.length || to >= root.commands.length || from === to) return;
        var rows = root.commands.slice();
        rows.splice(to, 0, rows.splice(from, 1)[0]);
        root.commands = rows; root.commandsRevision++;
    }
    function removeCommand(index) {
        if (index < 0 || index >= root.commands.length) return;
        var rows = root.commands.slice(); rows.splice(index, 1);
        root.commands = rows; root.commandsRevision++;
    }
    function addCommand() {
        root.commands = root.commands.concat([{name: "", command: "", icon: "terminal-2"}]);
        root.commandsRevision++;
    }

    function setCommandField(index, key, value) {
        if (index < 0 || index >= root.commands.length) return;
        var rows = root.commands.slice();
        rows[index] = Object.assign(Object.create(null), rows[index], {[key]: value});
        root.commands = rows;
        root.commandsRevision++;
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("CustomCommands", "Cannot save settings: pluginApi is null");
            return;
        }

        var valid = [];
        var displayed = [];
        for (var i = 0; i < commands.length; i++) {
            var name = commands[i].name.trim();
            var command = commands[i].command.trim();
            if (name !== "" || command !== "") {
                var row = Object.assign(Object.create(null), commands[i], {
                    "name": name,
                    "command": command,
                    "icon": commands[i].icon || "terminal-2"
                });
                valid.push(row);
                displayed.push(row);
            } else {
                // Filtered input is still the user's unfinished local work.
                displayed.push(commands[i]);
            }
        }

        root.commands = displayed;
        root.commandsRevision++;
        pluginApi.pluginSettings.commands = valid;
        if (pluginApi.saveSettings() !== false) root._savePending = true;
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
                            onTextChanged: {
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
                            onTextChanged: {
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
