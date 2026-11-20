import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _savePending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._savePending = false;
      Logger.d("Mawaqit", "Settings saved");
    }
  }
  property var pluginApi: null
  readonly property var cityField: pluginApi?.field("city") ?? null
  readonly property var countryField: pluginApi?.field("country") ?? null
  readonly property var methodField: pluginApi?.field("method") ?? null
  readonly property var showCountdownField: pluginApi?.field("showCountdown") ?? null
  readonly property var showElapsedField: pluginApi?.field("showElapsed") ?? null
  readonly property var hidePrayerNameField: pluginApi?.field("hidePrayerName") ?? null
  readonly property var showNotificationsField: pluginApi?.field("showNotifications") ?? null
  readonly property var playAzanField: pluginApi?.field("playAzan") ?? null
  readonly property var azanFileField: pluginApi?.field("azanFile") ?? null
  readonly property var schoolField: pluginApi?.field("school") ?? null
  readonly property var hijriDayOffsetField: pluginApi?.field("hijriDayOffset") ?? null
  readonly property var weekStartDayField: pluginApi?.field("weekStartDay") ?? null
  readonly property var tuneField: pluginApi?.field("tune") ?? null
  readonly property var tuneFajrField: pluginApi?.field("tuneFajr") ?? null
  readonly property var tuneDhuhrField: pluginApi?.field("tuneDhuhr") ?? null
  readonly property var tuneAsrField: pluginApi?.field("tuneAsr") ?? null
  readonly property var tuneMaghribField: pluginApi?.field("tuneMaghrib") ?? null
  readonly property var tuneIshaField: pluginApi?.field("tuneIsha") ?? null
  readonly property var widgetIconField: pluginApi?.field("widgetIcon") ?? null
  readonly property var dynamicIconField: pluginApi?.field("dynamicIcon") ?? null
  readonly property var textColorField: pluginApi?.field("textColor") ?? null
  readonly property var iconColorField: pluginApi?.field("iconColor") ?? null
  readonly property var activeColorField: pluginApi?.field("activeColor") ?? null
  readonly property var fajrAngleField: pluginApi?.field("fajrAngle") ?? null
  readonly property var ishaAngleField: pluginApi?.field("ishaAngle") ?? null
  property var methods: [
    {
      "key": "1",
      "name": "University of Islamic Sciences, Karachi"
    },
    {
      "key": "2",
      "name": "Islamic Society of North America (ISNA)"
    },
    {
      "key": "3",
      "name": "Muslim World League (MWL)"
    },
    {
      "key": "4",
      "name": "Umm Al-Qura University, Makkah"
    },
    {
      "key": "5",
      "name": "Egyptian General Authority of Survey"
    },
    {
      "key": "7",
      "name": "Institute of Geophysics, Tehran"
    },
    {
      "key": "8",
      "name": "Gulf Region"
    },
    {
      "key": "9",
      "name": "Kuwait"
    },
    {
      "key": "10",
      "name": "Qatar"
    },
    {
      "key": "11",
      "name": "Majlis Ugama Islam Singapura"
    },
    {
      "key": "12",
      "name": "Union Organization Islamic de France"
    },
    {
      "key": "13",
      "name": "Diyanet İşleri Başkanlığı, Turkey"
    },
    {
      "key": "14",
      "name": "Spiritual Administration of Muslims of Russia"
    },
    {
      "key": "15",
      "name": "Moonsighting Committee Worldwide"
    },
    {
      "key": "16",
      "name": "Dubai (Experimental)"
    },
    {
      "key": "19",
      "name": "Algeria"
    },
    {
      "key": "23",
      "name": "Ministry of Awqaf, Islamic Affairs and Holy Places, Jordan"
    },
    {
      "key": "99",
      "name": "Custom Method"
    }
  ]

  readonly property string valueCity: root.cityField?.value ?? "London"
  readonly property string valueCountry: root.countryField?.value ?? "UK"
  readonly property int valueMethod: root.methodField?.value ?? 3
  readonly property var valueFajrAngle: root.fajrAngleField?.value ?? null
  readonly property var valueIshaAngle: root.ishaAngleField?.value ?? null
  readonly property bool valueTune: root.tuneField?.value ?? false
  readonly property int valueTuneFajr: root.tuneFajrField?.value ?? 0
  readonly property int valueTuneDhuhr: root.tuneDhuhrField?.value ?? 0
  readonly property int valueTuneAsr: root.tuneAsrField?.value ?? 0
  readonly property int valueTuneMaghrib: root.tuneMaghribField?.value ?? 0
  readonly property int valueTuneIsha: root.tuneIshaField?.value ?? 0
  readonly property int valueSchool: root.schoolField?.value ?? 0
  readonly property bool valueShowCountdown: root.showCountdownField?.value ?? true
  readonly property bool valueShowElapsed: root.showElapsedField?.value ?? false
  readonly property bool valueHidePrayerName: root.hidePrayerNameField?.value ?? false
  readonly property bool valueShowNotifications: root.showNotificationsField?.value ?? true
  readonly property bool valuePlayAzan: root.playAzanField?.value ?? false
  readonly property string valueAzanFile: root.azanFileField?.value ?? "azan1.mp3"
  readonly property int valueHijriDayOffset: root.hijriDayOffsetField?.value ?? 0
  readonly property int valueWeekStartDay: root.weekStartDayField?.value ?? 1
  readonly property string valueWidgetIcon: root.widgetIconField?.value ?? "building-mosque"
  readonly property bool valueDynamicIcon: root.dynamicIconField?.value ?? false
  readonly property string valueTextColor: root.textColorField?.value ?? "none"
  readonly property string valueIconColor: root.iconColorField?.value ?? "none"
  readonly property string valueActiveColor: root.activeColorField?.value ?? "primary"

  property bool previewing: false

  spacing: Style.marginL

  // ── Location ──────────────────────────────────────────────────────────────

  NHeader {
    label: pluginApi?.tr("settings.location.header")
    description: pluginApi?.tr("settings.location.desc")
  }

  NPluginSettingsField {
    field: root.cityField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.city.label")
      description: pluginApi?.tr("settings.city.desc")
      placeholderText: "London"
      text: root.valueCity
      onEditCommitted: root.cityField.set(text.trim())
    }
  }

  NPluginSettingsField {
    field: root.countryField
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.country.label")
      description: pluginApi?.tr("settings.country.desc")
      placeholderText: "UK"
      text: root.valueCountry
      onEditCommitted: root.countryField.set(text.trim())
    }
  }

  NPluginSettingsField {
    field: root.methodField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.method.label")
      description: pluginApi?.tr("settings.method.desc")
      currentKey: String(root.valueMethod)
      model: root.methods
      onSelected: key => {
        root.methodField.set(parseInt(key));
      }
    }
  }

  NPluginSettingsField {
    field: root.fajrAngleField
    visible: root.valueMethod === 99
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.fajrAngle.label")
      description: pluginApi?.tr("settings.fajrAngle.desc")
      placeholderText: "18.0"
      text: root.valueFajrAngle !== null ? String(root.valueFajrAngle) : ""
      onEditCommitted: {
        const parsed = parseFloat(text);
        root.fajrAngleField.set(isNaN(parsed) ? null : parsed);
      }
    }
  }

  NPluginSettingsField {
    field: root.ishaAngleField
    visible: root.valueMethod === 99
    NTextInput {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.ishaAngle.label")
      description: pluginApi?.tr("settings.ishaAngle.desc")
      placeholderText: "17.0"
      text: root.valueIshaAngle !== null ? String(root.valueIshaAngle) : ""
      onEditCommitted: {
        const parsed = parseFloat(text);
        root.ishaAngleField.set(isNaN(parsed) ? null : parsed);
      }
    }
  }

  NPluginSettingsField {
    field: root.schoolField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.school.label")
      description: pluginApi?.tr("settings.school.desc")
      currentKey: String(root.valueSchool)
      model: [
        {
          "key": "0",
          "name": "Shafi / Maliki / Hanbali (Default)"
        },
        {
          "key": "1",
          "name": "Hanafi"
        }
      ]
      onSelected: key => root.schoolField.set(parseInt(key))
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Calibration ───────────────────────────────────────────────────────────

  NHeader {
    label: pluginApi?.tr("settings.calibration.header")
    description: pluginApi?.tr("settings.calibration.desc")
  }

  NPluginSettingsField {
    field: root.hijriDayOffsetField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.hijriDayOffset.label")
      description: pluginApi?.tr("settings.hijriDayOffset.desc")
      currentKey: String(root.valueHijriDayOffset)
      model: [
        {
          "key": "-1",
          "name": "−1 day"
        },
        {
          "key": "0",
          "name": "Default (from API)"
        },
        {
          "key": "1",
          "name": "+1 day"
        }
      ]
      onSelected: key => root.hijriDayOffsetField.set(parseInt(key))
    }
  }

  NHeader {
    label: pluginApi?.tr("settings.tune.header")
    description: pluginApi?.tr("settings.tune.desc")
    Layout.bottomMargin: -Style.marginM
  }

  NPluginSettingsField {
    field: root.tuneField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.tune.enable")
      checked: root.valueTune
      onToggled: checked => root.tuneField.set(checked)
    }
  }

  Repeater {
    model: [
      {
        key: "Fajr",
        labelKey: "settings.tune.fajr"
      },
      {
        key: "Dhuhr",
        labelKey: "settings.tune.dhuhr"
      },
      {
        key: "Asr",
        labelKey: "settings.tune.asr"
      },
      {
        key: "Maghrib",
        labelKey: "settings.tune.maghrib"
      },
      {
        key: "Isha",
        labelKey: "settings.tune.isha"
      }
    ]
    // One delegate per prayer tune leaf, each with its own field chrome.
    delegate: NPluginSettingsField {
      id: tuneChrome
      required property var modelData
      visible: root.valueTune
      field: root[modelData.key === "Fajr" ? "tuneFajrField" : modelData.key === "Dhuhr" ? "tuneDhuhrField" : modelData.key === "Asr" ? "tuneAsrField" : modelData.key === "Maghrib" ? "tuneMaghribField" : "tuneIshaField"]
      NTextInput {
        readonly property var modelData: tuneChrome.modelData
        Layout.fillWidth: true
        label: pluginApi?.tr(modelData.labelKey)
        placeholderText: "0"
        text: {
          const v = modelData.key === "Fajr" ? root.valueTuneFajr : modelData.key === "Dhuhr" ? root.valueTuneDhuhr : modelData.key === "Asr" ? root.valueTuneAsr : modelData.key === "Maghrib" ? root.valueTuneMaghrib : root.valueTuneIsha;
          return v === 0 ? "" : String(v);
        }
        onEditCommitted: {
          const n = parseInt(text);
          const v = isNaN(n) ? 0 : n;
          if (modelData.key === "Fajr")
            root.tuneFajrField.set(v);
          else if (modelData.key === "Dhuhr")
            root.tuneDhuhrField.set(v);
          else if (modelData.key === "Asr")
            root.tuneAsrField.set(v);
          else if (modelData.key === "Maghrib")
            root.tuneMaghribField.set(v);
          else
            root.tuneIshaField.set(v);
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Calendar ──────────────────────────────────────────────────────────────

  NHeader {
    label: pluginApi?.tr("settings.calendar.header")
    Layout.bottomMargin: -Style.marginM
  }

  NPluginSettingsField {
    field: root.weekStartDayField
    NComboBox {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.weekStartDay.label")
      description: pluginApi?.tr("settings.weekStartDay.desc")
      currentKey: String(root.valueWeekStartDay)
      model: [
        {
          "key": "6",
          "name": "Saturday"
        },
        {
          "key": "0",
          "name": "Sunday"
        },
        {
          "key": "1",
          "name": "Monday"
        }
      ]
      onSelected: key => root.weekStartDayField.set(parseInt(key))
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Display ───────────────────────────────────────────────────────────────

  NHeader {
    label: pluginApi?.tr("settings.display.header")
    Layout.bottomMargin: -Style.marginM
  }

  NPluginSettingsField {
    field: root.showCountdownField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.showCountdown.label")
      description: pluginApi?.tr("settings.showCountdown.desc")
      checked: root.valueShowCountdown
      onToggled: checked => root.showCountdownField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.showElapsedField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.showElapsed.label")
      description: pluginApi?.tr("settings.showElapsed.desc")
      checked: root.valueShowElapsed
      onToggled: checked => root.showElapsedField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.hidePrayerNameField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.hidePrayerName.label")
      description: pluginApi?.tr("settings.hidePrayerName.desc")
      checked: root.valueHidePrayerName
      onToggled: checked => root.hidePrayerNameField.set(checked)
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NHeader {
    label: pluginApi?.tr("settings.styling.header")
    Layout.bottomMargin: -Style.marginM
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NPluginSettingsField {
      field: root.widgetIconField
      NTextInput {
        id: widgetIconInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.widgetIcon.label")
        placeholderText: "building-mosque"
        text: root.valueWidgetIcon
        onEditCommitted: root.widgetIconField.set(text.trim())
      }
    }

    AtmoIcon {
      icon: root.valueWidgetIcon || "building-mosque"
      pointSize: Style.fontSizeXL
      color: AtmoColor.mPrimary
      Layout.alignment: Qt.AlignBottom
      Layout.bottomMargin: Style.marginM
    }

    AtmoIconButton {
      icon: "search"
      tooltipText: "Browse icons"
      Layout.alignment: Qt.AlignBottom
      Layout.bottomMargin: Style.marginXS
      onClicked: {
        mainIconPicker.open();
      }
    }

    AtmoIconPicker {
      id: mainIconPicker
      initialIcon: root.valueWidgetIcon
      onIconSelected: function (iconName) {
        root.widgetIconField.set(iconName);
      }
    }
  }

  NPluginSettingsField {
    field: root.dynamicIconField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.dynamicIcon.label")
      description: pluginApi?.tr("settings.dynamicIcon.desc")
      checked: root.valueDynamicIcon
      onToggled: checked => root.dynamicIconField.set(checked)
    }
  }

  NPluginSettingsField {
    field: root.textColorField
    NColorChoice {
      label: pluginApi?.tr("settings.textColor.label")
      currentKey: root.valueTextColor
      onSelected: key => {
        root.textColorField.set(key);
      }
    }
  }

  NPluginSettingsField {
    field: root.iconColorField
    NColorChoice {
      label: pluginApi?.tr("settings.iconColor.label")
      currentKey: root.valueIconColor
      onSelected: key => {
        root.iconColorField.set(key);
      }
    }
  }

  NPluginSettingsField {
    field: root.activeColorField
    NColorChoice {
      label: pluginApi?.tr("settings.activeColor.label")
      description: pluginApi?.tr("settings.activeColor.desc")
      currentKey: root.valueActiveColor
      onSelected: key => {
        root.activeColorField.set(key);
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  NHeader {
    label: pluginApi?.tr("settings.notifications.header")
    Layout.bottomMargin: -Style.marginM
  }

  NPluginSettingsField {
    field: root.showNotificationsField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.showNotifications.label")
      description: pluginApi?.tr("settings.notifications.desc")
      checked: root.valueShowNotifications
      onToggled: checked => root.showNotificationsField.set(checked)
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  // ── Azan ──────────────────────────────────────────────────────────────────

  NHeader {
    label: pluginApi?.tr("settings.azan.header")
    Layout.bottomMargin: -Style.marginM
  }

  NPluginSettingsField {
    field: root.playAzanField
    NToggle {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.playAzan.label")
      description: pluginApi?.tr("settings.azan.desc")
      checked: root.valuePlayAzan
      onToggled: checked => {
        root.playAzanField.set(checked);
        if (!checked && root.previewing) {
          pluginApi?.mainInstance?.stopAzanFile();
          root.previewing = false;
        }
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    visible: root.valuePlayAzan
    spacing: Style.marginM
    Layout.alignment: Qt.AlignVCenter

    NPluginSettingsField {
      field: root.azanFileField
      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.azanFile.label")
        description: pluginApi?.tr("settings.azanFile.desc")
        currentKey: root.valueAzanFile
        model: [
          {
            "key": "azan1.mp3",
            "name": pluginApi?.tr("settings.azan1")
          },
          {
            "key": "azan2.mp3",
            "name": pluginApi?.tr("settings.azan2")
          },
          {
            "key": "azan3.mp3",
            "name": pluginApi?.tr("settings.azan3")
          }
        ]
        onSelected: key => {
          root.azanFileField.set(key);
          if (root.previewing) {
            pluginApi?.mainInstance?.stopAzanFile();
            Qt.callLater(() => pluginApi?.mainInstance?.playAzanFile(root.valueAzanFile));
          }
        }
      }
    }

    AtmoIconButton {
      Layout.alignment: Qt.AlignBottom
      Layout.bottomMargin: Style.marginS
      Layout.preferredHeight: Math.round(Style.baseWidgetSize * 1.1 * Style.uiScaleRatio)
      Layout.preferredWidth: Math.round(Style.baseWidgetSize * 1.1 * Style.uiScaleRatio)
      icon: root.previewing ? "player-stop-filled" : "player-play-filled"
      tooltipText: root.previewing ? pluginApi?.tr("settings.azan.stop") : pluginApi?.tr("settings.azan.preview")
      onClicked: {
        const main = pluginApi?.mainInstance;
        if (!main)
          return;
        if (root.previewing) {
          main.stopAzanFile();
          root.previewing = false;
        } else {
          main.playAzanFile(root.valueAzanFile);
          root.previewing = true;
        }
      }
    }
  }

  Connections {
    target: pluginApi?.mainInstance ?? null
    function onAzanPlayingChanged() {
      if (pluginApi?.mainInstance && !pluginApi.mainInstance.azanPlaying)
        root.previewing = false;
    }
  }

  function saveSettings() {
    if (!pluginApi)
      return;
    if (root.previewing) {
      pluginApi?.mainInstance?.stopAzanFile();
      root.previewing = false;
    }
    if (pluginApi.saveSettings() !== false)
      root._savePending = true;
  }
}
