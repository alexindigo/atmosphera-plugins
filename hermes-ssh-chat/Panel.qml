import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  readonly property var mainInstance: pluginApi?.mainInstance ?? null
  readonly property var settingsConsumer: pluginApi?.settingsContext?.current() ? mainInstance?.settingsConsumerFor(pluginApi.settingsContext) : null
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true
  property real contentPreferredWidth: Math.round(Math.max(720, Math.min(1800, Number(cfg.panelWidth ?? defaults.panelWidth ?? 1200))) * Style.uiScaleRatio)
  property real contentPreferredHeight: Math.round(Math.max(560, Number(cfg.panelHeight ?? defaults.panelHeight ?? 760)) * Style.uiScaleRatio)

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property string valueHost: cfg.host ?? defaults.host ?? ""
  property int valuePort: cfg.port ?? defaults.port ?? 22
  property string valueUser: cfg.user ?? defaults.user ?? ""
  property string valuePassword: ""
  property int terminalCols: cfg.terminalCols ?? defaults.terminalCols ?? 180
  property int terminalRows: cfg.terminalRows ?? defaults.terminalRows ?? 32
  property int terminalFontSize: cfg.terminalFontSize ?? defaults.terminalFontSize ?? 11

  function doConnect() {
    root.settingsConsumer?.connect(
      root.pluginApi,
      root.valueHost,
      root.valuePort,
      root.valueUser,
      root.valuePassword,
      root.terminalRows,
      root.terminalCols
    );
    root.valuePassword = "";
    passwordInput.text = "";
  }

  onSettingsConsumerChanged: settingsConsumer?.activate(pluginApi)
  Component.onCompleted: settingsConsumer?.activate(pluginApi)

  Connections {
    target: pluginApi ? pluginApi.pluginSettings : null
    function refresh() {
      root.cfg = pluginApi?.pluginSettings || ({});
      root.valueHost = cfg.host ?? defaults.host ?? "";
      root.valuePort = cfg.port ?? defaults.port ?? 22;
      root.valueUser = cfg.user ?? defaults.user ?? "";
      root.terminalCols = cfg.terminalCols ?? defaults.terminalCols ?? 180;
      root.terminalRows = cfg.terminalRows ?? defaults.terminalRows ?? 32;
      root.terminalFontSize = cfg.terminalFontSize ?? defaults.terminalFontSize ?? 11;
    }
    function onHostChanged() {refresh();}
    function onPortChanged() {refresh();}
    function onUserChanged() {refresh();}
    function onTerminalColsChanged() {refresh();}
    function onTerminalRowsChanged() {refresh();}
    function onTerminalFontSizeChanged() {refresh();}
  }

  ColumnLayout {
    id: panelContainer
    anchors.fill: parent
    anchors.margins: Style.marginL
    spacing: Style.marginM

    NBox {
      Layout.fillWidth: true
      implicitHeight: headerRow.implicitHeight + Style.margin2M

      RowLayout {
        id: headerRow
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginM

        Image {
          property real iconSize: Math.round(Style.baseWidgetSize * 0.8)

          Layout.preferredWidth: iconSize
          Layout.preferredHeight: iconSize
          source: Qt.resolvedUrl("assets/hermesagent.svg")
          sourceSize.width: iconSize
          sourceSize.height: iconSize
          fillMode: Image.PreserveAspectFit
          smooth: true
          mipmap: true
          opacity: root.settingsConsumer?.sessionActive ? 1.0 : 0.72
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXXS

          NText {
            Layout.fillWidth: true
            text: pluginApi?.tr("panel.title")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: AtmoColor.mOnSurface
          }

          NText {
            Layout.fillWidth: true
            text: root.settingsConsumer?.statusText ?? ""
            pointSize: Style.fontSizeS
            color: root.settingsConsumer?.lastError ? AtmoColor.mError : AtmoColor.mOnSurfaceVariant
            elide: Text.ElideRight
          }
        }

        AtmoIconButton {
          visible: root.settingsConsumer?.sessionActive ?? false
          baseSize: Style.baseWidgetSize * 0.8
          icon: "power"
          tooltipText: pluginApi?.tr("panel.disconnect")
          colorFg: AtmoColor.mError
          onClicked: root.settingsConsumer?.disconnect()
        }

        AtmoIconButton {
          baseSize: Style.baseWidgetSize * 0.8
          icon: "settings"
          tooltipText: pluginApi?.tr("panel.settings")
          onClicked: {
            var screen = pluginApi?.panelOpenScreen;
            if (screen && pluginApi?.manifest)
              BarService.openPluginSettings(screen, pluginApi.manifest);
          }
        }

        AtmoIconButton {
          baseSize: Style.baseWidgetSize * 0.8
          icon: "close"
          tooltipText: pluginApi?.tr("panel.close")
          onClicked: pluginApi?.closePanel(pluginApi?.panelOpenScreen)
        }
      }
    }

    NBox {
      Layout.fillWidth: true
      visible: !root.settingsConsumer?.sessionActive
      implicitHeight: connectColumn.implicitHeight + Style.margin2M

      ColumnLayout {
        id: connectColumn
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginM

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          NTextInput {
            Layout.fillWidth: true
            label: pluginApi?.tr("panel.host.label")
            placeholderText: pluginApi?.tr("panel.host.placeholder")
            text: root.valueHost
            enabled: !root.settingsConsumer?.sessionActive
            onTextChanged: root.valueHost = text
            onAccepted: root.doConnect()
          }

          NTextInput {
            Layout.preferredWidth: Math.round(100 * Style.uiScaleRatio)
            label: pluginApi?.tr("panel.port.label")
            placeholderText: pluginApi?.tr("panel.port.placeholder")
            text: String(root.valuePort)
            enabled: !root.settingsConsumer?.sessionActive
            inputMethodHints: Qt.ImhDigitsOnly
            onTextChanged: root.valuePort = Math.max(1, Math.min(65535, Number(text || 22)))
            onAccepted: root.doConnect()
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginM

          NTextInput {
            Layout.fillWidth: true
            label: pluginApi?.tr("panel.user.label")
            placeholderText: pluginApi?.tr("panel.user.placeholder")
            text: root.valueUser
            enabled: !root.settingsConsumer?.sessionActive
            onTextChanged: root.valueUser = text
            onAccepted: root.doConnect()
          }

          NTextInput {
            id: passwordInput
            Layout.fillWidth: true
            label: pluginApi?.tr("panel.password.label")
            placeholderText: pluginApi?.tr("panel.password.placeholder")
            enabled: !root.settingsConsumer?.sessionActive
            inputItem.echoMode: TextInput.Password
            onTextChanged: root.valuePassword = text
            onAccepted: root.doConnect()
          }
        }

        NButton {
          Layout.fillWidth: true
          text: pluginApi?.tr("panel.connect")
          icon: "plug-connected"
          enabled: root.valueHost.length > 0 && root.valueUser.length > 0
          onClicked: root.doConnect()
        }
      }
    }

    NBox {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.settingsConsumer?.sessionActive ?? false

      TerminalView {
        id: terminalView
        anchors.fill: parent
        anchors.margins: Style.marginM
        cols: root.terminalCols
        rows: root.terminalRows
        fontSize: root.terminalFontSize
        session: root.settingsConsumer
        rawText: root.settingsConsumer?.terminalBuffer ?? ""
        sessionActive: root.settingsConsumer?.sessionActive ?? false
        onInput: function(text) { root.settingsConsumer?.send(text); }
      }
    }
  }

  onVisibleChanged: {
    if (visible && root.settingsConsumer?.sessionActive)
      Qt.callLater(function() { terminalView.focusTerminal(); });
  }
}
