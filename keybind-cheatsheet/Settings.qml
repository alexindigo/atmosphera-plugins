import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "." as Local
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: 0

  property var pluginApi: null
  readonly property var windowWidthField: pluginApi?.field("windowWidth") ?? null
  readonly property var windowHeightField: pluginApi?.field("windowHeight") ?? null
  readonly property var autoHeightField: pluginApi?.field("autoHeight") ?? null
  readonly property var columnCountField: pluginApi?.field("columnCount") ?? null
  readonly property var modKeyVariableField: pluginApi?.field("modKeyVariable") ?? null
  readonly property var hyprlandConfigPathField: pluginApi?.field("hyprlandConfigPath") ?? null
  readonly property var hyprlandLuaConfigPathField: pluginApi?.field("hyprlandLuaConfigPath") ?? null
  readonly property var hyprlandParserModeField: pluginApi?.field("hyprlandParserMode") ?? null
  readonly property var niriConfigPathField: pluginApi?.field("niriConfigPath") ?? null
  readonly property var mangoConfigPathField: pluginApi?.field("mangoConfigPath") ?? null
  readonly property var mergeSequentialBindsField: pluginApi?.field("mergeSequentialBinds") ?? null
  readonly property var showUndescribedBindsField: pluginApi?.field("showUndescribedBinds") ?? null
  readonly property var splitLargeWorkspaceCategoryField: pluginApi?.field("splitLargeWorkspaceCategory") ?? null
  readonly property var workspaceSplitThresholdField: pluginApi?.field("workspaceSplitThreshold") ?? null
  readonly property var keyColorAltField: pluginApi?.field("keyColorAlt") ?? null
  readonly property var keyColorXF86Field: pluginApi?.field("keyColorXF86") ?? null
  readonly property var keyColorPrintField: pluginApi?.field("keyColorPrint") ?? null
  readonly property var keyColorNumericField: pluginApi?.field("keyColorNumeric") ?? null
  readonly property var keyColorMouseField: pluginApi?.field("keyColorMouse") ?? null
  readonly property var keyColorSuperField: pluginApi?.field("keyColorSuper") ?? null
  readonly property var keyColorCtrlField: pluginApi?.field("keyColorCtrl") ?? null
  readonly property var keyColorShiftField: pluginApi?.field("keyColorShift") ?? null
  readonly property var keyColorDefaultField: pluginApi?.field("keyColorDefault") ?? null
  readonly property var keyLabelColorField: pluginApi?.field("keyLabelColor") ?? null
  readonly property var descriptionTextColorField: pluginApi?.field("descriptionTextColor") ?? null
  readonly property var keyTextSuperField: pluginApi?.field("keyTextSuper") ?? null
  readonly property var keyTextCtrlField: pluginApi?.field("keyTextCtrl") ?? null
  readonly property var keyTextShiftField: pluginApi?.field("keyTextShift") ?? null
  readonly property var keyTextAltField: pluginApi?.field("keyTextAlt") ?? null
  readonly property var keyTextXF86Field: pluginApi?.field("keyTextXF86") ?? null
  readonly property var keyTextPrintField: pluginApi?.field("keyTextPrint") ?? null
  readonly property var keyTextNumericField: pluginApi?.field("keyTextNumeric") ?? null
  readonly property var keyTextMouseField: pluginApi?.field("keyTextMouse") ?? null
  readonly property var keyTextDefaultField: pluginApi?.field("keyTextDefault") ?? null
  readonly property var keyColorMod2Field: pluginApi?.field("keyColorMod2") ?? null
  readonly property var keyColorMod3Field: pluginApi?.field("keyColorMod3") ?? null
  readonly property var keyColorMod5Field: pluginApi?.field("keyColorMod5") ?? null
  readonly property var keyTextMod2Field: pluginApi?.field("keyTextMod2") ?? null
  readonly property var keyTextMod3Field: pluginApi?.field("keyTextMod3") ?? null
  readonly property var keyTextMod5Field: pluginApi?.field("keyTextMod5") ?? null
  readonly property var keyLabelMod2Field: pluginApi?.field("keyLabelMod2") ?? null
  readonly property var keyLabelMod3Field: pluginApi?.field("keyLabelMod3") ?? null
  readonly property var keyLabelMod5Field: pluginApi?.field("keyLabelMod5") ?? null
  readonly property var bindOverridesField: pluginApi?.field("bindOverrides") ?? null
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // The selected editor owns preview and persistence independently. Baselines
  // read acknowledged input, so preview never makes a local edit look clean.
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  readonly property var editBindOverrides: root.bindOverridesField?.value || ({})

  function restoreHidden(clearDescriptions) {
    var next = JSON.parse(JSON.stringify(editBindOverrides));
    for (var key in next) {
      // Absence inherits the shared flag in placement settings. An explicit
      // false choice restores the bind for either selected owner.
      if (next[key].hidden === true)
        next[key].hidden = false;
      if (clearDescriptions && next[key].desc)
        next[key].desc = "";
    }
    root.bindOverridesField.set(next);
  }

  function _applyPreview(key, value) {
    if (!pluginApi)
      return;
    var patch = {};
    patch[key] = value;
    return pluginApi.previewSettings(patch);
  }

  // Edit-copy properties for non-preview settings (window, layout, parsing, paths)
  readonly property int editWindowWidth: root.windowWidthField?.value ?? 1400
  readonly property int editWindowHeight: {
    var height = root.windowHeightField?.value ?? 850;
    return height > 0 ? height : 850;
  }
  readonly property bool editAutoHeight: root.autoHeightField?.value ?? true
  readonly property int editColumnCount: root.columnCountField?.value ?? 3
  readonly property string editModKeyVariable: root.modKeyVariableField?.value || "$mod"
  readonly property string editHyprlandConfigPath: root.hyprlandConfigPathField?.value || "~/.config/hypr/hyprland.conf"
  readonly property string editHyprlandLuaConfigPath: root.hyprlandLuaConfigPathField?.value || "~/.config/hypr/hyprland.lua"
  readonly property string editHyprlandParserMode: root.hyprlandParserModeField?.value || "auto"
  readonly property string editNiriConfigPath: root.niriConfigPathField?.value || "~/.config/niri/config.kdl"
  readonly property string editMangoConfigPath: root.mangoConfigPathField?.value || "~/.config/mango/config.conf"
  readonly property bool editMergeSequentialBinds: root.mergeSequentialBindsField?.value ?? true
  readonly property bool editShowUndescribedBinds: root.showUndescribedBindsField?.value ?? false
  readonly property bool editSplitLargeWorkspaceCategory: root.splitLargeWorkspaceCategoryField?.value ?? true
  readonly property int editWorkspaceSplitThreshold: root.workspaceSplitThresholdField?.value ?? 12

  // Live-preview properties for colors (mirror current pluginSettings; written via _applyPreview).
  // All background color fields are stored as string (hex) for empty-string support.
  readonly property string valueKeyColorSuper: root.keyColorSuperField?.value ?? ""
  readonly property string valueKeyColorCtrl: root.keyColorCtrlField?.value ?? ""
  readonly property string valueKeyColorShift: root.keyColorShiftField?.value ?? ""
  readonly property string valueKeyColorAlt: root.keyColorAltField?.value ?? "#FF6B6B"
  readonly property string valueKeyColorXF86: root.keyColorXF86Field?.value ?? "#4ECDC4"
  readonly property string valueKeyColorPrint: root.keyColorPrintField?.value ?? "#95E1D3"
  readonly property string valueKeyColorNumeric: root.keyColorNumericField?.value ?? "#A8DADC"
  readonly property string valueKeyColorMouse: root.keyColorMouseField?.value ?? "#F38181"
  readonly property string valueKeyColorDefault: root.keyColorDefaultField?.value ?? "#6C757D"
  // Per-category text color overrides — empty string = fall back to keyLabelColor global
  readonly property string valueKeyTextSuper: root.keyTextSuperField?.value ?? ""
  readonly property string valueKeyTextCtrl: root.keyTextCtrlField?.value ?? ""
  readonly property string valueKeyTextShift: root.keyTextShiftField?.value ?? ""
  readonly property string valueKeyTextAlt: root.keyTextAltField?.value ?? ""
  readonly property string valueKeyTextXF86: root.keyTextXF86Field?.value ?? ""
  readonly property string valueKeyTextPrint: root.keyTextPrintField?.value ?? ""
  readonly property string valueKeyTextNumeric: root.keyTextNumericField?.value ?? ""
  readonly property string valueKeyTextMouse: root.keyTextMouseField?.value ?? ""
  readonly property string valueKeyTextDefault: root.keyTextDefaultField?.value ?? ""
  readonly property string valueKeyLabelColor: root.keyLabelColorField?.value ?? "#FFFFFF"
  // Generic X11 mods (Mod2/Mod3/Mod5): background colour, text colour, and a
  // display-label override (rename e.g. Mod3 -> "Hyper" for caps:hyper).
  readonly property string valueKeyColorMod2: root.keyColorMod2Field?.value ?? ""
  readonly property string valueKeyColorMod3: root.keyColorMod3Field?.value ?? ""
  readonly property string valueKeyColorMod5: root.keyColorMod5Field?.value ?? ""
  readonly property string valueKeyTextMod2: root.keyTextMod2Field?.value ?? ""
  readonly property string valueKeyTextMod3: root.keyTextMod3Field?.value ?? ""
  readonly property string valueKeyTextMod5: root.keyTextMod5Field?.value ?? ""
  readonly property string valueKeyLabelMod2: root.keyLabelMod2Field?.value ?? ""
  readonly property string valueKeyLabelMod3: root.keyLabelMod3Field?.value ?? ""
  readonly property string valueKeyLabelMod5: root.keyLabelMod5Field?.value ?? ""
  readonly property string valueDescriptionTextColor: root.descriptionTextColorField?.value ?? ""

  // Clipboard polling for quick-paste feature.
  // Reads wl-paste periodically while Settings is visible; exposes a validated hex if found.
  property string clipboardHex: ""

  Timer {
    id: clipboardTimer
    interval: 1500
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!clipboardProcess.running)
                   clipboardProcess.running = true
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
    if (clipboardProcess.running)
      clipboardProcess.running = false;
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

            NPluginSettingsField {
              field: root.windowWidthField
              NTextInput {
                id: widthInput
                Layout.preferredWidth: 100 * Style.uiScaleRatio
                Layout.preferredHeight: Style.baseWidgetSize
                text: root.editWindowWidth.toString()
                onEditCommitted: {
                  var val = parseInt(text);
                  if (!isNaN(val) && val >= 400 && val <= 3000) {
                    root.windowWidthField.set(val);
                  }
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

            NPluginSettingsField {
              field: root.autoHeightField
              NToggle {
                id: autoHeightToggle
                label: pluginApi?.tr("settings.auto-height")
                checked: root.editAutoHeight
                onToggled: function (checked) {
                  root.autoHeightField.set(checked);
                }
              }
            }

            NPluginSettingsField {
              field: root.windowHeightField
              NTextInput {
                id: heightInput
                Layout.preferredWidth: 100 * Style.uiScaleRatio
                Layout.preferredHeight: Style.baseWidgetSize
                text: root.editWindowHeight.toString()
                enabled: !autoHeightToggle.checked
                opacity: enabled ? 1.0 : 0.5
                onEditCommitted: {
                  var val = parseInt(text);
                  if (!isNaN(val) && val >= 300 && val <= 2000) {
                    root.windowHeightField.set(val);
                  }
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

            NPluginSettingsField {
              field: root.columnCountField
              NComboBox {
                id: columnCombo
                Layout.preferredWidth: 150 * Style.uiScaleRatio
                Layout.preferredHeight: Style.baseWidgetSize
                model: ListModel {
                  ListElement {
                    name: "1"
                    key: "1"
                  }
                  ListElement {
                    name: "2"
                    key: "2"
                  }
                  ListElement {
                    name: "3"
                    key: "3"
                  }
                  ListElement {
                    name: "4"
                    key: "4"
                  }
                }
                currentKey: root.editColumnCount.toString()
                onSelected: key => {
                  root.columnCountField.set(parseInt(key));
                }
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

          NPluginSettingsField {
            field: root.mergeSequentialBindsField
            NToggle {
              Layout.fillWidth: true
              label: pluginApi?.tr("settings.merge-sequential")
              description: pluginApi?.tr("settings.merge-sequential-hint")
              checked: root.editMergeSequentialBinds
              onToggled: function (checked) {
                root.mergeSequentialBindsField.set(checked);
              }
            }
          }

          NPluginSettingsField {
            field: root.showUndescribedBindsField
            NToggle {
              Layout.fillWidth: true
              label: pluginApi?.tr("settings.show-undescribed")
              description: pluginApi?.tr("settings.show-undescribed-hint")
              checked: root.editShowUndescribedBinds
              onToggled: function (checked) {
                root.showUndescribedBindsField.set(checked);
              }
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
                if (kind === "hidden" && o[k] && o[k].hidden === true)
                  n++;
                else if (kind === "desc" && o[k] && o[k].desc)
                  n++;
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

            NPluginSettingsField {
              field: root.bindOverridesField
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
          }

          NPluginSettingsField {
            field: root.splitLargeWorkspaceCategoryField
            NToggle {
              Layout.fillWidth: true
              label: pluginApi?.tr("settings.split-workspaces")
              description: pluginApi?.tr("settings.split-workspaces-hint")
              checked: root.editSplitLargeWorkspaceCategory
              onToggled: function (checked) {
                root.splitLargeWorkspaceCategoryField.set(checked);
              }
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

            NPluginSettingsField {
              field: root.workspaceSplitThresholdField
              NSpinBox {
                id: workspaceThreshold
                objectName: "settings-range-editWorkspaceSplitThreshold"
                Layout.preferredWidth: 140 * Style.uiScaleRatio
                value: root.editWorkspaceSplitThreshold
                from: 4
                to: 50
                stepSize: 1
                onValueModified: value => {
                  root.workspaceSplitThresholdField.set(value);
                }
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

            NPluginSettingsField {
              field: root.modKeyVariableField
              NTextInput {
                id: modVarInput
                Layout.fillWidth: true
                Layout.preferredHeight: Style.baseWidgetSize
                text: root.editModKeyVariable
                placeholderText: "$mod"
                onEditCommitted: {
                  if (text.length > 0)
                    root.modKeyVariableField.set(text);
                }
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

            NPluginSettingsField {
              field: root.hyprlandConfigPathField
              NTextInput {
                id: hyprlandPathInput
                Layout.fillWidth: true
                Layout.preferredHeight: Style.baseWidgetSize
                text: root.editHyprlandConfigPath
                placeholderText: "~/.config/hypr/hyprland.conf"
                onEditCommitted: {
                  if (text.length > 0)
                    root.hyprlandConfigPathField.set(text);
                }
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

            NPluginSettingsField {
              field: root.hyprlandLuaConfigPathField
              NTextInput {
                id: hyprlandLuaPathInput
                Layout.fillWidth: true
                Layout.preferredHeight: Style.baseWidgetSize
                text: root.editHyprlandLuaConfigPath
                placeholderText: "~/.config/hypr/hyprland.lua"
                onEditCommitted: {
                  if (text.length > 0)
                    root.hyprlandLuaConfigPathField.set(text);
                }
              }
            }

            RowLayout {
              spacing: Style.marginM
              NText {
                text: pluginApi?.tr("settings.hyprland-parser-mode")
                color: AtmoColor.mOnSurface
                pointSize: Style.fontSizeM
              }
              NPluginSettingsField {
                field: root.hyprlandParserModeField
                NComboBox {
                  id: parserModeCombo
                  Layout.preferredWidth: 180 * Style.uiScaleRatio
                  Layout.preferredHeight: Style.baseWidgetSize
                  model: ListModel {
                    ListElement {
                      name: "Auto"
                      key: "auto"
                    }
                    ListElement {
                      name: "Lua (hyprctl)"
                      key: "lua"
                    }
                    ListElement {
                      name: "Legacy .conf"
                      key: "conf"
                    }
                  }
                  currentKey: root.editHyprlandParserMode
                  onSelected: key => {
                    root.hyprlandParserModeField.set(key);
                  }
                }
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

            NPluginSettingsField {
              field: root.niriConfigPathField
              NTextInput {
                id: niriPathInput
                Layout.fillWidth: true
                Layout.preferredHeight: Style.baseWidgetSize
                text: root.editNiriConfigPath
                placeholderText: "~/.config/niri/config.kdl"
                onEditCommitted: {
                  if (text.length > 0)
                    root.niriConfigPathField.set(text);
                }
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

            NPluginSettingsField {
              field: root.mangoConfigPathField
              NTextInput {
                id: mangoPathInput
                Layout.fillWidth: true
                Layout.preferredHeight: Style.baseWidgetSize
                text: root.editMangoConfigPath
                placeholderText: "~/.config/mango/config.conf"
                onEditCommitted: {
                  if (text.length > 0)
                    root.mangoConfigPathField.set(text);
                }
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
                pluginApi?.mainInstance?.settingsConsumerFor(pluginApi.runtimeContext)?.refresh();
                ToastService.showNotice(pluginApi?.tr("settings.refresh-message"));
              }
            }

            NButton {
              text: pluginApi?.tr("settings.reset-defaults")
              icon: "rotate"
              onClicked: {
                // Remove these overrides; instance scope inherits plugin values and
                // plugin scope reveals the native lower level, not page literals.
                pluginApi.resetFields(["windowWidth", "windowHeight", "autoHeight", "columnCount", "modKeyVariable", "hyprlandConfigPath", "hyprlandLuaConfigPath", "hyprlandParserMode", "niriConfigPath", "mangoConfigPath", "mergeSequentialBinds", "showUndescribedBinds", "splitLargeWorkspaceCategory", "workspaceSplitThreshold"]);
                widthInput.text = Qt.binding(function () {
                  return root.editWindowWidth.toString();
                });
                heightInput.text = Qt.binding(function () {
                  return root.editWindowHeight.toString();
                });
                modVarInput.text = Qt.binding(function () {
                  return root.editModKeyVariable;
                });
                hyprlandPathInput.text = Qt.binding(function () {
                  return root.editHyprlandConfigPath;
                });
                hyprlandLuaPathInput.text = Qt.binding(function () {
                  return root.editHyprlandLuaConfigPath;
                });
                niriPathInput.text = Qt.binding(function () {
                  return root.editNiriConfigPath;
                });
                mangoPathInput.text = Qt.binding(function () {
                  return root.editMangoConfigPath;
                });

                // Apply refreshes this selected parser after these choices save.
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

            Local.PreviewBadge {
              label: "Super"
              bg: root.valueKeyColorSuper || AtmoColor.mPrimary
              fg: root.valueKeyTextSuper || root.valueKeyLabelColor
            }
            Local.PreviewBadge {
              label: "Ctrl"
              bg: root.valueKeyColorCtrl || AtmoColor.mSecondary
              fg: root.valueKeyTextCtrl || root.valueKeyLabelColor
            }
            Local.PreviewBadge {
              label: "Shift"
              bg: root.valueKeyColorShift || AtmoColor.mTertiary
              fg: root.valueKeyTextShift || root.valueKeyLabelColor
            }
            Local.PreviewBadge {
              label: "Alt"
              bg: root.valueKeyColorAlt
              fg: root.valueKeyTextAlt || root.valueKeyLabelColor
            }
            Local.PreviewBadge {
              label: "XF86Audio"
              bg: root.valueKeyColorXF86
              fg: root.valueKeyTextXF86 || root.valueKeyLabelColor
            }
            Local.PreviewBadge {
              label: "Print"
              bg: root.valueKeyColorPrint
              fg: root.valueKeyTextPrint || root.valueKeyLabelColor
            }
            Local.PreviewBadge {
              label: "1-9"
              bg: root.valueKeyColorNumeric
              fg: root.valueKeyTextNumeric || root.valueKeyLabelColor
            }
            Local.PreviewBadge {
              label: "mouse:272"
              bg: root.valueKeyColorMouse
              fg: root.valueKeyTextMouse || root.valueKeyLabelColor
            }
            Local.PreviewBadge {
              label: "Q"
              bg: root.valueKeyColorDefault
              fg: root.valueKeyTextDefault || root.valueKeyLabelColor
            }
            Local.PreviewBadge {
              label: root.valueKeyLabelMod3 || "Mod3"
              bg: root.valueKeyColorMod3 || root.valueKeyColorDefault
              fg: root.valueKeyTextMod3 || root.valueKeyLabelColor
            }
            Local.PreviewBadge {
              label: root.valueKeyLabelMod2 || "Mod2"
              bg: root.valueKeyColorMod2 || root.valueKeyColorDefault
              fg: root.valueKeyTextMod2 || root.valueKeyLabelColor
            }
            Local.PreviewBadge {
              label: root.valueKeyLabelMod5 || "Mod5"
              bg: root.valueKeyColorMod5 || root.valueKeyColorDefault
              fg: root.valueKeyTextMod5 || root.valueKeyLabelColor
            }
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
          NPluginSettingsField {
            field: root.keyColorSuperField
            NPluginSettingsField {
              field: root.keyTextSuperField
              Local.ColorPairRow {
                pluginApi: root.pluginApi
                labelText: pluginApi?.tr("settings.color-super")
                letter: "S"
                bgValue: root.valueKeyColorSuper
                textValue: root.valueKeyTextSuper
                bgFallback: AtmoColor.mPrimary
                textFallback: root.valueKeyLabelColor
                clipboardHex: root.clipboardHex
                onBgPicked: c => {
                  root.keyColorSuperField.set(c.toString());
                  root._applyPreview("keyColorSuper", c.toString());
                }
                onTextPicked: c => {
                  root.keyTextSuperField.set(c.toString());
                  root._applyPreview("keyTextSuper", c.toString());
                }
                onBgPasted: hex => {
                  root.keyColorSuperField.set(hex);
                  root._applyPreview("keyColorSuper", hex);
                }
                onTextPasted: hex => {
                  root.keyTextSuperField.set(hex);
                  root._applyPreview("keyTextSuper", hex);
                }
                onResetRequested: pluginApi.resetFields(["keyColorSuper", "keyTextSuper"])
              }
            }
          }

          // Ctrl
          NPluginSettingsField {
            field: root.keyColorCtrlField
            NPluginSettingsField {
              field: root.keyTextCtrlField
              Local.ColorPairRow {
                pluginApi: root.pluginApi
                labelText: pluginApi?.tr("settings.color-ctrl")
                letter: "C"
                bgValue: root.valueKeyColorCtrl
                textValue: root.valueKeyTextCtrl
                bgFallback: AtmoColor.mSecondary
                textFallback: root.valueKeyLabelColor
                clipboardHex: root.clipboardHex
                onBgPicked: c => {
                  root.keyColorCtrlField.set(c.toString());
                  root._applyPreview("keyColorCtrl", c.toString());
                }
                onTextPicked: c => {
                  root.keyTextCtrlField.set(c.toString());
                  root._applyPreview("keyTextCtrl", c.toString());
                }
                onBgPasted: hex => {
                  root.keyColorCtrlField.set(hex);
                  root._applyPreview("keyColorCtrl", hex);
                }
                onTextPasted: hex => {
                  root.keyTextCtrlField.set(hex);
                  root._applyPreview("keyTextCtrl", hex);
                }
                onResetRequested: pluginApi.resetFields(["keyColorCtrl", "keyTextCtrl"])
              }
            }
          }

          // Shift
          NPluginSettingsField {
            field: root.keyColorShiftField
            NPluginSettingsField {
              field: root.keyTextShiftField
              Local.ColorPairRow {
                pluginApi: root.pluginApi
                labelText: pluginApi?.tr("settings.color-shift")
                letter: "⇧"
                bgValue: root.valueKeyColorShift
                textValue: root.valueKeyTextShift
                bgFallback: AtmoColor.mTertiary
                textFallback: root.valueKeyLabelColor
                clipboardHex: root.clipboardHex
                onBgPicked: c => {
                  root.keyColorShiftField.set(c.toString());
                  root._applyPreview("keyColorShift", c.toString());
                }
                onTextPicked: c => {
                  root.keyTextShiftField.set(c.toString());
                  root._applyPreview("keyTextShift", c.toString());
                }
                onBgPasted: hex => {
                  root.keyColorShiftField.set(hex);
                  root._applyPreview("keyColorShift", hex);
                }
                onTextPasted: hex => {
                  root.keyTextShiftField.set(hex);
                  root._applyPreview("keyTextShift", hex);
                }
                onResetRequested: pluginApi.resetFields(["keyColorShift", "keyTextShift"])
              }
            }
          }

          // Alt
          NPluginSettingsField {
            field: root.keyColorAltField
            NPluginSettingsField {
              field: root.keyTextAltField
              Local.ColorPairRow {
                pluginApi: root.pluginApi
                labelText: pluginApi?.tr("settings.color-alt")
                letter: "A"
                bgValue: root.valueKeyColorAlt
                textValue: root.valueKeyTextAlt
                bgFallback: defaults.keyColorAlt || "#FF6B6B"
                textFallback: root.valueKeyLabelColor
                clipboardHex: root.clipboardHex
                onBgPicked: c => {
                  root.keyColorAltField.set(c.toString());
                  root._applyPreview("keyColorAlt", c.toString());
                }
                onTextPicked: c => {
                  root.keyTextAltField.set(c.toString());
                  root._applyPreview("keyTextAlt", c.toString());
                }
                onBgPasted: hex => {
                  root.keyColorAltField.set(hex);
                  root._applyPreview("keyColorAlt", hex);
                }
                onTextPasted: hex => {
                  root.keyTextAltField.set(hex);
                  root._applyPreview("keyTextAlt", hex);
                }
                onResetRequested: pluginApi.resetFields(["keyColorAlt", "keyTextAlt"])
              }
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

          NPluginSettingsField {
            field: root.keyColorMod3Field
            NPluginSettingsField {
              field: root.keyTextMod3Field
              NPluginSettingsField {
                field: root.keyLabelMod3Field
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
                  onBgPicked: c => {
                    root.keyColorMod3Field.set(c.toString());
                    root._applyPreview("keyColorMod3", c.toString());
                  }
                  onTextPicked: c => {
                    root.keyTextMod3Field.set(c.toString());
                    root._applyPreview("keyTextMod3", c.toString());
                  }
                  onBgPasted: hex => {
                    root.keyColorMod3Field.set(hex);
                    root._applyPreview("keyColorMod3", hex);
                  }
                  onTextPasted: hex => {
                    root.keyTextMod3Field.set(hex);
                    root._applyPreview("keyTextMod3", hex);
                  }
                  onLabelEdited: t => {
                    root.keyLabelMod3Field.set(t);
                    root._applyPreview("keyLabelMod3", t);
                  }
                  onResetRequested: pluginApi.resetFields(["keyColorMod3", "keyTextMod3", "keyLabelMod3"])
                }
              }
            }
          }

          NPluginSettingsField {
            field: root.keyColorMod2Field
            NPluginSettingsField {
              field: root.keyTextMod2Field
              NPluginSettingsField {
                field: root.keyLabelMod2Field
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
                  onBgPicked: c => {
                    root.keyColorMod2Field.set(c.toString());
                    root._applyPreview("keyColorMod2", c.toString());
                  }
                  onTextPicked: c => {
                    root.keyTextMod2Field.set(c.toString());
                    root._applyPreview("keyTextMod2", c.toString());
                  }
                  onBgPasted: hex => {
                    root.keyColorMod2Field.set(hex);
                    root._applyPreview("keyColorMod2", hex);
                  }
                  onTextPasted: hex => {
                    root.keyTextMod2Field.set(hex);
                    root._applyPreview("keyTextMod2", hex);
                  }
                  onLabelEdited: t => {
                    root.keyLabelMod2Field.set(t);
                    root._applyPreview("keyLabelMod2", t);
                  }
                  onResetRequested: pluginApi.resetFields(["keyColorMod2", "keyTextMod2", "keyLabelMod2"])
                }
              }
            }
          }

          NPluginSettingsField {
            field: root.keyColorMod5Field
            NPluginSettingsField {
              field: root.keyTextMod5Field
              NPluginSettingsField {
                field: root.keyLabelMod5Field
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
                  onBgPicked: c => {
                    root.keyColorMod5Field.set(c.toString());
                    root._applyPreview("keyColorMod5", c.toString());
                  }
                  onTextPicked: c => {
                    root.keyTextMod5Field.set(c.toString());
                    root._applyPreview("keyTextMod5", c.toString());
                  }
                  onBgPasted: hex => {
                    root.keyColorMod5Field.set(hex);
                    root._applyPreview("keyColorMod5", hex);
                  }
                  onTextPasted: hex => {
                    root.keyTextMod5Field.set(hex);
                    root._applyPreview("keyTextMod5", hex);
                  }
                  onLabelEdited: t => {
                    root.keyLabelMod5Field.set(t);
                    root._applyPreview("keyLabelMod5", t);
                  }
                  onResetRequested: pluginApi.resetFields(["keyColorMod5", "keyTextMod5", "keyLabelMod5"])
                }
              }
            }
          }

          // XF86
          NPluginSettingsField {
            field: root.keyColorXF86Field
            NPluginSettingsField {
              field: root.keyTextXF86Field
              Local.ColorPairRow {
                pluginApi: root.pluginApi
                labelText: pluginApi?.tr("settings.color-xf86")
                letter: "♪"
                bgValue: root.valueKeyColorXF86
                textValue: root.valueKeyTextXF86
                bgFallback: defaults.keyColorXF86 || "#4ECDC4"
                textFallback: root.valueKeyLabelColor
                clipboardHex: root.clipboardHex
                onBgPicked: c => {
                  root.keyColorXF86Field.set(c.toString());
                  root._applyPreview("keyColorXF86", c.toString());
                }
                onTextPicked: c => {
                  root.keyTextXF86Field.set(c.toString());
                  root._applyPreview("keyTextXF86", c.toString());
                }
                onBgPasted: hex => {
                  root.keyColorXF86Field.set(hex);
                  root._applyPreview("keyColorXF86", hex);
                }
                onTextPasted: hex => {
                  root.keyTextXF86Field.set(hex);
                  root._applyPreview("keyTextXF86", hex);
                }
                onResetRequested: pluginApi.resetFields(["keyColorXF86", "keyTextXF86"])
              }
            }
          }

          // Print
          NPluginSettingsField {
            field: root.keyColorPrintField
            NPluginSettingsField {
              field: root.keyTextPrintField
              Local.ColorPairRow {
                pluginApi: root.pluginApi
                labelText: pluginApi?.tr("settings.color-print")
                letter: "P"
                bgValue: root.valueKeyColorPrint
                textValue: root.valueKeyTextPrint
                bgFallback: defaults.keyColorPrint || "#95E1D3"
                textFallback: root.valueKeyLabelColor
                clipboardHex: root.clipboardHex
                onBgPicked: c => {
                  root.keyColorPrintField.set(c.toString());
                  root._applyPreview("keyColorPrint", c.toString());
                }
                onTextPicked: c => {
                  root.keyTextPrintField.set(c.toString());
                  root._applyPreview("keyTextPrint", c.toString());
                }
                onBgPasted: hex => {
                  root.keyColorPrintField.set(hex);
                  root._applyPreview("keyColorPrint", hex);
                }
                onTextPasted: hex => {
                  root.keyTextPrintField.set(hex);
                  root._applyPreview("keyTextPrint", hex);
                }
                onResetRequested: pluginApi.resetFields(["keyColorPrint", "keyTextPrint"])
              }
            }
          }

          // Numeric
          NPluginSettingsField {
            field: root.keyColorNumericField
            NPluginSettingsField {
              field: root.keyTextNumericField
              Local.ColorPairRow {
                pluginApi: root.pluginApi
                labelText: pluginApi?.tr("settings.color-numeric")
                letter: "1"
                bgValue: root.valueKeyColorNumeric
                textValue: root.valueKeyTextNumeric
                bgFallback: defaults.keyColorNumeric || "#A8DADC"
                textFallback: root.valueKeyLabelColor
                clipboardHex: root.clipboardHex
                onBgPicked: c => {
                  root.keyColorNumericField.set(c.toString());
                  root._applyPreview("keyColorNumeric", c.toString());
                }
                onTextPicked: c => {
                  root.keyTextNumericField.set(c.toString());
                  root._applyPreview("keyTextNumeric", c.toString());
                }
                onBgPasted: hex => {
                  root.keyColorNumericField.set(hex);
                  root._applyPreview("keyColorNumeric", hex);
                }
                onTextPasted: hex => {
                  root.keyTextNumericField.set(hex);
                  root._applyPreview("keyTextNumeric", hex);
                }
                onResetRequested: pluginApi.resetFields(["keyColorNumeric", "keyTextNumeric"])
              }
            }
          }

          // Mouse
          NPluginSettingsField {
            field: root.keyColorMouseField
            NPluginSettingsField {
              field: root.keyTextMouseField
              Local.ColorPairRow {
                pluginApi: root.pluginApi
                labelText: pluginApi?.tr("settings.color-mouse")
                letter: "M"
                bgValue: root.valueKeyColorMouse
                textValue: root.valueKeyTextMouse
                bgFallback: defaults.keyColorMouse || "#F38181"
                textFallback: root.valueKeyLabelColor
                clipboardHex: root.clipboardHex
                onBgPicked: c => {
                  root.keyColorMouseField.set(c.toString());
                  root._applyPreview("keyColorMouse", c.toString());
                }
                onTextPicked: c => {
                  root.keyTextMouseField.set(c.toString());
                  root._applyPreview("keyTextMouse", c.toString());
                }
                onBgPasted: hex => {
                  root.keyColorMouseField.set(hex);
                  root._applyPreview("keyColorMouse", hex);
                }
                onTextPasted: hex => {
                  root.keyTextMouseField.set(hex);
                  root._applyPreview("keyTextMouse", hex);
                }
                onResetRequested: pluginApi.resetFields(["keyColorMouse", "keyTextMouse"])
              }
            }
          }

          // Default letter keys
          NPluginSettingsField {
            field: root.keyColorDefaultField
            NPluginSettingsField {
              field: root.keyTextDefaultField
              Local.ColorPairRow {
                pluginApi: root.pluginApi
                labelText: pluginApi?.tr("settings.color-default")
                letter: "Q"
                bgValue: root.valueKeyColorDefault
                textValue: root.valueKeyTextDefault
                bgFallback: defaults.keyColorDefault || "#6C757D"
                textFallback: root.valueKeyLabelColor
                clipboardHex: root.clipboardHex
                onBgPicked: c => {
                  root.keyColorDefaultField.set(c.toString());
                  root._applyPreview("keyColorDefault", c.toString());
                }
                onTextPicked: c => {
                  root.keyTextDefaultField.set(c.toString());
                  root._applyPreview("keyTextDefault", c.toString());
                }
                onBgPasted: hex => {
                  root.keyColorDefaultField.set(hex);
                  root._applyPreview("keyColorDefault", hex);
                }
                onTextPasted: hex => {
                  root.keyTextDefaultField.set(hex);
                  root._applyPreview("keyTextDefault", hex);
                }
                onResetRequested: pluginApi.resetFields(["keyColorDefault", "keyTextDefault"])
              }
            }
          }

          // Description text (text-only row — no background)
          // Empty value = theme-aware (Color.mOnSurface) at render time.
          NPluginSettingsField {
            field: root.descriptionTextColorField
            Local.ColorPairRow {
              pluginApi: root.pluginApi
              labelText: pluginApi?.tr("settings.color-description")
              letter: "T"
              showBg: false
              bgValue: ""
              textValue: root.valueDescriptionTextColor
              textFallback: AtmoColor.mOnSurface
              clipboardHex: root.clipboardHex
              onTextPicked: c => {
                root.descriptionTextColorField.set(c.toString());
                root._applyPreview("descriptionTextColor", c.toString());
              }
              onTextPasted: hex => {
                root.descriptionTextColorField.set(hex);
                root._applyPreview("descriptionTextColor", hex);
              }
              onResetRequested: pluginApi.resetFields(["descriptionTextColor"])
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
            // One multi-field Reset: every color leaf reveals its inherited value.
            onClicked: pluginApi.resetFields(["descriptionTextColor", "keyColorAlt", "keyColorCtrl", "keyColorDefault", "keyColorMod2", "keyColorMod3", "keyColorMod5", "keyColorMouse", "keyColorNumeric", "keyColorPrint", "keyColorShift", "keyColorSuper", "keyColorXF86", "keyLabelColor", "keyLabelMod2", "keyLabelMod3", "keyLabelMod5", "keyTextAlt",
                                              "keyTextCtrl", "keyTextDefault", "keyTextMod2", "keyTextMod3", "keyTextMod5", "keyTextMouse", "keyTextNumeric", "keyTextPrint", "keyTextShift", "keyTextSuper", "keyTextXF86"])
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
    if (!pluginApi)
      return;

    pluginApi.saveSettings();
  }

  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if ((result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current") {
        root.pluginApi.mainInstance?.settingsConsumerFor(root.pluginApi.runtimeContext)?.refresh();
        ToastService.showNotice(root.pluginApi.tr("settings.saved"));
      }
    }
  }
}
