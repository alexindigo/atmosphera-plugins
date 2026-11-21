import QtQuick
import Quickshell.Io

Item {
  id: root

  property var pluginApi: null
  property var windowApi: null
  readonly property bool windowCurrent: windowApi?.settingsContext.current() ?? false

  onWindowCurrentChanged: if (windowApi && !windowCurrent) {
                            var retired = windowApi;
                            windowLoader.active = false;
                            Qt.callLater(function () {
                              if (root.windowApi === retired)
                                root.windowApi = null;
                            });
                          }

  function hide() {
    if (windowLoader.item)
      windowLoader.item.close();
    else
      windowLoader.active = false;
  }
  function show(caller, screen) {
    caller = caller || pluginApi;
    if (windowLoader.active || !caller?.settingsContext.current())
      return;
    windowApi = caller;
    windowLoader.setSource("Wallcards.qml", {
                             "pluginApi": caller,
                             "screenRef": screen || caller.panelOpenScreen
                           });
    windowLoader.active = true;
  }
  function toggle(caller, screen) {
    if (windowLoader.active)
      hide();
    else
      show(caller, screen);
  }

  Loader {
    id: windowLoader

    active: false

    Connections {
      function onQuitRequested() {
        windowLoader.active = false;
        root.windowApi = null;
      }

      target: windowLoader.item
    }
  }
  IpcHandler {
    function hide() {
      root.hide();
    }
    function show() {
      root.show(root.pluginApi);
    }
    function toggle() {
      root.toggle(root.pluginApi);
    }

    target: "plugin:wallcards"
  }
}
