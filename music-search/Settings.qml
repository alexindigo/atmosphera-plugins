import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Portals
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var autoSaveMp3AfterPlaybackField: pluginApi?.field("autoSaveMp3AfterPlayback") ?? null
  readonly property var showHomeRecentField: pluginApi?.field("showHomeRecent") ?? null
  readonly property var showHomeTopField: pluginApi?.field("showHomeTop") ?? null
  readonly property var showHomeTagsField: pluginApi?.field("showHomeTags") ?? null
  readonly property var showHomeArtistsField: pluginApi?.field("showHomeArtists") ?? null
  readonly property var showHomePlaylistsField: pluginApi?.field("showHomePlaylists") ?? null
  readonly property var defaultPanelTabField: pluginApi?.field("defaultPanelTab") ?? null
  readonly property var defaultPanelLibrarySectionField: pluginApi?.field("defaultPanelLibrarySection") ?? null
  readonly property var panelDensityField: pluginApi?.field("panelDensity") ?? null
  readonly property var showPanelHeaderField: pluginApi?.field("showPanelHeader") ?? null
  readonly property var showPanelNowPlayingField: pluginApi?.field("showPanelNowPlaying") ?? null
  readonly property var showPanelPlaybackProgressField: pluginApi?.field("showPanelPlaybackProgress") ?? null
  readonly property var showPanelProviderChipsField: pluginApi?.field("showPanelProviderChips") ?? null
  readonly property var showPanelRecentTracksField: pluginApi?.field("showPanelRecentTracks") ?? null
  readonly property var showPanelSearchHelperField: pluginApi?.field("showPanelSearchHelper") ?? null
  readonly property var showPanelPreviewField: pluginApi?.field("showPanelPreview") ?? null
  readonly property var showPanelUrlActionsField: pluginApi?.field("showPanelUrlActions") ?? null
  readonly property var showPanelSpeedControlsField: pluginApi?.field("showPanelSpeedControls") ?? null
  readonly property var showPanelQueueControlsField: pluginApi?.field("showPanelQueueControls") ?? null
  readonly property var showPanelStatusBannerField: pluginApi?.field("showPanelStatusBanner") ?? null
  readonly property var showBarHoverTrackTitleField: pluginApi?.field("showBarHoverTrackTitle") ?? null
  readonly property var previewMetadataModeField: pluginApi?.field("previewMetadataMode") ?? null
  readonly property var previewThumbnailSizeField: pluginApi?.field("previewThumbnailSize") ?? null
  readonly property var showPreviewChipsField: pluginApi?.field("showPreviewChips") ?? null
  readonly property var showUploaderMetadataField: pluginApi?.field("showUploaderMetadata") ?? null
  readonly property var showAlbumMetadataField: pluginApi?.field("showAlbumMetadata") ?? null
  readonly property var showDurationMetadataField: pluginApi?.field("showDurationMetadata") ?? null
  readonly property var showRatingMetadataField: pluginApi?.field("showRatingMetadata") ?? null
  readonly property var showTagMetadataField: pluginApi?.field("showTagMetadata") ?? null
  readonly property var showPlayStatsMetadataField: pluginApi?.field("showPlayStatsMetadata") ?? null
  readonly property var showStatusMetadataField: pluginApi?.field("showStatusMetadata") ?? null
  readonly property var mainInstance: pluginApi?.mainInstance ?? null
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
  // Effective selected values for presentation; controls submit field intents.
  readonly property var editPreferences: pluginApi?.pluginSettings ?? ({})
  readonly property string editDensity: editPreferences.panelDensity ?? root.defaults.panelDensity ?? "balanced"
  // Explicit field intents only; the selected session owns Apply/Reset.
  // Download folder and cache limit are separate explicit helper actions.
  readonly property bool settingsDirty: false
  readonly property string defaultDownloadDirectory: Quickshell.env("HOME") + "/Music/Noctalia"
  readonly property string currentProvider: root.mainInstance?.currentProvider ?? "youtube"
  readonly property string currentSortBy: root.mainInstance?.currentSortBy ?? "date"
  readonly property string currentYtPlayerClient: root.mainInstance?.ytPlayerClient ?? "android"
  readonly property string currentDownloadDirectory: root.mainInstance?.downloadDirectory ?? root.defaultDownloadDirectory
  readonly property int currentDownloadCacheMaxMb: root.mainInstance?.downloadCacheMaxMb ?? 0
  readonly property string previewMetadataMode: editPreferences.previewMetadataMode ?? root.defaults.previewMetadataMode ?? "always"
  readonly property bool showUploaderMetadata: editPreferences.showUploaderMetadata ?? root.defaults.showUploaderMetadata ?? true
  readonly property bool showAlbumMetadata: editPreferences.showAlbumMetadata ?? root.defaults.showAlbumMetadata ?? true
  readonly property bool showDurationMetadata: editPreferences.showDurationMetadata ?? root.defaults.showDurationMetadata ?? true
  readonly property bool showRatingMetadata: editPreferences.showRatingMetadata ?? root.defaults.showRatingMetadata ?? true
  readonly property bool showTagMetadata: editPreferences.showTagMetadata ?? root.defaults.showTagMetadata ?? true
  readonly property bool showPlayStatsMetadata: editPreferences.showPlayStatsMetadata ?? root.defaults.showPlayStatsMetadata ?? true
  readonly property bool showStatusMetadata: editPreferences.showStatusMetadata ?? root.defaults.showStatusMetadata ?? true
  readonly property bool showPreviewChips: editPreferences.showPreviewChips ?? root.defaults.showPreviewChips ?? true
  readonly property string previewThumbnailSize: editPreferences.previewThumbnailSize ?? root.defaults.previewThumbnailSize ?? "comfortable"
  readonly property bool showHomeRecent: editPreferences.showHomeRecent ?? root.defaults.showHomeRecent ?? true
  readonly property bool showHomeTop: editPreferences.showHomeTop ?? root.defaults.showHomeTop ?? true
  readonly property bool showHomeTags: editPreferences.showHomeTags ?? root.defaults.showHomeTags ?? true
  readonly property bool showHomeArtists: editPreferences.showHomeArtists ?? root.defaults.showHomeArtists ?? true
  readonly property bool showHomePlaylists: editPreferences.showHomePlaylists ?? root.defaults.showHomePlaylists ?? true
  readonly property string defaultPanelTab: editPreferences.defaultPanelTab ?? root.defaults.defaultPanelTab ?? "search"
  readonly property string defaultPanelLibrarySection: editPreferences.defaultPanelLibrarySection ?? root.defaults.defaultPanelLibrarySection ?? "tracks"
  readonly property string panelDensity: editDensity
  readonly property bool showPanelHeader: editPreferences.showPanelHeader ?? root.defaults.showPanelHeader ?? true
  readonly property bool showPanelNowPlaying: editPreferences.showPanelNowPlaying ?? root.defaults.showPanelNowPlaying ?? true
  readonly property bool showPanelPlaybackProgress: editPreferences.showPanelPlaybackProgress ?? root.defaults.showPanelPlaybackProgress ?? true
  readonly property bool showPanelProviderChips: editPreferences.showPanelProviderChips ?? root.defaults.showPanelProviderChips ?? true
  readonly property bool showPanelRecentTracks: editPreferences.showPanelRecentTracks ?? root.defaults.showPanelRecentTracks ?? true
  readonly property bool showPanelSearchHelper: editPreferences.showPanelSearchHelper ?? root.defaults.showPanelSearchHelper ?? true
  readonly property bool showPanelPreview: editPreferences.showPanelPreview ?? root.defaults.showPanelPreview ?? true
  readonly property bool showPanelUrlActions: editPreferences.showPanelUrlActions ?? root.defaults.showPanelUrlActions ?? true
  readonly property bool showPanelSpeedControls: editPreferences.showPanelSpeedControls ?? root.defaults.showPanelSpeedControls ?? true
  readonly property bool showPanelQueueControls: editPreferences.showPanelQueueControls ?? root.defaults.showPanelQueueControls ?? true
  readonly property bool showPanelStatusBanner: editPreferences.showPanelStatusBanner ?? root.defaults.showPanelStatusBanner ?? true
  readonly property bool showBarHoverTrackTitle: editPreferences.showBarHoverTrackTitle ?? root.defaults.showBarHoverTrackTitle ?? true
  readonly property bool autoSaveMp3AfterPlayback: editPreferences.autoSaveMp3AfterPlayback ?? root.defaults.autoSaveMp3AfterPlayback ?? false
  property string editDownloadDirectory: root.currentDownloadDirectory
  property int editDownloadCacheMaxMb: root.currentDownloadCacheMaxMb
  readonly property var downloadSettingsResult: root.mainInstance?.downloadSettingsResult ?? null
  readonly property bool downloadActionFailed: downloadSettingsResult?.status === "failed" || downloadSettingsResult?.status === "rejected"
  readonly property string downloadActionFeedback: {
    var result = downloadSettingsResult;
    if (!result)
      return "";
    if (result.status === "pending")
      return pluginApi?.tr("settings.downloads.actionPending") ?? "";
    if (result.status === "rejected" && result.errorCode === "busy")
      return pluginApi?.tr("settings.downloads.actionBusy") ?? "";
    if (result.status !== "saved")
      return pluginApi?.tr("settings.downloads.actionFailed") ?? "";
    return result.kind === "directory" ? pluginApi?.tr("notices.downloadFolderApplied", {
                                                         path: result.appliedValue
                                                       }) ?? "" : pluginApi?.tr("notices.downloadLimitApplied", {
                                                                                  limit: result.appliedValue
                                                                                }) ?? "";
  }

  spacing: Style.marginL

  function saveSetting(key, value) {
    if (!pluginApi) {
      Logger.e("MusicSearch", "Cannot save settings: pluginApi is null");
      return false;
    }
    return pluginApi.field(key)?.set(value) ?? false;
  }

  // Completion observer only; native publication belongs to the session.
  function saveSettings() {
    pluginApi.saveSettings();
  }

  function applyDownloadDirectory() {
    var target = (editDownloadDirectory || "").trim();
    if (target.length === 0) {
      return;
    }
    editDownloadDirectory = target;
    pluginApi?.mainInstance?.setDownloadDirectory(target);
  }

  function applyCacheLimit() {
    var target = Math.max(0, Math.floor(editDownloadCacheMaxMb || 0));
    editDownloadCacheMaxMb = target;
    pluginApi?.mainInstance?.setDownloadCacheMaxMb(target);
  }

  property string _lastDirectory: currentDownloadDirectory
  property int _lastCacheLimit: currentDownloadCacheMaxMb
  onCurrentDownloadDirectoryChanged: {
    if (editDownloadDirectory === _lastDirectory)
      editDownloadDirectory = currentDownloadDirectory;
    _lastDirectory = currentDownloadDirectory;
  }
  onCurrentDownloadCacheMaxMbChanged: {
    if (editDownloadCacheMaxMb === _lastCacheLimit)
      editDownloadCacheMaxMb = currentDownloadCacheMaxMb;
    _lastCacheLimit = currentDownloadCacheMaxMb;
  }

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    wrapMode: Text.Wrap
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
  }

  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.provider.label")
    description: pluginApi?.tr("settings.provider.desc")
    model: [
      {
        "key": "youtube",
        "name": pluginApi?.tr("providers.youtube")
      },
      {
        "key": "soundcloud",
        "name": pluginApi?.tr("providers.soundcloud")
      },
      {
        "key": "local",
        "name": pluginApi?.tr("providers.local")
      }
    ]
    currentKey: root.currentProvider
    defaultValue: "youtube"
    onSelected: key => pluginApi?.mainInstance?.setProvider(key)
  }

  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.sort.label")
    description: pluginApi?.tr("settings.sort.desc")
    model: [
      {
        "key": "date",
        "name": pluginApi?.tr("sort.savedDate")
      },
      {
        "key": "title",
        "name": pluginApi?.tr("sort.title")
      },
      {
        "key": "duration",
        "name": pluginApi?.tr("sort.duration")
      },
      {
        "key": "rating",
        "name": pluginApi?.tr("sort.rating")
      }
    ]
    currentKey: root.currentSortBy
    defaultValue: "date"
    onSelected: key => pluginApi?.mainInstance?.setSortBy(key)
  }

  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.ytClient.label")
    description: pluginApi?.tr("settings.ytClient.desc")
    model: [
      {
        "key": "android",
        "name": pluginApi?.tr("settings.ytClient.android")
      },
      {
        "key": "web",
        "name": pluginApi?.tr("settings.ytClient.web")
      },
      {
        "key": "default",
        "name": pluginApi?.tr("settings.ytClient.default")
      }
    ]
    currentKey: root.currentYtPlayerClient
    defaultValue: "android"
    onSelected: key => pluginApi?.mainInstance?.setYtPlayerClient(key)
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.downloads.title")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
  }

  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.downloads.currentFolder", {
                          "path": root.editDownloadDirectory
                        })
    wrapMode: Text.Wrap
    pointSize: Style.fontSizeS
    color: AtmoColor.mOnSurfaceVariant
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NButton {
      text: pluginApi?.tr("settings.downloads.chooseFolder")
      onClicked: downloadFolderPicker.openFilePicker()
    }

    NButton {
      text: pluginApi?.tr("settings.downloads.applyFolder")
      enabled: (root.editDownloadDirectory || "").trim().length > 0
      onClicked: root.applyDownloadDirectory()
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.cache.label")
      description: pluginApi?.tr("settings.cache.desc")
    }

    NSpinBox {
      id: cacheInput
      from: 0
      to: 500000
      stepSize: 128
      value: root.editDownloadCacheMaxMb
      onValueModified: value => root.editDownloadCacheMaxMb = value
    }

    NButton {
      text: pluginApi?.tr("settings.cache.apply")
      onClicked: root.applyCacheLimit()
    }
  }

  NText {
    objectName: "music-download-action-feedback"
    Layout.fillWidth: true
    visible: root.downloadActionFeedback.length > 0
    text: root.downloadActionFeedback
    wrapMode: Text.Wrap
    pointSize: Style.fontSizeS
    color: root.downloadActionFailed ? AtmoColor.mError : AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.autoSaveMp3AfterPlaybackField
    NToggle {
      label: pluginApi?.tr("settings.autoSave.label")
      description: pluginApi?.tr("settings.autoSave.desc")
      checked: root.autoSaveMp3AfterPlayback
      onToggled: root.saveSetting("autoSaveMp3AfterPlayback", checked)
      defaultValue: root.defaults.autoSaveMp3AfterPlayback ?? false
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.home.title")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.showHomeRecentField
    NToggle {
      label: pluginApi?.tr("settings.home.recent.label")
      description: pluginApi?.tr("settings.home.recent.desc")
      checked: root.showHomeRecent
      onToggled: root.saveSetting("showHomeRecent", checked)
      defaultValue: root.defaults.showHomeRecent ?? true
    }
  }

  NPluginSettingsField {
    field: root.showHomeTopField
    NToggle {
      label: pluginApi?.tr("settings.home.top.label")
      description: pluginApi?.tr("settings.home.top.desc")
      checked: root.showHomeTop
      onToggled: root.saveSetting("showHomeTop", checked)
      defaultValue: root.defaults.showHomeTop ?? true
    }
  }

  NPluginSettingsField {
    field: root.showHomeTagsField
    NToggle {
      label: pluginApi?.tr("settings.home.tags.label")
      description: pluginApi?.tr("settings.home.tags.desc")
      checked: root.showHomeTags
      onToggled: root.saveSetting("showHomeTags", checked)
      defaultValue: root.defaults.showHomeTags ?? true
    }
  }

  NPluginSettingsField {
    field: root.showHomeArtistsField
    NToggle {
      label: pluginApi?.tr("settings.home.artists.label")
      description: pluginApi?.tr("settings.home.artists.desc")
      checked: root.showHomeArtists
      onToggled: root.saveSetting("showHomeArtists", checked)
      defaultValue: root.defaults.showHomeArtists ?? true
    }
  }

  NPluginSettingsField {
    field: root.showHomePlaylistsField
    NToggle {
      label: pluginApi?.tr("settings.home.playlists.label")
      description: pluginApi?.tr("settings.home.playlists.desc")
      checked: root.showHomePlaylists
      onToggled: root.saveSetting("showHomePlaylists", checked)
      defaultValue: root.defaults.showHomePlaylists ?? true
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.panel.title")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.defaultPanelTabField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.panel.defaultTab.label")
      description: pluginApi?.tr("settings.panel.defaultTab.desc")
      model: [
        {
          "key": "search",
          "name": pluginApi?.tr("panel.search")
        },
        {
          "key": "library",
          "name": pluginApi?.tr("panel.library")
        },
        {
          "key": "queue",
          "name": pluginApi?.tr("panel.queue")
        }
      ]
      currentKey: root.defaultPanelTab
      defaultValue: root.defaults.defaultPanelTab ?? "search"
      onSelected: key => root.saveSetting("defaultPanelTab", key)
    }
  }

  NPluginSettingsField {
    field: root.defaultPanelLibrarySectionField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.panel.defaultLibrarySection.label")
      description: pluginApi?.tr("settings.panel.defaultLibrarySection.desc")
      model: [
        {
          "key": "tracks",
          "name": pluginApi?.tr("panel.tracks")
        },
        {
          "key": "playlists",
          "name": pluginApi?.tr("panel.playlists")
        },
        {
          "key": "artists",
          "name": pluginApi?.tr("panel.artists")
        },
        {
          "key": "tags",
          "name": pluginApi?.tr("panel.tags")
        }
      ]
      currentKey: root.defaultPanelLibrarySection
      defaultValue: root.defaults.defaultPanelLibrarySection ?? "tracks"
      onSelected: key => root.saveSetting("defaultPanelLibrarySection", key)
    }
  }

  NPluginSettingsField {
    field: root.panelDensityField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.panel.density.label")
      description: pluginApi?.tr("settings.panel.density.desc")
      model: [
        {
          "key": "compact",
          "name": pluginApi?.tr("settings.panel.density.compact")
        },
        {
          "key": "balanced",
          "name": pluginApi?.tr("settings.panel.density.balanced")
        },
        {
          "key": "roomy",
          "name": pluginApi?.tr("settings.panel.density.roomy")
        }
      ]
      currentKey: root.panelDensity
      defaultValue: root.defaults.panelDensity ?? "balanced"
      onSelected: key => root.saveSetting("panelDensity", key)
    }
  }

  NPluginSettingsField {
    field: root.showPanelHeaderField
    NToggle {
      label: pluginApi?.tr("settings.panel.header.label")
      description: pluginApi?.tr("settings.panel.header.desc")
      checked: root.showPanelHeader
      onToggled: root.saveSetting("showPanelHeader", checked)
      defaultValue: root.defaults.showPanelHeader ?? true
    }
  }

  NPluginSettingsField {
    field: root.showPanelNowPlayingField
    NToggle {
      label: pluginApi?.tr("settings.panel.nowPlaying.label")
      description: pluginApi?.tr("settings.panel.nowPlaying.desc")
      checked: root.showPanelNowPlaying
      onToggled: root.saveSetting("showPanelNowPlaying", checked)
      defaultValue: root.defaults.showPanelNowPlaying ?? true
    }
  }

  NPluginSettingsField {
    field: root.showPanelPlaybackProgressField
    NToggle {
      label: pluginApi?.tr("settings.panel.playbackProgress.label")
      description: pluginApi?.tr("settings.panel.playbackProgress.desc")
      checked: root.showPanelPlaybackProgress
      onToggled: root.saveSetting("showPanelPlaybackProgress", checked)
      defaultValue: root.defaults.showPanelPlaybackProgress ?? true
    }
  }

  NPluginSettingsField {
    field: root.showPanelProviderChipsField
    NToggle {
      label: pluginApi?.tr("settings.panel.providerChips.label")
      description: pluginApi?.tr("settings.panel.providerChips.desc")
      checked: root.showPanelProviderChips
      onToggled: root.saveSetting("showPanelProviderChips", checked)
      defaultValue: root.defaults.showPanelProviderChips ?? true
    }
  }

  NPluginSettingsField {
    field: root.showPanelRecentTracksField
    NToggle {
      label: pluginApi?.tr("settings.panel.recentTracks.label")
      description: pluginApi?.tr("settings.panel.recentTracks.desc")
      checked: root.showPanelRecentTracks
      onToggled: root.saveSetting("showPanelRecentTracks", checked)
      defaultValue: root.defaults.showPanelRecentTracks ?? true
    }
  }

  NPluginSettingsField {
    field: root.showPanelSearchHelperField
    NToggle {
      label: pluginApi?.tr("settings.panel.searchHelper.label")
      description: pluginApi?.tr("settings.panel.searchHelper.desc")
      checked: root.showPanelSearchHelper
      onToggled: root.saveSetting("showPanelSearchHelper", checked)
      defaultValue: root.defaults.showPanelSearchHelper ?? true
    }
  }

  NPluginSettingsField {
    field: root.showPanelPreviewField
    NToggle {
      label: pluginApi?.tr("settings.panel.preview.label")
      description: pluginApi?.tr("settings.panel.preview.desc")
      checked: root.showPanelPreview
      onToggled: root.saveSetting("showPanelPreview", checked)
      defaultValue: root.defaults.showPanelPreview ?? true
    }
  }

  NPluginSettingsField {
    field: root.showPanelUrlActionsField
    NToggle {
      label: pluginApi?.tr("settings.panel.urlActions.label")
      description: pluginApi?.tr("settings.panel.urlActions.desc")
      checked: root.showPanelUrlActions
      onToggled: root.saveSetting("showPanelUrlActions", checked)
      defaultValue: root.defaults.showPanelUrlActions ?? true
    }
  }

  NPluginSettingsField {
    field: root.showPanelSpeedControlsField
    NToggle {
      label: pluginApi?.tr("settings.panel.speedControls.label")
      description: pluginApi?.tr("settings.panel.speedControls.desc")
      checked: root.showPanelSpeedControls
      onToggled: root.saveSetting("showPanelSpeedControls", checked)
      defaultValue: root.defaults.showPanelSpeedControls ?? true
    }
  }

  NPluginSettingsField {
    field: root.showPanelQueueControlsField
    NToggle {
      label: pluginApi?.tr("settings.panel.queueControls.label")
      description: pluginApi?.tr("settings.panel.queueControls.desc")
      checked: root.showPanelQueueControls
      onToggled: root.saveSetting("showPanelQueueControls", checked)
      defaultValue: root.defaults.showPanelQueueControls ?? true
    }
  }

  NPluginSettingsField {
    field: root.showPanelStatusBannerField
    NToggle {
      label: pluginApi?.tr("settings.panel.statusBanner.label")
      description: pluginApi?.tr("settings.panel.statusBanner.desc")
      checked: root.showPanelStatusBanner
      onToggled: root.saveSetting("showPanelStatusBanner", checked)
      defaultValue: root.defaults.showPanelStatusBanner ?? true
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.bar.title")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.showBarHoverTrackTitleField
    NToggle {
      label: pluginApi?.tr("settings.bar.hoverTitle.label")
      description: pluginApi?.tr("settings.bar.hoverTitle.desc")
      checked: root.showBarHoverTrackTitle
      onToggled: root.saveSetting("showBarHoverTrackTitle", checked)
      defaultValue: root.defaults.showBarHoverTrackTitle ?? true
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.preview.title")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.previewMetadataModeField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.preview.metadata.label")
      description: pluginApi?.tr("settings.preview.metadata.desc")
      model: [
        {
          "key": "always",
          "name": pluginApi?.tr("settings.preview.metadata.all")
        },
        {
          "key": "playing",
          "name": pluginApi?.tr("settings.preview.metadata.playing")
        },
        {
          "key": "never",
          "name": pluginApi?.tr("settings.preview.metadata.disabled")
        }
      ]
      currentKey: root.previewMetadataMode
      defaultValue: root.defaults.previewMetadataMode ?? "always"
      onSelected: key => root.saveSetting("previewMetadataMode", key)
    }
  }

  NText {
    Layout.fillWidth: true
    text: {
      if (root.previewMetadataMode === "never") {
        return pluginApi?.tr("settings.preview.metadata.neverHint");
      }
      if (root.previewMetadataMode === "playing") {
        return pluginApi?.tr("settings.preview.metadata.playingHint");
      }
      return pluginApi?.tr("settings.preview.metadata.alwaysHint");
    }
    wrapMode: Text.Wrap
    pointSize: Style.fontSizeS
    color: AtmoColor.mOnSurfaceVariant
  }

  NPluginSettingsField {
    field: root.previewThumbnailSizeField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.preview.thumbnail.label")
      description: pluginApi?.tr("settings.preview.thumbnail.desc")
      model: [
        {
          "key": "small",
          "name": pluginApi?.tr("settings.preview.thumbnail.small")
        },
        {
          "key": "comfortable",
          "name": pluginApi?.tr("settings.preview.thumbnail.comfortable")
        },
        {
          "key": "large",
          "name": pluginApi?.tr("settings.preview.thumbnail.large")
        }
      ]
      currentKey: root.previewThumbnailSize
      defaultValue: root.defaults.previewThumbnailSize ?? "comfortable"
      onSelected: key => root.saveSetting("previewThumbnailSize", key)
    }
  }

  NPluginSettingsField {
    field: root.showPreviewChipsField
    NToggle {
      label: pluginApi?.tr("settings.preview.chips.label")
      description: pluginApi?.tr("settings.preview.chips.desc")
      checked: root.showPreviewChips
      onToggled: root.saveSetting("showPreviewChips", checked)
      defaultValue: root.defaults.showPreviewChips ?? true
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.metadata.title")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
  }

  NPluginSettingsField {
    field: root.showUploaderMetadataField
    NToggle {
      label: pluginApi?.tr("settings.metadata.uploader.label")
      description: pluginApi?.tr("settings.metadata.uploader.desc")
      checked: root.showUploaderMetadata
      onToggled: root.saveSetting("showUploaderMetadata", checked)
      defaultValue: root.defaults.showUploaderMetadata ?? true
    }
  }

  NPluginSettingsField {
    field: root.showAlbumMetadataField
    NToggle {
      label: pluginApi?.tr("settings.metadata.album.label")
      description: pluginApi?.tr("settings.metadata.album.desc")
      checked: root.showAlbumMetadata
      onToggled: root.saveSetting("showAlbumMetadata", checked)
      defaultValue: root.defaults.showAlbumMetadata ?? true
    }
  }

  NPluginSettingsField {
    field: root.showDurationMetadataField
    NToggle {
      label: pluginApi?.tr("settings.metadata.duration.label")
      description: pluginApi?.tr("settings.metadata.duration.desc")
      checked: root.showDurationMetadata
      onToggled: root.saveSetting("showDurationMetadata", checked)
      defaultValue: root.defaults.showDurationMetadata ?? true
    }
  }

  NPluginSettingsField {
    field: root.showRatingMetadataField
    NToggle {
      label: pluginApi?.tr("settings.metadata.rating.label")
      description: pluginApi?.tr("settings.metadata.rating.desc")
      checked: root.showRatingMetadata
      onToggled: root.saveSetting("showRatingMetadata", checked)
      defaultValue: root.defaults.showRatingMetadata ?? true
    }
  }

  NPluginSettingsField {
    field: root.showTagMetadataField
    NToggle {
      label: pluginApi?.tr("settings.metadata.tags.label")
      description: pluginApi?.tr("settings.metadata.tags.desc")
      checked: root.showTagMetadata
      onToggled: root.saveSetting("showTagMetadata", checked)
      defaultValue: root.defaults.showTagMetadata ?? true
    }
  }

  NPluginSettingsField {
    field: root.showPlayStatsMetadataField
    NToggle {
      label: pluginApi?.tr("settings.metadata.playStats.label")
      description: pluginApi?.tr("settings.metadata.playStats.desc")
      checked: root.showPlayStatsMetadata
      onToggled: root.saveSetting("showPlayStatsMetadata", checked)
      defaultValue: root.defaults.showPlayStatsMetadata ?? true
    }
  }

  NPluginSettingsField {
    field: root.showStatusMetadataField
    NToggle {
      label: pluginApi?.tr("settings.metadata.status.label")
      description: pluginApi?.tr("settings.metadata.status.desc")
      checked: root.showStatusMetadata
      onToggled: root.saveSetting("showStatusMetadata", checked)
      defaultValue: root.defaults.showStatusMetadata ?? true
    }
  }

  PortalFilePicker {
    id: downloadFolderPicker
    selectionMode: "folders"
    title: pluginApi?.tr("settings.downloads.folderPickerTitle")
    initialPath: root.editDownloadDirectory || (Quickshell.env("HOME") + "/Music")
    onAccepted: paths => {
      if (paths.length > 0) {
        root.editDownloadDirectory = paths[0];
        root.applyDownloadDirectory();
      }
    }
  }
}
