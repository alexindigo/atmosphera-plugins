import QtQuick
import QtQuick.Layouts
import qs.Commons

Row {
    id: root
    spacing: Style.marginXS

    property var pluginApi: null
    property var game: null
    visible: pluginApi?.pluginSettings?.showDebug ?? false

    component ActionBtn: Rectangle {
        id: btn
        property string icon: "●"
        property string label: pluginApi?.tr("debug.action")
        property var action

        width: 60
        height: 56
        radius: Style.radiusM
        color: {
            if (!enabled)
                return Qt.rgba(1, 1, 1, 0.04);
            if (_pressed)
                return Qt.rgba(1, 1, 1, 0.22);
            if (_hovered)
                return Qt.rgba(1, 1, 1, 0.15);
            return Qt.rgba(1, 1, 1, 0.09);
        }
        border.color: Qt.rgba(1, 1, 1, enabled ? 0.12 : 0.05)
        border.width: Style.marginM
        opacity: enabled ? 1.0 : 0.4

        property bool _hovered: false
        property bool _pressed: false

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
        scale: _pressed ? 0.92 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutBack
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: Style.marginS
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btn.icon
                font.pixelSize: Style.fontSizeM
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btn.label
                font.pixelSize: Style.fontSizeXS
                color: AtmoColor.mOnSurfaceVariant
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: btn._hovered = true
            onExited: {
                btn._hovered = false;
                btn._pressed = false;
            }
            onPressed: if (btn.enabled)
                btn._pressed = true
            onReleased: {
                btn._pressed = false;
                if (btn.enabled && containsMouse && btn.action) {
                    btn.action();
                }
            }
        }
    }

    ActionBtn {
        icon: "🍗"
        label: pluginApi?.tr("debug.feed")
        action: function () {
            if (root.game)
                root.game.feed(-10);
        }
    }

    ActionBtn {
        icon: "🎮"
        label: pluginApi?.tr("debug.play")
        action: function () {
            if (root.game && root.game.current)
                root.game.happiness += -10;
        }
    }

    ActionBtn {
        icon: "🧼"
        label: pluginApi?.tr("debug.clean")
        action: function () {
            if (root.game)
                root.game.clean(-10);
        }
    }

    ActionBtn {
        icon: root.game?.petState === "sleeping" ? "☀️" : "💤"
        label: pluginApi?.tr("debug.sleep")
        action: function () {
            if (root.game && root.game.current)
                root.game.energy += -10;
        }
    }
}
