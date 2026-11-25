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
  readonly property var sharedClient: pluginApi?.settingsContext ? settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property var profiles: sharedClient?.profiles ?? []
  readonly property var profileMeta: sharedClient?.profileMeta ?? ({})
  readonly property string lastAppliedProfile: sharedClient?.lastAppliedProfile ?? ""
  property var _settingsConsumers: new Map()
  Component { id: clientFactory; ProfileSettingsClient {} }
  property bool isBusy: false
  property var _lifetime: ({alive: true})
  signal operationCompleted(var result)
  Component.onDestruction: _lifetime.alive = false

  // ─── Reactive derived properties ────────────────────────────────────────────

  readonly property string pluginIcon:
    pluginApi?.pluginSettings?.icon ||
    pluginApi?.manifest?.metadata?.defaultSettings?.icon ||
    "bookmark"

  readonly property string profilesDir: sharedClient?.profilesDir ?? (Settings.configDir + "profiles/")

  readonly property string backupsDir: profilesDir + "_backups/"

  readonly property string scriptsDir: (pluginApi?.pluginDir ?? "") + "/assets/scripts"

  // ─── Helpers ────────────────────────────────────────────────────────────────

  function settingsConsumerFor(context) {
    if (!context || !context.current()) return null;
    if (_settingsConsumers.has(context)) return _settingsConsumers.get(context);
    var client = clientFactory.createObject(root, {
      settingsContext: context, scriptsDir: scriptsDir,
      isBusy: Qt.binding(function() { return root.isBusy; }),
      validate: function(name) { return root.validateName(name); },
      saveAction: function(name, callback, api) { return root.saveProfile(name, callback, api); },
      applyAction: function(name, includeWallpapers, callback, api) { return root.applyProfile(name, includeWallpapers, callback, api); },
      deleteAction: function(name, callback, api) { return root.deleteProfile(name, callback, api); },
      renameAction: function(oldName, newName, callback, api) { return root.renameProfile(oldName, newName, callback, api); },
      retire: function(retired) { root._settingsConsumers.delete(context); retired.destroy(); }
    });
    _settingsConsumers.set(context, client); return client;
  }

  function _capture(origin) {
    var api = origin === undefined ? pluginApi : origin;
    if (!api || !api.settingsContext || !api.settingsContext.current() || !api.settingsReady) return null;
    var client = settingsConsumerFor(api.settingsContext);
    if (!client) return null;
    var cfg = client.cfg;
    var path = client.profilesDir;
    return {api: api, context: api.settingsContext, directory: path, backups: path + "_backups/",
      backupEnabled: cfg.backupEnabled ?? true, backupCount: Math.max(1, Math.min(20, cfg.backupCount ?? 5)),
      icon: cfg.icon || api.manifest?.metadata?.defaultSettings?.icon || "bookmark", tr: api.tr,
      lastApplied: client.lastAppliedProfile};
  }

  function _current(request) {
    return request && request.context.current() && request.api && request.api.settingsContext === request.context;
  }

  function _refreshListings() {
    for (var client of _settingsConsumers.values()) client.listProfiles();
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

  // ─── Process: general commands ──────────────────────────────────

  Process {
    id: cmdProc
    stdout: StdioCollector { id: commandOutput }
    stderr: StdioCollector { id: commandErrors }
    property var pendingCallback: null
    onExited: function(exitCode, exitStatus) {
      root._settleCommand(exitCode, commandOutput.text, commandErrors.text)
    }
    onRunningChanged: if (!running && root._lifetime.alive) root._settleCommand(-1, "", "profile-command-start")
  }

  function _settleCommand(code, stdout, stderr) {
    var callback = cmdProc.pendingCallback;
    cmdProc.pendingCallback = null;
    if (callback) callback(code, stdout, stderr);
  }

  function _runCommand(cmd, callback) {
    if (cmdProc.running || cmdProc.pendingCallback) {
      var lifetime = _lifetime;
      Qt.callLater(function () { if (lifetime.alive) callback(1, "", "profile-command-busy"); })
      return false
    }
    cmdProc.pendingCallback = callback
    cmdProc.command = cmd
    cmdProc.running = true
    return true
  }

  // ─── Backup helpers ──────────────────────────────────────────────────────────

  function _createBackup(request, beforeProfileName, callback, hidden) {
    var base = hidden ? Settings.configDir + ".profile-operations/baselines/" : request.backups
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

  function _pruneBackups(request, callback) {
    _runCommand(["sh", scriptsDir + "/prune-backups.sh", request.backups, String(request.backupCount)], function(code) {
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
  }

  // ─── Public API ──────────────────────────────────────────────────────────────

  function listProfiles() {
    if (sharedClient) sharedClient.listProfiles();
  }

  function saveProfile(name, callback, origin) {
    var err = validateName(name)
    if (err) { if (callback) callback(false, err); return }
    if (isBusy) { if (callback) callback(false, "profile-busy"); return }
    var request = _capture(origin);
    if (!request) { if (callback) callback(false, "profile-origin-retired"); return false; }
    var trimmed = name.trim()
    var dirPath = request.directory + trimmed
    var wallpapersJson = _wallpapersJson()
    var metaJson = JSON.stringify({savedAt: new Date().toISOString()})
    isBusy = true
    _settleOwners("save", function (ready, receipt) {
      if (!ready || !_current(request)) { _complete(request, "save", trimmed, false, !ready ? _settingsFailure(receipt, "profile-settings-receipt") : "profile-origin-retired", callback, {settings: receipt}); return }
      _runCommand(["sh", scriptsDir + "/save-profile.sh", Settings.configDir, dirPath,
        wallpapersJson, metaJson], function(code, stdout, stderr) {
        _complete(request, "save", trimmed, code === 0, code === 0 ? "" : stderr.trim() || "profile-copy-failed", callback, {settings: receipt})
      })
    })
  }

  function _complete(request, operation, name, success, message, callback, outcomes) {
    isBusy = false
    var result = {operation: operation, name: name, status: success ? "completed" : "failed", outcomes: outcomes || {}}
    operationCompleted(result)
    _refreshListings()
    if (!_current(request)) return;
    if (success) {
      var key = {save: "toast.saved", apply: "toast.applied", delete: "toast.deleted"}[operation]
      if (key) ToastService.showNotice(request.tr("panel.title"), request.tr(key, {name: name}), request.icon)
    } else {
      ToastService.showError(request.tr("panel.title"), message)
    }
    if (callback) callback(success, message, result)
  }

  function _rememberProfile(request, name, callback) {
    if (!_current(request)) { callback(false, {status: "failed", error: {code: "profile-origin-retired"}}); return }
    var api = request.api;
    var address = api.runtime ? PluginInstances.address(api.placement) : null;
    var handle = address ? Settings.store : api.settingsHandle;
    var path = address ? address.path : ["lastAppliedProfile"];
    if (!handle) { callback(false, {status: "failed", error: {code: "profile-plugin-owner"}}); return; }
    var lifetime = _lifetime
    api.pluginSettings.lastAppliedProfile = name
    var input = handle.info(path).latestInput
    api.saveSettings(function (receipt) {
      if (!lifetime.alive) return
      var ok = _current(request) && ["saved", "nothing_to_save"].indexOf(receipt.status) !== -1 &&
        handle.info(path).latestInput === input &&
        (!receipt.unresolvedGroups || !receipt.unresolvedGroups.length)
      if (ok) {
        var client = root.settingsConsumerFor(request.context);
        if (client) client.lastAppliedProfile = name;
      }
      callback(ok, receipt)
    })
  }

  function applyProfile(name, includeWallpapers, callback, origin) {
    var err = validateName(name)
    if (err) { if (callback) callback(false, err); return }
    if (isBusy) { if (callback) callback(false, "profile-busy"); return }
    var request = _capture(origin);
    if (!request) { if (callback) callback(false, "profile-origin-retired"); return false; }
    var trimmed = name.trim()
    var dirPath = request.directory + trimmed
    var cfg = Settings.configDir
    var backupEnabled = request.backupEnabled
    var lifetime = _lifetime
    var outcomes = {settings: {status: "not_requested"}, wallpapers: {status: "not_requested"}}
    isBusy = true
    function fail(code) {
      if (lifetime.alive) root._complete(request, "apply", trimmed, false, code, callback, outcomes)
    }
    function remember() {
      _rememberProfile(request, trimmed, function (ok, receipt) {
        outcomes.lastApplied = receipt
        if (!ok) { fail("profile-last-applied-receipt"); return }
        root._complete(request, "apply", trimmed, true, "", callback, outcomes)
      })
    }
    function finish() {
      if (!backupEnabled) { remember(); return }
      _pruneBackups(request, function (ok) {
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
      if (!_current(request)) { fail("profile-origin-retired"); return; }
      _createBackup(request, trimmed, function (backedUp, baseline) {
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

  function deleteProfile(name, callback, origin) {
    var err = validateName(name)
    if (err) { if (callback) callback(false, err); return }
    if (isBusy) { if (callback) callback(false, "profile-busy"); return }

    var request = _capture(origin);
    if (!request) { if (callback) callback(false, "profile-origin-retired"); return false; }
    var trimmed = name.trim()
    isBusy = true
    _runCommand(["rm", "-rf", request.directory + trimmed], function(code, stdout, stderr) {
      if (code === 0) {
        if (request.lastApplied === trimmed) {
          _rememberProfile(request, "", function (ok, receipt) {
            _complete(request, "delete", trimmed, ok, ok ? "" : "profile-last-applied-receipt", callback, {lastApplied: receipt})
          })
        } else {
          _complete(request, "delete", trimmed, true, "", callback)
        }
      } else {
        _complete(request, "delete", trimmed, false, stderr.trim() || "profile-delete-failed", callback)
      }
    })
  }

  function renameProfile(oldName, newName, callback, origin) {
    var err = validateName(oldName) || validateName(newName)
    if (err) { if (callback) callback(false, err); return }
    if (isBusy) { if (callback) callback(false, "profile-busy"); return }

    var request = _capture(origin);
    if (!request) { if (callback) callback(false, "profile-origin-retired"); return false; }
    var oldT = oldName.trim()
    var newT = newName.trim()
    if (oldT === newT) { if (callback) callback(true, ""); return }

    isBusy = true
    _runCommand(["mv", request.directory + oldT, request.directory + newT], function(code, stdout, stderr) {
      if (code === 0) {
        if (request.lastApplied === oldT) {
          _rememberProfile(request, newT, function (ok, receipt) {
            _complete(request, "rename", newT, ok, ok ? "" : "profile-last-applied-receipt", callback, {lastApplied: receipt})
          })
        } else {
          _complete(request, "rename", newT, true, "", callback)
        }
      } else {
        _complete(request, "rename", newT, false, stderr.trim() || "profile-rename-failed", callback)
      }
    })
  }

}
