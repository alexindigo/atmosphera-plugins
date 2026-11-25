import QtQuick
import Quickshell.Io
import qs.Commons

// Main-owned listing/projection; profile effects remain one serial owner.
Item {
  id: root
  required property var settingsContext
  required property string scriptsDir
  required property var retire
  required property var saveAction
  required property var applyAction
  required property var deleteAction
  required property var renameAction
  required property var validate
  required property bool isBusy
  readonly property bool current: settingsContext.current()
  // A listed row can drive destructive actions; it is not a draft preview.
  readonly property var cfg: settingsContext.appliedSettings
  readonly property string profilesDir: {
    var path = cfg.profilesDir || "";
    if (!path || path.trim() === "") return Settings.configDir + "profiles/";
    return path.endsWith("/") ? path : path + "/";
  }
  // Confirmed operation display, not an optimistic native desired-value read.
  property string lastAppliedProfile: ""
  property var profiles: []
  property var profileMeta: ({})
  property var _listing: null
  property bool _constructed: false
  Component {
    id: listingFactory
    Process {
      property string directory
      stdout: StdioCollector { id: output }
      stderr: StdioCollector {}
      onExited: code => root.listed(this, code, output.text)
    }
  }
  function validateName(name) { return validate(name); }
  function profileExists(name) { return profiles.indexOf(name ? name.trim() : "") !== -1; }
  function accepts(api) { return current && api && api.settingsContext === settingsContext; }
  function saveProfile(name, callback, api) { return accepts(api) && saveAction(name, callback, api); }
  function applyProfile(name, includeWallpapers, callback, api) { return accepts(api) && applyAction(name, includeWallpapers, callback, api); }
  function deleteProfile(name, callback, api) { return accepts(api) && deleteAction(name, callback, api); }
  function renameProfile(oldName, newName, callback, api) { return accepts(api) && renameAction(oldName, newName, callback, api); }
  function stopListing() {
    var previous = _listing;
    _listing = null;
    if (previous) { previous.running = false; previous.destroy(); }
  }
  function listProfiles() {
    stopListing(); profiles = []; profileMeta = ({});
    if (!current) return;
    _listing = listingFactory.createObject(root, {directory: profilesDir, command: ["sh", scriptsDir + "/list-profiles.sh", profilesDir]});
    _listing.running = true;
  }
  function listed(listing, code, text) {
    if (!current || _listing !== listing || listing.directory !== profilesDir) return;
    var names = [], meta = {};
    if (code === 0) {
      for (var line of text.split('\n')) {
        if (!line.trim()) continue;
        var parts = line.split('\t'), name = parts[0].trim();
        if (name && !name.startsWith('.') && !name.startsWith('_')) {
          names.push(name); meta[name] = {savedAt: parts.length > 1 ? parts[1].trim() : ""};
        }
      }
    }
    profiles = names; profileMeta = meta;
    _listing = null; listing.destroy();
  }
  onProfilesDirChanged: if (_constructed) listProfiles()
  onCurrentChanged: if (_constructed && !current) { stopListing(); profiles = []; profileMeta = ({}); retire(root); }
  Component.onCompleted: { lastAppliedProfile = cfg.lastAppliedProfile || ""; _constructed = true; listProfiles(); }
  Component.onDestruction: stopListing()
}
