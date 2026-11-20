import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  property var pluginApi: null
  readonly property var feedsField: pluginApi?.field("feeds") ?? null
  readonly property var updateIntervalField: pluginApi?.field("updateInterval") ?? null
  readonly property var maxItemsPerFeedField: pluginApi?.field("maxItemsPerFeed") ?? null
  readonly property var showOnlyUnreadField: pluginApi?.field("showOnlyUnread") ?? null
  readonly property var markAsReadOnClickField: pluginApi?.field("markAsReadOnClick") ?? null

  readonly property var feeds: root.feedsField?.value || []
  readonly property int updateInterval: root.updateIntervalField?.value ?? 600
  readonly property int maxItemsPerFeed: root.maxItemsPerFeedField?.value ?? 10
  readonly property bool showOnlyUnread: root.showOnlyUnreadField?.value ?? false
  readonly property bool markAsReadOnClick: root.markAsReadOnClickField?.value ?? true
  // Explicit field intents only; the selected session owns Apply/Reset.
  readonly property bool settingsDirty: false
  property bool _savePending: false
  Connections {
    target: root.pluginApi
    function onSettingsCompleted(result) {
      if (!root._savePending || !result || (result.status !== "saved" && result.status !== "nothing_to_save") || result.refreshState !== "current")
        return;
      root._savePending = false;
      Logger.d("RSS Feed", "RSS Feed: Settings saved successfully");
    }
  }

  // Temporary fields for adding new feed
  property string newFeedName: ""
  property string newFeedUrl: ""

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("RSS Feed: Cannot save settings - pluginApi is null");
      return;
    }

    Logger.d("RSS Feed", "RSS Feed Settings: Saving - updateInterval:", updateInterval, "maxItems:", maxItemsPerFeed, "showOnlyUnread:", showOnlyUnread, "markAsReadOnClick:", markAsReadOnClick, "feeds:", feeds.length);

    if (pluginApi.saveSettings() !== false)
      root._savePending = true;
  }

  function addFeed() {
    if (newFeedName.trim() === "" || newFeedUrl.trim() === "") {
      Logger.e("RSS Feed: Name and URL are required");
      return;
    }

    const newFeeds = feeds.slice();
    newFeeds.push({
                    name: newFeedName.trim(),
                    url: newFeedUrl.trim()
                  });
    root.feedsField.set(newFeeds);

    newFeedName = "";
    newFeedUrl = "";
  }

  function removeFeed(index) {
    const newFeeds = feeds.slice();
    newFeeds.splice(index, 1);
    root.feedsField.set(newFeeds);
  }

  // Update Interval
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.updateInterval", "Update Interval") || "Update Interval"
      description: pluginApi?.tr("settings.updateIntervalDesc", "How often to check for new items (seconds)") || "How often to check for new items (seconds)"
    }

    RowLayout {
      spacing: Style.marginM

      NPluginSettingsField {
        field: root.updateIntervalField
        NSpinBox {
          id: rangeUpdateInterval
          objectName: "settings-range-updateInterval"
          from: 60
          to: 3600
          value: updateInterval
          onValueModified: value => {
            root.updateIntervalField.set(value);
          }
        }
      }

      Text {
        text: pluginApi?.tr("settings.seconds", "seconds") || "seconds"
        color: AtmoColor.mOnSurfaceVariant
        font.pixelSize: Style.fontSizeM
      }
    }
  }

  // Max Items Per Feed
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.maxItems", "Max Items Per Feed") || "Max Items Per Feed"
      description: pluginApi?.tr("settings.maxItemsDesc", "Maximum number of items to fetch from each feed") || "Maximum number of items to fetch from each feed"
    }

    NPluginSettingsField {
      field: root.maxItemsPerFeedField
      NSpinBox {
        id: rangeMaxItemsPerFeed
        objectName: "settings-range-maxItemsPerFeed"
        from: 5
        to: 50
        value: maxItemsPerFeed
        onValueModified: value => {
          root.maxItemsPerFeedField.set(value);
        }
      }
    }
  }

  // Show Only Unread
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.showOnlyUnread", "Show Only Unread") || "Show Only Unread"
      description: pluginApi?.tr("settings.showOnlyUnreadDesc", "Display only unread items in the panel") || "Display only unread items in the panel"
    }

    NPluginSettingsField {
      field: root.showOnlyUnreadField
      NToggle {
        checked: showOnlyUnread
        onToggled: checked => {
          root.showOnlyUnreadField.set(checked);
        }
      }
    }
  }

  // Mark as Read on Click
  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: pluginApi?.tr("settings.markOnClick", "Mark as Read on Click") || "Mark as Read on Click"
      description: pluginApi?.tr("settings.markOnClickDesc", "Automatically mark items as read when opening them") || "Automatically mark items as read when opening them"
    }

    NPluginSettingsField {
      field: root.markAsReadOnClickField
      NToggle {
        checked: markAsReadOnClick
        onToggled: checked => {
          root.markAsReadOnClickField.set(checked);
        }
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    height: 1
    color: AtmoColor.mOutline
  }

  // Feeds Management
  Text {
    text: pluginApi?.tr("settings.feeds", "RSS Feeds") || "RSS Feeds"
    font.pixelSize: Style.fontSizeL
    font.bold: true
    color: AtmoColor.mOnSurface
  }

  // Add New Feed
  NPluginSettingsField {
    field: root.feedsField
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      Text {
        text: pluginApi?.tr("settings.addFeed", "Add New Feed") || "Add New Feed"
        font.bold: true
        color: AtmoColor.mOnSurface
        font.pixelSize: Style.fontSizeM
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4

          Text {
            text: pluginApi?.tr("settings.feedName", "Feed Name") || "Feed Name"
            font.pixelSize: Style.fontSizeS
            color: AtmoColor.mOnSurfaceVariant
          }

          NTextInput {
            Layout.fillWidth: true
            placeholderText: "Example Blog"
            text: newFeedName
            onTextChanged: newFeedName = text
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4

          Text {
            text: pluginApi?.tr("settings.feedUrl", "Feed URL") || "Feed URL"
            font.pixelSize: Style.fontSizeS
            color: AtmoColor.mOnSurfaceVariant
          }

          NTextInput {
            Layout.fillWidth: true
            placeholderText: "https://example.com/feed.xml"
            text: newFeedUrl
            onTextChanged: newFeedUrl = text
          }
        }

        NButton {
          text: pluginApi?.tr("settings.add", "Add") || "Add"
          enabled: newFeedName.trim() !== "" && newFeedUrl.trim() !== ""
          onClicked: addFeed()
        }
      }
    }

    // Feed List
    ScrollView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.preferredHeight: 300
      clip: true

      ListView {
        model: feeds
        spacing: Style.marginS

        delegate: Rectangle {
          required property var modelData
          required property int index

          width: ListView.view.width
          height: feedItemLayout.implicitHeight + 16
          color: AtmoColor.mSurfaceVariant
          radius: Style.radiusM

          RowLayout {
            id: feedItemLayout
            anchors.fill: parent
            anchors.margins: 12
            spacing: Style.marginM

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 4

              Text {
                text: modelData.name
                font.pixelSize: Style.fontSizeM
                font.bold: true
                color: AtmoColor.mOnSurface
                Layout.fillWidth: true
              }

              Text {
                text: modelData.url
                font.pixelSize: Style.fontSizeS
                color: AtmoColor.mOnSurfaceVariant
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            NButton {
              text: pluginApi?.tr("settings.remove", "Remove") || "Remove"
              onClicked: removeFeed(index)
            }
          }
        }

        Text {
          visible: feeds.length === 0
          anchors.centerIn: parent
          text: pluginApi?.tr("settings.noFeeds", "No feeds configured. Add one above!") || "No feeds configured. Add one above!"
          font.pixelSize: Style.fontSizeM
          color: AtmoColor.mOnSurfaceVariant
        }
      }
    }
  }
}
