import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets
import Quickshell.Io
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    readonly property var settingsConsumer: pluginApi?.mainInstance?.settingsConsumerFor(pluginApi.settingsContext) ?? null

    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    property real contentPreferredWidth: 600 * Style.uiScaleRatio
    property real contentPreferredHeight: 400 * Style.uiScaleRatio

    property bool playlistViewActive: false 

    readonly property bool shuffleState: settingsConsumer?.shuffleState ?? false

    anchors.fill: parent

    property string playlistSelectionId: ""

    readonly property var searchResults: settingsConsumer?.searchResults ?? []
    readonly property var playlistResults: settingsConsumer?.playlistResults ?? []

    Component.onCompleted: {
        settingsConsumer?.readShuffle(pluginApi)
    }

    function shufflePlayback() {
        settingsConsumer?.shufflePlayback(pluginApi)
    }

    function sendPlayRequest(data) {
        settingsConsumer?.play(data, pluginApi)
    }

    Timer {
        id: searchDebounce
        interval: 300
        repeat: false
        onTriggered: searchForQuery(searchField.text)
    }


    function searchForQuery(query) {
        settingsConsumer?.search(query, pluginApi)
    }

    onPlaylistViewActiveChanged: {
        if (playlistViewActive) {
            settingsConsumer?.playlists(pluginApi)
        }
    }

    // Legacy playlistSelectionId has no UI producer; its old handler referenced
    // an undeclared process. Actual playlist rows use sendPlayRequest below.

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors {
                fill: parent
                margins: Style.marginL
            }
            spacing: Style.marginL

            NText {
                text: root.pluginApi?.tr("panel.title") || ""
                pointSize: Style.fontSizeL
                font.weight: Font.Bold
                color: AtmoColor.mOnSurface
            }
            ColumnLayout {
                Layout.fillWidth: true
                AuthorizationStatus {
                    Layout.fillWidth: true
                    status: root.settingsConsumer?.status ?? "not-authorized"
                    translate: key => root.pluginApi?.tr(key) || ""
                }
                NText {
                    Layout.fillWidth: true
                    text: root.pluginApi?.tr("authorization.runtime-guidance") || ""
                    wrapMode: Text.WordWrap
                }
                RowLayout {
                    NButton {
                        objectName: "spotify-authorize"
                        text: root.pluginApi?.tr("authorization.authorize") || ""
                        enabled: root.settingsConsumer !== null && !root.settingsConsumer.busy
                        onClicked: root.settingsConsumer?.authorize(root.pluginApi)
                    }
                    NButton {
                        objectName: "spotify-devices"
                        text: root.pluginApi?.tr("settings.devicelist_btn") || ""
                        enabled: root.settingsConsumer !== null && !root.settingsConsumer.busy
                        onClicked: root.settingsConsumer?.devices(root.pluginApi)
                    }
                }
                NText {
                    Layout.fillWidth: true
                    text: root.settingsConsumer?.availableDevices || ""
                    visible: text !== ""
                    wrapMode: Text.WordWrap
                }
            }
            // Header
            RowLayout {
                    spacing: Style.marginL
                    
                Rectangle {
                width: 90
                    height: 30
                    color: !(root.playlistViewActive) ? AtmoColor.mPrimary : searchArea.containsMouse ? AtmoColor.mHover : AtmoColor.mSurfaceVariant 
                    radius: Style.radiusS

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: Style.marginS
                        }
                        spacing: Style.marginS
                        
                        AtmoIcon {
                            Layout.alignment: Qt.AlignVCenter
                            icon: "search"
                            color: searchArea.containsMouse ? AtmoColor.mSurfaceVariant : !(root.playlistViewActive) ? AtmoColor.mSurfaceVariant : AtmoColor.mOnSurface
                        }
                            
                        NText {
                            pointSize: Style.fontSizeM
                            text: pluginApi?.tr("panel.search")
                            color: searchArea.containsMouse ? AtmoColor.mSurfaceVariant : !(root.playlistViewActive) ? AtmoColor.mSurfaceVariant : AtmoColor.mOnSurface
                        }
                    }

                    MouseArea {
                        id: searchArea
                        anchors.fill: parent    
                        hoverEnabled: true
                        onClicked: {
                            root.playlistViewActive = false
                        }
                    }
                }

                Rectangle {
                    width: 110
                    height: 30
                    color: root.playlistViewActive ? AtmoColor.mPrimary : playlistArea.containsMouse ? AtmoColor.mHover : AtmoColor.mSurfaceVariant 
                    radius: Style.radiusS

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: Style.marginS
                        }
                        spacing: Style.marginS
                            
                        AtmoIcon {
                            Layout.alignment: Qt.AlignVCenter
                            icon: "playlist"
                            color: playlistArea.containsMouse ? AtmoColor.mSurfaceVariant : root.playlistViewActive ? AtmoColor.mSurfaceVariant : AtmoColor.mOnSurface
                        }
                            
                        NText {
                            pointSize: Style.fontSizeM
                            text: pluginApi?.tr("panel.playlist")
                            color: playlistArea.containsMouse ? AtmoColor.mSurfaceVariant : root.playlistViewActive ? AtmoColor.mSurfaceVariant : AtmoColor.mOnSurface

                        }
                    }

                    MouseArea {
                        id: playlistArea
                        anchors.fill: parent    
                        hoverEnabled: true
                        onClicked: {
                            root.playlistViewActive = true
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                NText { text: pluginApi?.tr("panel.shuffle") }

                NToggle {
                    checked: root.shuffleState
                    MouseArea {
                        anchors.fill: parent
                        onClicked: shufflePlayback()
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
            
            // Content
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: AtmoColor.mSurfaceVariant
                radius: Style.radiusL

                visible: !playlistViewActive

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: Style.marginM
                    }
                    spacing: Style.marginM

                    NTextInput {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: pluginApi?.tr("panel.search_placeholder")

                        onTextChanged: searchDebounce.restart()
                    }

                    ColumnLayout {
                        visible: searchResults.length === 0
                        anchors {
                            fill: parent
                            margins: Style.marginM
                        }
                        spacing: Style.marginL

                        Item {
                            height: 50
                        }

                        AtmoIcon {
                            Layout.alignment: Qt.AlignHCenter
                            icon: "search"
                            pointSize: Style.fontSizeXXL * 2
                            
                        }

                        NText {
                            Layout.alignment: Qt.AlignHCenter
                            text: pluginApi?.tr("panel.search")
                            pointSize: Style.fontSizeL
                            font.weight: Font.Medium
                            color: AtmoColor.mPrimary
                        }

                        NText {
                            Layout.alignment: Qt.AlignHCenter
                            text: pluginApi?.tr("panel.search_hint")
                            pointSize: Style.fontSizeM
                            color: AtmoColor.mOnSurfaceVariant
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    ListView {
                        id: searchResultsView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: searchResults
                        clip: true
                        visible: searchResults.length != 0

                        property int selectedIndex: -1

                        delegate: Rectangle {
                            width: searchResultsView.width
                            height: 40
                            color: searchResultsView.selectedIndex === index ? AtmoColor.mPrimary : hovering ? AtmoColor.mHover : AtmoColor.mSurfaceVariant
                            radius: Style.radiusS

                            property bool hovering: false

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Style.marginM

                                AtmoIcon {
                                	icon: (modelData.type === "track")
                                		? "music"
                                		: (modelData.type === "album")
                                		? "disc"
                                		: "playlist"
                                }

                                NText {
                                    text: modelData.name
                                }

                                Item { Layout.fillWidth: true }

                                NText {
                                    text: (modelData.artists) ? modelData.artists[0].name : modelData.owner.display_name
                                    
                                }
                            }

                            MouseArea {
                                anchors.fill: parent    
                                hoverEnabled: true
                                onClicked: {
                                    searchResultsView.selectedIndex = index
                                    sendPlayRequest(modelData)
                                }
                                onEntered: hovering = true
                                onExited: hovering = false
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: AtmoColor.mSurfaceVariant
                radius: Style.radiusL

                visible: playlistViewActive

                ListView {
                    id: playlistList
                    anchors.fill: parent
                    model: playlistResults
                    clip: true

                    property int selectedIndex: -1

                    delegate: Rectangle {
                        width: playlistList.width
                        height: 40
                        color: playlistList.selectedIndex === index ? AtmoColor.mPrimary : hovering ? AtmoColor.mHover : AtmoColor.mSurfaceVariant
                        radius: Style.radiusS

                        property bool hovering: false

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Style.marginM

                            NText {
                                text: modelData.name
                            }
                        }

                        MouseArea {
                            anchors.fill: parent    
                            hoverEnabled: true
                            onClicked: {
                                playlistList.selectedIndex = index
                                sendPlayRequest(modelData)
                            }
                            onEntered: hovering = true
                            onExited: hovering = false
                        }
                    }
                }
            }
        }
    }
}
