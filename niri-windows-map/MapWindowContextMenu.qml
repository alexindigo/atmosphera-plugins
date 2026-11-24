import QtQuick
import qs.Commons
import qs.Widgets

NPopupContextMenu {
  id: root
  property string windowId: ""

  // Emitted when a menu action navigates (Focus) — NOT for Close
  signal focusRequested(string windowId)
  signal closeRequested(string windowId)

  model: [
    { id: "focus", text: "Focus", icon: Icon.apps },
    { id: "close", text: "Close", icon: Icon.close }
  ]

  onTriggered: function (actionId, _item) {
    if (!root.windowId) return
    switch (actionId) {
    case "focus":
      root.focusRequested(root.windowId)
      break
    case "close":
      root.closeRequested(root.windowId)
      break
    }
  }
}
