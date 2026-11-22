import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    // ===== NOCTALIA REQUIRED PROPERTIES =====
    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property string screenName: screen ? (screen.name ?? "") : ""
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(root.screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(root.screenName)
    readonly property string fixedFont: Settings.data.ui.fontFixed

    // Special fan level identifiers as reported by /proc/acpi/ibm/fan
    readonly property string levelAuto: "auto"
    readonly property string levelOff: "0"
    readonly property string levelUnknown: "unknown"

    // procfs/sysfs don't emit inotify events — values must be polled
    readonly property int pollIntervalMs: 2000
    readonly property int refreshDelayMs: 300

    readonly property var settingsConsumer: pluginApi?.mainInstance?.settingsConsumerFor(pluginApi.settingsContext) ?? null
    readonly property int fanRpm: settingsConsumer?.fanRpm ?? 0
    readonly property string fanLevel: settingsConsumer?.fanLevel ?? levelAuto

    // ===== READING NATIVE NOCTALIA SETTINGS =====
    readonly property bool colorizeByStatus:
        pluginApi?.pluginSettings?.colorizeByStatus ??
        pluginApi?.manifest?.metadata?.defaultSettings?.colorizeByStatus ??
        true

    readonly property bool allowPopupOpening:
        pluginApi?.pluginSettings?.allowPopupOpening ??
        pluginApi?.manifest?.metadata?.defaultSettings?.allowPopupOpening ??
        true

    // Per-mode colors. An empty value means "neutral" (match the bar): off and
    // forced-speed default to a theme color, automatic defaults to neutral.
    readonly property var rawColorLevel0:
        pluginApi?.pluginSettings?.colorLevel0 ??
        pluginApi?.manifest?.metadata?.defaultSettings?.colorLevel0 ??
        AtmoColor.mError
    readonly property var rawColorActive:
        pluginApi?.pluginSettings?.colorActive ??
        pluginApi?.manifest?.metadata?.defaultSettings?.colorActive ??
        AtmoColor.mPrimary
    readonly property var rawColorAuto:
        pluginApi?.pluginSettings?.colorAuto ??
        pluginApi?.manifest?.metadata?.defaultSettings?.colorAuto ??
        ""

    readonly property bool level0IsNeutral: String(rawColorLevel0).length === 0
    readonly property bool activeIsNeutral: String(rawColorActive).length === 0
    readonly property bool autoIsNeutral: String(rawColorAuto).length === 0

    readonly property string colorLevel0: level0IsNeutral ? Style.capsuleColor : rawColorLevel0
    readonly property string colorActive: activeIsNeutral ? Style.capsuleColor : rawColorActive
    readonly property string colorAuto: autoIsNeutral ? Style.capsuleColor : rawColorAuto

    readonly property real contentWidth: layout.implicitWidth + Style.marginS * 2
    readonly property real contentHeight: capsuleHeight
    implicitWidth: contentWidth
    implicitHeight: Style.barHeight

    readonly property bool isCustomActive: root.fanLevel !== root.levelAuto && root.fanLevel !== root.levelOff
    readonly property bool isOff: root.fanLevel === root.levelOff

    // Resolved color + neutral flag for the currently active fan mode
    readonly property bool currentIsNeutral:
        !root.colorizeByStatus
        || (root.isCustomActive ? root.activeIsNeutral
            : (root.isOff ? root.level0IsNeutral : root.autoIsNeutral))
    readonly property string currentColor:
        root.isCustomActive ? root.colorActive
        : (root.isOff ? root.colorLevel0 : root.colorAuto)

    // ===== NATIVE NOCTALIA CONTEXT MENU =====
    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": pluginApi?.tr("menu.widget-settings"),
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

    // ===== GRAPHICAL INTERFACE (CAPSULE) =====
    Rectangle {
        id: visualCapsule
        anchors.centerIn: parent
        width: root.contentWidth
        height: root.contentHeight
        radius: Style.radiusL
        
        color: root.currentIsNeutral ? Style.capsuleColor : root.currentColor
        border.color: root.currentIsNeutral ? Style.capsuleBorderColor : root.currentColor
        border.width: Style.capsuleBorderWidth

        RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: Style.marginXS

            AtmoIcon {
                id: fanIcon
                icon: "car-fan"
                color: root.currentIsNeutral ? AtmoColor.mOnSurface : AtmoColor.mOnPrimary
            }

            NText {
                id: fanText
                text: root.fanRpm + " RPM"
                pointSize: barFontSize
                font.family: root.fixedFont
                font.weight: Font.Bold
                color: root.currentIsNeutral ? AtmoColor.mOnSurface : AtmoColor.mOnPrimary
            }
        }
    }

    // ===== INTERACTION MANAGEMENT =====
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                PanelService.showContextMenu(contextMenu, root, screen)
            } else if (mouse.button === Qt.LeftButton) {
                if (root.allowPopupOpening && pluginApi && typeof pluginApi.openPanel === "function") {
                    pluginApi.openPanel(root.screen, root);
                }
            }
        }
    }
}
