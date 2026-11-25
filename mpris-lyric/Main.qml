import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var pluginApi: null
  property var _settingsConsumers: new Map()
  Component { id: clientFactory; MprisSettingsClient {} }
  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
      pluginApi: pluginApi,
      settingsContext: context,
      retire: function(retired) {
        root._settingsConsumers.delete(context);
        retired.destroy();
      }
    });
    _settingsConsumers.set(context, client);
    return client;
  }
  readonly property var settingsConsumer: pluginApi ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property string currentLyric: settingsConsumer?.currentLyric ?? ""
  readonly property string currentTranslation: settingsConsumer?.currentTranslation ?? ""
  readonly property double lyricProgress: settingsConsumer?.lyricProgress ?? 0
  readonly property bool isPlaying: settingsConsumer?.isPlaying ?? false
  readonly property string trackTitle: settingsConsumer?.trackTitle ?? ""
  readonly property string trackArtist: settingsConsumer?.trackArtist ?? ""
  readonly property bool canPlay: settingsConsumer?.canPlay ?? false
  readonly property bool canPause: settingsConsumer?.canPause ?? false
  readonly property bool canGoNext: settingsConsumer?.canGoNext ?? false
  readonly property bool canGoPrevious: settingsConsumer?.canGoPrevious ?? false
  function playPause() { settingsConsumer?.playPause(); }
  function next() { settingsConsumer?.next(); }
  function previous() { settingsConsumer?.previous(); }
  function updateLyrics() { settingsConsumer?.updateLyrics(); }
  IpcHandler {
    target: "plugin:mpris-lyric"
    function refresh() { root.updateLyrics(); }
    function setPlayer(name: string) {
      if (root.pluginApi && name) {
        root.pluginApi.pluginSettings.playerName = name;
        root.pluginApi.saveSettings();
      }
    }
  }
}
