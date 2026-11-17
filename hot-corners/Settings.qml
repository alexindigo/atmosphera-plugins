import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets
import qs.Services.Actions

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var corners: [
    {key: "TopLeft", name: "Top left", icon: "arrow-up-left"},
    {key: "TopRight", name: "Top right", icon: "arrow-up-right"},
    {key: "BottomLeft", name: "Bottom left", icon: "arrow-down-left"},
    {key: "BottomRight", name: "Bottom right", icon: "arrow-down-right"}
  ]
  NSettingsBaseline {
    id: displayBaseline
    readonly property var staged: root.normalizedCorners(root.pluginApi?.pluginSettings?.corners || ({}))
  }
  property var staged: JSON.parse(JSON.stringify(displayBaseline.staged))
  readonly property bool settingsDirty: {
    if (displayBaseline.differs({staged: root.staged})) return true;
    for (var i = 0; i < cornerRows.count; i++) {
      var row = cornerRows.itemAt(i);
      if (row && row.customDirty) return true;
    }
    return false;
  }
  spacing: Style.marginL

  function normalizedCorners(value) {
    var result = JSON.parse(JSON.stringify(value));
    root.corners.forEach(function(corner) {
      if (result[corner.key] === undefined) result[corner.key] = "";
    });
    return result;
  }

  function stage(corner, command) {
    var next = Object.assign({}, root.staged);
    next[corner] = command;
    root.staged = next;
  }

  function actionByKey(key) {
    var actions = ActionRegistry.actions;
    for (var i = 0; i < actions.length; i++)
      if (actions[i].key === key) return actions[i];
    return null;
  }

  function saveSettings() {
    if (!pluginApi?.pluginSettings) return;
    for (var i = 0; i < cornerRows.count; i++)
      cornerRows.itemAt(i).commitCustomEditor();
    pluginApi.pluginSettings.corners = JSON.parse(JSON.stringify(root.staged));
    // This stages the page API; the popup owns the receipt-backed Apply.
    pluginApi.saveSettings();
  }

  ListModel { id: actionModel }
  function rebuildModel() {
    actionModel.clear();
    ActionRegistry.actions.forEach(function(action) {
      actionModel.append({key: action.key, name: action.label, description: action.description,
        icon: action.icon, section: action.section, group: action.group, command: action.command});
    });
  }
  Connections {
    target: ActionRegistry
    function onRevisionChanged() { root.rebuildModel(); }
  }
  Component.onCompleted: rebuildModel()

  Repeater {
    id: cornerRows
    model: root.corners
    delegate: ColumnLayout {
      id: cornerRow
      required property var modelData
      readonly property string command: root.staged[modelData.key] || ""
      readonly property var matched: ActionRegistry.match(command)
      readonly property string actionKey: matched ? matched.action.key : ""
      // Keep argument delegates alive while only argument values change.
      readonly property var action: root.actionByKey(actionKey)
      readonly property bool customDirty: actionField.customDirty
      function commitCustomEditor() { actionField.commitCustomEditor(); }
      function stageArgument(name, value) {
        if (!matched) return;
        var values = Object.assign({}, matched.values);
        values[name] = value;
        var composed = ActionRegistry.compose(action, values);
        if (composed !== "") root.stage(modelData.key, composed);
      }
      Layout.fillWidth: true
      Layout.minimumWidth: 0
      spacing: Style.marginS

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS
        AtmoIcon { icon: cornerRow.modelData.icon; pointSize: Style.fontSizeM }
        NText {
          text: cornerRow.modelData.name
          Layout.fillWidth: true
          Layout.minimumWidth: 0
          wrapMode: Text.NoWrap
          elide: Text.ElideRight
        }
      }
      NSearchableComboBox {
        id: actionField
        objectName: "hotCorner-" + cornerRow.modelData.key
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        stacked: true
        selectOnNavigation: false
        clearable: true
        customEntry: true
        popupHeight: 360
        model: actionModel
        currentKey: cornerRow.actionKey
        displayIcon: cornerRow.matched ? cornerRow.matched.action.icon : cornerRow.command !== "" ? "terminal" : "circle-dashed"
        displayText: cornerRow.matched ? ActionRegistry.displayLabel(cornerRow.matched.action, cornerRow.matched.values) : cornerRow.command !== "" ? "Custom command" : ""
        displaySubtitle: cornerRow.command
        placeholder: "No action"
        sectionRole: "section"
        groupRole: "group"
        searchRoles: ["name", "description", "command"]
        popupTitle: "Choose corner action"
        searchPlaceholder: "Search actions or type a command"
        noMatchLabel: "No matching actions"
        runCommandLabel: "Run command: %1"
        customEntryLabel: "Custom command..."
        customEditorTitle: "Custom command"
        customEditorConfirmText: "Use command"
        customEditorCancelText: "Cancel"
        customText: cornerRow.command
        onSelected: key => {
          var action = root.actionByKey(key);
          if (action) root.stage(cornerRow.modelData.key, ActionRegistry.compose(action, {}));
        }
        onCustomEntered: text => root.stage(cornerRow.modelData.key, text)
        onCleared: root.stage(cornerRow.modelData.key, "")
      }

      Repeater {
        model: cornerRow.action ? cornerRow.action.arguments : []
        delegate: RowLayout {
          id: argumentRow
          required property var modelData
          Layout.fillWidth: true
          Layout.minimumWidth: 0
          spacing: Style.marginM
          NText {
            text: argumentRow.modelData.label
            Layout.maximumWidth: cornerRow.width / 3
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
          }
          Loader {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            sourceComponent: argumentRow.modelData.type === "choice" ? choiceEditor : valueEditor
          }
          Component {
            id: choiceEditor
            NSearchableComboBox {
              objectName: "hotCorner-" + cornerRow.modelData.key + "-" + argumentRow.modelData.name
              stacked: true
              searchable: false
              selectOnNavigation: false
              popupTitle: argumentRow.modelData.label
              currentKey: cornerRow.matched ? String(cornerRow.matched.values[argumentRow.modelData.name]) : ""
              model: ListModel { id: choices }
              Component.onCompleted: argumentRow.modelData.choices.forEach(function(choice) {
                choices.append({key: choice.value, name: choice.label});
              })
              onSelected: key => cornerRow.stageArgument(argumentRow.modelData.name, key)
            }
          }
          Component {
            id: valueEditor
            Rectangle {
              // The validation frame owns its outline; the input owns editing.
              objectName: "hotCorner-" + cornerRow.modelData.key + "-" + argumentRow.modelData.name
              implicitHeight: valueInput.implicitHeight + Style.borderS * 2
              color: "transparent"
              radius: Style.iRadiusM
              border.width: Style.borderS
              border.color: valueInput.inputItem.acceptableInput ? "transparent" : AtmoColor.mError
              NTextInput {
                id: valueInput
                anchors.fill: parent
                anchors.margins: Style.borderS
                minimumInputWidth: 0
                text: cornerRow.matched ? String(cornerRow.matched.values[argumentRow.modelData.name]) : ""
                inputItem.validator: argumentRow.modelData.type === "number" ? numberValidator : null
                inputMethodHints: argumentRow.modelData.type === "number" ? Qt.ImhDigitsOnly : Qt.ImhNone
                onTextEdited: {
                  if (inputItem.acceptableInput)
                    cornerRow.stageArgument(argumentRow.modelData.name, argumentRow.modelData.type === "number" ? Number(text) : text);
                }
                IntValidator {
                  id: numberValidator
                  bottom: argumentRow.modelData.min === undefined ? -2147483648 : argumentRow.modelData.min
                  top: argumentRow.modelData.max === undefined ? 2147483647 : argumentRow.modelData.max
                }
              }
            }
          }
        }
      }
    }
  }
}
