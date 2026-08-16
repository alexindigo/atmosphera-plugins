import QtQuick
import Quickshell
import qs.Widgets

AtmoIconButtonHot {
  property ShellScreen screen
  property var pluginApi: null

  icon: "noctalia"
  tooltipText: "Hello World"
  onClicked: {
    if (pluginApi) {
      pluginApi.togglePanel(screen, this);
    }
  }
}
