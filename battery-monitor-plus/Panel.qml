import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.Commons
import qs.Services.Hardware
import qs.Services.Networking
import qs.Services.Power
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null

  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property var settingsClient: pluginApi?.mainInstance?.settingsConsumerFor(pluginApi.settingsContext)
  readonly property var monitor: settingsClient?.observation
  readonly property string deviceNativePath: cfg.deviceNativePath ?? defaults.deviceNativePath ?? "__default__"
  readonly property var selectedDevice: monitor?.selectedDevice ?? null
  readonly property var primaryDevice: selectedDevice
  readonly property bool showPowerProfiles: cfg.showPowerProfiles ?? defaults.showPowerProfiles ?? false
  readonly property bool showNoctaliaPerformance: cfg.showNoctaliaPerformance ?? defaults.showNoctaliaPerformance ?? false
  readonly property bool powerProfileAvailable: PowerProfileService.available
  readonly property var powerProfiles: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
  readonly property bool profilesAvailable: PowerProfileService.available
  readonly property int refreshIntervalSeconds: Math.max(1, cfg.refreshIntervalSeconds ?? defaults.refreshIntervalSeconds ?? 5)
  property int profileIndex: profileToIndex(PowerProfileService.profile)
  property int refreshNonce: 0

  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  property real contentPreferredWidth: 440 * Style.uiScaleRatio
  property real contentPreferredHeight: 500 * Style.uiScaleRatio

  anchors.fill: parent

  Connections {
    target: PowerProfileService
    function onProfileChanged() {
      root.profileIndex = root.profileToIndex(PowerProfileService.profile);
    }
  }

  Timer {
    interval: root.refreshIntervalSeconds * 1000
    repeat: true
    running: true
    onTriggered: root.refreshNonce++
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      id: mainLayout
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      NBox {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + Style.margin2M

        RowLayout {
          id: headerRow
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          AtmoIcon {
            pointSize: Style.fontSizeXXL
            color: (BatteryService.isCharging(root.primaryDevice) || BatteryService.isPluggedIn(root.primaryDevice)) ? AtmoColor.mPrimary : (BatteryService.isCriticalBattery(root.primaryDevice) || BatteryService.isLowBattery(root.primaryDevice)) ? AtmoColor.mError : AtmoColor.mOnSurface
            icon: BatteryService.getIcon(BatteryService.getPercentage(root.primaryDevice), BatteryService.isCharging(root.primaryDevice), BatteryService.isPluggedIn(root.primaryDevice), BatteryService.isDeviceReady(root.primaryDevice))
          }

          ColumnLayout {
            spacing: Style.marginXXS
            Layout.fillWidth: true

            NText {
              text: I18n.tr("common.battery")
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: AtmoColor.mOnSurface
              Layout.fillWidth: true
              elide: Text.ElideRight
            }

            NText {
              text: statusText(root.primaryDevice)
              pointSize: Style.fontSizeS
              color: AtmoColor.mOnSurfaceVariant
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
          }

          AtmoIconButton {
            icon: "settings"
            tooltipText: pluginApi?.tr("menu.settings")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              if (pluginApi) {
                BarService.openPluginSettings(pluginApi.panelOpenScreen, pluginApi.manifest);
              }
            }
          }

          AtmoIconButton {
            icon: "close"
            tooltipText: I18n.tr("common.close")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: {
              if (pluginApi) {
                pluginApi.closePanel(pluginApi.panelOpenScreen);
              }
            }
          }
        }
      }

      NBox {
        Layout.fillWidth: true
        implicitHeight: detailsLayout.implicitHeight + Style.margin2L

        ColumnLayout {
          id: detailsLayout
          anchors.fill: parent
          anchors.margins: Style.marginL
          spacing: Style.marginM

          Repeater {
            model: detailRows(root.primaryDevice, root.monitor ? root.monitor.refreshNonce : root.refreshNonce)

            delegate: RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginM

              NText {
                Layout.preferredWidth: 150 * Style.uiScaleRatio
                text: modelData.label
                pointSize: Style.fontSizeS
                color: AtmoColor.mOnSurfaceVariant
                elide: Text.ElideRight
              }

              NText {
                Layout.fillWidth: true
                text: modelData.value
                pointSize: Style.fontSizeS
                font.weight: Style.fontWeightBold
                color: AtmoColor.mOnSurface
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
              }
            }
          }
        }
      }

      NBox {
        Layout.fillWidth: true
        implicitHeight: chargeLayout.implicitHeight + Style.margin2L
        visible: BatteryService.laptopBatteries.length > 0 || BatteryService.bluetoothBatteries.length > 0

        ColumnLayout {
          id: chargeLayout
          anchors.fill: parent
          anchors.margins: Style.marginL
          spacing: Style.marginL

          Repeater {
            model: BatteryService.laptopBatteries
            delegate: ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                AtmoIcon {
                  icon: BatteryService.getIcon(BatteryService.getPercentage(modelData), BatteryService.isCharging(modelData), BatteryService.isPluggedIn(modelData), BatteryService.isDeviceReady(modelData))
                  color: (BatteryService.isCharging(modelData) || BatteryService.isPluggedIn(modelData)) ? AtmoColor.mPrimary : (BatteryService.isCriticalBattery(modelData) || BatteryService.isLowBattery(modelData)) ? AtmoColor.mError : AtmoColor.mOnSurface
                }

                NText {
                  readonly property string dName: BatteryService.getDeviceName(modelData)
                  text: dName ? dName : I18n.tr("common.battery")
                  color: (BatteryService.isCharging(modelData) || BatteryService.isPluggedIn(modelData)) ? AtmoColor.mPrimary : (BatteryService.isCriticalBattery(modelData) || BatteryService.isLowBattery(modelData)) ? AtmoColor.mError : AtmoColor.mOnSurface
                  pointSize: Style.fontSizeS
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                NText {
                  text: BatteryService.getTimeRemainingText(modelData)
                  pointSize: Style.fontSizeS
                  color: AtmoColor.mOnSurfaceVariant
                }
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                Rectangle {
                  Layout.fillWidth: true
                  height: Math.round(8 * Style.uiScaleRatio)
                  radius: Math.min(Style.radiusL, height / 2)
                  color: AtmoColor.mSurface

                  Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.max(0, Math.min(1, BatteryService.getPercentage(modelData) / 100))
                    color: AtmoColor.mPrimary
                  }
                }

                NText {
                  Layout.preferredWidth: 40 * Style.uiScaleRatio
                  horizontalAlignment: Text.AlignRight
                  text: `${BatteryService.getPercentage(modelData)}%`
                  color: (BatteryService.isCharging(modelData) || BatteryService.isPluggedIn(modelData)) ? AtmoColor.mPrimary : (BatteryService.isCriticalBattery(modelData) || BatteryService.isLowBattery(modelData)) ? AtmoColor.mError : AtmoColor.mOnSurface
                  pointSize: Style.fontSizeS
                  font.weight: Style.fontWeightBold
                }
              }
            }
          }

          NDivider {
            Layout.fillWidth: true
            visible: BatteryService.laptopBatteries.length > 0 && BatteryService.bluetoothBatteries.length > 0
          }

          Repeater {
            model: BatteryService.bluetoothBatteries
            delegate: ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                AtmoIcon {
                  icon: BluetoothService.getDeviceIcon(modelData)
                  color: AtmoColor.mOnSurface
                }

                NText {
                  readonly property string dName: BatteryService.getDeviceName(modelData)
                  text: dName ? dName : I18n.tr("common.bluetooth")
                  pointSize: Style.fontSizeS
                  color: AtmoColor.mOnSurface
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                Rectangle {
                  Layout.fillWidth: true
                  height: Math.round(8 * Style.uiScaleRatio)
                  radius: Math.min(Style.radiusL, height / 2)
                  color: AtmoColor.mSurface

                  Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.max(0, Math.min(1, BatteryService.getPercentage(modelData) / 100))
                    color: AtmoColor.mPrimary
                  }
                }

                NText {
                  Layout.preferredWidth: 40 * Style.uiScaleRatio
                  horizontalAlignment: Text.AlignRight
                  text: `${BatteryService.getPercentage(modelData)}%`
                  color: AtmoColor.mPrimary
                  pointSize: Style.fontSizeS
                  font.weight: Style.fontWeightBold
                }
              }
            }
          }
        }
      }

      NBox {
        Layout.fillWidth: true
        height: controlsLayout.implicitHeight + Style.margin2L
        visible: root.showPowerProfiles || root.showNoctaliaPerformance

        ColumnLayout {
          id: controlsLayout
          anchors.fill: parent
          anchors.margins: Style.marginL
          spacing: Style.marginM

          ColumnLayout {
            visible: root.powerProfileAvailable && root.showPowerProfiles

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              NText {
                text: I18n.tr("battery.power-profile")
                font.weight: Style.fontWeightBold
                color: AtmoColor.mOnSurface
                Layout.fillWidth: true
              }

              NText {
                text: PowerProfileService.getName(root.profileIndex)
                color: AtmoColor.mOnSurfaceVariant
              }
            }

            NValueSlider {
              Layout.fillWidth: true
              from: 0
              to: 2
              stepSize: 1
              snapAlways: true
              heightRatio: 0.5
              value: root.profileIndex
              enabled: root.profilesAvailable
              onPressedChanged: (pressed, v) => {
                if (!pressed) {
                  setProfileByIndex(v);
                }
              }
              onMoved: v => {
                root.profileIndex = v;
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginS

              AtmoIcon {
                icon: "powersaver"
                pointSize: Style.fontSizeS
                color: PowerProfileService.getIcon() === "powersaver" ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
              }

              AtmoIcon {
                icon: "balanced"
                pointSize: Style.fontSizeS
                color: PowerProfileService.getIcon() === "balanced" ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
                Layout.fillWidth: true
              }

              AtmoIcon {
                icon: "performance"
                pointSize: Style.fontSizeS
                color: PowerProfileService.getIcon() === "performance" ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
              }
            }
          }

          NDivider {
            Layout.fillWidth: true
            visible: root.showPowerProfiles && PowerProfileService.available && root.showNoctaliaPerformance
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            visible: root.showNoctaliaPerformance

            NText {
              text: I18n.tr("toast.noctalia-performance.label")
              pointSize: Style.fontSizeM
              font.weight: Style.fontWeightBold
              color: AtmoColor.mOnSurface
              Layout.fillWidth: true
            }

            AtmoIcon {
              icon: PowerProfileService.noctaliaPerformanceMode ? "rocket" : "rocket-off"
              pointSize: Style.fontSizeL
              color: PowerProfileService.noctaliaPerformanceMode ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
            }

            NToggle {
              checked: PowerProfileService.noctaliaPerformanceMode
              onToggled: checked => PowerProfileService.noctaliaPerformanceMode = checked
            }
          }
        }
      }
    }
  }

  function profileToIndex(p) {
    return powerProfiles.indexOf(p) ?? 1;
  }

  function indexToProfile(idx) {
    return powerProfiles[idx] ?? PowerProfile.Balanced;
  }

  function setProfileByIndex(idx) {
    var prof = indexToProfile(idx);
    root.profileIndex = idx;
    PowerProfileService.setProfile(prof);
  }

  function detailRows(device, tick) {
    return [
      {
        "label": pluginApi?.tr("panel.status"),
        "value": statusText(device)
      },
      {
        "label": powerLabel(device),
        "value": formatPower(device, false, true)
      },
      {
        "label": timeLabel(device),
        "value": formatRemainingTime(device, true)
      },
      {
        "label": pluginApi?.tr("panel.batteryLevel"),
        "value": BatteryService.isDeviceReady(device) ? `${BatteryService.getPercentage(device)}%` : pluginApi?.tr("common.unavailable")
      },
      {
        "label": pluginApi?.tr("panel.batteryHealth"),
        "value": healthText(device)
      },
      {
        "label": pluginApi?.tr("panel.powerProfile"),
        "value": powerProfileText()
      }
    ];
  }

  function statusText(device) {
    return root.monitor?.statusText() ?? pluginApi?.tr("status.noBattery");
  }

  function formatPower(device, compact, showUnavailable) {
    return root.monitor?.formatPower(compact, showUnavailable) ?? (showUnavailable ? pluginApi?.tr("common.unavailable") : "");
  }

  function formatRemainingTime(device, showUnavailable) {
    return root.monitor?.formatRelevantTime(showUnavailable) ?? (showUnavailable ? pluginApi?.tr("common.unavailable") : "");
  }

  function healthText(device) {
    return root.monitor?.healthText() ?? pluginApi?.tr("common.unavailable");
  }

  function powerLabel(device) {
    if (root.monitor && root.monitor.sysfsOk) {
      return root.monitor.isChargingHardware ? pluginApi?.tr("panel.chargingPower") : pluginApi?.tr("panel.currentPower");
    }

    return BatteryService.isCharging(device) ? pluginApi?.tr("panel.chargingPower") : pluginApi?.tr("panel.currentPower");
  }

  function timeLabel(device) {
    if (root.monitor && root.monitor.sysfsOk) {
      return root.monitor.isChargingHardware ? pluginApi?.tr("panel.timeUntilFull") : pluginApi?.tr("panel.remainingTime");
    }

    return BatteryService.isCharging(device) ? pluginApi?.tr("panel.timeUntilFull") : pluginApi?.tr("panel.remainingTime");
  }

  function powerProfileText() {
    if (!PowerProfileService.available) {
      return pluginApi?.tr("profile.unavailable");
    }

    switch (PowerProfileService.getIcon()) {
    case "powersaver":
      return pluginApi?.tr("profile.powerSaver");
    case "performance":
      return pluginApi?.tr("profile.performance");
    case "balanced":
      return pluginApi?.tr("profile.balanced");
    default:
      return pluginApi?.tr("profile.unknown");
    }
  }
}
