import QtQuick

Loader {
  id: root

  required property bool useSharedDecoder
  required property string iconSource
  required property size sourceSize

  // Resolve the current renderer only on the current shell. Importing it
  // into the map's eager component graph would break the legacy shell.
  source: useSharedDecoder ? Qt.resolvedUrl("SharedMapFavicon.qml") : ""
  sourceComponent: useSharedDecoder ? undefined : legacy

  Binding {
    target: root.item
    property: "source"
    value: root.iconSource
  }

  Binding {
    target: root.item
    property: "sourceSize"
    value: root.sourceSize
  }

  Component {
    id: legacy

    Image {
      fillMode: Image.PreserveAspectFit
      smooth: true
      asynchronous: true
    }
  }
}
