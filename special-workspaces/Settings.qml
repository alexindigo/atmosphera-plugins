import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

  NSettingsBaseline {
    id: displayBaseline
    readonly property string mainIcon: cfg.mainIcon ?? defaults.mainIcon
    readonly property string expandDirection: cfg.expandDirection ?? defaults.expandDirection
    readonly property bool drawer: cfg.drawer ?? defaults.drawer
    readonly property bool hideEmpty: cfg.hideEmptyWorkspaces ?? defaults.hideEmptyWorkspaces
    readonly property string primarySymbolColor: cfg.primarySymbolColor ?? defaults.primarySymbolColor
    readonly property bool primaryShowPill: cfg.primaryShowPill ?? defaults.primaryShowPill ?? true
    readonly property string primaryPillColor: cfg.primaryPillColor ?? defaults.primaryPillColor
    readonly property real primarySize: cfg.primarySize ?? defaults.primarySize
    readonly property real primaryBorderRadius: cfg.primaryBorderRadius ?? defaults.primaryBorderRadius ?? 1.0
    readonly property string primaryFocusColor: cfg.primaryFocusColor ?? defaults.primaryFocusColor ?? "primary"
    readonly property string panelBackgroundColor: cfg.panelBackgroundColor ?? defaults.panelBackgroundColor ?? "none"
    readonly property bool panelBackgroundEnabled: cfg.panelBackgroundEnabled ?? defaults.panelBackgroundEnabled ?? true
    readonly property var workspaces: root.displayWorkspaces()
    ranges: [NSettingsRange { field: "primaryBorderRadius"; from: rangePrimaryBorderRadius.from; to: rangePrimaryBorderRadius.to }, NSettingsRange { field: "primarySize"; from: rangePrimarySize.from; to: rangePrimarySize.to }]
  }
  readonly property bool settingsDirty: { root.workspacesRevision; return displayBaseline.differs({mainIcon: root.mainIcon, expandDirection: root.expandDirection, drawer: root.drawer, hideEmpty: root.hideEmpty, primarySymbolColor: root.primarySymbolColor, primaryShowPill: root.primaryShowPill, primaryPillColor: root.primaryPillColor, primarySize: root.primarySize, primaryBorderRadius: root.primaryBorderRadius, primaryFocusColor: root.primaryFocusColor, panelBackgroundColor: root.panelBackgroundColor, panelBackgroundEnabled: root.panelBackgroundEnabled, workspaces: root.workspaces}); }
  property bool _savePending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current") return;
      root._savePending = false;
      Logger.i("SpecialWorkspaces", "Settings saved");
    }
  }

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property string mainIcon: displayBaseline.mainIcon
    property string expandDirection: displayBaseline.expandDirection
    property bool drawer: displayBaseline.drawer
    property bool hideEmpty: displayBaseline.hideEmpty
    property string primarySymbolColor: displayBaseline.primarySymbolColor
    property bool primaryShowPill: displayBaseline.primaryShowPill
    property string primaryPillColor: displayBaseline.primaryPillColor
    property real primarySize: displayBaseline.project("primarySize")
    property real primaryBorderRadius: displayBaseline.project("primaryBorderRadius")
    property string primaryFocusColor: displayBaseline.primaryFocusColor
    property string panelBackgroundColor: displayBaseline.panelBackgroundColor
    property bool panelBackgroundEnabled: displayBaseline.panelBackgroundEnabled

    readonly property string barPosition: Settings.getBarPositionForScreen()
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property bool isPerpendicular: (isBarVertical && (root.expandDirection === "left" || root.expandDirection === "right")) ||
                                            (!isBarVertical && (root.expandDirection === "up" || root.expandDirection === "down"))

    // Local mutable copy for editing
    property var workspaces: displayBaseline.workspaces
    property int workspacesRevision: 0

    // Track which workspace rows are expanded
    property var expandedIndices: ({})

    spacing: Style.marginL

    Component.onCompleted: {
        loadWorkspaces();
    }

    NSettingsRange { id: workspaceSizeRange; field: "workspace-size"; from: 0.3; to: 1.0 }
    NSettingsRange { id: workspaceRadiusRange; field: "workspace-radius"; from: 0; to: 1.0 }

    function setWorkspaceField(index, key, value) {
        if (index < 0 || index >= root.workspaces.length) return;
        var rows = root.workspaces.slice();
        rows[index] = Object.assign(Object.create(null), rows[index], {[key]: value});
        root.workspaces = rows;
        root.workspacesRevision++;
    }

    function workspaceRow(row) {
        return Object.assign(Object.create(null), row, {
            name: row.name || "", icon: row.icon || "star", symbolColor: row.symbolColor ?? "none",
            showPill: row.showPill ?? true, pillColor: row.pillColor ?? "primary",
            size: workspaceSizeRange.project(row.size ?? 0.9),
            borderRadius: workspaceRadiusRange.project(row.borderRadius ?? 1.0), focusColor: row.focusColor ?? "primary"
        });
    }
    function addWorkspace() {
        root.workspaces = root.workspaces.concat([root.workspaceRow({})]); root.workspacesRevision++;
    }
    function removeWorkspace(index) {
        if (index < 0 || index >= root.workspaces.length) return;
        var rows = root.workspaces.slice(); rows.splice(index, 1);
        root.workspaces = rows; root.workspacesRevision++;
    }

    function displayWorkspaces() {
      var src = cfg.workspaces ?? defaults.workspaces ?? [];
      if (!src || typeof src.slice !== "function") return [];
      var rows = [];
      for (var index = 0; index < src.length; index++) rows.push(root.workspaceRow(src[index]));
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

        var valid = [];
        var displayed = [];
        for (var index = 0; index < root.workspaces.length; index++) {
            var row = root.workspaceRow(root.workspaces[index]);
            row.name = row.name.trim();
            if (row.name !== "") {
                valid.push(row);
                displayed.push(row);
            } else {
                // An unnamed row may contain styles the user is still editing.
                displayed.push(root.workspaces[index]);
            }
        }

        pluginApi.pluginSettings.mainIcon = root.mainIcon;
        pluginApi.pluginSettings.expandDirection = root.expandDirection;
        pluginApi.pluginSettings.drawer = root.drawer;
        pluginApi.pluginSettings.hideEmptyWorkspaces = root.hideEmpty;
        pluginApi.pluginSettings.primarySymbolColor = root.primarySymbolColor;
        pluginApi.pluginSettings.primaryShowPill = root.primaryShowPill;
        pluginApi.pluginSettings.primaryPillColor = root.primaryPillColor;
        pluginApi.pluginSettings.primarySize = root.primarySize;
        pluginApi.pluginSettings.primaryBorderRadius = root.primaryBorderRadius;
        pluginApi.pluginSettings.primaryFocusColor = root.primaryFocusColor;
        pluginApi.pluginSettings.panelBackgroundColor = root.panelBackgroundColor;
        pluginApi.pluginSettings.panelBackgroundEnabled = root.panelBackgroundEnabled;
        root.workspaces = displayed;
        root.workspacesRevision++;
        pluginApi.pluginSettings.workspaces = valid;
        if (pluginApi.saveSettings() !== false) root._savePending = true;
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

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.label")
        description: pluginApi?.tr("settings.drawer.tooltip")
        checked: root.drawer
        onToggled: checked => root.drawer = checked
    }

    RowLayout {
        visible: root.drawer
        spacing: Style.marginM

        AtmoIcon {
            Layout.alignment: Qt.AlignVCenter
            icon: root.mainIcon
            pointSize: Style.fontSizeXL
        }

        NTextInput {
            id: mainIconInput
            Layout.preferredWidth: 140
            label: pluginApi?.tr("settings.drawer.mainIcon.label")
            text: root.mainIcon
            onTextChanged: {
                if (text !== root.mainIcon) {
                    root.mainIcon = text;
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
            root.mainIcon = iconName;
            mainIconInput.text = iconName;
        }
    }

    NColorChoice {
        visible: root.drawer
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.symbolColor.label")
        description: pluginApi?.tr("settings.drawer.symbolColor.description")
        currentKey: root.primarySymbolColor
        onSelected: key => { root.primarySymbolColor = key; }
        defaultValue: "none"
    }

    NToggle {
        visible: root.drawer
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.showPill.label")
        description: pluginApi?.tr("settings.drawer.showPill.description")
        checked: root.primaryShowPill
        onToggled: checked => { root.primaryShowPill = checked; }
        defaultValue: true
    }

    NColorChoice {
        visible: root.drawer && root.primaryShowPill
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.pillColor.label")
        description: pluginApi?.tr("settings.drawer.pillColor.description")
        currentKey: root.primaryPillColor
        onSelected: key => { root.primaryPillColor = key; }
        defaultValue: "none"
    }

    NColorChoice {
        visible: root.drawer
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.focusColor.label")
        description: pluginApi?.tr("settings.drawer.focusColor.description")
        currentKey: root.primaryFocusColor
        onSelected: key => { root.primaryFocusColor = key; }
        defaultValue: "primary"
    }

    ColumnLayout {
        visible: root.drawer
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.drawer.borderRadius.label")
            description: pluginApi?.tr("settings.drawer.borderRadius.description", { value: Math.round(root.primaryBorderRadius * 100) })
        }

        NSlider {
          id: rangePrimaryBorderRadius
          objectName: "settings-range-primaryBorderRadius"
            Layout.fillWidth: true
            from: 0
            to: 1.0
            stepSize: 0.05
            value: root.primaryBorderRadius
            onMoved: root.primaryBorderRadius = value
        }
    }

    ColumnLayout {
        visible: root.drawer
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.drawer.size.label")
            description: pluginApi?.tr("settings.drawer.size.description", { value: Math.round(root.primarySize * 100) })
        }

        NSlider {
          id: rangePrimarySize
          objectName: "settings-range-primarySize"
            Layout.fillWidth: true
            from: 0.3
            to: 1.0
            stepSize: 0.05
            value: root.primarySize
            onMoved: root.primarySize = value
        }
    }

    NComboBox {
        visible: root.drawer
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.expandDirection.label")
        description: pluginApi?.tr("settings.drawer.expandDirection.description")
        model: [
            { "key": "down", "name": pluginApi?.tr("settings.drawer.expandDirection.down") },
            { "key": "up", "name": pluginApi?.tr("settings.drawer.expandDirection.up") },
            { "key": "right", "name": pluginApi?.tr("settings.drawer.expandDirection.right") },
            { "key": "left", "name": pluginApi?.tr("settings.drawer.expandDirection.left") }
        ]
        currentKey: root.expandDirection
        onSelected: function (key) {
            root.expandDirection = key;
        }
        defaultValue: "down"
    }

    NToggle {
        visible: root.drawer && root.isPerpendicular
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.panelBackground.enabled.label")
        description: pluginApi?.tr("settings.drawer.panelBackground.enabled.description")
        checked: root.panelBackgroundEnabled
        onToggled: checked => { root.panelBackgroundEnabled = checked; }
        defaultValue: true
    }

    NColorChoice {
        visible: root.drawer && root.isPerpendicular && root.panelBackgroundEnabled
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.drawer.panelBackgroundColor.label")
        description: pluginApi?.tr("settings.drawer.panelBackgroundColor.description")
        currentKey: root.panelBackgroundColor
        onSelected: key => { root.panelBackgroundColor = key; }
        defaultValue: "none"
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

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.workspaces.hideEmpty.label")
        description: pluginApi?.tr("settings.workspaces.hideEmpty.description")
        checked: root.hideEmpty
        onToggled: checked => root.hideEmpty = checked
    }

    // Workspace list
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
                    onTextChanged: {
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
                    onTextChanged: {
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
                        description: pluginApi?.tr("settings.workspaces.size.description", { value: Math.round((wsRow.ws ? wsRow.ws.size ?? 0.9 : 0.9) * 100) })
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
                        description: pluginApi?.tr("settings.workspaces.borderRadius.description", { value: Math.round((wsRow.ws ? wsRow.ws.borderRadius ?? 1.0 : 1.0) * 100) })
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
