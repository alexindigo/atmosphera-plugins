import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _savePending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._savePending = false;
      Logger.i("SpecialWorkspaces", "Settings saved");
    }
  }

  property var pluginApi: null
  readonly property var mainIconField: pluginApi?.field("mainIcon") ?? null
  readonly property var expandDirectionField: pluginApi?.field("expandDirection") ?? null
  readonly property var drawerField: pluginApi?.field("drawer") ?? null
  readonly property var hideEmptyWorkspacesField: pluginApi?.field("hideEmptyWorkspaces") ?? null
  readonly property var primarySymbolColorField: pluginApi?.field("primarySymbolColor") ?? null
  readonly property var primaryShowPillField: pluginApi?.field("primaryShowPill") ?? null
  readonly property var primaryPillColorField: pluginApi?.field("primaryPillColor") ?? null
  readonly property var primarySizeField: pluginApi?.field("primarySize") ?? null
  readonly property var primaryBorderRadiusField: pluginApi?.field("primaryBorderRadius") ?? null
  readonly property var primaryFocusColorField: pluginApi?.field("primaryFocusColor") ?? null
  readonly property var panelBackgroundColorField: pluginApi?.field("panelBackgroundColor") ?? null
  readonly property var panelBackgroundEnabledField: pluginApi?.field("panelBackgroundEnabled") ?? null

  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string mainIcon: root.mainIconField?.value ?? defaults.mainIcon
  readonly property string expandDirection: root.expandDirectionField?.value ?? defaults.expandDirection
  readonly property bool drawer: root.drawerField?.value ?? defaults.drawer
  readonly property bool hideEmpty: root.hideEmptyWorkspacesField?.value ?? defaults.hideEmptyWorkspaces
  readonly property string primarySymbolColor: root.primarySymbolColorField?.value ?? defaults.primarySymbolColor
  readonly property bool primaryShowPill: root.primaryShowPillField?.value ?? true
  readonly property string primaryPillColor: root.primaryPillColorField?.value ?? defaults.primaryPillColor
  readonly property real primarySize: root.primarySizeField?.value ?? defaults.primarySize
  readonly property real primaryBorderRadius: root.primaryBorderRadiusField?.value ?? 1.0
  readonly property string primaryFocusColor: root.primaryFocusColorField?.value ?? "primary"
  readonly property string panelBackgroundColor: root.panelBackgroundColorField?.value ?? "none"
  readonly property bool panelBackgroundEnabled: root.panelBackgroundEnabledField?.value ?? true

  readonly property string barPosition: Settings.getBarPositionForScreen()
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property bool isPerpendicular: (isBarVertical && (root.expandDirection === "left" || root.expandDirection === "right")) || (!isBarVertical && (root.expandDirection === "up" || root.expandDirection === "down"))

  readonly property var workspacesField: pluginApi?.field("workspaces") ?? null
  // Row editor buffer: unnamed rows stay local; every explicit row operation
  // submits the complete list of named rows as one atomic intent.
  property var workspaces: []
  property int workspacesRevision: 0
  readonly property var workspacesValue: workspacesField?.value ?? []
  onWorkspacesValueChanged: {
    if (JSON.stringify(root.validRows(root.workspaces)) !== JSON.stringify(root.validRows(root.displayWorkspaces())))
      root.loadWorkspaces();
  }
  function validRows(rows) {
    var valid = [];
    for (var index = 0; index < rows.length; index++) {
      var row = root.workspaceRow(rows[index]);
      row.name = row.name.trim();
      if (row.name !== "")
        valid.push(row);
    }
    return valid;
  }
  function submitWorkspaces() {
    return root.workspacesField.set(root.validRows(root.workspaces));
  }

  // Track which workspace rows are expanded
  property var expandedIndices: ({})

  spacing: Style.marginL

  Component.onCompleted: {
    loadWorkspaces();
  }

  NSettingsRange {
    id: workspaceSizeRange
    field: "workspace-size"
    from: 0.3
    to: 1.0
  }
  NSettingsRange {
    id: workspaceRadiusRange
    field: "workspace-radius"
    from: 0
    to: 1.0
  }

  function setWorkspaceField(index, key, value) {
    if (index < 0 || index >= root.workspaces.length)
      return;
    var rows = root.workspaces.slice();
    rows[index] = Object.assign(Object.create(null), rows[index], {
                                  [key]: value
                                });
    root.workspaces = rows;
    root.workspacesRevision++;
    root.submitWorkspaces();
  }

  function workspaceRow(row) {
    return Object.assign(Object.create(null), row, {
                           name: row.name || "",
                           icon: row.icon || "star",
                           symbolColor: row.symbolColor ?? "none",
                           showPill: row.showPill ?? true,
                           pillColor: row.pillColor ?? "primary",
                           size: workspaceSizeRange.project(row.size ?? 0.9),
                           borderRadius: workspaceRadiusRange.project(row.borderRadius ?? 1.0),
                           focusColor: row.focusColor ?? "primary"
                         });
  }
  function addWorkspace() {
    root.workspaces = root.workspaces.concat([root.workspaceRow({})]);
    root.workspacesRevision++;
  }
  function removeWorkspace(index) {
    if (index < 0 || index >= root.workspaces.length)
      return;
    var rows = root.workspaces.slice();
    rows.splice(index, 1);
    root.workspaces = rows;
    root.workspacesRevision++;
    root.submitWorkspaces();
  }

  function displayWorkspaces() {
    var src = root.workspacesValue;
    if (!src || typeof src.slice !== "function")
      return [];
    var rows = [];
    for (var index = 0; index < src.length; index++)
      rows.push(root.workspaceRow(src[index]));
    return rows;
  }

  function loadWorkspaces() {
    workspaces = root.displayWorkspaces();
    workspacesRevision++;
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("SpecialWorkspaces", "Cannot save settings: pluginApi is null");
      return;
    }

    root.workspacesRevision++;
    if (pluginApi.saveSettings() !== false)
      root._savePending = true;
  }

  // ── Title ──

  NText {
    text: pluginApi?.tr("settings.title")
    pointSize: Style.fontSizeL
    font.bold: true
  }

  NText {
    text: pluginApi?.tr("settings.description")
    color: AtmoColor.mOnSurfaceVariant
    Layout.fillWidth: true
    wrapMode: Text.Wrap
  }

  // ── Drawer Section ──

  NText {
    text: pluginApi?.tr("settings.drawer.title")
    pointSize: Style.fontSizeM
    font.bold: true
  }

  NPluginSettingsField {
    field: root.drawerField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.drawer.label")
      description: pluginApi?.tr("settings.drawer.tooltip")
      checked: root.drawer
      onToggled: checked => root.drawerField.set(checked)
    }
  }

  RowLayout {
    visible: root.drawer
    spacing: Style.marginM

    AtmoIcon {
      Layout.alignment: Qt.AlignVCenter
      icon: root.mainIcon
      pointSize: Style.fontSizeXL
    }

    NPluginSettingsField {
      field: root.mainIconField
      NTextInput {
        id: mainIconInput
        Layout.preferredWidth: 140
        label: pluginApi?.tr("settings.drawer.mainIcon.label")
        text: root.mainIcon
        onEditCommitted: {
          if (text !== root.mainIcon) {
            root.mainIconField.set(text);
          }
        }
      }
    }

    AtmoIconButton {
      icon: "search"
      tooltipText: pluginApi?.tr("settings.drawer.mainIcon.browseTooltip")
      onClicked: {
        mainIconPicker.open();
      }
    }
  }

  AtmoIconPicker {
    id: mainIconPicker
    initialIcon: root.mainIcon
    onIconSelected: function (iconName) {
      root.mainIconField.set(iconName);
      mainIconInput.text = Qt.binding(function () {
        return root.mainIcon;
      });
    }
  }

  NPluginSettingsField {
    field: root.primarySymbolColorField
    visible: root.drawer
    NColorChoice {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.drawer.symbolColor.label")
      description: pluginApi?.tr("settings.drawer.symbolColor.description")
      currentKey: root.primarySymbolColor
      onSelected: key => {
        root.primarySymbolColorField.set(key);
      }
      defaultValue: "none"
    }
  }

  NPluginSettingsField {
    field: root.primaryShowPillField
    visible: root.drawer
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.drawer.showPill.label")
      description: pluginApi?.tr("settings.drawer.showPill.description")
      checked: root.primaryShowPill
      onToggled: checked => {
        root.primaryShowPillField.set(checked);
      }
      defaultValue: true
    }
  }

  NPluginSettingsField {
    field: root.primaryPillColorField
    visible: root.drawer && root.primaryShowPill
    NColorChoice {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.drawer.pillColor.label")
      description: pluginApi?.tr("settings.drawer.pillColor.description")
      currentKey: root.primaryPillColor
      onSelected: key => {
        root.primaryPillColorField.set(key);
      }
      defaultValue: "none"
    }
  }

  NPluginSettingsField {
    field: root.primaryFocusColorField
    visible: root.drawer
    NColorChoice {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.drawer.focusColor.label")
      description: pluginApi?.tr("settings.drawer.focusColor.description")
      currentKey: root.primaryFocusColor
      onSelected: key => {
        root.primaryFocusColorField.set(key);
      }
      defaultValue: "primary"
    }
  }

  ColumnLayout {
    visible: root.drawer
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.drawer.borderRadius.label")
      description: pluginApi?.tr("settings.drawer.borderRadius.description", {
                                   value: Math.round(root.primaryBorderRadius * 100)
                                 })
    }

    NPluginSettingsField {
      field: root.primaryBorderRadiusField
      NSlider {
        id: rangePrimaryBorderRadius
        objectName: "settings-range-primaryBorderRadius"
        Layout.fillWidth: true
        from: 0
        to: 1.0
        stepSize: 0.05
        value: root.primaryBorderRadius
        onMoved: root.primaryBorderRadiusField.set(value)
      }
    }
  }

  ColumnLayout {
    visible: root.drawer
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.drawer.size.label")
      description: pluginApi?.tr("settings.drawer.size.description", {
                                   value: Math.round(root.primarySize * 100)
                                 })
    }

    NPluginSettingsField {
      field: root.primarySizeField
      NSlider {
        id: rangePrimarySize
        objectName: "settings-range-primarySize"
        Layout.fillWidth: true
        from: 0.3
        to: 1.0
        stepSize: 0.05
        value: root.primarySize
        onMoved: root.primarySizeField.set(value)
      }
    }
  }

  NPluginSettingsField {
    field: root.expandDirectionField
    visible: root.drawer
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.drawer.expandDirection.label")
      description: pluginApi?.tr("settings.drawer.expandDirection.description")
      model: [
        {
          "key": "down",
          "name": pluginApi?.tr("settings.drawer.expandDirection.down")
        },
        {
          "key": "up",
          "name": pluginApi?.tr("settings.drawer.expandDirection.up")
        },
        {
          "key": "right",
          "name": pluginApi?.tr("settings.drawer.expandDirection.right")
        },
        {
          "key": "left",
          "name": pluginApi?.tr("settings.drawer.expandDirection.left")
        }
      ]
      currentKey: root.expandDirection
      onSelected: function (key) {
        root.expandDirectionField.set(key);
      }
      defaultValue: "down"
    }
  }

  NPluginSettingsField {
    field: root.panelBackgroundEnabledField
    visible: root.drawer && root.isPerpendicular
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.drawer.panelBackground.enabled.label")
      description: pluginApi?.tr("settings.drawer.panelBackground.enabled.description")
      checked: root.panelBackgroundEnabled
      onToggled: checked => {
        root.panelBackgroundEnabledField.set(checked);
      }
      defaultValue: true
    }
  }

  NPluginSettingsField {
    field: root.panelBackgroundColorField
    visible: root.drawer && root.isPerpendicular && root.panelBackgroundEnabled
    NColorChoice {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.drawer.panelBackgroundColor.label")
      description: pluginApi?.tr("settings.drawer.panelBackgroundColor.description")
      currentKey: root.panelBackgroundColor
      onSelected: key => {
        root.panelBackgroundColorField.set(key);
      }
      defaultValue: "none"
    }
  }

  // ── Workspaces Section ──

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    text: pluginApi?.tr("settings.workspaces.title")
    pointSize: Style.fontSizeM
    font.bold: true
  }

  NPluginSettingsField {
    field: root.hideEmptyWorkspacesField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.workspaces.hideEmpty.label")
      description: pluginApi?.tr("settings.workspaces.hideEmpty.description")
      checked: root.hideEmpty
      onToggled: checked => root.hideEmptyWorkspacesField.set(checked)
    }
  }

  // Workspace list
  NPluginSettingsField {
    field: root.workspacesField
    Repeater {
      model: {
        void root.workspacesRevision;
        return root.workspaces.length;
      }

      delegate: ColumnLayout {
        id: wsRow
        required property int index

        Layout.fillWidth: true
        spacing: Style.marginS

        readonly property var ws: {
          void root.workspacesRevision;
          return index >= 0 && index < root.workspaces.length ? root.workspaces[index] : null;
        }

        readonly property bool wsExpanded: root.expandedIndices[index] === true

        // ── Collapsed row (always visible) ──
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          AtmoIcon {
            Layout.alignment: Qt.AlignVCenter
            icon: wsRow.ws ? wsRow.ws.icon : "star"
            pointSize: Style.fontSizeXL
          }

          NTextInput {
            Layout.fillWidth: true
            Layout.preferredWidth: 140
            placeholderText: pluginApi?.tr("settings.workspaces.namePlaceholder")
            text: wsRow.ws ? wsRow.ws.name : ""
            onEditCommitted: {
              if (wsRow.ws && text !== wsRow.ws.name) {
                root.setWorkspaceField(wsRow.index, "name", text);
              }
            }
          }

          NTextInput {
            id: iconInput
            Layout.preferredWidth: 120
            placeholderText: pluginApi?.tr("settings.workspaces.iconPlaceholder")
            text: wsRow.ws ? wsRow.ws.icon : ""
            onEditCommitted: {
              if (wsRow.ws && text !== wsRow.ws.icon) {
                root.setWorkspaceField(wsRow.index, "icon", text);
              }
            }

            Connections {
              target: root
              function onWorkspacesRevisionChanged() {
                if (wsRow.ws && iconInput.text !== wsRow.ws.icon) {
                  iconInput.text = wsRow.ws.icon;
                }
              }
            }
          }

          AtmoIconButton {
            icon: "search"
            tooltipText: pluginApi?.tr("settings.workspaces.browseTooltip")
            onClicked: {
              iconPicker.activeIndex = wsRow.index;
              iconPicker.initialIcon = wsRow.ws ? wsRow.ws.icon : "star";
              iconPicker.query = wsRow.ws ? wsRow.ws.icon : "";
              iconPicker.open();
            }
          }

          AtmoIconButton {
            icon: wsRow.wsExpanded ? "chevron-up" : "chevron-down"
            tooltipText: pluginApi?.tr("settings.workspaces.expandTooltip")
            onClicked: {
              var copy = Object.assign({}, root.expandedIndices);
              copy[wsRow.index] = !wsRow.wsExpanded;
              root.expandedIndices = copy;
            }
          }

          AtmoIconButton {
            icon: "trash"
            tooltipText: pluginApi?.tr("settings.workspaces.removeTooltip")
            onClicked: {
              var copy = Object.assign({}, root.expandedIndices);
              delete copy[wsRow.index];
              root.expandedIndices = copy;
              root.removeWorkspace(wsRow.index);
            }
          }
        }

        // ── Expanded section (per-workspace styling) ──
        ColumnLayout {
          visible: wsRow.wsExpanded
          Layout.fillWidth: true
          Layout.leftMargin: Style.marginL
          spacing: Style.marginM

          NColorChoice {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.workspaces.symbolColor.label")
            description: pluginApi?.tr("settings.workspaces.symbolColor.description")
            currentKey: wsRow.ws ? wsRow.ws.symbolColor ?? "none" : "none"
            onSelected: key => {
              root.setWorkspaceField(wsRow.index, "symbolColor", key);
            }
            defaultValue: "none"
          }

          NToggle {
            id: showPillToggle
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.workspaces.showPill.label")
            description: pluginApi?.tr("settings.workspaces.showPill.description")
            checked: (wsRow.ws ? wsRow.ws.showPill ?? true : true)
            onToggled: checked => {
              root.setWorkspaceField(wsRow.index, "showPill", checked);
            }
            defaultValue: true
          }

          NColorChoice {
            visible: (wsRow.ws ? wsRow.ws.showPill ?? true : true)
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.workspaces.pillColor.label")
            description: pluginApi?.tr("settings.workspaces.pillColor.description")
            currentKey: wsRow.ws ? wsRow.ws.pillColor ?? "primary" : "primary"
            onSelected: key => {
              root.setWorkspaceField(wsRow.index, "pillColor", key);
            }
            defaultValue: "primary"
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NLabel {
              label: pluginApi?.tr("settings.workspaces.size.label")
              description: pluginApi?.tr("settings.workspaces.size.description", {
                                           value: Math.round((wsRow.ws ? wsRow.ws.size ?? 0.9 : 0.9) * 100)
                                         })
            }

            NSlider {
              objectName: "workspace-size-" + wsRow.index
              Layout.fillWidth: true
              from: workspaceSizeRange.from
              to: workspaceSizeRange.to
              stepSize: 0.05
              value: wsRow.ws ? wsRow.ws.size ?? 0.9 : 0.9
              onMoved: {
                root.setWorkspaceField(wsRow.index, "size", value);
              }
            }
          }

          NColorChoice {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.workspaces.focusColor.label")
            description: pluginApi?.tr("settings.workspaces.focusColor.description")
            currentKey: wsRow.ws ? wsRow.ws.focusColor ?? "primary" : "primary"
            onSelected: key => {
              root.setWorkspaceField(wsRow.index, "focusColor", key);
            }
            defaultValue: "primary"
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NLabel {
              label: pluginApi?.tr("settings.workspaces.borderRadius.label")
              description: pluginApi?.tr("settings.workspaces.borderRadius.description", {
                                           value: Math.round((wsRow.ws ? wsRow.ws.borderRadius ?? 1.0 : 1.0) * 100)
                                         })
            }

            NSlider {
              objectName: "workspace-radius-" + wsRow.index
              Layout.fillWidth: true
              from: workspaceRadiusRange.from
              to: workspaceRadiusRange.to
              stepSize: 0.05
              value: wsRow.ws ? wsRow.ws.borderRadius ?? 1.0 : 1.0
              onMoved: {
                root.setWorkspaceField(wsRow.index, "borderRadius", value);
              }
            }
          }
        }
      }
    }

    AtmoIconPicker {
      id: iconPicker
      property int activeIndex: -1
      initialIcon: "star"
      onIconSelected: function (iconName) {
        if (activeIndex >= 0 && activeIndex < root.workspaces.length) {
          root.setWorkspaceField(activeIndex, "icon", iconName);
        }
      }
    }

    NButton {
      text: pluginApi?.tr("settings.workspaces.add")
      icon: "plus"
      onClicked: {
        root.addWorkspace();
      }
    }
  }
}
