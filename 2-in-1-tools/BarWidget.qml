import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

AtmoIconButton {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0
    property var cfg: pluginApi?.pluginSettings ?? ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})

    readonly property string outputName: screen?.name ?? ""
    readonly property var backend: pluginApi?.mainInstance
    readonly property string currentTransform: backend?.transformForOutput(outputName) ?? "Normal"
    readonly property string configuredIcon: cfg.iconName ?? defaults.iconName ?? "rotate-cw"
    readonly property bool showTransformInTooltip: cfg.showTransformInTooltip ?? defaults.showTransformInTooltip ?? true

    icon: backend?.buttonUsesManualRotate(pluginApi?.settingsContext) ? configuredIcon : (backend?.buttonIconName(pluginApi?.settingsContext) ?? "screen-rotation")
    visible: backend?.buttonVisible(outputName, pluginApi?.settingsContext) ?? false
    enabled: backend?.buttonEnabled(outputName, pluginApi?.settingsContext) ?? false
    tooltipText: backend?.buttonUsesManualRotate(pluginApi?.settingsContext)
        ? (showTransformInTooltip
            ? "Rotate display · Current: " + (backend?.transformLabel(currentTransform) ?? "Normal")
            : "Rotate display")
        : (backend?.buttonTooltip(outputName, pluginApi?.settingsContext) ?? "Auto-rotate")
    tooltipDirection: BarService.getTooltipDirection(screen?.name)
    baseSize: Style.getCapsuleHeightForScreen(screen?.name)
    applyUiScale: false
    customRadius: Style.radiusL
    colorBg: Style.capsuleColor
    colorFg: AtmoColor.mOnSurfaceVariant
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    onClicked: backend?.activatePrimaryButton(outputName, pluginApi?.settingsContext)
    onRightClicked: PanelService.showContextMenu(contextMenu, root, screen)

    Component.onCompleted: backend?.refreshTransform(outputName, pluginApi?.settingsContext)
    onScreenChanged: backend?.refreshTransform(outputName, pluginApi?.settingsContext)

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": backend?.buttonUsesManualRotate(pluginApi?.settingsContext) ? "Rotate now" : "Toggle rotation lock",
                "action": "rotate",
                "icon": backend?.buttonUsesManualRotate(pluginApi?.settingsContext) ? configuredIcon : (backend?.buttonIconName(pluginApi?.settingsContext) ?? "screen-rotation")
            },
            {
                "label": "Rotate manually",
                "action": "manual-rotate",
                "icon": configuredIcon
            },
            {
                "label": "Refresh state",
                "action": "refresh",
                "icon": "refresh"
            },
            {
                "label": "Settings",
                "action": "settings",
                "icon": "settings"
            }
        ]

        onTriggered: action => {
            contextMenu.close()
            PanelService.closeContextMenu(screen)

            if (action === "rotate")
                backend?.activatePrimaryButton(outputName, pluginApi?.settingsContext)
            else if (action === "manual-rotate")
                backend?.cycleTransform(outputName, pluginApi?.settingsContext)
            else if (action === "refresh")
                backend?.refreshTransform(outputName, pluginApi?.settingsContext)
            else if (action === "settings")
                BarService.openPluginSettings(root.screen, pluginApi.manifest)
        }
    }
}
