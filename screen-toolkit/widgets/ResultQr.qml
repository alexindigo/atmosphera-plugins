import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI
import "../utils/utils.js" as U
Item {
    id: root
    property var pluginApi: null
    property var mainInstance: null
    implicitWidth: parent?.width ?? 0
    implicitHeight: contentCol.implicitHeight
    readonly property string qrResult: mainInstance?.qrResult ?? ""
    readonly property string qrCapturePath: mainInstance?.qrCapturePath ?? ""
    readonly property string qrType: {
        var r = root.qrResult
        if (r.startsWith("http://") || r.startsWith("https://")) return "url"
        if (r.startsWith("WIFI:")) return "wifi"
        if (r.startsWith("BEGIN:VCARD")) return "contact"
        if (r.startsWith("mailto:")) return "email"
        if (r.startsWith("otpauth://")) return "otp"
        return "text"
    }
    readonly property string qrWifiName: {
        if (root.qrType !== "wifi") return ""
        var m = root.qrResult.match(/S:([^;]+)/)
        return m ? m[1] : ""
    }
    readonly property string qrWifiPass: {
        if (root.qrType !== "wifi") return ""
        var m = root.qrResult.match(/P:([^;]+)/)
        return m ? m[1] : ""
    }
    Process { id: clipProc }
    function _copy(text) {
        if (!text || text === "") return
        clipProc.exec({
            command: ["bash", "-c", "printf '%s' " + U.shellEscape(text) + " | wl-copy 2>/dev/null"]
        })
    }
    function clear() {
        if (mainInstance) {
            mainInstance.clearQrResult()
            mainInstance.activeTool = ""
        }
    }
    Column {
        id: contentCol
        width: parent.width
        spacing: Style.marginM
        Row {
            width: parent.width
            spacing: Style.marginS
            AtmoIcon {
                icon: "qrcode"
                color: AtmoColor.mPrimary
                anchors.verticalCenter: parent.verticalCenter
            }
            NText {
                text: pluginApi?.tr("tools.qr")
                color: AtmoColor.mPrimary
                font.weight: Font.Bold
                pointSize: Style.fontSizeS
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Rectangle {
            width: parent.width
            height: Math.min(
                qrThumb.implicitHeight * (parent.width / Math.max(qrThumb.implicitWidth, 1)),
                160 * Style.uiScaleRatio
            )
            radius: Style.radiusM
            color: "transparent"
            clip: true
            border.color: Style.capsuleBorderColor
            border.width: Style.capsuleBorderWidth
            visible: root.qrCapturePath !== "" && root.qrResult !== "" && qrThumb.status === Image.Ready
            Image {
                id: qrThumb
                anchors.fill: parent
                source: (root.qrCapturePath !== "" && root.qrResult !== "")
                    ? ("file://" + root.qrCapturePath)
                    : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                cache: false
            }
        }
        Rectangle {
            height: 26
            width: qrBadge.implicitWidth + Style.marginM * 2
            radius: Style.radiusS
            color: Qt.alpha(AtmoColor.mPrimary, 0.15)
            NText {
                id: qrBadge
                anchors.centerIn: parent
                font.weight: Font.Bold
                pointSize: Style.fontSizeXS
                color: AtmoColor.mPrimary
                text: root.qrType === "url" ? "🔗 URL"
                    : root.qrType === "wifi" ? "📶 WiFi"
                    : root.qrType === "contact" ? "👤 Contact"
                    : root.qrType === "email" ? "✉️ Email"
                    : root.qrType === "otp" ? "🔐 OTP"
                    : "📄 Text"
            }
        }
        Column {
            width: parent.width
            spacing: Style.marginS
            visible: root.qrType === "wifi"
            Rectangle {
                width: parent.width
                height: 38
                radius: Style.radiusM
                color: AtmoColor.mSurface
                border.color: Style.capsuleBorderColor
                border.width: Style.capsuleBorderWidth
                Row {
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: Style.marginS
                    AtmoIcon {
                        icon: "wifi"
                        color: AtmoColor.mPrimary
                    }
                    NText {
                        text: root.qrWifiName || "Unknown"
                        color: AtmoColor.mOnSurface
                        font.weight: Font.Bold
                        pointSize: Style.fontSizeS
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: 38
                radius: Style.radiusM
                color: wph.containsMouse ? AtmoColor.mHover : AtmoColor.mSurface
                border.color: Style.capsuleBorderColor
                border.width: Style.capsuleBorderWidth
                Row {
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: Style.marginS
                    AtmoIcon {
                        icon: "key"
                        color: AtmoColor.mOnSurfaceVariant
                    }
                    NText {
                        text: root.qrWifiPass ? "••••••••" : pluginApi?.tr("panel.noPassword")
                        color: AtmoColor.mOnSurfaceVariant
                        pointSize: Style.fontSizeS
                    }
                    AtmoIcon {
                        icon: "copy"
                        color: AtmoColor.mOnSurfaceVariant
                    }
                }
                MouseArea {
                    id: wph
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.qrWifiPass !== ""
                    onClicked: {
                        root._copy(root.qrWifiPass)
                        ToastService.showNotice(pluginApi?.tr("panel.passwordCopied"))
                    }
                }
            }
        }
        Rectangle {
            width: parent.width
            height: 120 * Style.uiScaleRatio
            radius: Style.radiusM
            color: AtmoColor.mSurface
            clip: true
            border.color: Style.capsuleBorderColor
            border.width: Style.capsuleBorderWidth
            visible: root.qrType !== "wifi"
            Flickable {
                id: qrFlick
                anchors.fill: parent
                anchors.margins: Style.marginS
                contentHeight: qrText.implicitHeight
                clip: true
                interactive: qrText.implicitHeight > qrFlick.height
                TextEdit {
                    id: qrText
                    width: qrFlick.width
                    text: root.qrResult
                    wrapMode: TextEdit.WordWrap
                    color: AtmoColor.mOnSurface
                    font.pointSize: Style.fontSizeS
                    selectByMouse: true
                    selectionColor: AtmoColor.mPrimary
                    selectedTextColor: AtmoColor.mOnPrimary
                    WheelHandler {
                        onWheel: event => {
                            qrFlick.flick(0, event.angleDelta.y * 5)
                            event.accepted = false
                        }
                    }
                }
            }
        }
        Row {
            width: parent.width
            spacing: Style.marginS
            Rectangle {
                width: parent.width - 46
                height: 38
                radius: Style.radiusM
                color: qah.containsMouse ? AtmoColor.mPrimary : AtmoColor.mSurface
                border.color: AtmoColor.mPrimary
                border.width: Style.capsuleBorderWidth
                Row {
                    anchors.centerIn: parent
                    spacing: Style.marginS
                    AtmoIcon {
                        icon: root.qrType === "url" ? "external-link"
                            : root.qrType === "email" ? "mail"
                            : "copy"
                        color: qah.containsMouse ? AtmoColor.mOnPrimary : AtmoColor.mPrimary
                    }
                    NText {
                        text: root.qrType === "url" ? pluginApi?.tr("panel.openUrl")
                            : root.qrType === "email" ? pluginApi?.tr("panel.composeEmail")
                            : pluginApi?.tr("panel.copy")
                        color: qah.containsMouse ? AtmoColor.mOnPrimary : AtmoColor.mPrimary
                        font.weight: Font.Bold
                        pointSize: Style.fontSizeS
                    }
                }
                MouseArea {
                    id: qah
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.qrType === "url" || root.qrType === "email") {
                            Qt.openUrlExternally(root.qrResult)
                        } else {
                            root._copy(root.qrResult)
                            ToastService.showNotice(pluginApi?.tr("panel.copied"))
                        }
                    }
                }
            }
            Rectangle {
                width: 38
                height: 38
                radius: Style.radiusM
                color: qch.containsMouse ? Qt.alpha(AtmoColor.mError, 0.15) : AtmoColor.mSurface
                border.color: qch.containsMouse ? AtmoColor.mError : Style.capsuleBorderColor
                border.width: Style.capsuleBorderWidth
                AtmoIcon {
                    anchors.centerIn: parent
                    icon: "trash"
                    color: qch.containsMouse ? (AtmoColor.mError || "#f44336") : AtmoColor.mOnSurfaceVariant
                }
                MouseArea {
                    id: qch
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clear()
                }
            }
        }
    }
}
