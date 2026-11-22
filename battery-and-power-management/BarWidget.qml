import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen: null
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property string screenName: screen ? (screen.name ?? "") : ""
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(root.screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(root.screenName)
    readonly property string fixedFont: Settings.data?.ui?.fontFixed ?? "monospace"

    property color profileBackgroundColor: {
        if (mouseArea.containsMouse) {
            return AtmoColor.mHover;
        }

        if (root.batStatus === pluginApi.tr("battery.status-charging")) {
            return AtmoColor.mPrimary;
        }

        if (root.colorizeByProfile) {
            if (root.currentProfile === "power-saver") return root.colorPowerSaver;
            if (root.currentProfile === "performance") return root.colorPerformance;
        }

        return Style.capsuleColor;
    }

    property color profileForegroundColor: {
        if (mouseArea.containsMouse || root.batStatus === pluginApi.tr("battery.status-charging")) {
            return AtmoColor.mOnPrimary;
        }
        
        if (root.colorizeByProfile && (root.currentProfile === "power-saver" || root.currentProfile === "performance")) {
            return AtmoColor.mOnPrimary;
        }
        
        return AtmoColor.mOnSurface;
}

    readonly property var settingsConsumer: pluginApi?.mainInstance?.settingsConsumerFor(pluginApi.settingsContext) ?? null
    readonly property int batPercent: settingsConsumer?.batPercent ?? 0
    readonly property real wattNum: settingsConsumer?.wattNum ?? 0
    readonly property string batStatus: settingsConsumer?.batStatus ?? ""
    readonly property string currentProfile: settingsConsumer?.currentProfile ?? "balanced"

    readonly property real contentWidth: layout.implicitWidth + Style.marginM * 2
    readonly property real contentHeight: capsuleHeight
    implicitWidth: contentWidth
    implicitHeight: Style.barHeight

    property bool colorizeByProfile:
        pluginApi?.pluginSettings?.colorizeByProfile ??
        pluginApi?.manifest?.metadata?.defaultSettings?.colorizeByProfile ??
        true

    property string colorPowerSaver:
        pluginApi?.pluginSettings?.colorPowerSaver ??
        pluginApi?.manifest?.metadata?.defaultSettings?.colorPowerSaver ??
        AtmoColor.mSecondary

    property string colorPerformance:
        pluginApi?.pluginSettings?.colorPerformance ??
        pluginApi?.manifest?.metadata?.defaultSettings?.colorPerformance ??
        AtmoColor.mError

    property bool showProfile:
        pluginApi?.pluginSettings?.showProfile ??
        pluginApi?.manifest?.metadata?.defaultSettings?.showProfile ??
        true

    property bool showBalancedIcon:
        pluginApi?.pluginSettings?.showBalancedIcon  ??
        pluginApi?.manifest?.metadata?.defaultSettings?.showBalancedIcon ??
        false

    function getBatteryIcon() {
        return settingsConsumer?.getBatteryIcon() ?? "battery";
    }

    // ===== UI =====
    Rectangle {
        id: visualCapsule
        anchors.centerIn: parent
        width: root.contentWidth
        height: root.contentHeight
        radius: Style.radiusL
        
        color: mouseArea.containsMouse 
            ? AtmoColor.mHover 
            : (root.batStatus === pluginApi.tr("battery.status-charging") ? AtmoColor.mPrimary : root.profileBackgroundColor)

        border.color: root.batStatus === pluginApi.tr("battery.status-charging") ? AtmoColor.mPrimary : Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: Style.marginS

            AtmoIcon {
                icon: root.getBatteryIcon()
                color: root.profileForegroundColor
            }

            NText {
                text: root.batPercent + "% " + (root.batStatus === pluginApi.tr("battery.status-charging") ? "+" : "-") + root.wattNum.toFixed(1) + "W"
                pointSize: barFontSize
                font.family: root.fixedFont
                font.weight: Font.Bold
                color: root.profileForegroundColor
            }

            AtmoIcon {
                visible: root.showProfile
                icon: {
                    if (root.currentProfile === "power-saver") return "leaf";
                    if (root.currentProfile === "performance") return "gauge";
                    if (root.showBalancedIcon) return "scale";
                    return "";
                }
                color: root.profileForegroundColor
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton


        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                PanelService.showContextMenu(contextMenu, root, screen)
            } else {
                root.settingsConsumer?.refreshAll();
                pluginApi.openPanel(root.screen, root);
            }
        }
    }

    // ===== CONTEXT MENU ====
    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": pluginApi.tr("settings.widget-settings"),
                "action": "settings",
                "icon": "settings"
            }
        ]

        onTriggered: action => {
            contextMenu.close()
            PanelService.closeContextMenu(screen)

            if (action === "settings") {
                if (pluginApi?.manifest) {
                    BarService.openPluginSettings(screen, pluginApi.manifest)
                }
            }
        }
    }

    
}
