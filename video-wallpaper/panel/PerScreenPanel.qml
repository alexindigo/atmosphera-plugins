pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.Commons
import qs.Services.UI
import qs.Widgets

import "../common"
import "../common/MonitorCommands.js" as Commands

ColumnLayout {
    id: root
    required property var pluginApi
    readonly property var monitorCommand: Commands.create(function () { return root.pluginApi?.pluginSettings?.monitors; },
        function (value) { root.pluginApi.pluginSettings.monitors = value; }, function (value) { return Settings.store.copyValue(value); },
        function () { return root.pluginApi?.manifest?.metadata?.defaultSettings; })
    anchors.fill: parent


    /***************************
    * PROPERTIES
    ***************************/
    required property string screenName
    required property bool   thumbCacheReady
    required property FolderModel folderModel

    readonly property string currentWallpaper: Commands.record(pluginApi?.pluginSettings?.monitors, screenName)?.currentWallpaper ?? ""
    readonly property bool   monitorSpecific:  pluginApi?.pluginSettings?.monitorSpecific                ?? false


    /***************************
    * FUNCTIONS
    ***************************/
    function saveMonitorProperty(key: string, value: var): bool {
        if(pluginApi == null) {
            Logger.e("video-wallpaper", "PluginAPI is null.");
            return false;
        }

        if (!pluginApi.mainInstance?.admitRuntime(pluginApi)) return false;
        var names = monitorSpecific ? [screenName] : Array.from(Quickshell.screens).map(screen => screen.name);
        return names.length > 0 && monitorCommand.submit(names.map(name => ({op: "set", screen: name, field: key, value: value})));
    }


    /***************************
    * COMPONENTS
    ***************************/
    // Wallpapers folder content
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true

        color: AtmoColor.mSurfaceVariant;
        radius: Style.radiusS;

        ColumnLayout {
            anchors.fill: parent
            visible: !root.thumbCacheReady
            spacing: Style.marginS

            NText {
                text: root.pluginApi?.tr("panel.loading")
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                pointSize: Style.fontSizeL
                font.weight: Font.Bold
            }
        }

        ColumnLayout {
            anchors.fill: parent
            visible: root.thumbCacheReady
            spacing: Style.marginS

            NGridView {
                id: gridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Style.marginXXS

                property int columns: Math.max(1, Math.floor(availableWidth / 300));
                property int itemSize: Math.floor(availableWidth / columns)

                cellWidth: itemSize
                // For now all wallpapers are shown in a 16:9 ratio
                cellHeight: Math.floor(itemSize * (9/16))

                model: root.folderModel.ready && root.thumbCacheReady ? root.folderModel.files : 0

                // Wallpaper
                delegate: Item {
                    id: wallpaper
                    required property string modelData
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    NImageRounded {
                        id: wallpaperImage
                        anchors {
                            fill: parent
                            margins: Style.marginXXS
                        }

                        radius: Style.radiusXS

                        borderWidth: {
                            if (root.thumbCacheReady && root.currentWallpaper == wallpaper.modelData) return Style.borderM;
                            else return 0;
                        }
                        borderColor: AtmoColor.mPrimary;

                        imagePath: {
                            if (root.thumbCacheReady && root.pluginApi.mainInstance != null) return root.pluginApi.mainInstance.getThumbPath(wallpaper.modelData);
                            else return "";
                        }
                        fallbackIcon: "alert-circle"

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent

                            acceptedButtons: Qt.LeftButton
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true;

                            onClicked: {
                                if(root.pluginApi.mainInstance == null) {
                                    Logger.e("video-wallpaper", "Can't change background because pluginApi or main instance doesn't exist!");
                                    return;
                                }

                                root.saveMonitorProperty("currentWallpaper", wallpaper.modelData);
                                root.pluginApi.saveSettings();
                            }

                            onEntered: TooltipService.show(wallpaperImage, wallpaper.modelData, "auto", 100);
                            onExited: TooltipService.hideImmediately();
                        }
                    }
                }
            }

        }
    }

    ToolRow {
        pluginApi:       root.pluginApi
        screenName:      root.screenName
        randomAction: () => root.pluginApi.mainInstance.random(root.screenName, root.pluginApi)
        clearAction: () => root.pluginApi.mainInstance.clear(root.screenName, root.pluginApi)
        settingWriter: (key, value) => {
            if (root.saveMonitorProperty(key, value)) root.pluginApi.saveSettings();
        }
    }
}
