import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Edit copies of settings
  property string editAqiScale: displayBaseline.editAqiScale
  property bool editUseNoctaliaLocation: displayBaseline.editUseNoctaliaLocation
  property string editCustomLatitude: displayBaseline.editCustomLatitude
  property string editCustomLongitude: displayBaseline.editCustomLongitude
  property int editRefreshInterval: displayBaseline.project("editRefreshInterval")
  property bool editBoldText: displayBaseline.editBoldText
  property string editDataSource: displayBaseline.editDataSource
  property string editAqicnToken: displayBaseline.editAqicnToken
  property bool _refreshPending: false
  property bool _savePending: false
  NSettingsBaseline {
    id: displayBaseline
    readonly property string editAqiScale: cfg.aqiScale ?? defaults.aqiScale ?? "us"
    readonly property bool editUseNoctaliaLocation: cfg.useNoctaliaLocation ?? defaults.useNoctaliaLocation ?? true
    readonly property string editCustomLatitude: cfg.customLatitude ?? defaults.customLatitude ?? ""
    readonly property string editCustomLongitude: cfg.customLongitude ?? defaults.customLongitude ?? ""
    readonly property int editRefreshInterval: cfg.refreshInterval ?? defaults.refreshInterval ?? 30
    readonly property bool editBoldText: cfg.boldText ?? defaults.boldText ?? true
    readonly property string editDataSource: cfg.dataSource ?? defaults.dataSource ?? "open-meteo"
    readonly property string editAqicnToken: cfg.aqicnToken ?? defaults.aqicnToken ?? ""
    ranges: [NSettingsRange { field: "editRefreshInterval"; from: rangeEditRefreshInterval.from; to: rangeEditRefreshInterval.to }]
  }
  readonly property bool settingsDirty: displayBaseline.differs({editAqiScale: root.editAqiScale, editUseNoctaliaLocation: root.editUseNoctaliaLocation, editCustomLatitude: root.editCustomLatitude, editCustomLongitude: root.editCustomLongitude, editRefreshInterval: root.editRefreshInterval, editBoldText: root.editBoldText, editDataSource: root.editDataSource, editAqicnToken: root.editAqicnToken})
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current") return;
      root._savePending = false;
      var refresh = root._refreshPending;
      root._refreshPending = false;
      if (refresh) root.pluginApi.mainInstance?.refresh();
      Logger.i("Air Quality", "Settings saved");
    }
  }

  spacing: Style.marginM

  // --- Data Source ---
  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXS

      NText {
        text: pluginApi?.tr("settings.dataSource")
        pointSize: Style.fontSizeM
        color: AtmoColor.mOnSurface
      }

      NText {
        text: pluginApi?.tr("settings.dataSourceDesc")
        pointSize: Style.fontSizeS
        color: AtmoColor.mOnSurfaceVariant
      }
    }

    NComboBox {
      Layout.preferredWidth: 260 * Style.uiScaleRatio
      Layout.preferredHeight: Style.baseWidgetSize
      model: [
        { key: "open-meteo", name: pluginApi?.tr("settings.dataSourceOpenMeteo") },
        { key: "aqicn", name: pluginApi?.tr("settings.dataSourceAqicn") }
      ]
      currentKey: root.editDataSource
      onSelected: key => {
        root.editDataSource = key
        if (key === "aqicn") root.editAqiScale = "us"
      }
    }
  }

  // --- AQICN Token ---
  NTextInput {
    Layout.fillWidth: true
    visible: root.editDataSource === "aqicn"
    label: pluginApi?.tr("settings.aqicnToken")
    description: pluginApi?.tr("settings.aqicnTokenDesc")
    placeholderText: pluginApi?.tr("settings.aqicnTokenPlaceholder")
    text: root.editAqicnToken
    onTextChanged: root.editAqicnToken = text
  }

  // --- AQI Scale ---
  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginXS

      NText {
        text: pluginApi?.tr("settings.aqiScale")
        pointSize: Style.fontSizeM
        color: AtmoColor.mOnSurface
      }

      NText {
        text: pluginApi?.tr("settings.aqiScaleDesc")
        pointSize: Style.fontSizeS
        color: AtmoColor.mOnSurfaceVariant
      }
    }

    NComboBox {
      Layout.preferredWidth: 180 * Style.uiScaleRatio
      Layout.preferredHeight: Style.baseWidgetSize
      enabled: root.editDataSource !== "aqicn"
      model: [
        { key: "us", name: pluginApi?.tr("settings.aqiScaleUs") },
        { key: "eu", name: pluginApi?.tr("settings.aqiScaleEu") }
      ]
      currentKey: root.editAqiScale
      onSelected: key => {
        root.editAqiScale = key
      }
    }
  }

  // --- Location ---
  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: locationToggle.implicitHeight
    NToggle {
      id: locationToggle
      anchors.fill: parent
      label: pluginApi?.tr("settings.useNoctaliaLocation")
      description: pluginApi?.tr("settings.useNoctaliaLocationDesc")
      checked: root.editUseNoctaliaLocation
      onToggled: checked => root.editUseNoctaliaLocation = checked
    }
  }

  NTextInput {
    Layout.fillWidth: true
    visible: !root.editUseNoctaliaLocation
    label: pluginApi?.tr("settings.customLatitude")
    description: pluginApi?.tr("settings.customLocationDesc")
    placeholderText: "41.3851"
    text: root.editCustomLatitude
    onTextChanged: root.editCustomLatitude = text
  }

  NTextInput {
    Layout.fillWidth: true
    visible: !root.editUseNoctaliaLocation
    label: pluginApi?.tr("settings.customLongitude")
    placeholderText: "2.1734"
    text: root.editCustomLongitude
    onTextChanged: root.editCustomLongitude = text
  }

  // --- Refresh Interval ---
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.refreshInterval")
      description: pluginApi?.tr("settings.refreshIntervalDesc") + root.editRefreshInterval
    }

    NSlider {
      id: rangeEditRefreshInterval
      objectName: "settings-range-editRefreshInterval"
      Layout.fillWidth: true
      from: 5
      to: 120
      stepSize: 5
      value: root.editRefreshInterval
      onMoved: root.editRefreshInterval = value
    }
  }

  // --- Appearance ---
  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: boldToggle.implicitHeight
    NToggle {
      id: boldToggle
      anchors.fill: parent
      label: pluginApi?.tr("settings.boldText")
      description: pluginApi?.tr("settings.boldTextDesc")
      checked: root.editBoldText
      onToggled: checked => root.editBoldText = checked
    }
  }

  // Required — called by the shell when user saves
  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Air Quality", "Cannot save: pluginApi is null")
      return
    }

    var locationChanged = pluginApi.pluginSettings.useNoctaliaLocation !== root.editUseNoctaliaLocation
        || pluginApi.pluginSettings.customLatitude !== root.editCustomLatitude
        || pluginApi.pluginSettings.customLongitude !== root.editCustomLongitude
    var scaleChanged = pluginApi.pluginSettings.aqiScale !== root.editAqiScale
    var dataSourceChanged = pluginApi.pluginSettings.dataSource !== root.editDataSource
        || pluginApi.pluginSettings.aqicnToken !== root.editAqicnToken

    pluginApi.pluginSettings.aqiScale = root.editAqiScale
    pluginApi.pluginSettings.dataSource = root.editDataSource
    pluginApi.pluginSettings.aqicnToken = root.editAqicnToken
    pluginApi.pluginSettings.useNoctaliaLocation = root.editUseNoctaliaLocation
    pluginApi.pluginSettings.customLatitude = root.editCustomLatitude
    pluginApi.pluginSettings.customLongitude = root.editCustomLongitude
    pluginApi.pluginSettings.refreshInterval = root.editRefreshInterval
    pluginApi.pluginSettings.boldText = root.editBoldText

    if (pluginApi.saveSettings() !== false) {
      root._savePending = true;
      root._refreshPending = root._refreshPending || locationChanged || scaleChanged || dataSourceChanged;
    }
  }
}
