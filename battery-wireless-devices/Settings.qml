import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Plugin-wide settings UI (the "settings" entry point). Rendered inside a
// scroll view by the plugin settings popup. Input remains local until Apply.
ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var refreshIntervalField: pluginApi?.field("refreshInterval") ?? null
  readonly property var showPercentageField: pluginApi?.field("showPercentage") ?? null
  readonly property var showChargingField: pluginApi?.field("showCharging") ?? null
  readonly property var devicesField: pluginApi?.field("devices") ?? null
  readonly property var deviceOrderField: pluginApi?.field("deviceOrder") ?? null
  readonly property int editRefreshInterval: {
    var value = root.refreshIntervalField?.value;
    return typeof value === "number" && value > 0 ? value : 60;
  }
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property real preferredWidth: 540

  spacing: Style.marginM
  Layout.fillWidth: true

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.WordWrap
    text: root.pluginApi?.tr("settings.shared-observation") ?? ""
  }

  // Working copy of the per-device config: { <id>: { enabled, icon, iconColor,
  // ringColor, launchCmd, name, type } }. Mutated in place by the controls so
  // the Repeater never rebuilds and loses edits.
  property var editDevices: ({})

  // Devices shown in the list, in bar order: union of currently-detected
  // devices and any previously-configured ones (so unplugged devices keep
  // their settings). Reorderable by drag; persisted as deviceOrder.
  property var deviceList: []

  // Geometry for the drag-reorderable, absolutely-positioned card list.
  // All cards are the same height, captured from a realized delegate.
  property real cardSpacing: Style.marginS
  property real cardHeight: 0
  readonly property real cardStride: cardHeight + cardSpacing

  readonly property var liveDevices: (pluginApi && pluginApi.mainInstance) ? (pluginApi.mainInstance.devices || []) : []

  readonly property var iconOptions: [
    {
      key: "",
      name: pluginApi?.tr("settings.icon.auto")
    },
    {
      key: "mouse",
      name: pluginApi?.tr("settings.icon.mouse")
    },
    {
      key: "keyboard",
      name: pluginApi?.tr("settings.icon.keyboard")
    },
    {
      key: "headphones",
      name: pluginApi?.tr("settings.icon.headphones")
    },
    {
      key: "device-gamepad",
      name: pluginApi?.tr("settings.icon.gamepad")
    },
    {
      key: "bluetooth",
      name: pluginApi?.tr("settings.icon.bluetooth")
    },
    {
      key: "device-desktop",
      name: pluginApi?.tr("settings.icon.desktop")
    },
    {
      key: "battery",
      name: pluginApi?.tr("settings.icon.battery")
    }
  ]

  // Notifiable mirror of the global "show percentage" setting. NToggle emits
  // toggled(checked) but never updates its own `checked`, so we drive it from
  // this property (same reason the per-device toggle uses enabledLocal).
  readonly property bool showPercentageEdit: root.showPercentageField?.value === true
  readonly property bool showChargingEdit: root.showChargingField?.value === true

  // Guards against committing during initial population.
  property bool initialized: false

  Component.onCompleted: {
    populateList();
    initialized = true;
  }

  function _defaultCfg() {
    return {
      enabled: false,
      icon: "",
      iconColor: "none",
      ringColor: "none",
      launchCmd: "",
      name: "",
      type: "device"
    };
  }

  function _source(id) {
    var i = id.indexOf(":");
    return i >= 0 ? id.substring(0, i) : id;
  }

  // Build editDevices + deviceList from saved settings and live detection.
  function deviceView(settings, live) {
    var saved = settings.devices || {};
    var merged = ({});

    // Seed from saved config (preserves offline devices).
    for (var id in saved) {
      merged[id] = Object.assign(root._defaultCfg(), saved[id]);
    }
    // Overlay live detection (updates name/type for known, adds new).
    var byId = ({});
    for (var i = 0; i < live.length; i++) {
      var d = live[i];
      byId[d.id] = d;
      if (!merged[d.id])
        merged[d.id] = root._defaultCfg();
      merged[d.id].name = d.name;
      merged[d.id].type = d.type;
    }

    // Heal stale duplicates: a saved offline entry that refers to the same
    // physical device as a detected one (same source + name, different id —
    // e.g. an old name-based id from when the serial was unreadable). Fold
    // its config into the detected id, then drop the stale entry.
    var changed = false;
    for (var k = 0; k < live.length; k++) {
      var dd = live[k];
      for (var mid in merged) {
        if (mid === dd.id || byId[mid])
          continue;
        if (root._source(mid) !== dd.source || merged[mid].name !== dd.name)
          continue;
        if (!saved.hasOwnProperty(dd.id)) {
          merged[mid].name = dd.name;
          merged[mid].type = dd.type;
          merged[dd.id] = merged[mid];
        }
        delete merged[mid];
        changed = true;
      }
    }

    // Build the display list honouring the saved order, appending any
    // newly-detected (online first) then offline devices not yet ordered.
    var order = settings.deviceOrder || [];
    var seen = ({});
    var list = [];
    var addId = function (id) {
      if (seen[id] || !merged[id])
        return;
      seen[id] = true;
      var on = byId[id];
      list.push({
                  "id": id,
                  "name": on ? on.name : (merged[id].name || id),
                  "type": on ? on.type : (merged[id].type || "device"),
                  "battery": on ? on.battery : -1,
                  "charging": on ? on.charging : false,
                  "online": !!on
                });
    };
    for (var oi = 0; oi < order.length; oi++)
      addId(order[oi]);
    for (var j = 0; j < live.length; j++)
      addId(live[j].id);
    for (var sid in merged)
      addId(sid);
    return {
      devices: merged,
      list: list
    };
  }

  // The working view is derived from the field values plus live detection,
  // so field Reset and the periodic rescan converge on the same state.
  function populateList() {
    var view = deviceView({
                            devices: root.devicesField?.value || ({}),
                            deviceOrder: root.deviceOrderField?.value || []
                          }, liveDevices);
    editDevices = view.devices;
    deviceList = view.list;
  }

  function _devicesIntent(source) {
    var devices = ({});
    for (var id in source)
      devices[id] = Object.assign({}, source[id]);
    return devices;
  }

  function _order(list) {
    return list.map(function (device) {
      return device.id;
    });
  }

  // Remove a device entry entirely (e.g. stale offline cruft). A still-present
  // device will be re-detected with default config on the next scan.
  function removeDevice(id) {
    var devices = root._devicesIntent(root.editDevices);
    delete devices[id];
    root.devicesField.set(devices);
    root.deviceOrderField.set(root._order(root.deviceList).filter(function (entry) {
      return entry !== id;
    }));
    root.populateList();
  }

  // Reorder the device list (drag-and-drop). Top = left-most in the bar.
  function moveDevice(fromIndex, toIndex) {
    if (fromIndex === toIndex)
      return;
    if (fromIndex < 0 || fromIndex >= root.deviceList.length)
      return;
    if (toIndex < 0 || toIndex >= root.deviceList.length)
      return;
    var nl = root.deviceList.slice();
    var item = nl.splice(fromIndex, 1)[0];
    nl.splice(toIndex, 0, item);
    root.deviceOrderField.set(root._order(nl));
    root.populateList();
  }

  function set(id, key, value) {
    var devices = root._devicesIntent(root.editDevices);
    devices[id] = Object.assign(root._defaultCfg(), devices[id]);
    devices[id][key] = value;
    root.devicesField.set(devices);
    root.populateList();
  }

  // Completion observer only; native publication belongs to the session.
  function saveSettings() {
    pluginApi?.saveSettings();
  }

  // ---- Global options ----------------------------------------------------

  NLabel {
    label: pluginApi?.tr("settings.header.label")
    description: pluginApi?.tr("settings.header.desc")
  }

  NPluginSettingsField {
    field: root.showPercentageField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.showPercentage.label")
      description: pluginApi?.tr("settings.showPercentage.desc")
      checked: root.showPercentageEdit
      onToggled: checked => {
        root.showPercentageField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.showChargingField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.showCharging.label")
      description: pluginApi?.tr("settings.showCharging.desc")
      checked: root.showChargingEdit
      onToggled: checked => {
        root.showChargingField.set(checked);
      }
    }
  }

  NPluginSettingsField {
    field: root.refreshIntervalField
    NSpinBox {
      id: intervalSpin
      objectName: "settings-range-editRefreshInterval"
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.refreshInterval.label")
      description: pluginApi?.tr("settings.refreshInterval.desc")
      from: 10
      to: 900
      stepSize: 10
      suffix: "s"
      value: root.editRefreshInterval
      onValueModified: value => root.refreshIntervalField.set(value)
    }
  }

  RowLayout {
    Layout.fillWidth: true
    NButton {
      text: pluginApi?.tr("settings.rescan")
      icon: "refresh"
      onClicked: {
        if (pluginApi && pluginApi.mainInstance)
          pluginApi.mainInstance.refresh();
        rescanTimer.restart();
      }
    }
    Item {
      Layout.fillWidth: true
    }
  }

  // Re-read the device list shortly after a manual scan completes.
  Timer {
    id: rescanTimer
    interval: 3000
    onTriggered: root.populateList()
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    visible: root.deviceList.length === 0
    text: pluginApi?.tr("settings.noDevices")
    color: AtmoColor.mOnSurfaceVariant
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  // ---- Per-device cards (drag the handle to reorder) ---------------------
  NPluginSettingsField {
    field: root.devicesField
    NPluginSettingsField {
      field: root.deviceOrderField
      Item {
        id: cardsContainer
        Layout.fillWidth: true
        implicitHeight: root.deviceList.length > 0 ? root.deviceList.length * root.cardStride - root.cardSpacing : 0

        Repeater {
          id: cardsRepeater
          model: root.deviceList

          delegate: Rectangle {
            id: card
            required property int index
            required property var modelData
            readonly property var cfg: root.editDevices[modelData.id] || root._defaultCfg()
            // Notifiable mirror of cfg.enabled so the toggle updates live
            // (editDevices is mutated in place and doesn't emit change signals).
            property bool enabledLocal: cfg.enabled === true

            // Drag state
            property bool dragging: false
            property int dragStartIndex: -1
            property int dragTargetIndex: -1

            width: cardsContainer.width
            height: cardCol.implicitHeight + Style.marginM * 2
            onHeightChanged: if (root.cardHeight !== height)
                               root.cardHeight = height

            radius: Style.radiusM
            color: AtmoColor.mSurfaceVariant
            border.width: 1
            border.color: dragging ? AtmoColor.mPrimary : AtmoColor.mOutline
            z: dragging ? 10 : 0

            // Resting position, with neighbours shifting to make room while
            // another card is dragged over them.
            y: {
              if (card.dragging)
                return card.y;
              var draggedIndex = -1;
              var targetIndex = -1;
              for (var i = 0; i < cardsRepeater.count; i++) {
                var it = cardsRepeater.itemAt(i);
                if (it && it.dragging) {
                  draggedIndex = it.dragStartIndex;
                  targetIndex = it.dragTargetIndex;
                  break;
                }
              }
              var stride = card.height + root.cardSpacing;
              if (draggedIndex !== -1 && targetIndex !== -1 && draggedIndex !== targetIndex) {
                if (draggedIndex < targetIndex) {
                  if (card.index > draggedIndex && card.index <= targetIndex)
                    return (card.index - 1) * stride;
                } else {
                  if (card.index >= targetIndex && card.index < draggedIndex)
                    return (card.index + 1) * stride;
                }
              }
              return card.index * stride;
            }

            Behavior on y {
              enabled: !card.dragging
              NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutQuad
              }
            }

            ColumnLayout {
              id: cardCol
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: Style.marginS

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                // Drag handle
                Rectangle {
                  id: dragHandle
                  Layout.preferredWidth: Style.baseWidgetSize * 0.7
                  Layout.preferredHeight: Style.baseWidgetSize * 0.7
                  Layout.alignment: Qt.AlignVCenter
                  radius: Style.iRadiusXS
                  color: dragMouse.containsMouse ? AtmoColor.mSurface : "transparent"

                  ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 3
                    Repeater {
                      model: 3
                      Rectangle {
                        Layout.preferredWidth: Style.baseWidgetSize * 0.45
                        Layout.preferredHeight: 2
                        radius: 1
                        color: AtmoColor.mOutline
                      }
                    }
                  }

                  MouseArea {
                    id: dragMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: Qt.SizeVerCursor
                    z: 1000
                    onPressed: mouse => {
                      card.dragStartIndex = card.index;
                      card.dragTargetIndex = card.index;
                      card.dragging = true;
                    }
                    onPositionChanged: mouse => {
                      if (!card.dragging)
                        return;
                      var dy = mouse.y - dragHandle.height / 2;
                      var newY = Math.max(0, Math.min(card.y + dy, cardsContainer.height - card.height));
                      card.y = newY;
                      var stride = card.height + root.cardSpacing;
                      var t = Math.floor((newY + card.height / 2) / stride);
                      card.dragTargetIndex = Math.max(0, Math.min(t, cardsRepeater.count - 1));
                    }
                    onReleased: {
                      var from = card.dragStartIndex;
                      var to = card.dragTargetIndex;
                      card.dragging = false;
                      card.dragStartIndex = -1;
                      card.dragTargetIndex = -1;
                      if (from !== -1 && to !== -1 && from !== to)
                        root.moveDevice(from, to);
                      else
                        root.deviceList = root.deviceList.slice(); // rebuild to snap back
                    }
                    onCanceled: {
                      card.dragging = false;
                      card.dragStartIndex = -1;
                      card.dragTargetIndex = -1;
                      root.deviceList = root.deviceList.slice();
                    }
                  }
                }

                NText {
                  text: card.modelData.name
                  font.weight: Style.fontWeightBold
                  color: AtmoColor.mOnSurface
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
                NText {
                  text: card.modelData.online ? (card.modelData.battery >= 0 ? card.modelData.battery + "%" : "—") + (card.modelData.charging ? " ⚡" : "") : pluginApi?.tr("settings.offline")
                  color: card.modelData.online ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
                }

                AtmoIconButton {
                  icon: "trash"
                  baseSize: Style.baseWidgetSize * 0.8
                  tooltipText: pluginApi?.tr("settings.removeDevice")
                  colorFg: AtmoColor.mError
                  onClicked: root.removeDevice(card.modelData.id)
                }
              }

              NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.showInBar")
                checked: card.enabledLocal
                onToggled: checked => {
                  card.enabledLocal = checked;
                  root.set(card.modelData.id, "enabled", checked);
                }
              }

              NComboBox {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.icon.label")
                model: root.iconOptions
                currentKey: card.cfg.icon || ""
                onSelected: key => root.set(card.modelData.id, "icon", key)
              }

              NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.iconColor.label")
                description: pluginApi?.tr("settings.iconColor.desc")
                currentKey: card.cfg.iconColor || "none"
                onSelected: key => root.set(card.modelData.id, "iconColor", key)
              }

              NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.ringColor.label")
                description: pluginApi?.tr("settings.ringColor.desc")
                currentKey: card.cfg.ringColor || "none"
                onSelected: key => root.set(card.modelData.id, "ringColor", key)
              }

              NTextInput {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.launchCmd.label")
                text: card.cfg.launchCmd || ""
                placeholderText: pluginApi?.tr("settings.launchCmd.placeholder")
                onEditCommitted: root.set(card.modelData.id, "launchCmd", text)
              }
            }
          }
        }
      }
    }
  }
}
