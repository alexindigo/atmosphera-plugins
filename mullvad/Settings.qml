import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
	id: root
	property var pluginApi: null
	spacing: Style.marginS

	// cfg -> defaults -> hardcoded fallback chain (per AGENTS.md)
	readonly property var cfg: pluginApi?.pluginSettings || ({})
	readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

	property int refreshInterval: displayBaseline.refreshInterval
	property bool showCountryFlag: cfg.showCountryFlag ?? defaults.showCountryFlag ?? false
	property bool showCityName: displayBaseline.showCityName
	property bool showIp: displayBaseline.showIp
	property bool compactMode: displayBaseline.compactMode
	property string clickAction: displayBaseline.clickAction
	property bool relayClickConnects: displayBaseline.relayClickConnects
	property bool confirmDisconnectInLockdown: displayBaseline.confirmDisconnectInLockdown
	property int expiryWarningDays: displayBaseline.expiryWarningDays
	property string favoriteCountriesText: displayBaseline.favoriteCountriesText

	NSettingsBaseline {
		id: displayBaseline
		readonly property int refreshInterval: cfg.refreshInterval ?? defaults.refreshInterval ?? 3000
		readonly property bool showCityName: cfg.showCityName ?? defaults.showCityName ?? false
		readonly property bool showIp: cfg.showIp ?? defaults.showIp ?? false
		readonly property bool compactMode: cfg.compactMode ?? defaults.compactMode ?? false
		readonly property string clickAction: cfg.clickAction ?? defaults.clickAction ?? "panel"
		readonly property bool relayClickConnects: cfg.relayClickConnects ?? defaults.relayClickConnects ?? true
		readonly property bool confirmDisconnectInLockdown: cfg.confirmDisconnectInLockdown ?? defaults.confirmDisconnectInLockdown ?? true
		readonly property int expiryWarningDays: cfg.expiryWarningDays ?? defaults.expiryWarningDays ?? 7
		readonly property string favoriteCountriesText: (cfg.favoriteCountries ?? defaults.favoriteCountries ?? []).join(",")
	}
	readonly property bool settingsDirty: displayBaseline.differs({refreshInterval: root.refreshInterval, showCityName: root.showCityName, showIp: root.showIp, compactMode: root.compactMode, clickAction: root.clickAction, relayClickConnects: root.relayClickConnects, confirmDisconnectInLockdown: root.confirmDisconnectInLockdown, expiryWarningDays: root.expiryWarningDays, favoriteCountriesText: root.favoriteCountriesText})

	function saveSettings() {
		if (!pluginApi) {
			Logger.e("Mullvad", "Cannot save: pluginApi is null")
			return
		}
		pluginApi.pluginSettings.refreshInterval = root.refreshInterval
		pluginApi.pluginSettings.showCityName = root.showCityName
		pluginApi.pluginSettings.showIp = root.showIp
		pluginApi.pluginSettings.compactMode = root.compactMode
		pluginApi.pluginSettings.clickAction = root.clickAction
		pluginApi.pluginSettings.relayClickConnects = root.relayClickConnects
		pluginApi.pluginSettings.confirmDisconnectInLockdown = root.confirmDisconnectInLockdown
		pluginApi.pluginSettings.expiryWarningDays = root.expiryWarningDays
		var fav = (root.favoriteCountriesText || "")
			.split(",")
			.map(function (s) { return s.trim().toLowerCase() })
			.filter(function (s) { return s.length === 2 })
		root.favoriteCountriesText = fav.join(",")
		pluginApi.pluginSettings.favoriteCountries = fav
		pluginApi.saveSettings(function (result) {
			if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
				Logger.i("Mullvad", "Settings saved")
		})
	}

	NSpinBox {
		Layout.fillWidth: true
		label: pluginApi?.tr("settings.refresh-interval")
		from: 1000; to: 60000; stepSize: 500
		value: root.refreshInterval
		onValueChanged: root.refreshInterval = value
	}

	NToggle {
		Layout.fillWidth: true
		label: pluginApi?.tr("settings.show-city")
		checked: root.showCityName
		onToggled: checked => root.showCityName = checked
	}

	NToggle {
		Layout.fillWidth: true
		label: pluginApi?.tr("settings.show-ip")
		checked: root.showIp
		onToggled: checked => root.showIp = checked
	}

	NToggle {
		Layout.fillWidth: true
		label: pluginApi?.tr("settings.compact-mode")
		checked: root.compactMode
		onToggled: checked => root.compactMode = checked
	}

	NComboBox {
		Layout.fillWidth: true
		label: pluginApi?.tr("settings.click-action")
		model: [
			{ key: "toggle", name: pluginApi?.tr("settings.click-toggle") },
			{ key: "panel", name: pluginApi?.tr("settings.click-panel") }
		]
		currentKey: root.clickAction
		onSelected: key => root.clickAction = key
	}

	NToggle {
		Layout.fillWidth: true
		label: pluginApi?.tr("settings.relay-click-connects")
		checked: root.relayClickConnects
		onToggled: checked => root.relayClickConnects = checked
	}

	NToggle {
		Layout.fillWidth: true
		label: pluginApi?.tr("settings.confirm-disconnect-lockdown")
		checked: root.confirmDisconnectInLockdown
		onToggled: checked => root.confirmDisconnectInLockdown = checked
	}

	NSpinBox {
		Layout.fillWidth: true
		label: pluginApi?.tr("settings.expiry-warning-days")
		from: 0; to: 90
		value: root.expiryWarningDays
		onValueChanged: root.expiryWarningDays = value
	}

	NTextInput {
		Layout.fillWidth: true
		label: pluginApi?.tr("settings.favorite-countries")
		text: root.favoriteCountriesText
		onTextChanged: root.favoriteCountriesText = text
	}
}
