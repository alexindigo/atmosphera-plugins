import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    property var pluginApi: null

    property var cfg:      pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    // Edit copies
    property int    editRefreshInterval: displayBaseline.project("editRefreshInterval")
    property bool   editShowGovernor:    displayBaseline.editShowGovernor
    property bool   editShowTurbo:       displayBaseline.editShowTurbo
    property bool   editCompactMode:     displayBaseline.editCompactMode
    NSettingsBaseline {
      ranges: [NSettingsRange { field: "editRefreshInterval"; from: rangeEditRefreshInterval.from; to: rangeEditRefreshInterval.to }]
        id: displayBaseline
        readonly property int editRefreshInterval: cfg.refreshInterval ?? defaults.refreshInterval ?? 3000
        readonly property bool editShowGovernor: cfg.showGovernor ?? defaults.showGovernor ?? true
        readonly property bool editShowTurbo: cfg.showTurbo ?? defaults.showTurbo ?? true
        readonly property bool editCompactMode: cfg.compactMode ?? defaults.compactMode ?? false
    }
    readonly property bool settingsDirty: displayBaseline.differs({editRefreshInterval: root.editRefreshInterval, editShowGovernor: root.editShowGovernor, editShowTurbo: root.editShowTurbo, editCompactMode: root.editCompactMode})

    spacing: Style.marginL

    NToggle {
        Layout.fillWidth: true
        label:       pluginApi?.tr("settings.compact.label")
        description: pluginApi?.tr("settings.compact.desc")
        checked: root.editCompactMode
        onToggled: root.editCompactMode = checked
    }

    NToggle {
        Layout.fillWidth: true
        label:       pluginApi?.tr("settings.show-governor.label")
        description: pluginApi?.tr("settings.show-governor.desc")
        checked: root.editShowGovernor
        onToggled: root.editShowGovernor = checked
    }

    NToggle {
        Layout.fillWidth: true
        label:       pluginApi?.tr("settings.show-turbo.label")
        description: pluginApi?.tr("settings.show-turbo.desc")
        checked: root.editShowTurbo
        onToggled: root.editShowTurbo = checked
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NText {
            text: pluginApi?.tr("settings.refresh.label")
            pointSize: Style.fontSizeS
            font.weight: Font.Medium
            color: AtmoColor.mOnSurface
        }

        NText {
            text: pluginApi?.tr("settings.refresh.desc")
            pointSize: Style.fontSizeXS
            color: AtmoColor.mOnSurfaceVariant
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NSlider {
                id: rangeEditRefreshInterval
                objectName: "settings-range-editRefreshInterval"
                onValueChanged: root.editRefreshInterval = value
                Layout.fillWidth: true
                from: 1000
                to: 10000
                stepSize: 500
                value: root.editRefreshInterval
                onMoved: root.editRefreshInterval = value
            }

            NText {
                text: (root.editRefreshInterval / 1000).toFixed(1) + "s"
                pointSize: Style.fontSizeS
                font.family: Settings.data?.ui?.fontFixed ?? "monospace"
                color: AtmoColor.mOnSurface
                Layout.preferredWidth: 36 * Style.uiScaleRatio
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    function saveSettings() {
        if (!pluginApi) return
        pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval
        pluginApi.pluginSettings.showGovernor    = root.editShowGovernor
        pluginApi.pluginSettings.showTurbo       = root.editShowTurbo
        pluginApi.pluginSettings.compactMode     = root.editCompactMode
        pluginApi.saveSettings()
    }
}
