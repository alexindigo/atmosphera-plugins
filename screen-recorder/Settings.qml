import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Portals
import qs.Services.Compositor
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null
  readonly property var hideInactiveField: pluginApi?.field("hideInactive") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null
  readonly property var directoryField: pluginApi?.field("directory") ?? null
  readonly property var filenamePatternField: pluginApi?.field("filenamePattern") ?? null
  readonly property var frameRateField: pluginApi?.field("frameRate") ?? null
  readonly property var customFrameRateField: pluginApi?.field("customFrameRate") ?? null
  readonly property var audioCodecField: pluginApi?.field("audioCodec") ?? null
  readonly property var videoCodecField: pluginApi?.field("videoCodec") ?? null
  readonly property var qualityField: pluginApi?.field("quality") ?? null
  readonly property var colorRangeField: pluginApi?.field("colorRange") ?? null
  readonly property var showCursorField: pluginApi?.field("showCursor") ?? null
  readonly property var copyToClipboardField: pluginApi?.field("copyToClipboard") ?? null
  readonly property var audioSourceField: pluginApi?.field("audioSource") ?? null
  readonly property var videoSourceField: pluginApi?.field("videoSource") ?? null
  readonly property var resolutionField: pluginApi?.field("resolution") ?? null
  readonly property var restorePortalSessionField: pluginApi?.field("restorePortalSession") ?? null
  readonly property var replayEnabledField: pluginApi?.field("replayEnabled") ?? null
  readonly property var replayDurationField: pluginApi?.field("replayDuration") ?? null
  readonly property var customReplayDurationField: pluginApi?.field("customReplayDuration") ?? null
  readonly property var replayStorageField: pluginApi?.field("replayStorage") ?? null

  readonly property bool editHideInactive: root.hideInactiveField?.value ?? false

  readonly property string editIconColor: root.iconColorField?.value ?? "none"

  readonly property string editDirectory: root.directoryField?.value || ""

  readonly property string editFilenamePattern: root.filenamePatternField?.value || "recording_yyyyMMdd_HHmmss"

  // Migrate legacy frame rates to "custom"
  readonly property var _validFrameRates: ["30", "60", "120", "custom"]
  readonly property string _rawFrameRate: pluginApi?.pluginSettings?.frameRate || pluginApi?.manifest?.metadata?.defaultSettings?.frameRate || "60"

  readonly property string editFrameRate: _validFrameRates.includes(_rawFrameRate) ? _rawFrameRate : "custom"

  readonly property string editCustomFrameRate: _validFrameRates.includes(_rawFrameRate) ? (root.customFrameRateField?.value || "60") : _rawFrameRate

  readonly property string editAudioCodec: root.audioCodecField?.value || "opus"

  readonly property string editVideoCodec: root.videoCodecField?.value || "h264"

  readonly property string editQuality: root.qualityField?.value || "very_high"

  readonly property string editColorRange: root.colorRangeField?.value || "limited"

  readonly property bool editShowCursor: root.showCursorField?.value ?? true

  readonly property bool editCopyToClipboard: root.copyToClipboardField?.value ?? false

  readonly property string editAudioSource: root.audioSourceField?.value || "default_output"

  readonly property string editVideoSource: root.videoSourceField?.value || "portal"
  function selectVideoSource(key) {
    if (!root.videoSourceField.set(key)) return false;
    // Only the user's source selection authors its dependent codec choice.
    // Reset, inheritance and metadata refresh must not create codec intent.
    if (key !== "screen" && key !== "focused-monitor" && (root.editVideoCodec === "av1_hdr" || root.editVideoCodec === "hevc_hdr"))
      return root.videoCodecField.set("h264");
    return true;
  }

  readonly property string editResolution: root.resolutionField?.value || "original"

  readonly property bool editRestorePortalSession: root.restorePortalSessionField?.value ?? false

  // Replay settings
  readonly property bool editReplayEnabled: root.replayEnabledField?.value ?? false

  readonly property var _validReplayDurations: ["15", "30", "60", "120", "300", "custom"]
  readonly property string _rawReplayDuration: pluginApi?.pluginSettings?.replayDuration || pluginApi?.manifest?.metadata?.defaultSettings?.replayDuration || "30"

  readonly property string editReplayDuration: _validReplayDurations.includes(_rawReplayDuration) ? _rawReplayDuration : "custom"

  readonly property string editCustomReplayDuration: _validReplayDurations.includes(_rawReplayDuration) ? (root.customReplayDurationField?.value || "30") : _rawReplayDuration

  readonly property string editReplayStorage: root.replayStorageField?.value || "ram"

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi || !pluginApi.pluginSettings) {
      Logger.e("ScreenRecorder", "Cannot save: pluginApi or pluginSettings is null");
      return;
    }

    // Core settings

    // Replay settings

    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("ScreenRecorder", "Settings saved successfully");
    });
  }
  // Icon Color
  NPluginSettingsField {
    field: root.iconColorField
    NComboBox {
      label: I18n.tr("common.select-icon-color")
      description: I18n.tr("common.select-color-description")
      model: AtmoColor.colorKeyModel
      currentKey: root.editIconColor
      onSelected: key => root.iconColorField.set(key)
      minimumWidth: 200
    }
  }

  NPluginSettingsField {
    field: root.directoryField
    NTextInputButton {
      label: pluginApi.tr("settings.general.output-folder")
      description: pluginApi.tr("settings.general.output-folder-description")
      placeholderText: Quickshell.env("HOME") + "/Videos"
      text: root.editDirectory
      buttonIcon: "folder-open"
      buttonTooltip: pluginApi.tr("settings.general.output-folder")
      onInputEditCommitted: root.directoryField.set(text)
      onButtonClicked: folderPicker.openFilePicker()
    }
  }

  // Filename Pattern
  NPluginSettingsField {
    field: root.filenamePatternField
    NTextInput {
      label: pluginApi?.tr("settings.filename-pattern.label") || "Filename pattern"
      description: pluginApi?.tr("settings.filename-pattern.description") || "Pattern for generated filenames. Supported: yyyy, yy, MM, M, dd, d, HH, H, mm, m, ss, s (e.g., mycool-recording_yyyyMMdd_HHmmss)"
      placeholderText: "recording_yyyyMMdd_HHmmss"
      text: root.editFilenamePattern
      onEditCommitted: root.filenamePatternField.set(text)
      Layout.fillWidth: true
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // Show Cursor
  NPluginSettingsField {
    field: root.showCursorField
    NToggle {
      label: pluginApi.tr("settings.general.show-cursor")
      description: pluginApi.tr("settings.general.show-cursor-description")
      checked: root.editShowCursor
      onToggled: c => root.showCursorField.set(c)
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.showCursor ?? true
    }
  }

  // Copy to Clipboard
  NPluginSettingsField {
    field: root.copyToClipboardField
    NToggle {
      label: pluginApi.tr("settings.general.copy-to-clipboard")
      description: pluginApi.tr("settings.general.copy-to-clipboard-description")
      checked: root.editCopyToClipboard
      onToggled: c => root.copyToClipboardField.set(c)
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.copyToClipboard ?? false
    }
  }

  // Hide When Inactive Toggle
  NPluginSettingsField {
    field: root.hideInactiveField
    NToggle {
      label: pluginApi.tr("settings.general.hide-when-inactive")
      description: pluginApi.tr("settings.general.hide-when-inactive-description")
      checked: root.editHideInactive
      onToggled: c => root.hideInactiveField.set(c)
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.hideInactive ?? false
    }
  }

  // Restore Portal Session
  NPluginSettingsField {
    field: root.restorePortalSessionField
    NToggle {
      label: pluginApi.tr("settings.general.restore-portal-session")
      description: pluginApi.tr("settings.general.restore-portal-session-description")
      checked: root.editRestorePortalSession
      onToggled: c => root.restorePortalSessionField.set(c)
      defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.restorePortalSession ?? false
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // Replay Settings
  ColumnLayout {
    spacing: Style.marginL
    Layout.fillWidth: true

    NPluginSettingsField {
      field: root.replayEnabledField
      NToggle {
        label: pluginApi.tr("settings.replay.enable")
        description: pluginApi.tr("settings.replay.enable-desc")
        checked: root.editReplayEnabled
        onToggled: c => root.replayEnabledField.set(c)
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.replayEnabled ?? false
      }
    }

    NPluginSettingsField {
      field: root.replayDurationField
      visible: root.editReplayEnabled
      NComboBox {
        label: pluginApi.tr("settings.replay.duration")
        description: pluginApi.tr("settings.replay.duration-desc")
        model: [
          {
            "key": "15",
            "name": "15s"
          },
          {
            "key": "30",
            "name": "30s"
          },
          {
            "key": "60",
            "name": "60s"
          },
          {
            "key": "120",
            "name": "2 min"
          },
          {
            "key": "300",
            "name": "5 min"
          },
          {
            "key": "custom",
            "name": pluginApi.tr("settings.video.frame-rate-custom")
          }
        ]
        currentKey: root.editReplayDuration
        onSelected: key => root.replayDurationField.set(key)
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.replayDuration || "30"
      }
    }

    NPluginSettingsField {
      field: root.customReplayDurationField
      visible: root.editReplayEnabled && root.editReplayDuration === "custom"
      NTextInput {
        label: pluginApi.tr("settings.replay.custom-duration")
        description: pluginApi.tr("settings.replay.custom-duration-desc")
        placeholderText: "30"
        text: root.editCustomReplayDuration
        onEditCommitted: {
          var numeric = text.replace(/[^0-9]/g, '');
          if (numeric !== text) {
            text = numeric;
          }
          if (numeric) {
            root.customReplayDurationField.set(numeric);
          }
        }
        Layout.fillWidth: true
      }
    }

    NPluginSettingsField {
      field: root.replayStorageField
      visible: root.editReplayEnabled
      NComboBox {
        label: pluginApi.tr("settings.replay.storage")
        description: pluginApi.tr("settings.replay.storage-desc")
        model: [
          {
            "key": "ram",
            "name": pluginApi.tr("settings.replay.storage-ram")
          },
          {
            "key": "disk",
            "name": pluginApi.tr("settings.replay.storage-disk")
          }
        ]
        currentKey: root.editReplayStorage
        onSelected: key => root.replayStorageField.set(key)
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.replayStorage || "ram"
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // Video Settings
  ColumnLayout {
    spacing: Style.marginL
    Layout.fillWidth: true

    // Source
    NPluginSettingsField {
      field: root.videoSourceField
      NComboBox {
        label: pluginApi.tr("settings.video.source")
        description: pluginApi.tr("settings.video.source-desc")
        model: {
          let options = [
                {
                  "key": "portal",
                  "name": pluginApi.tr("settings.video.sources-portal")
                },
                {
                  "key": "screen",
                  "name": pluginApi.tr("settings.video.sources-screen")
                }
              ];
          if (CompositorService.isHyprland) {
            options.push({
                           "key": "focused-monitor",
                           "name": pluginApi.tr("settings.video.sources-focused-monitor")
                         });
          }
          return options;
        }
        currentKey: root.editVideoSource
        onSelected: key => root.selectVideoSource(key)
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.videoSource || "portal"
      }
    }

    // Frame Rate
    NPluginSettingsField {
      field: root.frameRateField
      NComboBox {
        label: pluginApi.tr("settings.video.frame-rate")
        description: pluginApi.tr("settings.video.frame-rate-desc")
        model: [
          {
            "key": "30",
            "name": "30 FPS"
          },
          {
            "key": "60",
            "name": "60 FPS"
          },
          {
            "key": "120",
            "name": "120 FPS"
          },
          {
            "key": "custom",
            "name": pluginApi.tr("settings.video.frame-rate-custom")
          }
        ]
        currentKey: root.editFrameRate
        onSelected: key => root.frameRateField.set(key)
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.frameRate || "60"
      }
    }

    // Custom Frame Rate
    NPluginSettingsField {
      field: root.customFrameRateField
      visible: root.editFrameRate === "custom"
      NTextInput {
        label: pluginApi.tr("settings.video.custom-frame-rate")
        description: pluginApi.tr("settings.video.custom-frame-rate-desc")
        placeholderText: "60"
        text: root.editCustomFrameRate
        onEditCommitted: {
          // Only allow numeric values
          var numeric = text.replace(/[^0-9]/g, '');
          if (numeric !== text) {
            text = numeric;
          }
          if (numeric) {
            root.customFrameRateField.set(numeric);
          }
        }
        Layout.fillWidth: true
      }
    }

    // Video Quality
    NPluginSettingsField {
      field: root.qualityField
      NComboBox {
        label: pluginApi.tr("settings.video.quality")
        description: pluginApi.tr("settings.video.quality-desc")
        model: [
          {
            "key": "medium",
            "name": pluginApi.tr("settings.video.quality-medium")
          },
          {
            "key": "high",
            "name": pluginApi.tr("settings.video.quality-high")
          },
          {
            "key": "very_high",
            "name": pluginApi.tr("settings.video.quality-very-high")
          },
          {
            "key": "ultra",
            "name": pluginApi.tr("settings.video.quality-ultra")
          }
        ]
        currentKey: root.editQuality
        onSelected: key => root.qualityField.set(key)
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.quality || "very_high"
      }
    }

    // Video Codec
    NPluginSettingsField {
      field: root.videoCodecField
      NComboBox {
        label: pluginApi.tr("settings.video.codec")
        description: pluginApi.tr("settings.video.codec-desc")
        model: {
          let options = [
                {
                  "key": "h264",
                  "name": "H264"
                },
                {
                  "key": "hevc",
                  "name": "HEVC"
                },
                {
                  "key": "av1",
                  "name": "AV1"
                },
                {
                  "key": "vp8",
                  "name": "VP8"
                },
                {
                  "key": "vp9",
                  "name": "VP9"
                }
              ];
          // Only add HDR options if source is 'screen' or 'focused-monitor'
          if (root.editVideoSource === "screen" || root.editVideoSource === "focused-monitor") {
            options.push({
                           "key": "hevc_hdr",
                           "name": "HEVC HDR"
                         });
            options.push({
                           "key": "av1_hdr",
                           "name": "AV1 HDR"
                         });
          }
          return options;
        }
        currentKey: root.editVideoCodec
        onSelected: key => {
          root.videoCodecField.set(key);
          // If an HDR codec is selected, change the colorRange to full
          if (key.includes("_hdr")) {
            root.colorRangeField.set("full");
          }
        }
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.videoCodec || "h264"

      }
    }

    // Color Range
    NPluginSettingsField {
      field: root.colorRangeField
      NComboBox {
        label: pluginApi.tr("settings.video.color-range")
        description: pluginApi.tr("settings.video.color-range-desc")
        model: [
          {
            "key": "limited",
            "name": pluginApi.tr("settings.video.color-range-limited")
          },
          {
            "key": "full",
            "name": pluginApi.tr("settings.video.color-range-full")
          }
        ]
        currentKey: root.editColorRange
        onSelected: key => root.colorRangeField.set(key)
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.colorRange || "limited"
      }
    }

    // Resolution
    NPluginSettingsField {
      field: root.resolutionField
      NComboBox {
        label: pluginApi.tr("settings.video.resolution")
        description: pluginApi.tr("settings.video.resolution-desc")
        model: [
          {
            "key": "original",
            "name": pluginApi.tr("settings.video.resolution-original")
          },
          {
            "key": "1920x1080",
            "name": "1920x1080 (Full HD)"
          },
          {
            "key": "1920x1200",
            "name": "1920x1200 (WUXGA)"
          },
          {
            "key": "2560x1440",
            "name": "2560x1440 (QHD)"
          },
          {
            "key": "3840x2160",
            "name": "3840x2160 (4K)"
          },
          {
            "key": "1280x720",
            "name": "1280x720 (HD)"
          }
        ]
        currentKey: root.editResolution
        onSelected: key => root.resolutionField.set(key)
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.resolution || "original"
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // Audio Settings
  ColumnLayout {
    spacing: Style.marginL
    Layout.fillWidth: true

    // Audio Source
    NPluginSettingsField {
      field: root.audioSourceField
      NComboBox {
        label: pluginApi.tr("settings.audio.source")
        description: pluginApi.tr("settings.audio.source-desc")
        model: [
          {
            "key": "none",
            "name": pluginApi.tr("settings.audio.audio-sources-none")
          },
          {
            "key": "default_output",
            "name": pluginApi.tr("settings.audio.audio-sources-system-output")
          },
          {
            "key": "default_input",
            "name": pluginApi.tr("settings.audio.audio-sources-microphone-input")
          },
          {
            "key": "both",
            "name": pluginApi.tr("settings.audio.audio-sources-both")
          }
        ]
        currentKey: root.editAudioSource
        onSelected: key => root.audioSourceField.set(key)
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.audioSource || "default_output"
      }
    }

    // Audio Codec
    NPluginSettingsField {
      field: root.audioCodecField
      NComboBox {
        label: pluginApi.tr("settings.audio.codec")
        description: pluginApi.tr("settings.audio.codec-desc")
        model: [
          {
            "key": "opus",
            "name": "Opus"
          },
          {
            "key": "aac",
            "name": "AAC"
          }
        ]
        currentKey: root.editAudioCodec
        onSelected: key => root.audioCodecField.set(key)
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.audioCodec || "opus"
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }

  PortalFilePicker {
    id: folderPicker
    selectionMode: "folders"
    title: pluginApi.tr("settings.general.output-folder")
    initialPath: root.editDirectory || Quickshell.env("HOME") + "/Videos"
    onAccepted: paths => {
      if (paths.length > 0) {
        root.directoryField.set(paths[0]);
      }
    }
  }
}
