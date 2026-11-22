import QtQuick
import qs.Commons
import "./components"
import QtMultimedia

Item {
    id: root

    property var pluginApi: null
    property var game: null
    signal foodBurstRequested()
    signal cleanBurstRequested()

    width: animCtrl.frameW
    height: animCtrl.frameH

    AnimationController {
        id: animCtrl
        game: root.game
        anchors.centerIn: parent
        frameH: 220
        frameW: 220
    }

    Repeater {
        id: foodParticles
        model: 5
        delegate: Text {
            id: foodParticle

            text: ["🍗", "✨", "💛", "🌟", "💫"][index]
            font.pixelSize: Style.fontSizeXL

            property real startX: 0
            property real startY: 0

            opacity: 0
            visible: false

            Component.onCompleted: {
                resetPosition();
            }

            Connections {
                target: root
                function onFoodBurstRequested() { foodParticle.burst(); }
            }

            function resetPosition() {
                startX = root.width / 2 + (Math.random() * 60 - 30);
                startY = root.height / 2;

                x = startX;
                y = startY;
            }

            function burst() {
                resetPosition();

                visible = true;
                opacity = 1;
                foodBurstAnim.restart();
            }

            SequentialAnimation {
                id: foodBurstAnim

                ParallelAnimation {
                    NumberAnimation {
                        target: foodParticle
                        property: "y"
                        to: foodParticle.startY - 40 - Math.random() * 20
                        duration: 600
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: foodParticle
                        property: "opacity"
                        to: 0
                        duration: 600
                        easing.type: Easing.InQuad
                    }
                }

                ScriptAction {
                    script: {
                        foodParticle.visible = false;
                        foodParticle.x = foodParticle.startX;
                        foodParticle.y = foodParticle.startY;
                    }
                }
            }
        }
    }

    Repeater {
        id: cleanParticles
        model: 5
        delegate: Text {
            id: cleanParticle
            text: ["🧼", "✨", "💧", "⭐", "🫧"][index]
            font.pixelSize: Style.fontSizeXL

            property real startX: 0
            property real startY: 0

            opacity: 0
            visible: false

            Component.onCompleted: {
                resetPosition();
            }

            Connections {
                target: root
                function onCleanBurstRequested() { cleanParticle.burst(); }
            }

            function resetPosition() {
                startX = root.width / 2 + (Math.random() * 60 - 30);
                startY = root.height / 2;

                x = startX;
                y = startY;
            }

            function burst() {
                resetPosition();

                visible = true;
                opacity = 1;
                cleanBurstAnim.restart();
            }

            SequentialAnimation {
                id: cleanBurstAnim

                ParallelAnimation {
                    NumberAnimation {
                        target: cleanParticle
                        property: "y"
                        to: cleanParticle.startY - 40 - Math.random() * 20
                        duration: 600
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: cleanParticle
                        property: "opacity"
                        to: 0
                        duration: 600
                        easing.type: Easing.InQuad
                    }
                }

                ScriptAction {
                    script: {
                        cleanParticle.visible = false;
                        cleanParticle.x = cleanParticle.startX;
                        cleanParticle.y = cleanParticle.startY;
                    }
                }
            }
        }
    }

    SoundEffect {
        id: soundEat
        source: "sounds/eat.wav"
        volume: pluginApi?.pluginSettings?.volume ?? 1.0
    }
    DropArea {
        anchors.fill: parent
        keys: ["food"]
        z: 999

        onDropped: drop => {
            drop.acceptProposedAction();

            if (root.game?.petState === "sleeping")
                return;
            root.game?.feed(10);
            soundEat.play();
            root.burstFood();
        }

        Rectangle {
            anchors.topMargin: 100
            anchors.fill: parent
            color: "transparent"
            radius: parent.width / 2
            opacity: 1
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }
    }

    DropArea {
        id: soapDrop
        anchors.fill: parent
        keys: ["soap"]
        z: 999

        property bool active: containsDrag

        onEntered: {
            cleanTimer.start();
        }

        onExited: {
            cleanTimer.stop();
        }

        Rectangle {
            anchors.topMargin: 100
            anchors.fill: parent
            radius: parent.width / 2
            color: "transparent"
            opacity: 1
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }
    }

    Timer {
        id: cleanTimer
        interval: 120
        repeat: true

        onTriggered: {
            root.game?.clean(2.5);
            root.burstClean();
        }
    }

    function burstFood() {
        foodBurstRequested();
    }

    function burstClean() {
        cleanBurstRequested();
    }
}
