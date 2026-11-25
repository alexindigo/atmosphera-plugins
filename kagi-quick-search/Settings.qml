import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  readonly property var kagiSessionTokenField: pluginApi?.field("kagiSessionToken") ?? null
  readonly property var debounceMsField: pluginApi?.field("debounceMs") ?? null
  readonly property string editToken: root.kagiSessionTokenField?.value ?? ""
  readonly property int editDebounce: root.debounceMsField?.value ?? 500

  spacing: Style.marginM

  Component.onCompleted: {
    Logger.i("Kagi", "Settings UI loaded");
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NPluginSettingsField {
      field: root.kagiSessionTokenField
      NTextInput {
        Layout.fillWidth: true
        label: "Kagi Session Token (Required)"
        text: root.editToken
        onEditCommitted: root.kagiSessionTokenField.set(text.trim())
      }
    }

    NImageText {
      Layout.fillWidth: true
      text: "To get your Kagi session token:\n- Open kagi.com in your browser, right click, and select \"Inspect Element\"\n- Switch to the \"Network\" tab and filter for \"Fetch/XHR\"\n- Type something in the search bar\n- Click on any entry that's labeled with \"autosuggest\"\n- Scroll down until you see an item labelled \"Set-Cookie\"\n- You'll see something like `kagi_session=Copy_this_its_long; ...`<br/>Copy the text after the `=` and before the `;` and paste it above, then hit save."
      color: AtmoColor.mOnSurfaceVariant
      pointSize: Style.fontSizeS
      format: "markdown"
    }

    NLabel {
      label: "Debounce"
      description: "How long it'll take to search your query in milliseconds"
    }

    NPluginSettingsField {
      field: root.debounceMsField
      NSlider {
        id: debounceSlider
        objectName: "settings-range-editDebounce"
        from: 300
        to: 1500
        value: root.editDebounce
        stepSize: 100
        onMoved: {
          root.debounceMsField.set(value);
        }
      }
    }

    Text {
        textFormat: Text.PlainText
        text: `${root.editDebounce}ms`
        color: AtmoColor.mOnSurfaceVariant
        font.pointSize: Style.fontSizeS
    }
  }

  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Kagi", "Cannot save settings: pluginApi is null");
      return;
    }
    pluginApi.saveSettings(function (result) {
      if (result && (result.status === "saved" || result.status === "nothing_to_save") && result.refreshState === "current")
        Logger.i("Kagi", "Settings saved successfully");
    });
  }
}
