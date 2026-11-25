import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null
  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.Wrap
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
  }
  readonly property var screenshotPathField: pluginApi?.field("screenshotPath") ?? null
  readonly property var videoPathField: pluginApi?.field("videoPath") ?? null
  readonly property var filenameFormatField: pluginApi?.field("filenameFormat") ?? null
  readonly property var x02ApiKeyField: pluginApi?.field("x02ApiKey") ?? null
  readonly property var x02ExpiryField: pluginApi?.field("x02Expiry") ?? null
  readonly property var shareSkipPopoverField: pluginApi?.field("shareSkipPopover") ?? null
  readonly property var recordSkipConfirmationField: pluginApi?.field("recordSkipConfirmation") ?? null
  readonly property var recordCopyToClipboardField: pluginApi?.field("recordCopyToClipboard") ?? null
  readonly property var gifMaxSecondsField: pluginApi?.field("gifMaxSeconds") ?? null
  readonly property var searchEngineUrlField: pluginApi?.field("searchEngineUrl") ?? null
  spacing: Style.marginL

  readonly property string screenshotPath: root.screenshotPathField?.value || ""
  readonly property string videoPath: root.videoPathField?.value || ""
  readonly property string filenameFormat: root.filenameFormatField?.value || ""
  readonly property string x02ApiKey: root.x02ApiKeyField?.value || ""
  readonly property string x02Expiry: root.x02ExpiryField?.value || "7d"
  readonly property bool shareSkipPopover: root.shareSkipPopoverField?.value ?? false
  readonly property bool recordSkipConfirmation: root.recordSkipConfirmationField?.value ?? false
  readonly property bool recordCopyToClipboard: root.recordCopyToClipboardField?.value ?? false
  readonly property string gifMaxSeconds: String(Math.max(5, Math.min(300, root.gifMaxSecondsField?.value ?? 30)))
  readonly property string searchEngineUrl: root.searchEngineUrlField?.value || ""
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property string _previewNow: ""

  Timer {
    id: previewClock
    interval: 1000
    repeat: true
    running: root.visible
    onTriggered: root._previewNow = new Date().toString()
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.saveSettings();
  }

  function buildPreview(fmt) {
    var _ = root._previewNow;
    var now = new Date();
    if (!fmt || fmt.trim() === "")
      return Qt.formatDateTime(now, "yyyy-MM-dd_HH-mm-ss");
    return fmt.replace(/%Y/g, Qt.formatDateTime(now, "yyyy")).replace(/%m/g, Qt.formatDateTime(now, "MM")).replace(/%d/g, Qt.formatDateTime(now, "dd")).replace(/%H/g, Qt.formatDateTime(now, "HH")).replace(/%M/g, Qt.formatDateTime(now, "mm")).replace(/%S/g, Qt.formatDateTime(now, "ss"));
  }

  // ── Paths ─────────────────────────────────────────────────────────────────
  NPluginSettingsField {
    field: root.screenshotPathField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.screenshotPath")
      description: pluginApi?.tr("settings.screenshotPathDesc")
      placeholderText: "~/Pictures/Screenshots"
      text: root.screenshotPath
      onEditCommitted: {
        root.screenshotPathField.set(text);
      }
    }
  }

  NPluginSettingsField {
    field: root.videoPathField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.videoPath")
      description: pluginApi?.tr("settings.videoPathDesc")
      placeholderText: "~/Videos"
      text: root.videoPath
      onEditCommitted: {
        root.videoPathField.set(text);
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  // ── Filename format ───────────────────────────────────────────────────────
  NPluginSettingsField {
    field: root.filenameFormatField
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      ColumnLayout {
        spacing: Style.marginXS
        NLabel {
          label: pluginApi?.tr("settings.filenameFormat")
        }
        NText {
          text: pluginApi?.tr("settings.filenameFormatDesc")
          pointSize: Style.fontSizeXS
          color: AtmoColor.mOnSurfaceVariant
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }
      }

      Flow {
        Layout.fillWidth: true
        spacing: Style.marginS
        readonly property var tokens: [
          {
            label: pluginApi?.tr("settings.filenameTokens.year"),
            value: "%Y"
          },
          {
            label: pluginApi?.tr("settings.filenameTokens.month"),
            value: "%m"
          },
          {
            label: pluginApi?.tr("settings.filenameTokens.day"),
            value: "%d"
          },
          {
            label: pluginApi?.tr("settings.filenameTokens.hour"),
            value: "%H"
          },
          {
            label: pluginApi?.tr("settings.filenameTokens.minute"),
            value: "%M"
          },
          {
            label: pluginApi?.tr("settings.filenameTokens.second"),
            value: "%S"
          },
        ]
        Repeater {
          model: parent.tokens
          delegate: Rectangle {
            height: 28
            width: tokenRow.implicitWidth + Style.marginM * 2
            radius: Style.radiusM
            color: tokenMA.containsMouse ? AtmoColor.mPrimary : AtmoColor.mSurfaceVariant
            Behavior on color {
              ColorAnimation {
                duration: 120
              }
            }
            Row {
              id: tokenRow
              anchors.centerIn: parent
              spacing: Style.marginXS
              NText {
                text: modelData.label
                pointSize: Style.fontSizeXS
                font.weight: Font.Medium
                color: tokenMA.containsMouse ? AtmoColor.mOnPrimary : AtmoColor.mOnSurface
                anchors.verticalCenter: parent.verticalCenter
              }
              NText {
                text: modelData.value
                pointSize: Style.fontSizeXS
                color: tokenMA.containsMouse ? Qt.rgba(1, 1, 1, 0.65) : AtmoColor.mOnSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
              }
            }
            MouseArea {
              id: tokenMA
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (!filenameInput.inputItem)
                  return;
                var input = filenameInput.inputItem;
                var cur = input.cursorPosition;
                var txt = input.text;
                root.filenameFormatField.set(txt.substring(0, cur) + modelData.value + txt.substring(cur));
                input.cursorPosition = cur + modelData.value.length;
                input.forceActiveFocus();
              }
            }
          }
        }
      }

      NTextInput {
        id: filenameInput
        Layout.fillWidth: true
        placeholderText: "%Y-%m-%dT%H-%M-%S"
        text: root.filenameFormat
        onEditCommitted: root.filenameFormatField.set(text)
      }

      Rectangle {
        Layout.fillWidth: true
        height: previewRow.implicitHeight + Style.marginM * 2
        radius: Style.radiusM
        color: AtmoColor.mSurfaceVariant
        opacity: 0.7
        Row {
          id: previewRow
          anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Style.marginM
            rightMargin: Style.marginM
          }
          spacing: Style.marginS
          AtmoIcon {
            icon: "file"
            color: AtmoColor.mOnSurfaceVariant
            scale: 0.85
            anchors.verticalCenter: parent.verticalCenter
          }
          NText {
            text: root.buildPreview(root.filenameFormat) + ".ext"
            pointSize: Style.fontSizeXS
            color: AtmoColor.mOnSurface
            font.family: "monospace"
            elide: Text.ElideRight
            width: parent.width - Style.marginM * 2
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  // ── Share ─────────────────────────────────────────────────────────────────
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    RowLayout {
      spacing: Style.marginS
      AtmoIcon {
        icon: "share"
        color: AtmoColor.mPrimary
      }
      NLabel {
        label: pluginApi?.tr("settings.shareSection")
      }
    }

    NPluginSettingsField {
      field: root.x02ApiKeyField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.x02ApiKey")
        description: pluginApi?.tr("settings.x02ApiKeyDesc")
        placeholderText: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        text: root.x02ApiKey
        onEditCommitted: {
          root.x02ApiKeyField.set(text);
        }
      }
    }

    // Expiry — only relevant when API key is set
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXS
      opacity: root.x02ApiKey.trim() !== "" ? 1.0 : 0.4

      NLabel {
        label: pluginApi?.tr("settings.x02Expiry")
      }

      NText {
        text: pluginApi?.tr("settings.x02ExpiryDesc")
        pointSize: Style.fontSizeXS
        color: AtmoColor.mOnSurfaceVariant
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      NPluginSettingsField {
        field: root.x02ExpiryField
        Flow {
          Layout.fillWidth: true
          spacing: Style.marginS

          readonly property var expiryDefs: [
            {
              id: "1h",
              label: pluginApi?.tr("settings.expiry1h")
            },
            {
              id: "1d",
              label: pluginApi?.tr("settings.expiry1d")
            },
            {
              id: "7d",
              label: pluginApi?.tr("settings.expiry7d")
            },
            {
              id: "30d",
              label: pluginApi?.tr("settings.expiry30d")
            },
            {
              id: "permanent",
              label: pluginApi?.tr("settings.expiryPermanent")
            },
          ]

          Repeater {
            model: parent.expiryDefs
            delegate: Rectangle {
              height: 28
              width: _expLabel.implicitWidth + Style.marginM * 2
              radius: Style.radiusM
              enabled: root.x02ApiKey.trim() !== ""
              color: root.x02Expiry === modelData.id ? AtmoColor.mPrimary : (_expMA.containsMouse ? AtmoColor.mHover : AtmoColor.mSurfaceVariant)
              Behavior on color {
                ColorAnimation {
                  duration: 120
                }
              }
              NText {
                id: _expLabel
                anchors.centerIn: parent
                text: modelData.label
                pointSize: Style.fontSizeXS
                font.weight: root.x02Expiry === modelData.id ? Font.Bold : Font.Normal
                color: root.x02Expiry === modelData.id ? AtmoColor.mOnPrimary : (_expMA.containsMouse ? AtmoColor.mOnHover : AtmoColor.mOnSurface)
              }
              MouseArea {
                id: _expMA
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: parent.enabled
                onClicked: root.x02ExpiryField.set(modelData.id)
              }
            }
          }
        }
      }
    }

    NPluginSettingsField {
      field: root.shareSkipPopoverField
      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.shareSkipPopover")
        description: pluginApi?.tr("settings.shareSkipPopoverDesc")
        checked: root.shareSkipPopover
        onToggled: v => {
          root.shareSkipPopoverField.set(v);
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  // ── Recording ─────────────────────────────────────────────────────────────
  NLabel {
    label: pluginApi?.tr("settings.recordingSection")
  }

  NPluginSettingsField {
    field: root.recordSkipConfirmationField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.recordSkipConfirmation")
      description: pluginApi?.tr("settings.recordSkipConfirmationDesc")
      checked: root.recordSkipConfirmation
      onToggled: v => {
        root.recordSkipConfirmationField.set(v);
      }
    }
  }

  NPluginSettingsField {
    field: root.recordCopyToClipboardField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.recordCopyToClipboard")
      description: pluginApi?.tr("settings.recordCopyToClipboardDesc")
      checked: root.recordCopyToClipboard
      onToggled: v => {
        root.recordCopyToClipboardField.set(v);
      }
    }
  }

  NPluginSettingsField {
    field: root.gifMaxSecondsField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.gifMaxSeconds")
      description: pluginApi?.tr("settings.gifMaxSecondsDesc")
      placeholderText: "30"
      text: root.gifMaxSeconds
      onEditCommitted: {
        var val = parseInt(text);
        if (!isNaN(val))
          root.gifMaxSecondsField.set(Math.max(5, Math.min(300, val)));
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
    Layout.topMargin: Style.marginM
    Layout.bottomMargin: Style.marginM
  }

  // ── OCR ───────────────────────────────────────────────────────────────────
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    RowLayout {
      spacing: Style.marginS
      AtmoIcon {
        icon: "scan"
        color: AtmoColor.mPrimary
      }
      NLabel {
        label: pluginApi?.tr("settings.ocrSection")
      }
    }

    NPluginSettingsField {
      field: root.searchEngineUrlField
      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.searchEngineUrl")
        description: pluginApi?.tr("settings.searchEngineUrlDesc")
        placeholderText: "https://www.google.com/search?q="
        text: root.searchEngineUrl
        onEditCommitted: {
          root.searchEngineUrlField.set(text);
        }
      }
    }
  }
}
