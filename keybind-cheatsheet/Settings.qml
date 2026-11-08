import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI
import "." as Local

ColumnLayout {
  id: root
  spacing: 0

  property var pluginApi: null
  readonly property var cfg: pluginApi?.initialSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // The selected editor owns preview and persistence independently. Baselines
  // read acknowledged input, so preview never makes a local edit look clean.
  NSettingsBaseline {
    id: displayBaseline
    readonly property int editWindowWidth: root.cfg.windowWidth ?? root.defaults.windowWidth ?? 1400
    readonly property int editWindowHeight: {
      var height = root.cfg.windowHeight ?? root.defaults.windowHeight ?? 850;
      return height > 0 ? height : 850;
    }
    readonly property bool editAutoHeight: root.cfg.autoHeight ?? root.defaults.autoHeight ?? true
    readonly property int editColumnCount: root.cfg.columnCount ?? root.defaults.columnCount ?? 3
    readonly property string editModKeyVariable: root.cfg.modKeyVariable || root.defaults.modKeyVariable || "$mod"
    readonly property string editHyprlandConfigPath: root.cfg.hyprlandConfigPath || root.defaults.hyprlandConfigPath || "~/.config/hypr/hyprland.conf"
    readonly property string editHyprlandLuaConfigPath: root.cfg.hyprlandLuaConfigPath || root.defaults.hyprlandLuaConfigPath || "~/.config/hypr/hyprland.lua"
    readonly property string editHyprlandParserMode: root.cfg.hyprlandParserMode || root.defaults.hyprlandParserMode || "auto"
    readonly property string editNiriConfigPath: root.cfg.niriConfigPath || root.defaults.niriConfigPath || "~/.config/niri/config.kdl"
    readonly property string editMangoConfigPath: root.cfg.mangoConfigPath || root.defaults.mangoConfigPath || "~/.config/mango/config.conf"
    readonly property bool editMergeSequentialBinds: root.cfg.mergeSequentialBinds ?? root.defaults.mergeSequentialBinds ?? true
    readonly property bool editShowUndescribedBinds: root.cfg.showUndescribedBinds ?? root.defaults.showUndescribedBinds ?? false
    readonly property bool editSplitLargeWorkspaceCategory: root.cfg.splitLargeWorkspaceCategory ?? root.defaults.splitLargeWorkspaceCategory ?? true
    readonly property int editWorkspaceSplitThreshold: root.cfg.workspaceSplitThreshold ?? root.defaults.workspaceSplitThreshold ?? 12
    readonly property var editBindOverrides: root.cfg.bindOverrides || ({})
    readonly property var editCheatsheetData: root.cfg.cheatsheetData || []
    readonly property string valueKeyColorSuper: root.cfg.keyColorSuper ?? root.defaults.keyColorSuper ?? ""
    readonly property string valueKeyColorCtrl: root.cfg.keyColorCtrl ?? root.defaults.keyColorCtrl ?? ""
    readonly property string valueKeyColorShift: root.cfg.keyColorShift ?? root.defaults.keyColorShift ?? ""
    readonly property string valueKeyColorAlt: root.cfg.keyColorAlt ?? root.defaults.keyColorAlt ?? "#FF6B6B"
    readonly property string valueKeyColorXF86: root.cfg.keyColorXF86 ?? root.defaults.keyColorXF86 ?? "#4ECDC4"
    readonly property string valueKeyColorPrint: root.cfg.keyColorPrint ?? root.defaults.keyColorPrint ?? "#95E1D3"
    readonly property string valueKeyColorNumeric: root.cfg.keyColorNumeric ?? root.defaults.keyColorNumeric ?? "#A8DADC"
    readonly property string valueKeyColorMouse: root.cfg.keyColorMouse ?? root.defaults.keyColorMouse ?? "#F38181"
    readonly property string valueKeyColorDefault: root.cfg.keyColorDefault ?? root.defaults.keyColorDefault ?? "#6C757D"
    readonly property string valueKeyTextSuper: root.cfg.keyTextSuper ?? root.defaults.keyTextSuper ?? ""
    readonly property string valueKeyTextCtrl: root.cfg.keyTextCtrl ?? root.defaults.keyTextCtrl ?? ""
    readonly property string valueKeyTextShift: root.cfg.keyTextShift ?? root.defaults.keyTextShift ?? ""
    readonly property string valueKeyTextAlt: root.cfg.keyTextAlt ?? root.defaults.keyTextAlt ?? ""
    readonly property string valueKeyTextXF86: root.cfg.keyTextXF86 ?? root.defaults.keyTextXF86 ?? ""
    readonly property string valueKeyTextPrint: root.cfg.keyTextPrint ?? root.defaults.keyTextPrint ?? ""
    readonly property string valueKeyTextNumeric: root.cfg.keyTextNumeric ?? root.defaults.keyTextNumeric ?? ""
    readonly property string valueKeyTextMouse: root.cfg.keyTextMouse ?? root.defaults.keyTextMouse ?? ""
    readonly property string valueKeyTextDefault: root.cfg.keyTextDefault ?? root.defaults.keyTextDefault ?? ""
    readonly property string valueKeyLabelColor: root.cfg.keyLabelColor ?? root.defaults.keyLabelColor ?? "#FFFFFF"
    readonly property string valueKeyColorMod2: root.cfg.keyColorMod2 ?? root.defaults.keyColorMod2 ?? ""
    readonly property string valueKeyColorMod3: root.cfg.keyColorMod3 ?? root.defaults.keyColorMod3 ?? ""
    readonly property string valueKeyColorMod5: root.cfg.keyColorMod5 ?? root.defaults.keyColorMod5 ?? ""
    readonly property string valueKeyTextMod2: root.cfg.keyTextMod2 ?? root.defaults.keyTextMod2 ?? ""
    readonly property string valueKeyTextMod3: root.cfg.keyTextMod3 ?? root.defaults.keyTextMod3 ?? ""
    readonly property string valueKeyTextMod5: root.cfg.keyTextMod5 ?? root.defaults.keyTextMod5 ?? ""
    readonly property string valueKeyLabelMod2: root.cfg.keyLabelMod2 ?? root.defaults.keyLabelMod2 ?? ""
    readonly property string valueKeyLabelMod3: root.cfg.keyLabelMod3 ?? root.defaults.keyLabelMod3 ?? ""
    readonly property string valueKeyLabelMod5: root.cfg.keyLabelMod5 ?? root.defaults.keyLabelMod5 ?? ""
    readonly property string valueDescriptionTextColor: root.cfg.descriptionTextColor ?? root.defaults.descriptionTextColor ?? ""
    ranges: [NSettingsRange { field: "editWorkspaceSplitThreshold"; from: workspaceThreshold.from; to: workspaceThreshold.to }]
  }
  readonly property bool settingsDirty: displayBaseline.differs({editWindowWidth: editWindowWidth, editWindowHeight: editWindowHeight, editAutoHeight: editAutoHeight, editColumnCount: editColumnCount, editModKeyVariable: editModKeyVariable, editHyprlandConfigPath: editHyprlandConfigPath, editHyprlandLuaConfigPath: editHyprlandLuaConfigPath, editHyprlandParserMode: editHyprlandParserMode, editNiriConfigPath: editNiriConfigPath, editMangoConfigPath: editMangoConfigPath, editMergeSequentialBinds: editMergeSequentialBinds, editShowUndescribedBinds: editShowUndescribedBinds, editSplitLargeWorkspaceCategory: editSplitLargeWorkspaceCategory, editWorkspaceSplitThreshold: editWorkspaceSplitThreshold, editBindOverrides: editBindOverrides, editCheatsheetData: editCheatsheetData, valueKeyColorSuper: valueKeyColorSuper, valueKeyColorCtrl: valueKeyColorCtrl, valueKeyColorShift: valueKeyColorShift, valueKeyColorAlt: valueKeyColorAlt, valueKeyColorXF86: valueKeyColorXF86, valueKeyColorPrint: valueKeyColorPrint, valueKeyColorNumeric: valueKeyColorNumeric, valueKeyColorMouse: valueKeyColorMouse, valueKeyColorDefault: valueKeyColorDefault, valueKeyTextSuper: valueKeyTextSuper, valueKeyTextCtrl: valueKeyTextCtrl, valueKeyTextShift: valueKeyTextShift, valueKeyTextAlt: valueKeyTextAlt, valueKeyTextXF86: valueKeyTextXF86, valueKeyTextPrint: valueKeyTextPrint, valueKeyTextNumeric: valueKeyTextNumeric, valueKeyTextMouse: valueKeyTextMouse, valueKeyTextDefault: valueKeyTextDefault, valueKeyLabelColor: valueKeyLabelColor, valueKeyColorMod2: valueKeyColorMod2, valueKeyColorMod3: valueKeyColorMod3, valueKeyColorMod5: valueKeyColorMod5, valueKeyTextMod2: valueKeyTextMod2, valueKeyTextMod3: valueKeyTextMod3, valueKeyTextMod5: valueKeyTextMod5, valueKeyLabelMod2: valueKeyLabelMod2, valueKeyLabelMod3: valueKeyLabelMod3, valueKeyLabelMod5: valueKeyLabelMod5, valueDescriptionTextColor: valueDescriptionTextColor})

  property var editBindOverrides: JSON.parse(JSON.stringify(displayBaseline.editBindOverrides))
  property var editCheatsheetData: JSON.parse(JSON.stringify(displayBaseline.editCheatsheetData))

  function restoreHidden(clearDescriptions) {
    var next = JSON.parse(JSON.stringify(editBindOverrides));
    for (var key in next) {
      // Absence inherits the shared flag in placement settings. An explicit
      // false choice restores the bind for either selected owner.
      if (next[key].hidden === true) next[key].hidden = false;
      if (clearDescriptions && next[key].desc) next[key].desc = "";
    }
    editBindOverrides = next;
  }

  function _applyPreview(key, value) {
    if (!pluginApi) return;
    var patch = {};
    patch[key] = value;
    return pluginApi.previewSettings(patch);
  }

  // Edit-copy properties for non-preview settings (window, layout, parsing, paths)
  property int editWindowWidth: cfg.windowWidth ?? defaults.windowWidth ?? 1400
  property int editWindowHeight: displayBaseline.editWindowHeight
  property bool editAutoHeight: cfg.autoHeight ?? defaults.autoHeight ?? true
  property int editColumnCount: cfg.columnCount ?? defaults.columnCount ?? 3
  property string editModKeyVariable: cfg.modKeyVariable || defaults.modKeyVariable || "$mod"
  property string editHyprlandConfigPath: cfg.hyprlandConfigPath || defaults.hyprlandConfigPath || "~/.config/hypr/hyprland.conf"
  property string editHyprlandLuaConfigPath: cfg.hyprlandLuaConfigPath || defaults.hyprlandLuaConfigPath || "~/.config/hypr/hyprland.lua"
  property string editHyprlandParserMode: cfg.hyprlandParserMode || defaults.hyprlandParserMode || "auto"
  property string editNiriConfigPath: cfg.niriConfigPath || defaults.niriConfigPath || "~/.config/niri/config.kdl"
  property string editMangoConfigPath: cfg.mangoConfigPath || defaults.mangoConfigPath || "~/.config/mango/config.conf"
  property bool editMergeSequentialBinds: cfg.mergeSequentialBinds ?? defaults.mergeSequentialBinds ?? true
  property bool editShowUndescribedBinds: cfg.showUndescribedBinds ?? defaults.showUndescribedBinds ?? false
  property bool editSplitLargeWorkspaceCategory: cfg.splitLargeWorkspaceCategory ?? defaults.splitLargeWorkspaceCategory ?? true
  property int editWorkspaceSplitThreshold: displayBaseline.project("editWorkspaceSplitThreshold")

  // Live-preview properties for colors (mirror current pluginSettings; written via _applyPreview).
  // All background color fields are stored as string (hex) for empty-string support.
  property string valueKeyColorSuper:   cfg.keyColorSuper   ?? defaults.keyColorSuper   ?? ""
  property string valueKeyColorCtrl:    cfg.keyColorCtrl    ?? defaults.keyColorCtrl    ?? ""
  property string valueKeyColorShift:   cfg.keyColorShift   ?? defaults.keyColorShift   ?? ""
  property string valueKeyColorAlt:     cfg.keyColorAlt     ?? defaults.keyColorAlt     ?? "#FF6B6B"
  property string valueKeyColorXF86:    cfg.keyColorXF86    ?? defaults.keyColorXF86    ?? "#4ECDC4"
  property string valueKeyColorPrint:   cfg.keyColorPrint   ?? defaults.keyColorPrint   ?? "#95E1D3"
  property string valueKeyColorNumeric: cfg.keyColorNumeric ?? defaults.keyColorNumeric ?? "#A8DADC"
  property string valueKeyColorMouse:   cfg.keyColorMouse   ?? defaults.keyColorMouse   ?? "#F38181"
  property string valueKeyColorDefault: cfg.keyColorDefault ?? defaults.keyColorDefault ?? "#6C757D"
  // Per-category text color overrides — empty string = fall back to keyLabelColor global
  property string valueKeyTextSuper:   cfg.keyTextSuper   ?? defaults.keyTextSuper   ?? ""
  property string valueKeyTextCtrl:    cfg.keyTextCtrl    ?? defaults.keyTextCtrl    ?? ""
  property string valueKeyTextShift:   cfg.keyTextShift   ?? defaults.keyTextShift   ?? ""
  property string valueKeyTextAlt:     cfg.keyTextAlt     ?? defaults.keyTextAlt     ?? ""
  property string valueKeyTextXF86:    cfg.keyTextXF86    ?? defaults.keyTextXF86    ?? ""
  property string valueKeyTextPrint:   cfg.keyTextPrint   ?? defaults.keyTextPrint   ?? ""
  property string valueKeyTextNumeric: cfg.keyTextNumeric ?? defaults.keyTextNumeric ?? ""
  property string valueKeyTextMouse:   cfg.keyTextMouse   ?? defaults.keyTextMouse   ?? ""
  property string valueKeyTextDefault: cfg.keyTextDefault ?? defaults.keyTextDefault ?? ""
  property string valueKeyLabelColor:  cfg.keyLabelColor  ?? defaults.keyLabelColor  ?? "#FFFFFF"
  // Generic X11 mods (Mod2/Mod3/Mod5): background colour, text colour, and a
  // display-label override (rename e.g. Mod3 -> "Hyper" for caps:hyper).
  property string valueKeyColorMod2: cfg.keyColorMod2 ?? defaults.keyColorMod2 ?? ""
  property string valueKeyColorMod3: cfg.keyColorMod3 ?? defaults.keyColorMod3 ?? ""
  property string valueKeyColorMod5: cfg.keyColorMod5 ?? defaults.keyColorMod5 ?? ""
  property string valueKeyTextMod2:  cfg.keyTextMod2  ?? defaults.keyTextMod2  ?? ""
  property string valueKeyTextMod3:  cfg.keyTextMod3  ?? defaults.keyTextMod3  ?? ""
  property string valueKeyTextMod5:  cfg.keyTextMod5  ?? defaults.keyTextMod5  ?? ""
  property string valueKeyLabelMod2: cfg.keyLabelMod2 ?? defaults.keyLabelMod2 ?? ""
  property string valueKeyLabelMod3: cfg.keyLabelMod3 ?? defaults.keyLabelMod3 ?? ""
  property string valueKeyLabelMod5: cfg.keyLabelMod5 ?? defaults.keyLabelMod5 ?? ""
  property string valueDescriptionTextColor: cfg.descriptionTextColor ?? defaults.descriptionTextColor ?? ""

  // Clipboard polling for quick-paste feature.
  // Reads wl-paste periodically while Settings is visible; exposes a validated hex if found.
  property string clipboardHex: ""

  Timer {
    id: clipboardTimer
    interval: 1500
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!clipboardProcess.running) clipboardProcess.running = true
  }

  Process {
    id: clipboardProcess
    command: ["wl-paste", "-n"]
    stdout: StdioCollector {
      onStreamFinished: {
        var raw = (text || "").trim();
        // Accept #RRGGBB or #RRGGBBAA (with or without leading #)
        var m = raw.match(/^#?([0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?)$/);
        if (m) {
          root.clipboardHex = "#" + m[1].toUpperCase();
        } else {
          root.clipboardHex = "";
        }
      }
    }
  }

  Component.onDestruction: {
    clipboardTimer.stop();
    if (clipboardProcess.running) clipboardProcess.running = false;
  }

  // ============ TAB BAR ============
  NTabBar {
    id: tabBar
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      text: pluginApi?.tr("settings.tab-general")
      icon: "settings"
      tabIndex: 0
      checked: tabBar.currentIndex === 0
    }
    NTabButton {
      text: pluginApi?.tr("settings.tab-appearance")
      icon: "color-picker"
      tabIndex: 1
      checked: tabBar.currentIndex === 1
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: Style.marginS
  }

  // ============ TAB VIEW ============
  NTabView {
    id: tabView
    currentIndex: tabBar.currentIndex

    // ============ TAB 1: GENERAL ============
    ColumnLayout {
      id: generalTab
      spacing: Style.marginM

      // Header
      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.title")
        pointSize: Style.fontSizeXXL
        font.weight: Style.fontWeightBold
        color: AtmoColor.mOnSurface
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.description")
        color: AtmoColor.mOnSurfaceVariant
        pointSize: Style.fontSizeM
        wrapMode: Text.WordWrap
      }

      // ===== Window Size =====
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: sizeContent.implicitHeight + Style.marginM * 2
        color: AtmoColor.mSurfaceVariant

        ColumnLayout {
          id: sizeContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.window-size")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: AtmoColor.mOnSurface
          }

          RowLayout {
            spacing: Style.marginM

            NText {
              text: pluginApi?.tr("settings.width")
              color: AtmoColor.mOnSurface
              pointSize: Style.fontSizeM
              Layout.preferredWidth: 120
            }

            NTextInput {
              id: widthInput
              Layout.preferredWidth: 100 * Style.uiScaleRatio
              Layout.preferredHeight: Style.baseWidgetSize
              text: root.editWindowWidth.toString()
              onTextChanged: {
                var val = parseInt(text);
                if (!isNaN(val) && val >= 400 && val <= 3000) {
                  root.editWindowWidth = val;
                }
              }
            }

            NText {
              text: pluginApi?.tr("settings.width-range")
              color: AtmoColor.mOnSurfaceVariant
              pointSize: Style.fontSizeS
            }
          }

          RowLayout {
            spacing: Style.marginM

            NText {
              text: pluginApi?.tr("settings.height")
              color: AtmoColor.mOnSurface
              pointSize: Style.fontSizeM
              Layout.preferredWidth: 120
            }

            NToggle {
              id: autoHeightToggle
              label: pluginApi?.tr("settings.auto-height")
              checked: root.editAutoHeight
              onToggled: function(checked) {
                root.editAutoHeight = checked;
              }
            }

            NTextInput {
              id: heightInput
              Layout.preferredWidth: 100 * Style.uiScaleRatio
              Layout.preferredHeight: Style.baseWidgetSize
              text: root.editWindowHeight.toString()
              enabled: !autoHeightToggle.checked
              opacity: enabled ? 1.0 : 0.5
              onTextChanged: {
                var val = parseInt(text);
                if (!isNaN(val) && val >= 300 && val <= 2000) {
                  root.editWindowHeight = val;
                }
              }
            }

            NText {
              text: pluginApi?.tr("settings.height-range")
              color: AtmoColor.mOnSurfaceVariant
              pointSize: Style.fontSizeS
              opacity: autoHeightToggle.checked ? 0.5 : 1.0
            }
          }

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.auto-height-hint")
            color: AtmoColor.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            wrapMode: Text.WordWrap
          }
        }
      }

      // ===== Layout (Columns) =====
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: columnContent.implicitHeight + Style.marginM * 2
        color: AtmoColor.mSurfaceVariant

        ColumnLayout {
          id: columnContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.layout")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: AtmoColor.mOnSurface
          }

          RowLayout {
            spacing: Style.marginM

            NText {
              text: pluginApi?.tr("settings.columns")
              color: AtmoColor.mOnSurface
              pointSize: Style.fontSizeM
            }

            NComboBox {
              id: columnCombo
              Layout.preferredWidth: 150 * Style.uiScaleRatio
              Layout.preferredHeight: Style.baseWidgetSize
              model: ListModel {
                ListElement { name: "1"; key: "1" }
                ListElement { name: "2"; key: "2" }
                ListElement { name: "3"; key: "3" }
                ListElement { name: "4"; key: "4" }
              }
              currentKey: root.editColumnCount.toString()
              onSelected: key => {
                root.editColumnCount = parseInt(key);
              }
            }
          }

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.columns-hint")
            color: AtmoColor.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            wrapMode: Text.WordWrap
          }
        }
      }

      // ===== Parsing Options =====
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: parsingContent.implicitHeight + Style.marginM * 2
        color: AtmoColor.mSurfaceVariant

        ColumnLayout {
          id: parsingContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.parsing-options")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: AtmoColor.mOnSurface
          }

          NToggle {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.merge-sequential")
            description: pluginApi?.tr("settings.merge-sequential-hint")
            checked: root.editMergeSequentialBinds
            onToggled: function(checked) {
              root.editMergeSequentialBinds = checked;
            }
          }

          NToggle {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.show-undescribed")
            description: pluginApi?.tr("settings.show-undescribed-hint")
            checked: root.editShowUndescribedBinds
            onToggled: function(checked) {
              root.editShowUndescribedBinds = checked;
            }
          }

          // Bind override management (custom descriptions / hidden binds)
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS

            function overrideCount(kind) {
              var o = root.editBindOverrides;
              var n = 0;
              for (var k in o) {
                if (kind === "hidden" && o[k] && o[k].hidden === true) n++;
                else if (kind === "desc" && o[k] && o[k].desc) n++;
              }
              return n;
            }

            NText {
              Layout.fillWidth: true
              text: pluginApi?.tr("settings.overrides-summary", {
                "hidden": parent.overrideCount("hidden"),
                "custom": parent.overrideCount("desc")
              })
              color: AtmoColor.mOnSurfaceVariant
              pointSize: Style.fontSizeXS
              wrapMode: Text.WordWrap
            }

            RowLayout {
              spacing: Style.marginM

              NButton {
                text: pluginApi?.tr("settings.restore-hidden")
                icon: "eye"
                onClicked: {
                  root.restoreHidden();
                }
              }

              NButton {
                text: pluginApi?.tr("settings.clear-overrides")
                icon: "rotate"
                onClicked: {
                  root.restoreHidden(true);
                }
              }
            }
          }

          NToggle {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.split-workspaces")
            description: pluginApi?.tr("settings.split-workspaces-hint")
            checked: root.editSplitLargeWorkspaceCategory
            onToggled: function(checked) {
              root.editSplitLargeWorkspaceCategory = checked;
            }
          }

          RowLayout {
            spacing: Style.marginM
            visible: root.editSplitLargeWorkspaceCategory

            NText {
              text: pluginApi?.tr("settings.split-threshold")
              color: AtmoColor.mOnSurface
              pointSize: Style.fontSizeM
              Layout.fillWidth: true
            }

            NSpinBox {
              id: workspaceThreshold
              objectName: "settings-range-editWorkspaceSplitThreshold"
              Layout.preferredWidth: 140 * Style.uiScaleRatio
              value: root.editWorkspaceSplitThreshold
              from: 4
              to: 50
              stepSize: 1
              onValueModified: value => {
                root.editWorkspaceSplitThreshold = value;
              }
            }
          }
        }
      }

      // ===== Configuration Files =====
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: pathsContent.implicitHeight + Style.marginM * 2
        color: AtmoColor.mSurfaceVariant

        ColumnLayout {
          id: pathsContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.config-paths")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: AtmoColor.mOnSurface
          }

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.config-paths-description")
            color: AtmoColor.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            wrapMode: Text.WordWrap
          }

          ColumnLayout {
            spacing: Style.marginXS

            RowLayout {
              spacing: Style.marginS
              AtmoIcon {
                icon: "keyboard"
                pointSize: Style.fontSizeM
                color: AtmoColor.mOnSurface
              }
              NText {
                text: pluginApi?.tr("settings.mod-var")
                color: AtmoColor.mOnSurface
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
              }
            }

            NTextInput {
              id: modVarInput
              Layout.fillWidth: true
              Layout.preferredHeight: Style.baseWidgetSize
              text: root.editModKeyVariable
              placeholderText: "$mod"
              onTextChanged: {
                if (text.length > 0) root.editModKeyVariable = text;
              }
            }

            NText {
              Layout.fillWidth: true
              text: pluginApi?.tr("settings.mod-var-hint")
              color: AtmoColor.mOnSurfaceVariant
              pointSize: Style.fontSizeXS
              wrapMode: Text.WordWrap
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: AtmoColor.mOutline
            opacity: 0.3
          }

          ColumnLayout {
            spacing: Style.marginXS

            RowLayout {
              spacing: Style.marginS
              AtmoIcon {
                icon: "terminal"
                pointSize: Style.fontSizeM
                color: AtmoColor.mPrimary
              }
              NText {
                text: pluginApi?.tr("settings.hyprland-path")
                color: AtmoColor.mOnSurface
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
              }
            }

            NTextInput {
              id: hyprlandPathInput
              Layout.fillWidth: true
              Layout.preferredHeight: Style.baseWidgetSize
              text: root.editHyprlandConfigPath
              placeholderText: "~/.config/hypr/hyprland.conf"
              onTextChanged: {
                if (text.length > 0) root.editHyprlandConfigPath = text;
              }
            }

            NText {
              Layout.fillWidth: true
              text: pluginApi?.tr("settings.hyprland-format-hint")
              color: AtmoColor.mOnSurfaceVariant
              pointSize: Style.fontSizeXS
              wrapMode: Text.WordWrap
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: AtmoColor.mOutline
            opacity: 0.3
          }

          // Hyprland Lua path + parser mode (Hyprland 0.55+)
          ColumnLayout {
            spacing: Style.marginXS

            RowLayout {
              spacing: Style.marginS
              AtmoIcon {
                icon: "terminal"
                pointSize: Style.fontSizeM
                color: AtmoColor.mPrimary
              }
              NText {
                text: pluginApi?.tr("settings.hyprland-lua-path")
                color: AtmoColor.mOnSurface
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
              }
            }

            NTextInput {
              id: hyprlandLuaPathInput
              Layout.fillWidth: true
              Layout.preferredHeight: Style.baseWidgetSize
              text: root.editHyprlandLuaConfigPath
              placeholderText: "~/.config/hypr/hyprland.lua"
              onTextChanged: {
                if (text.length > 0) root.editHyprlandLuaConfigPath = text;
              }
            }

            RowLayout {
              spacing: Style.marginM
              NText {
                text: pluginApi?.tr("settings.hyprland-parser-mode")
                color: AtmoColor.mOnSurface
                pointSize: Style.fontSizeM
              }
              NComboBox {
                id: parserModeCombo
                Layout.preferredWidth: 180 * Style.uiScaleRatio
                Layout.preferredHeight: Style.baseWidgetSize
                model: ListModel {
                  ListElement { name: "Auto"; key: "auto" }
                  ListElement { name: "Lua (hyprctl)"; key: "lua" }
                  ListElement { name: "Legacy .conf"; key: "conf" }
                }
                currentKey: root.editHyprlandParserMode
                onSelected: key => { root.editHyprlandParserMode = key; }
              }
            }

            NText {
              Layout.fillWidth: true
              text: pluginApi?.tr("settings.hyprland-lua-hint")
              color: AtmoColor.mOnSurfaceVariant
              pointSize: Style.fontSizeXS
              wrapMode: Text.WordWrap
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: AtmoColor.mOutline
            opacity: 0.3
          }

          ColumnLayout {
            spacing: Style.marginXS

            RowLayout {
              spacing: Style.marginS
              AtmoIcon {
                icon: "layout"
                pointSize: Style.fontSizeM
                color: AtmoColor.mSecondary
              }
              NText {
                text: pluginApi?.tr("settings.niri-path")
                color: AtmoColor.mOnSurface
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
              }
            }

            NTextInput {
              id: niriPathInput
              Layout.fillWidth: true
              Layout.preferredHeight: Style.baseWidgetSize
              text: root.editNiriConfigPath
              placeholderText: "~/.config/niri/config.kdl"
              onTextChanged: {
                if (text.length > 0) root.editNiriConfigPath = text;
              }
            }

            NText {
              Layout.fillWidth: true
              text: pluginApi?.tr("settings.niri-format-hint")
              color: AtmoColor.mOnSurfaceVariant
              pointSize: Style.fontSizeXS
              wrapMode: Text.WordWrap
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: AtmoColor.mOutline
            opacity: 0.3
          }

          ColumnLayout {
            spacing: Style.marginXS

            RowLayout {
              spacing: Style.marginS
              AtmoIcon {
                icon: "terminal"
                pointSize: Style.fontSizeM
                color: AtmoColor.mTertiary
              }
              NText {
                text: pluginApi?.tr("settings.mango-path")
                color: AtmoColor.mOnSurface
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
              }
            }

            NTextInput {
              id: mangoPathInput
              Layout.fillWidth: true
              Layout.preferredHeight: Style.baseWidgetSize
              text: root.editMangoConfigPath
              placeholderText: "~/.config/mango/config.conf"
              onTextChanged: {
                if (text.length > 0) root.editMangoConfigPath = text;
              }
            }

            NText {
              Layout.fillWidth: true
              text: pluginApi?.tr("settings.mango-format-hint")
              color: AtmoColor.mOnSurfaceVariant
              pointSize: Style.fontSizeXS
              wrapMode: Text.WordWrap
            }
          }
        }
      }

      // ===== Actions =====
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: actionsContent.implicitHeight + Style.marginM * 2
        color: AtmoColor.mSurfaceVariant

        ColumnLayout {
          id: actionsContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.actions")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: AtmoColor.mOnSurface
          }

          RowLayout {
            spacing: Style.marginM

            NButton {
              text: pluginApi?.tr("settings.refresh-keybinds")
              icon: "refresh"
              onClicked: {
                pluginApi?.mainInstance?.refresh();
                ToastService.showNotice(pluginApi?.tr("settings.refresh-message"));
              }
            }

            NButton {
              text: pluginApi?.tr("settings.reset-defaults")
              icon: "rotate"
              onClicked: {
                root.editWindowWidth = defaults.windowWidth || 1400;
                root.editWindowHeight = defaults.windowHeight || 850;
                root.editAutoHeight = defaults.autoHeight ?? true;
                root.editColumnCount = defaults.columnCount || 3;
                root.editModKeyVariable = defaults.modKeyVariable || "$mod";
                root.editHyprlandConfigPath = defaults.hyprlandConfigPath || "~/.config/hypr/hyprland.conf";
                root.editHyprlandLuaConfigPath = defaults.hyprlandLuaConfigPath || "~/.config/hypr/hyprland.lua";
                root.editHyprlandParserMode = defaults.hyprlandParserMode || "auto";
                root.editNiriConfigPath = defaults.niriConfigPath || "~/.config/niri/config.kdl";
                root.editMangoConfigPath = defaults.mangoConfigPath || "~/.config/mango/config.conf";
                root.editMergeSequentialBinds = defaults.mergeSequentialBinds ?? true;
                root.editShowUndescribedBinds = defaults.showUndescribedBinds ?? false;
                root.editSplitLargeWorkspaceCategory = defaults.splitLargeWorkspaceCategory ?? true;
                root.editWorkspaceSplitThreshold = defaults.workspaceSplitThreshold ?? 12;

                widthInput.text = root.editWindowWidth.toString();
                heightInput.text = root.editWindowHeight.toString();
                modVarInput.text = root.editModKeyVariable;
                hyprlandPathInput.text = root.editHyprlandConfigPath;
                hyprlandLuaPathInput.text = root.editHyprlandLuaConfigPath;
                niriPathInput.text = root.editNiriConfigPath;
                mangoPathInput.text = root.editMangoConfigPath;

                root.editCheatsheetData = [];
              }
            }
          }
        }
      }

      // ===== Keybind Setup =====
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: keybindContent.implicitHeight + Style.marginM * 2
        color: AtmoColor.mSurfaceVariant

        ColumnLayout {
          id: keybindContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.keybind-setup")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: AtmoColor.mOnSurface
          }

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.keybind-setup-description")
            color: AtmoColor.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            wrapMode: Text.WordWrap
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: commandText.implicitHeight + Style.marginS * 2
            color: AtmoColor.mSurface
            radius: Style.radiusS

            NText {
              id: commandText
              anchors.fill: parent
              anchors.margins: Style.marginS
              text: pluginApi?.tr("settings.keybind-ipc-command")
              font.family: "monospace"
              pointSize: Style.fontSizeS
              color: AtmoColor.mPrimary
              wrapMode: Text.WrapAnywhere
            }
          }

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.keybind-example-hyprland")
            color: AtmoColor.mOnSurfaceVariant
            pointSize: Style.fontSizeXS
            wrapMode: Text.WordWrap
          }

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.keybind-example-niri")
            color: AtmoColor.mOnSurfaceVariant
            pointSize: Style.fontSizeXS
            wrapMode: Text.WordWrap
          }

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.keybind-example-mango")
            color: AtmoColor.mOnSurfaceVariant
            pointSize: Style.fontSizeXS
            wrapMode: Text.WordWrap
          }
        }
      }

      Item {
        Layout.preferredHeight: Style.marginL
      }
    }
    // ============ END TAB 1 ============

    // ============ TAB 2: APPEARANCE ============
    ColumnLayout {
      id: appearanceTab
      spacing: Style.marginM

      // Header
      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.appearance-section")
        pointSize: Style.fontSizeXXL
        font.weight: Style.fontWeightBold
        color: AtmoColor.mOnSurface
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.appearance-description")
        color: AtmoColor.mOnSurfaceVariant
        pointSize: Style.fontSizeM
        wrapMode: Text.WordWrap
      }

      // ===== Live Preview =====
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: previewContent.implicitHeight + Style.marginM * 2
        color: AtmoColor.mSurfaceVariant

        ColumnLayout {
          id: previewContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.preview-section")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: AtmoColor.mOnSurface
          }

          Flow {
            Layout.fillWidth: true
            spacing: Style.marginS

            Local.PreviewBadge { label: "Super"; bg: root.valueKeyColorSuper || AtmoColor.mPrimary; fg: root.valueKeyTextSuper || root.valueKeyLabelColor }
            Local.PreviewBadge { label: "Ctrl"; bg: root.valueKeyColorCtrl || AtmoColor.mSecondary; fg: root.valueKeyTextCtrl || root.valueKeyLabelColor }
            Local.PreviewBadge { label: "Shift"; bg: root.valueKeyColorShift || AtmoColor.mTertiary; fg: root.valueKeyTextShift || root.valueKeyLabelColor }
            Local.PreviewBadge { label: "Alt"; bg: root.valueKeyColorAlt; fg: root.valueKeyTextAlt || root.valueKeyLabelColor }
            Local.PreviewBadge { label: "XF86Audio"; bg: root.valueKeyColorXF86; fg: root.valueKeyTextXF86 || root.valueKeyLabelColor }
            Local.PreviewBadge { label: "Print"; bg: root.valueKeyColorPrint; fg: root.valueKeyTextPrint || root.valueKeyLabelColor }
            Local.PreviewBadge { label: "1-9"; bg: root.valueKeyColorNumeric; fg: root.valueKeyTextNumeric || root.valueKeyLabelColor }
            Local.PreviewBadge { label: "mouse:272"; bg: root.valueKeyColorMouse; fg: root.valueKeyTextMouse || root.valueKeyLabelColor }
            Local.PreviewBadge { label: "Q"; bg: root.valueKeyColorDefault; fg: root.valueKeyTextDefault || root.valueKeyLabelColor }
            Local.PreviewBadge { label: root.valueKeyLabelMod3 || "Mod3"; bg: root.valueKeyColorMod3 || root.valueKeyColorDefault; fg: root.valueKeyTextMod3 || root.valueKeyLabelColor }
            Local.PreviewBadge { label: root.valueKeyLabelMod2 || "Mod2"; bg: root.valueKeyColorMod2 || root.valueKeyColorDefault; fg: root.valueKeyTextMod2 || root.valueKeyLabelColor }
            Local.PreviewBadge { label: root.valueKeyLabelMod5 || "Mod5"; bg: root.valueKeyColorMod5 || root.valueKeyColorDefault; fg: root.valueKeyTextMod5 || root.valueKeyLabelColor }
          }

          // Description preview sample
          NText {
            Layout.fillWidth: true
            Layout.topMargin: Style.marginS
            text: pluginApi?.tr("settings.color-description") + " — sample"
            color: root.valueDescriptionTextColor
            pointSize: Style.fontSizeM
          }
        }
      }

      // ===== Color Pickers =====
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: colorContent.implicitHeight + Style.marginM * 2
        color: AtmoColor.mSurfaceVariant

        ColumnLayout {
          id: colorContent
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.color-pickers")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: AtmoColor.mOnSurface
          }

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.color-theme-hint")
            color: AtmoColor.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            wrapMode: Text.WordWrap
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS
            AtmoIcon {
              icon: "clipboard"
              pointSize: Style.fontSizeM
              color: root.clipboardHex.length > 0 ? AtmoColor.mPrimary : AtmoColor.mOnSurfaceVariant
            }
            NText {
              Layout.fillWidth: true
              text: pluginApi?.tr("settings.color-paste-hint")
              color: AtmoColor.mOnSurfaceVariant
              pointSize: Style.fontSizeS
              wrapMode: Text.WordWrap
            }
          }

          // Super (modifier: empty bg = theme accent)
          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-super")
            letter: "S"
            bgValue: root.valueKeyColorSuper
            textValue: root.valueKeyTextSuper
            bgFallback: AtmoColor.mPrimary
            textFallback: root.valueKeyLabelColor
            clipboardHex: root.clipboardHex
            onBgPicked: c => { root.valueKeyColorSuper = c.toString(); root._applyPreview("keyColorSuper", c.toString()); }
            onTextPicked: c => { root.valueKeyTextSuper = c.toString(); root._applyPreview("keyTextSuper", c.toString()); }
            onBgPasted: hex => { root.valueKeyColorSuper = hex; root._applyPreview("keyColorSuper", hex); }
            onTextPasted: hex => { root.valueKeyTextSuper = hex; root._applyPreview("keyTextSuper", hex); }
            onResetRequested: {
              root.valueKeyColorSuper = ""; root._applyPreview("keyColorSuper", "");
              root.valueKeyTextSuper  = ""; root._applyPreview("keyTextSuper", "");
            }
          }

          // Ctrl
          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-ctrl")
            letter: "C"
            bgValue: root.valueKeyColorCtrl
            textValue: root.valueKeyTextCtrl
            bgFallback: AtmoColor.mSecondary
            textFallback: root.valueKeyLabelColor
            clipboardHex: root.clipboardHex
            onBgPicked: c => { root.valueKeyColorCtrl = c.toString(); root._applyPreview("keyColorCtrl", c.toString()); }
            onTextPicked: c => { root.valueKeyTextCtrl = c.toString(); root._applyPreview("keyTextCtrl", c.toString()); }
            onBgPasted: hex => { root.valueKeyColorCtrl = hex; root._applyPreview("keyColorCtrl", hex); }
            onTextPasted: hex => { root.valueKeyTextCtrl = hex; root._applyPreview("keyTextCtrl", hex); }
            onResetRequested: {
              root.valueKeyColorCtrl = ""; root._applyPreview("keyColorCtrl", "");
              root.valueKeyTextCtrl  = ""; root._applyPreview("keyTextCtrl", "");
            }
          }

          // Shift
          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-shift")
            letter: "⇧"
            bgValue: root.valueKeyColorShift
            textValue: root.valueKeyTextShift
            bgFallback: AtmoColor.mTertiary
            textFallback: root.valueKeyLabelColor
            clipboardHex: root.clipboardHex
            onBgPicked: c => { root.valueKeyColorShift = c.toString(); root._applyPreview("keyColorShift", c.toString()); }
            onTextPicked: c => { root.valueKeyTextShift = c.toString(); root._applyPreview("keyTextShift", c.toString()); }
            onBgPasted: hex => { root.valueKeyColorShift = hex; root._applyPreview("keyColorShift", hex); }
            onTextPasted: hex => { root.valueKeyTextShift = hex; root._applyPreview("keyTextShift", hex); }
            onResetRequested: {
              root.valueKeyColorShift = ""; root._applyPreview("keyColorShift", "");
              root.valueKeyTextShift  = ""; root._applyPreview("keyTextShift", "");
            }
          }

          // Alt
          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-alt")
            letter: "A"
            bgValue: root.valueKeyColorAlt
            textValue: root.valueKeyTextAlt
            bgFallback: defaults.keyColorAlt || "#FF6B6B"
            textFallback: root.valueKeyLabelColor
            clipboardHex: root.clipboardHex
            onBgPicked: c => { root.valueKeyColorAlt = c.toString(); root._applyPreview("keyColorAlt", c.toString()); }
            onTextPicked: c => { root.valueKeyTextAlt = c.toString(); root._applyPreview("keyTextAlt", c.toString()); }
            onBgPasted: hex => { root.valueKeyColorAlt = hex; root._applyPreview("keyColorAlt", hex); }
            onTextPasted: hex => { root.valueKeyTextAlt = hex; root._applyPreview("keyTextAlt", hex); }
            onResetRequested: {
              var d = defaults.keyColorAlt || "#FF6B6B";
              root.valueKeyColorAlt = d; root._applyPreview("keyColorAlt", d);
              root.valueKeyTextAlt  = ""; root._applyPreview("keyTextAlt", "");
            }
          }

          // Generic X11 mods (Mod2/Mod3/Mod5): same colour controls as the other
          // modifiers, plus a rename field (e.g. caps:hyper -> label Mod3 "Hyper").
          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("settings.mod-label-hint")
            color: AtmoColor.mOnSurfaceVariant
            pointSize: Style.fontSizeS
            wrapMode: Text.WordWrap
          }

          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-mod3")
            letter: root.valueKeyLabelMod3.length > 0 ? root.valueKeyLabelMod3.charAt(0) : "3"
            showLabel: true
            labelValue: root.valueKeyLabelMod3
            labelPlaceholder: "Mod3"
            bgValue: root.valueKeyColorMod3
            textValue: root.valueKeyTextMod3
            bgFallback: defaults.keyColorDefault || "#6C757D"
            textFallback: root.valueKeyLabelColor
            clipboardHex: root.clipboardHex
            onBgPicked: c => { root.valueKeyColorMod3 = c.toString(); root._applyPreview("keyColorMod3", c.toString()); }
            onTextPicked: c => { root.valueKeyTextMod3 = c.toString(); root._applyPreview("keyTextMod3", c.toString()); }
            onBgPasted: hex => { root.valueKeyColorMod3 = hex; root._applyPreview("keyColorMod3", hex); }
            onTextPasted: hex => { root.valueKeyTextMod3 = hex; root._applyPreview("keyTextMod3", hex); }
            onLabelEdited: t => { root.valueKeyLabelMod3 = t; root._applyPreview("keyLabelMod3", t); }
            onResetRequested: {
              root.valueKeyColorMod3 = ""; root._applyPreview("keyColorMod3", "");
              root.valueKeyTextMod3  = ""; root._applyPreview("keyTextMod3", "");
              root.valueKeyLabelMod3 = ""; root._applyPreview("keyLabelMod3", "");
            }
          }

          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-mod2")
            letter: root.valueKeyLabelMod2.length > 0 ? root.valueKeyLabelMod2.charAt(0) : "2"
            showLabel: true
            labelValue: root.valueKeyLabelMod2
            labelPlaceholder: "Mod2"
            bgValue: root.valueKeyColorMod2
            textValue: root.valueKeyTextMod2
            bgFallback: defaults.keyColorDefault || "#6C757D"
            textFallback: root.valueKeyLabelColor
            clipboardHex: root.clipboardHex
            onBgPicked: c => { root.valueKeyColorMod2 = c.toString(); root._applyPreview("keyColorMod2", c.toString()); }
            onTextPicked: c => { root.valueKeyTextMod2 = c.toString(); root._applyPreview("keyTextMod2", c.toString()); }
            onBgPasted: hex => { root.valueKeyColorMod2 = hex; root._applyPreview("keyColorMod2", hex); }
            onTextPasted: hex => { root.valueKeyTextMod2 = hex; root._applyPreview("keyTextMod2", hex); }
            onLabelEdited: t => { root.valueKeyLabelMod2 = t; root._applyPreview("keyLabelMod2", t); }
            onResetRequested: {
              root.valueKeyColorMod2 = ""; root._applyPreview("keyColorMod2", "");
              root.valueKeyTextMod2  = ""; root._applyPreview("keyTextMod2", "");
              root.valueKeyLabelMod2 = ""; root._applyPreview("keyLabelMod2", "");
            }
          }

          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-mod5")
            letter: root.valueKeyLabelMod5.length > 0 ? root.valueKeyLabelMod5.charAt(0) : "5"
            showLabel: true
            labelValue: root.valueKeyLabelMod5
            labelPlaceholder: "Mod5"
            bgValue: root.valueKeyColorMod5
            textValue: root.valueKeyTextMod5
            bgFallback: defaults.keyColorDefault || "#6C757D"
            textFallback: root.valueKeyLabelColor
            clipboardHex: root.clipboardHex
            onBgPicked: c => { root.valueKeyColorMod5 = c.toString(); root._applyPreview("keyColorMod5", c.toString()); }
            onTextPicked: c => { root.valueKeyTextMod5 = c.toString(); root._applyPreview("keyTextMod5", c.toString()); }
            onBgPasted: hex => { root.valueKeyColorMod5 = hex; root._applyPreview("keyColorMod5", hex); }
            onTextPasted: hex => { root.valueKeyTextMod5 = hex; root._applyPreview("keyTextMod5", hex); }
            onLabelEdited: t => { root.valueKeyLabelMod5 = t; root._applyPreview("keyLabelMod5", t); }
            onResetRequested: {
              root.valueKeyColorMod5 = ""; root._applyPreview("keyColorMod5", "");
              root.valueKeyTextMod5  = ""; root._applyPreview("keyTextMod5", "");
              root.valueKeyLabelMod5 = ""; root._applyPreview("keyLabelMod5", "");
            }
          }

          // XF86
          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-xf86")
            letter: "♪"
            bgValue: root.valueKeyColorXF86
            textValue: root.valueKeyTextXF86
            bgFallback: defaults.keyColorXF86 || "#4ECDC4"
            textFallback: root.valueKeyLabelColor
            clipboardHex: root.clipboardHex
            onBgPicked: c => { root.valueKeyColorXF86 = c.toString(); root._applyPreview("keyColorXF86", c.toString()); }
            onTextPicked: c => { root.valueKeyTextXF86 = c.toString(); root._applyPreview("keyTextXF86", c.toString()); }
            onBgPasted: hex => { root.valueKeyColorXF86 = hex; root._applyPreview("keyColorXF86", hex); }
            onTextPasted: hex => { root.valueKeyTextXF86 = hex; root._applyPreview("keyTextXF86", hex); }
            onResetRequested: {
              var d = defaults.keyColorXF86 || "#4ECDC4";
              root.valueKeyColorXF86 = d; root._applyPreview("keyColorXF86", d);
              root.valueKeyTextXF86  = ""; root._applyPreview("keyTextXF86", "");
            }
          }

          // Print
          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-print")
            letter: "P"
            bgValue: root.valueKeyColorPrint
            textValue: root.valueKeyTextPrint
            bgFallback: defaults.keyColorPrint || "#95E1D3"
            textFallback: root.valueKeyLabelColor
            clipboardHex: root.clipboardHex
            onBgPicked: c => { root.valueKeyColorPrint = c.toString(); root._applyPreview("keyColorPrint", c.toString()); }
            onTextPicked: c => { root.valueKeyTextPrint = c.toString(); root._applyPreview("keyTextPrint", c.toString()); }
            onBgPasted: hex => { root.valueKeyColorPrint = hex; root._applyPreview("keyColorPrint", hex); }
            onTextPasted: hex => { root.valueKeyTextPrint = hex; root._applyPreview("keyTextPrint", hex); }
            onResetRequested: {
              var d = defaults.keyColorPrint || "#95E1D3";
              root.valueKeyColorPrint = d; root._applyPreview("keyColorPrint", d);
              root.valueKeyTextPrint  = ""; root._applyPreview("keyTextPrint", "");
            }
          }

          // Numeric
          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-numeric")
            letter: "1"
            bgValue: root.valueKeyColorNumeric
            textValue: root.valueKeyTextNumeric
            bgFallback: defaults.keyColorNumeric || "#A8DADC"
            textFallback: root.valueKeyLabelColor
            clipboardHex: root.clipboardHex
            onBgPicked: c => { root.valueKeyColorNumeric = c.toString(); root._applyPreview("keyColorNumeric", c.toString()); }
            onTextPicked: c => { root.valueKeyTextNumeric = c.toString(); root._applyPreview("keyTextNumeric", c.toString()); }
            onBgPasted: hex => { root.valueKeyColorNumeric = hex; root._applyPreview("keyColorNumeric", hex); }
            onTextPasted: hex => { root.valueKeyTextNumeric = hex; root._applyPreview("keyTextNumeric", hex); }
            onResetRequested: {
              var d = defaults.keyColorNumeric || "#A8DADC";
              root.valueKeyColorNumeric = d; root._applyPreview("keyColorNumeric", d);
              root.valueKeyTextNumeric  = ""; root._applyPreview("keyTextNumeric", "");
            }
          }

          // Mouse
          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-mouse")
            letter: "M"
            bgValue: root.valueKeyColorMouse
            textValue: root.valueKeyTextMouse
            bgFallback: defaults.keyColorMouse || "#F38181"
            textFallback: root.valueKeyLabelColor
            clipboardHex: root.clipboardHex
            onBgPicked: c => { root.valueKeyColorMouse = c.toString(); root._applyPreview("keyColorMouse", c.toString()); }
            onTextPicked: c => { root.valueKeyTextMouse = c.toString(); root._applyPreview("keyTextMouse", c.toString()); }
            onBgPasted: hex => { root.valueKeyColorMouse = hex; root._applyPreview("keyColorMouse", hex); }
            onTextPasted: hex => { root.valueKeyTextMouse = hex; root._applyPreview("keyTextMouse", hex); }
            onResetRequested: {
              var d = defaults.keyColorMouse || "#F38181";
              root.valueKeyColorMouse = d; root._applyPreview("keyColorMouse", d);
              root.valueKeyTextMouse  = ""; root._applyPreview("keyTextMouse", "");
            }
          }

          // Default letter keys
          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-default")
            letter: "Q"
            bgValue: root.valueKeyColorDefault
            textValue: root.valueKeyTextDefault
            bgFallback: defaults.keyColorDefault || "#6C757D"
            textFallback: root.valueKeyLabelColor
            clipboardHex: root.clipboardHex
            onBgPicked: c => { root.valueKeyColorDefault = c.toString(); root._applyPreview("keyColorDefault", c.toString()); }
            onTextPicked: c => { root.valueKeyTextDefault = c.toString(); root._applyPreview("keyTextDefault", c.toString()); }
            onBgPasted: hex => { root.valueKeyColorDefault = hex; root._applyPreview("keyColorDefault", hex); }
            onTextPasted: hex => { root.valueKeyTextDefault = hex; root._applyPreview("keyTextDefault", hex); }
            onResetRequested: {
              var d = defaults.keyColorDefault || "#6C757D";
              root.valueKeyColorDefault = d; root._applyPreview("keyColorDefault", d);
              root.valueKeyTextDefault  = ""; root._applyPreview("keyTextDefault", "");
            }
          }

          // Description text (text-only row — no background)
          // Empty value = theme-aware (Color.mOnSurface) at render time.
          Local.ColorPairRow {
            pluginApi: root.pluginApi
            labelText: pluginApi?.tr("settings.color-description")
            letter: "T"
            showBg: false
            bgValue: ""
            textValue: root.valueDescriptionTextColor
            textFallback: AtmoColor.mOnSurface
            clipboardHex: root.clipboardHex
            onTextPicked: c => { root.valueDescriptionTextColor = c.toString(); root._applyPreview("descriptionTextColor", c.toString()); }
            onTextPasted: hex => { root.valueDescriptionTextColor = hex; root._applyPreview("descriptionTextColor", hex); }
            onResetRequested: {
              root.valueDescriptionTextColor = ""; root._applyPreview("descriptionTextColor", "");
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: AtmoColor.mOutline
            opacity: 0.3
          }

          NButton {
            Layout.alignment: Qt.AlignRight
            text: pluginApi?.tr("settings.reset-all-colors")
            icon: "rotate"
            onClicked: {
              var dAlt     = defaults.keyColorAlt     || "#FF6B6B";
              var dXF86    = defaults.keyColorXF86    || "#4ECDC4";
              var dPrint   = defaults.keyColorPrint   || "#95E1D3";
              var dNumeric = defaults.keyColorNumeric || "#A8DADC";
              var dMouse   = defaults.keyColorMouse   || "#F38181";
              var dDefault = defaults.keyColorDefault || "#6C757D";
              var dLabel   = defaults.keyLabelColor   || "#FFFFFF";
              var dDesc    = defaults.descriptionTextColor ?? "";

              root.valueKeyColorSuper = "";
              root.valueKeyColorCtrl = "";
              root.valueKeyColorShift = "";
              root.valueKeyColorAlt = dAlt;
              root.valueKeyColorXF86 = dXF86;
              root.valueKeyColorPrint = dPrint;
              root.valueKeyColorNumeric = dNumeric;
              root.valueKeyColorMouse = dMouse;
              root.valueKeyColorDefault = dDefault;
              root.valueKeyLabelColor = dLabel;
              root.valueDescriptionTextColor = dDesc;

              root.valueKeyTextSuper = "";
              root.valueKeyTextCtrl = "";
              root.valueKeyTextShift = "";
              root.valueKeyTextAlt = "";
              root.valueKeyTextXF86 = "";
              root.valueKeyTextPrint = "";
              root.valueKeyTextNumeric = "";
              root.valueKeyTextMouse = "";
              root.valueKeyTextDefault = "";

              root.valueKeyColorMod2 = ""; root.valueKeyColorMod3 = ""; root.valueKeyColorMod5 = "";
              root.valueKeyTextMod2  = ""; root.valueKeyTextMod3  = ""; root.valueKeyTextMod5  = "";
              root.valueKeyLabelMod2 = ""; root.valueKeyLabelMod3 = ""; root.valueKeyLabelMod5 = "";

              if (pluginApi) {
                pluginApi.previewSettings({
                  keyColorSuper: "",
                  keyColorCtrl: "",
                  keyColorShift: "",
                  keyColorAlt: dAlt,
                  keyColorXF86: dXF86,
                  keyColorPrint: dPrint,
                  keyColorNumeric: dNumeric,
                  keyColorMouse: dMouse,
                  keyColorDefault: dDefault,
                  keyLabelColor: dLabel,
                  descriptionTextColor: dDesc,
                  keyTextSuper: "",
                  keyTextCtrl: "",
                  keyTextShift: "",
                  keyTextAlt: "",
                  keyTextXF86: "",
                  keyTextPrint: "",
                  keyTextNumeric: "",
                  keyTextMouse: "",
                  keyTextDefault: "",
                  keyColorMod2: "", keyColorMod3: "", keyColorMod5: "",
                  keyTextMod2: "", keyTextMod3: "", keyTextMod5: "",
                  keyLabelMod2: "", keyLabelMod3: "", keyLabelMod5: ""
                });
              }
            }
          }
        }
      }

      Item {
        Layout.preferredHeight: Style.marginL
      }
    }
    // ============ END TAB 2 ============
  }
  // ============ END TAB VIEW ============

  // Save function called by the shell when user clicks Apply/Save
  function saveSettings() {
    if (!pluginApi) return;

    pluginApi.pluginSettings.windowWidth = root.editWindowWidth;
    pluginApi.pluginSettings.windowHeight = root.editWindowHeight;
    pluginApi.pluginSettings.autoHeight = root.editAutoHeight;
    pluginApi.pluginSettings.columnCount = root.editColumnCount;
    pluginApi.pluginSettings.modKeyVariable = root.editModKeyVariable;
    pluginApi.pluginSettings.hyprlandConfigPath = root.editHyprlandConfigPath;
    pluginApi.pluginSettings.hyprlandLuaConfigPath = root.editHyprlandLuaConfigPath;
    pluginApi.pluginSettings.hyprlandParserMode = root.editHyprlandParserMode;
    pluginApi.pluginSettings.niriConfigPath = root.editNiriConfigPath;
    pluginApi.pluginSettings.mangoConfigPath = root.editMangoConfigPath;
    pluginApi.pluginSettings.mergeSequentialBinds = root.editMergeSequentialBinds;
    pluginApi.pluginSettings.showUndescribedBinds = root.editShowUndescribedBinds;
    pluginApi.pluginSettings.splitLargeWorkspaceCategory = root.editSplitLargeWorkspaceCategory;
    pluginApi.pluginSettings.workspaceSplitThreshold = root.editWorkspaceSplitThreshold;

    pluginApi.pluginSettings.keyColorAlt = root.valueKeyColorAlt.toString();
    pluginApi.pluginSettings.keyColorXF86 = root.valueKeyColorXF86.toString();
    pluginApi.pluginSettings.keyColorPrint = root.valueKeyColorPrint.toString();
    pluginApi.pluginSettings.keyColorNumeric = root.valueKeyColorNumeric.toString();
    pluginApi.pluginSettings.keyColorMouse = root.valueKeyColorMouse.toString();
    pluginApi.pluginSettings.keyColorSuper = root.valueKeyColorSuper;
    pluginApi.pluginSettings.keyColorCtrl  = root.valueKeyColorCtrl;
    pluginApi.pluginSettings.keyColorShift = root.valueKeyColorShift;
    pluginApi.pluginSettings.keyColorDefault = root.valueKeyColorDefault.toString();
    pluginApi.pluginSettings.keyLabelColor = root.valueKeyLabelColor.toString();
    pluginApi.pluginSettings.descriptionTextColor = root.valueDescriptionTextColor.toString();

    pluginApi.pluginSettings.keyTextSuper   = root.valueKeyTextSuper;
    pluginApi.pluginSettings.keyTextCtrl    = root.valueKeyTextCtrl;
    pluginApi.pluginSettings.keyTextShift   = root.valueKeyTextShift;
    pluginApi.pluginSettings.keyTextAlt     = root.valueKeyTextAlt;
    pluginApi.pluginSettings.keyTextXF86    = root.valueKeyTextXF86;
    pluginApi.pluginSettings.keyTextPrint   = root.valueKeyTextPrint;
    pluginApi.pluginSettings.keyTextNumeric = root.valueKeyTextNumeric;
    pluginApi.pluginSettings.keyTextMouse   = root.valueKeyTextMouse;
    pluginApi.pluginSettings.keyTextDefault = root.valueKeyTextDefault;

    pluginApi.pluginSettings.keyColorMod2 = root.valueKeyColorMod2;
    pluginApi.pluginSettings.keyColorMod3 = root.valueKeyColorMod3;
    pluginApi.pluginSettings.keyColorMod5 = root.valueKeyColorMod5;
    pluginApi.pluginSettings.keyTextMod2  = root.valueKeyTextMod2;
    pluginApi.pluginSettings.keyTextMod3  = root.valueKeyTextMod3;
    pluginApi.pluginSettings.keyTextMod5  = root.valueKeyTextMod5;
    pluginApi.pluginSettings.keyLabelMod2 = root.valueKeyLabelMod2;
    pluginApi.pluginSettings.keyLabelMod3 = root.valueKeyLabelMod3;
    pluginApi.pluginSettings.keyLabelMod5 = root.valueKeyLabelMod5;

    pluginApi.pluginSettings.bindOverrides = JSON.parse(JSON.stringify(root.editBindOverrides));
    pluginApi.pluginSettings.cheatsheetData = JSON.parse(JSON.stringify(root.editCheatsheetData));
    pluginApi.saveSettings();
  }

  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if ((result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current") {
        root.pluginApi.mainInstance?.refresh();
        ToastService.showNotice(root.pluginApi.tr("settings.saved"));
      }
    }
  }
}
