import QtQml

// One admitted operation, not a live settings client or physical owner.
QtObject {
  required property var context
  required property var values
  required property var defaults
  required property int screenWidth
  required property int screenHeight
  required property bool luaMode
  readonly property bool current: context?.current() ?? false
  readonly property int gapSize: values.gapSize ?? defaults.gapSize ?? 10
  readonly property real topMarginPercent: values.topMarginPercent ?? defaults.topMarginPercent ?? 2.5
  readonly property real windowHeightPercent: values.windowHeightPercent ?? defaults.windowHeightPercent ?? 95
  readonly property real friendsWidthPercent: values.friendsWidthPercent ?? defaults.friendsWidthPercent ?? 10
  readonly property real mainWidthPercent: values.mainWidthPercent ?? defaults.mainWidthPercent ?? 60
  readonly property real chatWidthPercent: values.chatWidthPercent ?? defaults.chatWidthPercent ?? 25
  readonly property bool useCustomLayout: values.useCustomLayout ?? defaults.useCustomLayout ?? false
  readonly property int topMargin: Math.round(screenHeight * topMarginPercent / 100)
  readonly property int windowHeight: Math.round(screenHeight * windowHeightPercent / 100)
  readonly property int friendsWidth: Math.round(screenWidth * friendsWidthPercent / 100 - gapSize)
  readonly property int mainWidth: Math.round(screenWidth * mainWidthPercent / 100 - gapSize * 2)
  readonly property int chatWidth: Math.round(screenWidth * chatWidthPercent / 100 - gapSize)
  readonly property int centerOffset: Math.round((screenWidth - friendsWidth - gapSize - mainWidth - gapSize - chatWidth) / 2)
}
