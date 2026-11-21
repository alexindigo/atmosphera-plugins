import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property color sectionBackgroundColor: AtmoColor.mSurfaceVariant

  readonly property var barCycleIntervalSecField: pluginApi?.field("barCycleIntervalSec") ?? null
  readonly property var barDisplayModeField: pluginApi?.field("barDisplayMode") ?? null
  readonly property var barMetricField: pluginApi?.field("barMetric") ?? null
  readonly property var providersField: pluginApi?.field("providers") ?? null
  readonly property var refreshIntervalSecField: pluginApi?.field("refreshIntervalSec") ?? null
  // Effective values for presentation; only explicit control intents submit.
  readonly property var editSettings: pluginApi?.pluginSettings ?? ({})
  readonly property int editCycleInterval: barCycleIntervalSecField?.value ?? 5
  readonly property int editRefreshInterval: refreshIntervalSecField?.value ?? 30
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function setField(key, value) {
    return pluginApi.field(key).set(value);
  }

  // providers is one atomic map: a member control's intent is the whole map.
  function setProvider(provider, key, value) {
    var providers = Object.assign({}, providersField?.value);
    providers[provider] = Object.assign({}, providers[provider]);
    providers[provider][key] = value;
    return setField("providers", providers);
  }

  // Completion observer only; native publication belongs to the session.
  function saveSettings() {
    pluginApi.saveSettings();
  }

  spacing: Style.marginL

  NText {
    visible: root.pluginApi?.scopeKind === "instance"
    Layout.fillWidth: true
    text: root.pluginApi?.tr("settings.shared-effect") ?? ""
    wrapMode: Text.WordWrap
  }

  NText {
    text: "Model Usage Settings"
    pointSize: Style.fontSizeXL
    font.weight: Style.fontWeightBold
    color: AtmoColor.mOnSurface
    Layout.fillWidth: true
  }

  Rectangle {
    Layout.fillWidth: true
    color: root.sectionBackgroundColor
    radius: Style.radiusS
    implicitHeight: generalColumn.implicitHeight + Style.marginXL

    ColumnLayout {
      id: generalColumn
      anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        margins: Style.marginL
      }
      spacing: Style.marginM

      NText {
        text: "General"
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightSemiBold
        color: AtmoColor.mPrimary
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NText {
          text: "Bar display mode"
          pointSize: Style.fontSizeM
          font.weight: Style.fontWeightSemiBold
          color: AtmoColor.mOnSurface
        }
        NText {
          text: "Show active provider or cycle between enabled providers"
          pointSize: Style.fontSizeXS
          color: AtmoColor.mOnSurfaceVariant
        }

        NPluginSettingsField {
          field: root.barDisplayModeField
          NComboBox {
            Layout.fillWidth: true
            model: [
              {
                key: "active",
                name: "Active provider"
              },
              {
                key: "cycle",
                name: "Cycle providers"
              }
            ]
            currentKey: editSettings?.barDisplayMode ?? "active"
            onSelected: key => {
              root.setField("barDisplayMode", key);
            }
          }
        }
      }

      ColumnLayout {
        visible: (editSettings?.barDisplayMode ?? "active") === "cycle"
        Layout.fillWidth: true
        spacing: Style.marginXS

        NText {
          text: "Cycle interval (seconds)"
          pointSize: Style.fontSizeM
          font.weight: Style.fontWeightSemiBold
          color: AtmoColor.mOnSurface
        }

        NPluginSettingsField {
          field: root.barCycleIntervalSecField
          NSpinBox {
            id: cycleInput
            objectName: "settings-range-editCycleInterval"
            from: 2
            to: 60
            value: root.editCycleInterval
            stepSize: 1
            onValueModified: value => root.barCycleIntervalSecField.set(value)
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NText {
          text: "Bar metric"
          pointSize: Style.fontSizeM
          font.weight: Style.fontWeightSemiBold
          color: AtmoColor.mOnSurface
        }
        NText {
          text: "What number to show in the bar capsule"
          pointSize: Style.fontSizeXS
          color: AtmoColor.mOnSurfaceVariant
        }

        NPluginSettingsField {
          field: root.barMetricField
          NComboBox {
            Layout.fillWidth: true
            model: [
              {
                key: "prompts",
                name: "Prompts"
              },
              {
                key: "tokens",
                name: "Tokens"
              },
              {
                key: "usage",
                name: "Usage %"
              }
            ]
            currentKey: editSettings?.barMetric ?? "prompts"
            onSelected: key => {
              root.setField("barMetric", key);
            }
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NText {
          text: "Refresh interval (seconds)"
          pointSize: Style.fontSizeM
          font.weight: Style.fontWeightSemiBold
          color: AtmoColor.mOnSurface
        }
        NText {
          text: "Fallback polling interval when file watch misses changes"
          pointSize: Style.fontSizeXS
          color: AtmoColor.mOnSurfaceVariant
        }

        NPluginSettingsField {
          field: root.refreshIntervalSecField
          NSpinBox {
            id: refreshInput
            objectName: "settings-range-editRefreshInterval"
            from: 5
            to: 300
            value: root.editRefreshInterval
            stepSize: 5
            onValueModified: value => root.refreshIntervalSecField.set(value)
          }
        }
      }
    }
  }

  NPluginSettingsField {
    field: root.providersField
    Rectangle {
      Layout.fillWidth: true
      color: root.sectionBackgroundColor
      radius: Style.radiusS
      implicitHeight: providersColumn.implicitHeight + Style.marginXL

      ColumnLayout {
        id: providersColumn
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          margins: Style.marginL
        }
        spacing: Style.marginM

        NText {
          text: "Providers"
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightSemiBold
          color: AtmoColor.mPrimary
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM
          NToggle {
            checked: editSettings?.providers?.claude?.enabled ?? true
            onToggled: value => {
              root.setProvider("claude", "enabled", value);
            }
          }
          NText {
            text: "Claude Code"
            pointSize: Style.fontSizeM
            color: AtmoColor.mOnSurface
            Layout.fillWidth: true
          }
          NText {
            text: "Local files"
            pointSize: Style.fontSizeXS
            color: AtmoColor.mOnSurfaceVariant
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM
          NToggle {
            checked: editSettings?.providers?.codex?.enabled ?? true
            onToggled: value => {
              root.setProvider("codex", "enabled", value);
            }
          }
          NText {
            text: "Codex"
            pointSize: Style.fontSizeM
            color: AtmoColor.mOnSurface
            Layout.fillWidth: true
          }
          NText {
            text: "Local files"
            pointSize: Style.fontSizeXS
            color: AtmoColor.mOnSurfaceVariant
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM
          NToggle {
            checked: editSettings?.providers?.copilot?.enabled ?? false
            onToggled: value => {
              root.setProvider("copilot", "enabled", value);
            }
          }
          NText {
            text: "Copilot"
            pointSize: Style.fontSizeM
            color: AtmoColor.mOnSurface
            Layout.fillWidth: true
          }
          NText {
            text: "GitHub auth"
            pointSize: Style.fontSizeXS
            color: AtmoColor.mOnSurfaceVariant
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM
          NToggle {
            checked: editSettings?.providers?.gemini?.enabled ?? false
            onToggled: value => {
              root.setProvider("gemini", "enabled", value);
            }
          }
          NText {
            text: pluginApi?.tr("settings.providers.gemini.name")
            pointSize: Style.fontSizeM
            color: AtmoColor.mOnSurface
            Layout.fillWidth: true
          }
          NText {
            text: pluginApi?.tr("settings.providers.gemini.source")
            pointSize: Style.fontSizeXS
            color: AtmoColor.mOnSurfaceVariant
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM
            NToggle {
              checked: editSettings?.providers?.openrouter?.enabled ?? false
              onToggled: value => {
                root.setProvider("openrouter", "enabled", value);
              }
            }
            NText {
              text: "OpenRouter"
              pointSize: Style.fontSizeM
              color: AtmoColor.mOnSurface
              Layout.fillWidth: true
            }
            NText {
              text: "API key"
              pointSize: Style.fontSizeXS
              color: AtmoColor.mOnSurfaceVariant
            }
          }

          NTextInput {
            visible: editSettings?.providers?.openrouter?.enabled ?? false
            Layout.fillWidth: true
            Layout.leftMargin: Style.marginXL
            placeholderText: "OPENROUTER_API_KEY env var or enter key here"
            text: editSettings?.providers?.openrouter?.apiKey ?? ""

            onEditCommitted: root.setProvider("openrouter", "apiKey", text)
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXS

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM
            NToggle {
              checked: editSettings?.providers?.zen?.enabled ?? false
              onToggled: value => {
                root.setProvider("zen", "enabled", value);
              }
            }
            NText {
              text: "Zen (opencode.ai)"
              pointSize: Style.fontSizeM
              color: AtmoColor.mOnSurface
              Layout.fillWidth: true
            }
            NText {
              text: "API key"
              pointSize: Style.fontSizeXS
              color: AtmoColor.mOnSurfaceVariant
            }
          }

          NTextInput {
            visible: editSettings?.providers?.zen?.enabled ?? false
            Layout.fillWidth: true
            Layout.leftMargin: Style.marginXL
            placeholderText: "OPENCODE_ZEN_API_KEY / OPENCODE_API_KEY env var or enter key here"
            text: editSettings?.providers?.zen?.apiKey ?? ""

            onEditCommitted: root.setProvider("zen", "apiKey", text)
          }
        }
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    Item {
      Layout.fillWidth: true
    }

    NButton {
      text: "Reset"
      // One multi-field Reset of every declared preference on this page.
      onClicked: pluginApi.resetFields(["barCycleIntervalSec", "barDisplayMode", "barMetric", "providers", "refreshIntervalSec"])
    }
  }
}
