import QtQuick
import Quickshell.Io
import qs.Commons

// Scalar query inputs are captured at generation creation. Replaced workers
// stop their processes and cannot attach old results to a new selected source.
Item {
  id: root
  required property var pluginApi
  required property bool fortuneEnabled
  required property bool fortuneOffensive
  required property bool fortuneEqual
  required property string fortuneCategory
  required property int fortuneMaxLength
  required property bool listEnabled
  required property string textFile
  property bool active: true
  property string fortuneText: ""
  property string listText: ""
  property int _retries: 0
  readonly property int _maxRetries: 10
  readonly property string _examplesPath: Qt.resolvedUrl("examples.txt").toString().replace(/^file:\/\//, "")
  readonly property string _activePath: textFile.trim().length > 0 ? textFile.trim() : _examplesPath
  Process {
    id: fortuneProcess
    command: {
      var cmd = ["fortune", "-s"];
      if (root.fortuneOffensive) cmd.push("-o");
      if (root.fortuneEqual) cmd.push("-e");
      if (root.fortuneCategory.trim().length > 0) cmd.push(root.fortuneCategory.trim());
      return cmd;
    }
    stdout: StdioCollector {}
    onExited: exitCode => {
      if (!root.active) return;
      if (exitCode === 127) {
        Logger.e("NotJustText", "fortune is not installed - install it to use fortune mode");
        root.fortuneText = root.pluginApi?.tr("fortune.notInstalled") ?? "";
        return;
      }
      if (exitCode !== 0) Logger.w("NotJustText", "fortune exited with code", exitCode);
      var lines = stdout.text.trim().split('\n').filter(line => line.trim().length > 0);
      if (lines.length === 1 && lines[0].length <= root.fortuneMaxLength) {
        root.fortuneText = lines[0].trim();
        root._retries = 0;
      } else if (root._retries < root._maxRetries) {
        root._retries++;
        Qt.callLater(root.triggerFortune);
      } else {
        Logger.w("NotJustText", "Gave up after", root._maxRetries, "retries finding a short single-line fortune");
        root.fortuneText = root.pluginApi?.tr("fortune.gaveUp") ?? "";
        root._retries = 0;
      }
    }
  }
  Process {
    id: textFileProcess
    command: ["cat", root._activePath]
    stdout: StdioCollector {}
    onExited: exitCode => {
      if (!root.active) return;
      if (exitCode !== 0) {
        Logger.w("NotJustText", "Could not read text file:", root._activePath);
        root.listText = "";
        return;
      }
      var lines = stdout.text.split('\n').filter(line => line.trim().length > 0 && !line.trim().startsWith('# '));
      root.listText = lines.length > 0 ? lines[Math.floor(Math.random() * lines.length)].trim() : "";
    }
  }
  function triggerFortune() {
    if (!active) return;
    fortuneProcess.running = false;
    fortuneProcess.running = true;
  }
  function pickFromFile() {
    if (!active) return;
    textFileProcess.running = false;
    textFileProcess.running = true;
  }
  onActiveChanged: {
    if (!active) { fortuneProcess.running = false; textFileProcess.running = false; }
  }
  Component.onCompleted: {
    if (fortuneEnabled) triggerFortune();
    if (listEnabled) pickFromFile();
  }
}
