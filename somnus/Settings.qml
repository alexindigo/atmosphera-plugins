import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property string editIconColor: displayBaseline.editIconColor
    property string editHoverColor: displayBaseline.editHoverColor
    property real editBtnWidth: displayBaseline.project("editBtnWidth")
    property real editBtnHeight: displayBaseline.project("editBtnHeight")
    property real editBtnSpacing: displayBaseline.project("editBtnSpacing")
    property real editBtnOpacity: displayBaseline.project("editBtnOpacity")
    property bool editUseOverlay: displayBaseline.editUseOverlay
    property bool editAnimationsEnabled: displayBaseline.editAnimationsEnabled
    property bool editLockOnSuspend: displayBaseline.editLockOnSuspend
    property real editHoverDesaturation: displayBaseline.project("editHoverDesaturation")
    property real editOverlayBlur: displayBaseline.project("editOverlayBlur")
    property real editOverlayTint: displayBaseline.project("editOverlayTint")
    property real editPanelTint: displayBaseline.project("editPanelTint")

    NSettingsBaseline {
        ranges: [
          NSettingsRange { field: "editBtnWidth"; from: rangeEditBtnWidth.from; to: rangeEditBtnWidth.to },
          NSettingsRange { field: "editBtnHeight"; from: rangeEditBtnHeight.from; to: rangeEditBtnHeight.to },
          NSettingsRange { field: "editBtnSpacing"; from: rangeEditBtnSpacing.from; to: rangeEditBtnSpacing.to },
          NSettingsRange { field: "editBtnOpacity"; from: rangeEditBtnOpacity.from; to: rangeEditBtnOpacity.to },
          NSettingsRange { field: "editHoverDesaturation"; from: rangeEditHoverDesaturation.from / 100; to: rangeEditHoverDesaturation.to / 100 },
          NSettingsRange { field: "editOverlayBlur"; from: rangeEditOverlayBlur.from; to: rangeEditOverlayBlur.to },
          NSettingsRange { field: "editOverlayTint"; from: rangeEditOverlayTint.from; to: rangeEditOverlayTint.to },
          NSettingsRange { field: "editPanelTint"; from: rangeEditPanelTint.from; to: rangeEditPanelTint.to }
        ]
        id: displayBaseline
        readonly property string editIconColor: cfg.iconColor ?? defaults.iconColor ?? "primary"
        readonly property string editHoverColor: cfg.hoverColor ?? defaults.hoverColor ?? "primary"
        readonly property real editBtnWidth: cfg.buttonWidth ?? defaults.buttonWidth ?? 470
        readonly property real editBtnHeight: cfg.buttonHeight ?? defaults.buttonHeight ?? 280
        readonly property real editBtnSpacing: cfg.buttonSpacing ?? defaults.buttonSpacing ?? 20
        readonly property real editBtnOpacity: cfg.buttonOpacity ?? defaults.buttonOpacity ?? 0.50
        readonly property bool editUseOverlay: cfg.useOverlay ?? defaults.useOverlay ?? true
        readonly property bool editAnimationsEnabled: cfg.animationsEnabled ?? defaults.animationsEnabled ?? true
        readonly property bool editLockOnSuspend: cfg.lockOnSuspend ?? defaults.lockOnSuspend ?? true
        readonly property real editHoverDesaturation: cfg.hoverDesaturation ?? defaults.hoverDesaturation ?? 0.0
        readonly property real editOverlayBlur: cfg.overlayBlur ?? defaults.overlayBlur ?? 0.75
        readonly property real editOverlayTint: cfg.overlayTint ?? defaults.overlayTint ?? 0.6
        readonly property real editPanelTint: cfg.panelTint ?? defaults.panelTint ?? 0.7
    }
    readonly property bool settingsDirty: displayBaseline.differs({editIconColor: root.editIconColor, editHoverColor: root.editHoverColor, editBtnWidth: root.editBtnWidth, editBtnHeight: root.editBtnHeight, editBtnSpacing: root.editBtnSpacing, editBtnOpacity: root.editBtnOpacity, editUseOverlay: root.editUseOverlay, editAnimationsEnabled: root.editAnimationsEnabled, editLockOnSuspend: root.editLockOnSuspend, editHoverDesaturation: root.editHoverDesaturation, editOverlayBlur: root.editOverlayBlur, editOverlayTint: root.editOverlayTint, editPanelTint: root.editPanelTint})

    spacing: Style.marginM

    NText {
        text: pluginApi?.tr("header.title")
        pointSize: Style.fontSizeXL
        font.weight: Style.fontWeightBold
        color: AtmoColor.mOnSurface
    }

    NText {
        text: pluginApi?.tr("header.desc")
        pointSize: Style.fontSizeS
        color: AtmoColor.mOnSurfaceVariant
        Layout.bottomMargin: Style.marginM
    }

    NDivider { Layout.fillWidth: true }

    NText {
        text: pluginApi?.tr("section.barButton")
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightBold
        color: AtmoColor.mOnSurface
    }

    NColorChoice {
        label: pluginApi?.tr("settings.iconColor.label")
        description: pluginApi?.tr("settings.iconColor.desc")
        currentKey: root.editIconColor
        onSelected: key => { root.editIconColor = key; }
        defaultValue: defaults.iconColor || "primary"
    }

    NDivider { Layout.fillWidth: true; Layout.topMargin: Style.marginS; Layout.bottomMargin: Style.marginS }

    NText {
        text: pluginApi?.tr("section.behavior")
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightBold
        color: AtmoColor.mOnSurface
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.lockOnSuspend.label")
        description: pluginApi?.tr("settings.lockOnSuspend.desc")
        checked: root.editLockOnSuspend
        onToggled: checked => { root.editLockOnSuspend = checked; }
        defaultValue: defaults.lockOnSuspend ?? true
    }

    NDivider { Layout.fillWidth: true; Layout.topMargin: Style.marginS; Layout.bottomMargin: Style.marginS }

    NText {
        text: pluginApi?.tr("section.buttons")
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightBold
        color: AtmoColor.mOnSurface
    }

    NValueSlider {
        id: rangeEditBtnWidth
        objectName: "settings-range-editBtnWidth"
        onValueChanged: root.editBtnWidth = value
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.buttonWidth.label")
        from: 200; to: 500; stepSize: 10; snapAlways: true
        value: root.editBtnWidth
        text: root.editBtnWidth + "px"
        defaultValue: defaults.buttonWidth ?? 470
        showReset: true
        onMoved: v => { root.editBtnWidth = v; }
    }

    NValueSlider {
        id: rangeEditBtnHeight
        objectName: "settings-range-editBtnHeight"
        onValueChanged: root.editBtnHeight = value
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.buttonHeight.label")
        from: 150; to: 400; stepSize: 10; snapAlways: true
        value: root.editBtnHeight
        text: root.editBtnHeight + "px"
        defaultValue: defaults.buttonHeight ?? 280
        showReset: true
        onMoved: v => { root.editBtnHeight = v; }
    }

    NValueSlider {
        id: rangeEditBtnSpacing
        objectName: "settings-range-editBtnSpacing"
        onValueChanged: root.editBtnSpacing = value
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.buttonSpacing.label")
        description: pluginApi?.tr("settings.buttonSpacing.desc")
        from: 10; to: 80; stepSize: 5; snapAlways: true
        value: root.editBtnSpacing
        text: root.editBtnSpacing + "px"
        defaultValue: defaults.buttonSpacing ?? 20
        showReset: true
        onMoved: v => { root.editBtnSpacing = v; }
    }

    NValueSlider {
        id: rangeEditBtnOpacity
        objectName: "settings-range-editBtnOpacity"
        onValueChanged: root.editBtnOpacity = value
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.buttonOpacity.label")
        from: 0.1; to: 1.0; stepSize: 0.05; snapAlways: true
        value: root.editBtnOpacity
        text: Math.round(root.editBtnOpacity * 100) + "%"
        defaultValue: defaults.buttonOpacity ?? 0.50
        showReset: true
        onMoved: v => { root.editBtnOpacity = v; }
    }

    NColorChoice {
        label: pluginApi?.tr("settings.hoverColor.label")
        description: pluginApi?.tr("settings.hoverColor.desc")
        currentKey: root.editHoverColor
        onSelected: key => { root.editHoverColor = key; }
        defaultValue: defaults.hoverColor || "primary"
    }

    NValueSlider {
        id: rangeEditHoverDesaturation
        objectName: "settings-range-editHoverDesaturation"
        onValueChanged: root.editHoverDesaturation = value / 100
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.hoverDesaturation.label")
        description: pluginApi?.tr("settings.hoverDesaturation.desc")
        from: 0; to: 85; stepSize: 5; snapAlways: true
        value: root.editHoverDesaturation * 100
        text: Math.round(root.editHoverDesaturation * 100) + "%"
        defaultValue: defaults.hoverDesaturation ?? 0.0
        showReset: true
        onMoved: v => { root.editHoverDesaturation = v / 100; }
    }

    NDivider { Layout.fillWidth: true; Layout.topMargin: Style.marginS; Layout.bottomMargin: Style.marginS }

    NText {
        text: pluginApi?.tr("section.background")
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightBold
        color: AtmoColor.mOnSurface
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.useOverlay.label")
        description: pluginApi?.tr("settings.useOverlay.desc")
        checked: root.editUseOverlay
        onToggled: checked => { root.editUseOverlay = checked; }
        defaultValue: defaults.useOverlay ?? true
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.editUseOverlay
        spacing: Style.marginM

        NValueSlider {
            id: rangeEditOverlayBlur
            objectName: "settings-range-editOverlayBlur"
            onValueChanged: root.editOverlayBlur = value
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.overlayBlur.label")
            description: pluginApi?.tr("settings.overlayBlur.desc")
            from: 0.0; to: 1.0; stepSize: 0.05; snapAlways: true
            value: root.editOverlayBlur
            text: Math.round(root.editOverlayBlur * 100) + "%"
            defaultValue: defaults.overlayBlur ?? 0.75
            showReset: true
            onMoved: v => { root.editOverlayBlur = v; }
        }

        NValueSlider {
            id: rangeEditOverlayTint
            objectName: "settings-range-editOverlayTint"
            onValueChanged: root.editOverlayTint = value
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.overlayTint.label")
            description: pluginApi?.tr("settings.overlayTint.desc")
            from: 0.0; to: 1.0; stepSize: 0.05; snapAlways: true
            value: root.editOverlayTint
            text: Math.round(root.editOverlayTint * 100) + "%"
            defaultValue: defaults.overlayTint ?? 0.6
            showReset: true
            onMoved: v => { root.editOverlayTint = v; }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: !root.editUseOverlay
        spacing: Style.marginM

        NValueSlider {
            id: rangeEditPanelTint
            objectName: "settings-range-editPanelTint"
            onValueChanged: root.editPanelTint = value
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.panelTint.label")
            description: pluginApi?.tr("settings.panelTint.desc")
            from: 0.0; to: 1.0; stepSize: 0.05; snapAlways: true
            value: root.editPanelTint
            text: Math.round(root.editPanelTint * 100) + "%"
            defaultValue: defaults.panelTint ?? 0.7
            showReset: true
            onMoved: v => { root.editPanelTint = v; }
        }
    }

    NDivider { Layout.fillWidth: true; Layout.topMargin: Style.marginS; Layout.bottomMargin: Style.marginS }

    NText {
        text: pluginApi?.tr("section.animations")
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightBold
        color: AtmoColor.mOnSurface
    }

    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.animationsEnabled.label")
        description: pluginApi?.tr("settings.animationsEnabled.desc")
        checked: root.editAnimationsEnabled
        onToggled: checked => { root.editAnimationsEnabled = checked; }
        defaultValue: defaults.animationsEnabled ?? true
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("Somnus", "Cannot save settings: pluginApi is null")
            return
        }
        root.editIconColor = root.editIconColor || "primary"
        root.editHoverColor = root.editHoverColor || "primary"
        pluginApi.pluginSettings.iconColor = root.editIconColor
        pluginApi.pluginSettings.hoverColor = root.editHoverColor
        pluginApi.pluginSettings.buttonWidth = root.editBtnWidth
        pluginApi.pluginSettings.buttonHeight = root.editBtnHeight
        pluginApi.pluginSettings.buttonSpacing = root.editBtnSpacing
        pluginApi.pluginSettings.buttonOpacity = root.editBtnOpacity
        pluginApi.pluginSettings.useOverlay = root.editUseOverlay
        pluginApi.pluginSettings.overlayBlur = root.editOverlayBlur
        pluginApi.pluginSettings.overlayTint = root.editOverlayTint
        pluginApi.pluginSettings.panelTint = root.editPanelTint
        pluginApi.pluginSettings.animationsEnabled = root.editAnimationsEnabled
        pluginApi.pluginSettings.lockOnSuspend = root.editLockOnSuspend
        pluginApi.pluginSettings.hoverDesaturation = root.editHoverDesaturation
        pluginApi.saveSettings(function (result) {
            if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
                Logger.i("Somnus", "Settings saved successfully")
        })
    }
}
