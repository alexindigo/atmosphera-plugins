import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import Quickshell.Io

ColumnLayout {
    id: root

    property var pluginApi: null
    property var service: pluginApi?.mainInstance?.service ?? null

    property string editBatteryDevice: displayBaseline.editBatteryDevice
    NSettingsBaseline {
        id: displayBaseline
        readonly property string editBatteryDevice: pluginApi?.pluginSettings?.batteryDevice || root.service?.batteries[0] || pluginApi?.manifest?.metadata?.defaultSettings?.batteryDevice || "/sys/class/power_supply/BAT0"
    }
    readonly property bool settingsDirty: displayBaseline.differs({editBatteryDevice: root.editBatteryDevice})
    property bool _applyEffectPending: false
    Connections {
        target: root.pluginApi
        function onSettingsCompleted(result) {
            if (!root._applyEffectPending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current") return;
            root._applyEffectPending = false;
            root.service?.refresh();
            Logger.i("BatteryThreshold", "Current battery: " + root.pluginApi.pluginSettings.batteryDevice);
        }
    }

    spacing: Style.marginL

    NText {
        visible: !service?.isAvailable
        text: pluginApi?.tr("settings.no-battery-device")
        pointSize: Style.fontSizeM
        color: AtmoColor.mOnSurfaceVariant
    }

    NComboBox {
        Layout.fillWidth: true
        visible: service?.isAvailable ?? false
        label: pluginApi?.tr("settings.battery-device")
        description: pluginApi?.tr("settings.battery-device-desc")

        model: (service?.batteries ?? []).map(path => ({
                    key: path,
                    name: `${modelNameOf(path)} (${path.split("/").slice(-1)})`
                }))

        currentKey: root.editBatteryDevice
        onSelected: key => root.editBatteryDevice = key
    }

    function modelNameOf(battery) {
        modelNameView.path = `${battery}/model_name`;
        modelNameView.reload();
        modelNameView.waitForJob();
        return modelNameView.text().trim();
    }

    FileView {
        id: modelNameView
        path: `${root.editBatteryDevice}/model_name`
        printErrors: false
    }

    function saveSettings() {
        pluginApi.pluginSettings.batteryDevice = root.editBatteryDevice;
        if (pluginApi.saveSettings() !== false)
            root._applyEffectPending = true;
    }
}
