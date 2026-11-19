import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Plugins
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  // Reactive state consumed by BarWidget and Panel
  property var profiles: []
  property var profileMeta: ({})
  property string lastAppliedProfile: ""
  property bool isBusy: false
  property var _lifetime: ({alive: true})
  signal operationCompleted(var result)
  Component.onDestruction: _lifetime.alive = false

  // ─── Reactive derived properties ────────────────────────────────────────────

  readonly property string pluginIcon:
    pluginApi?.pluginSettings?.icon ||
    pluginApi?.manifest?.metadata?.defaultSettings?.icon ||
    "bookmark"

  readonly property string profilesDir: {
    var dir = pluginApi?.pluginSettings?.profilesDir || ""
    if (!dir || dir.trim() === "")
      return Settings.configDir + "profiles/"
    return dir.endsWith("/") ? dir : dir + "/"
  }

  readonly property string backupsDir: profilesDir + "_backups/"

  readonly property string scriptsDir: (pluginApi?.pluginDir ?? "") + "/assets/scripts"

  // ─── Helpers ────────────────────────────────────────────────────────────────

  function _profilePath(name) {
    return profilesDir + name.trim()
  }

  function _timestamp() {
    var now = new Date()
    var pad = function(n) { return String(n).padStart(2, '0') }
    return now.getFullYear() + '-' + pad(now.getMonth() + 1) + '-' + pad(now.getDate()) +
           '_' + pad(now.getHours()) + '-' + pad(now.getMinutes()) + '-' + pad(now.getSeconds())
  }

  function profileExists(name) {
    return root.profiles.indexOf(name ? name.trim() : "") !== -1
  }

  function validateName(name) {
    if (!name || name.trim() === "")
      return pluginApi?.tr("error.name-empty")
    var t = name.trim()
    if (t.length > 64)
      return pluginApi?.tr("error.name-too-long")
    if (/[\/\\.:<>"|?*\x00-\x1f]/.test(t))
      return pluginApi?.tr("error.name-invalid")
    return ""
  }

  // ─── Process: directory listing ─────────────────────────────────────────────

  Process {
    id: listProc
    stdout: StdioCollector { id: listOutput }
    stderr: StdioCollector {}
    onExited: function(exitCode, exitStatus) {
      var names = []
      var meta = {}
      if (exitCode === 0) {
        var lines = listOutput.text.split('\n')
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i]
          if (line.trim() === "") continue
          var parts = line.split('\t')
          var name = parts[0].trim()
          var savedAt = parts.length > 1 ? parts[1].trim() : ""
          if (name && !name.startsWith('.') && !name.startsWith('_')) {
            names.push(name)
            meta[name] = { savedAt: savedAt }
          }
        }
      }
      Logger.i("ShellProfiles", "Profiles found:", names.length)
      root.profiles = names
      root.profileMeta = meta
    }
  }

  // ─── Process: general commands ──────────────────────────────────

  Process {
    id: cmdProc
    stdout: StdioCollector { id: commandOutput }
    stderr: StdioCollector { id: commandErrors }
    property var pendingCallback: null
    onExited: function(exitCode, exitStatus) {
      var cb = pendingCallback
      pendingCallback = null
      if (cb) cb(exitCode, commandOutput.text, commandErrors.text)
    }
  }

  function _runCommand(cmd, callback) {
    if (cmdProc.running || cmdProc.pendingCallback) {
      Qt.callLater(function () { callback(1, "", "profile-command-busy") })
      return false
    }
    cmdProc.pendingCallback = callback
    cmdProc.command = cmd
    cmdProc.running = true
    return true
  }

  // ─── Backup helpers ──────────────────────────────────────────────────────────

  function _createBackup(beforeProfileName, callback, hidden) {
    var base = hidden ? Settings.configDir + ".profile-operations/baselines/" : backupsDir
    var backupDir = base + _timestamp() + "-" + Date.now()
    var metaJson = JSON.stringify({
      "savedAt": new Date().toISOString(),
      "description": "auto-backup before applying: " + beforeProfileName
    })
    _runCommand(["sh", scriptsDir + "/backup-configs.sh", Settings.configDir, backupDir,
      _wallpapersJson(), metaJson], function(code, stdout, stderr) {
      callback(code === 0, code === 0 ? backupDir : "", stderr)
    })
  }

  function _wallpapersJson() {
    var screens = []
    var map = WallpaperService.currentWallpapers
    for (var key of Object.keys(map)) {
      var entry = map[key]
      if (!entry) continue
      screens.push({name: key, light: typeof entry === "string" ? entry : entry.light || "",
        dark: typeof entry === "string" ? entry : entry.dark || ""})
    }
    return JSON.stringify({screens: screens})
  }

  function _settleOwners(operation, callback) {
    var lifetime = _lifetime
    Service.synchronizePreferences(operation, function (result) {
      if (lifetime.alive) callback(result.status === "current" && result.refreshState === "current", result)
    })
  }

  function _settingsFailure(receipt, fallback) {
    if (receipt?.error?.code !== "unresolved-group" || !receipt.preferenceBlockers?.length)
      return fallback
    var workflows = receipt.preferenceBlockers.map(function (blocker) {
      return blocker.ownerKey + "/" + (blocker.requestKey || blocker.groupToken) + " (" + blocker.state + ")"
    })
    return "Profile settings blocked by unresolved workflow: " + workflows.join(", ")
  }

  function _pruneBackups(bDir, callback) {
    var maxCount = Math.max(1, Math.min(20, pluginApi?.pluginSettings?.backupCount ?? 5))
    _runCommand(["sh", scriptsDir + "/prune-backups.sh", bDir, String(maxCount)], function(code) {
      if (callback) callback(code === 0)
    })
  }

  // ─── IPC handlers ────────────────────────────────────────────────────────────

  IpcHandler {
    target: "plugin:shell-profiles"

    function toggleProfiles() {
      if (!pluginApi) return
      pluginApi.withCurrentScreen(screen => {
        pluginApi.togglePanel(screen)
      })
    }

    function applyProfile(name: string) {
      if (!pluginApi || !name) return
      var includeWallpapers = pluginApi.pluginSettings?.includeWallpapers ?? true
      root.applyProfile(name, includeWallpapers)
    }
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  Component.onCompleted: {
    Logger.i("ShellProfiles", "Main loaded")
    Quickshell.execDetached(["mkdir", "-p", profilesDir])
    Quickshell.execDetached(["mkdir", "-p", backupsDir])
    listProfiles()
    lastAppliedProfile = pluginApi?.pluginSettings?.lastAppliedProfile || ""
  }

  // ─── Public API ──────────────────────────────────────────────────────────────

  function listProfiles() {
    if (listProc.running) return
    listProc.command = ["sh", scriptsDir + "/list-profiles.sh", profilesDir]
    listProc.running = true
  }

  function saveProfile(name, callback) {
    var err = validateName(name)
    if (err) { if (callback) callback(false, err); return }
    if (isBusy) { if (callback) callback(false, "profile-busy"); return }
    var trimmed = name.trim()
    var dirPath = _profilePath(trimmed)
    var wallpapersJson = _wallpapersJson()
    var metaJson = JSON.stringify({savedAt: new Date().toISOString()})
    isBusy = true
    _settleOwners("save", function (ready, receipt) {
      if (!ready) { _complete("save", trimmed, false, _settingsFailure(receipt, "profile-settings-receipt"), callback, {settings: receipt}); return }
      _runCommand(["sh", scriptsDir + "/save-profile.sh", Settings.configDir, dirPath,
        wallpapersJson, metaJson], function(code, stdout, stderr) {
        _complete("save", trimmed, code === 0, code === 0 ? "" : stderr.trim() || "profile-copy-failed", callback, {settings: receipt})
      })
    })
  }

  function _complete(operation, name, success, message, callback, outcomes) {
    isBusy = false
    var result = {operation: operation, name: name, status: success ? "completed" : "failed", outcomes: outcomes || {}}
    operationCompleted(result)
    if (success) {
      listProfiles()
      var key = {save: "toast.saved", apply: "toast.applied", delete: "toast.deleted"}[operation]
      if (key) ToastService.showNotice(pluginApi?.tr("panel.title"), pluginApi?.tr(key, {name: name}), pluginIcon)
    } else {
      ToastService.showError(pluginApi?.tr("panel.title"), message)
    }
    if (callback) callback(success, message, result)
  }

  function _rememberProfile(name, callback) {
    if (!pluginApi?.settingsReady) { callback(false, {status: "failed", error: {code: "profile-plugin-owner"}}); return }
    var lifetime = _lifetime
    pluginApi.pluginSettings.lastAppliedProfile = name
    var input = pluginApi.settingsHandle.info(["lastAppliedProfile"]).latestInput
    pluginApi.saveSettings(function (receipt) {
      if (!lifetime.alive) return
      var ok = ["saved", "nothing_to_save"].indexOf(receipt.status) !== -1 &&
        pluginApi.settingsHandle.info(["lastAppliedProfile"]).latestInput === input &&
        (!receipt.unresolvedGroups || !receipt.unresolvedGroups.length)
      if (ok) root.lastAppliedProfile = name
      callback(ok, receipt)
    })
  }

  function applyProfile(name, includeWallpapers, callback) {
    var err = validateName(name)
    if (err) { if (callback) callback(false, err); return }
    if (isBusy) { if (callback) callback(false, "profile-busy"); return }
    var trimmed = name.trim()
    var dirPath = _profilePath(trimmed)
    var cfg = Settings.configDir
    var backupEnabled = pluginApi?.pluginSettings?.backupEnabled ?? true
    var pruneDirectory = backupsDir
    var lifetime = _lifetime
    var outcomes = {settings: {status: "not_requested"}, wallpapers: {status: "not_requested"}}
    isBusy = true
    function fail(code) {
      if (lifetime.alive) root._complete("apply", trimmed, false, code, callback, outcomes)
    }
    function remember() {
      _rememberProfile(trimmed, function (ok, receipt) {
        outcomes.lastApplied = receipt
        if (!ok) { fail("profile-last-applied-receipt"); return }
        root._complete("apply", trimmed, true, "", callback, outcomes)
      })
    }
    function finish() {
      if (!backupEnabled) { remember(); return }
      _pruneBackups(pruneDirectory, function (ok) {
        if (!ok) { fail("profile-backup-prune"); return }
        remember()
      })
    }
    function wallpapers(entries) {
      try {
        for (var entry of entries) {
          if (entry.light) WallpaperService.changeWallpaper(entry.light, entry.name, "light")
          if (entry.dark) WallpaperService.changeWallpaper(entry.dark, entry.name, "dark")
        }
        for (var entry of entries) {
          if ((entry.light && WallpaperService.getWallpaperPathForSlot(entry.name, "light") !== entry.light) ||
              (entry.dark && WallpaperService.getWallpaperPathForSlot(entry.name, "dark") !== entry.dark)) {
            throw new Error("profile-wallpaper-consumer")
          }
        }
        outcomes.wallpapers = {status: includeWallpapers ? "changed" : "not_requested", screens: entries.length}
      } catch (error) { fail("profile-wallpaper-consumer"); return }
      // Wallpaper selection may itself submit settings (e.g. solid color mode).
      _settleOwners("save", function (ok, receipt) {
        outcomes.afterEffects = receipt
        if (!ok) { fail(_settingsFailure(receipt, "profile-settings-receipt")); return }
        finish()
      })
    }
    function publish(baseline, entries) {
      if (!outcomes.before.isCurrent()) { fail("profile-concurrent-edit"); return }
      _runCommand(["sh", scriptsDir + "/apply-profile.sh", dirPath, cfg, baseline, cfg + ".profile-operations"], function(code, stdout) {
        if (code !== 0) { fail("profile-copy-failed"); return }
        try { outcomes.files = JSON.parse(stdout) }
        catch (error) { fail("profile-copy-receipt"); return }
        if (!outcomes.before.isCurrent()) { fail("profile-concurrent-edit"); return }
        _settleOwners("reload", function (ok, receipt) {
          outcomes.settings = receipt
          if (!ok) { fail(_settingsFailure(receipt, "profile-reload-receipt")); return }
          AtmoColor.reloadFromDisk(function (colors) {
            if (!lifetime.alive) return
            outcomes.colors = colors
            if (colors.status !== "reloaded") { fail("profile-colors-reload"); return }
            Registry.reloadFromDisk(function (registry) {
              if (!lifetime.alive) return
              outcomes.registry = registry
              if (registry.status !== "reloaded") { fail("profile-registry-reload"); return }
              wallpapers(entries)
            })
          })
        })
      })
    }
    _settleOwners("save", function (ok, receipt) {
      outcomes.before = receipt
      if (!ok) { fail(_settingsFailure(receipt, "profile-settings-receipt")); return }
      _createBackup(trimmed, function (backedUp, baseline) {
        if (!backedUp) { fail("profile-backup-failed"); return }
        outcomes.backup = {status: "saved", directory: baseline, automatic: backupEnabled}
        if (!includeWallpapers) { publish(baseline, []); return }
        _runCommand(["cat", dirPath + "/wallpapers.json"], function (code, text) {
          try {
            if (code !== 0) throw new Error("profile-wallpapers-read")
            var data = JSON.parse(text)
            if (!data || !Array.isArray(data.screens) || !data.screens.every(function (entry) {
              return entry && typeof entry.name === "string" && entry.name.length &&
                typeof entry.light === "string" && typeof entry.dark === "string"
            })) throw new Error("profile-wallpapers-shape")
            publish(baseline, data.screens)
          } catch (error) { fail("profile-wallpapers-read") }
        })
      }, !backupEnabled)
    })
  }

  function deleteProfile(name, callback) {
    var err = validateName(name)
    if (err) { if (callback) callback(false, err); return }
    if (isBusy) { if (callback) callback(false, "profile-busy"); return }

    var trimmed = name.trim()
    isBusy = true
    _runCommand(["rm", "-rf", _profilePath(trimmed)], function(code, stdout, stderr) {
      if (code === 0) {
        if (root.lastAppliedProfile === trimmed) {
          _rememberProfile("", function (ok, receipt) {
            _complete("delete", trimmed, ok, ok ? "" : "profile-last-applied-receipt", callback, {lastApplied: receipt})
          })
        } else {
          _complete("delete", trimmed, true, "", callback)
        }
      } else {
        _complete("delete", trimmed, false, stderr.trim() || "profile-delete-failed", callback)
      }
    })
  }

  function renameProfile(oldName, newName, callback) {
    var err = validateName(oldName) || validateName(newName)
    if (err) { if (callback) callback(false, err); return }
    if (isBusy) { if (callback) callback(false, "profile-busy"); return }

    var oldT = oldName.trim()
    var newT = newName.trim()
    if (oldT === newT) { if (callback) callback(true, ""); return }

    isBusy = true
    _runCommand(["mv", _profilePath(oldT), _profilePath(newT)], function(code, stdout, stderr) {
      if (code === 0) {
        if (root.lastAppliedProfile === oldT) {
          _rememberProfile(newT, function (ok, receipt) {
            _complete("rename", newT, ok, ok ? "" : "profile-last-applied-receipt", callback, {lastApplied: receipt})
          })
        } else {
          _complete("rename", newT, true, "", callback)
        }
      } else {
        _complete("rename", newT, false, stderr.trim() || "profile-rename-failed", callback)
      }
    })
  }

}
