import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    readonly property var service: pluginApi?.mainInstance?.settingsConsumerFor(pluginApi.settingsContext) ?? null
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 320 * Style.uiScaleRatio
    property real contentPreferredHeight: panelContent.implicitHeight + Style.marginL * 2
    readonly property bool allowAttach: true
    anchors.fill: parent

    property string batteryModelName: ""

    FileView {
        id: modelNameView
        path: service?.batteryDevice ? service.batteryDevice + "/model_name" : ""
        printErrors: false

        onLoaded: {
            Logger.d("BatteryThreshold", "device: " + modelNameView.path);
            root.batteryModelName = text().trim();
        }
    }

    function writeThreshold(value) {
        if (!service?.isWritable)
            return;
        service.setThreshold(value, pluginApi);
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            id: panelContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                NText {
                    text: pluginApi?.tr("panel.title")
                    pointSize: Style.fontSizeL
                    font.weight: Font.DemiBold
                    color: AtmoColor.mOnSurface
                }

                NText {
                    visible: !service?.isAvailable || root.batteryModelName !== ""
                    text: !service?.isAvailable ? pluginApi?.tr("panel.not-available") : root.batteryModelName
                    pointSize: Style.fontSizeM
                    color: AtmoColor.mOnSurfaceVariant
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: AtmoColor.mOutline
                opacity: 0.3
                visible: service?.isAvailable ?? false
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginS
                visible: service?.isAvailable ?? false

                RowLayout {
                    Layout.fillWidth: true

                    NText {
                        text: pluginApi?.tr("panel.title")
                        pointSize: Style.fontSizeM
                        color: AtmoColor.mOnSurface
                        Layout.fillWidth: true
                    }

                    NText {
                        text: (service?.currentThreshold ?? 0) + "%"
                        pointSize: Style.fontSizeL
                        font.weight: Font.Bold
                        color: AtmoColor.mPrimary
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginS

                    NText {
                        text: "40%"
                        pointSize: Style.fontSizeXS
                        color: AtmoColor.mOnSurfaceVariant
                    }

                    NSlider {
                        id: thresholdSlider
                        Layout.fillWidth: true
                        from: 40
                        to: 100
                        stepSize: 5
                        value: service?.currentThreshold ?? 0
                        enabled: (service?.isWritable ?? false) && !service.busy
                        onMoved: root.writeThreshold(Math.round(value))
                    }

                    NText {
                        text: "100%"
                        pointSize: Style.fontSizeXS
                        color: AtmoColor.mOnSurfaceVariant
                    }
                }

                NText {
                    Layout.fillWidth: true
                    text: service?.isWritable ? pluginApi?.tr("panel.adjust-limit") : pluginApi?.tr("panel.read-only")
                    pointSize: Style.fontSizeXS
                    color: service?.isWritable ? AtmoColor.mOnSurfaceVariant : AtmoColor.mTertiary
                    horizontalAlignment: Text.AlignHCenter
                }
                NText {
                    Layout.fillWidth: true
                    text: pluginApi?.tr("settings.shared-device") ?? ""
                    wrapMode: Text.WordWrap
                    color: AtmoColor.mOnSurfaceVariant
                    pointSize: Style.fontSizeXS
                }
                NText {
                    Layout.fillWidth: true
                    visible: (service?.actionError ?? "") !== ""
                    text: pluginApi?.tr("panel.action-failed") ?? ""
                    wrapMode: Text.WordWrap
                    color: AtmoColor.mError
                }
            }
        }
    }
}
