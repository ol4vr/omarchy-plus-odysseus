import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.ol4vr.odysseus"
  property string modelState: "unknown"
  readonly property string controlPath: decodeURIComponent(Qt.resolvedUrl("scripts/control").toString().replace(/^file:\/\//, ""))

  function runAction(name) {
    if (action.running) return
    action.command = ["bash", root.controlPath, name]
    action.running = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: poll
    command: ["systemctl", "show", "omarchy-plus-odysseus.service", "--property=ActiveState", "--value"]
    stdout: StdioCollector {
      onStreamFinished: root.modelState = text.trim() || "unknown"
    }
  }
  Process {
    id: action
    onExited: { if (!poll.running) poll.running = true }
  }
  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: { if (!poll.running) poll.running = true }
  }
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰚩 AI" + (action.running || root.modelState === "activating" ? " …" : root.modelState === "active" ? " ●" : "")
    horizontalMargin: 8.75
    verticalPadding: 8.75
    tooltipText: "Odysseus · " + root.modelState + "\nLeft click: start AI and open workspace\nRight click: stop AI and release VRAM"
    onPressed: function(b) {
      if (b === Qt.RightButton) root.runAction("stop")
      else if (b === Qt.LeftButton) root.runAction("open")
    }
  }
}
