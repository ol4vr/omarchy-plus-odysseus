import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.ol4vr.odysseus"
  property string modelState: "unknown"
  property bool openAfterStart: true
  readonly property bool busy: action.running || modelState === "activating" || modelState === "deactivating"
  readonly property string controlPath: decodeURIComponent(Qt.resolvedUrl("scripts/control").toString().replace(/^file:\/\//, ""))

  function runAction(name) {
    if (action.running) return
    action.command = ["bash", root.controlPath, name]
    action.running = true
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  readonly property real openPanelIndicatorWidth: button.labelWidth
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))
  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.settings = root.settings
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
  }
  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: poll
    command: ["bash", root.controlPath, "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var state = JSON.parse(text)
          root.modelState = state.state
          root.openAfterStart = state.open_after_start === true
        } catch (e) { root.modelState = "unknown" }
      }
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
    text: "󰚩 AI" + (root.busy ? " …" : root.modelState === "active" ? " ●" : "")
    horizontalMargin: 8.75
    verticalPadding: 8.75
    tooltipText: "Odysseus · " + root.modelState + "\nLeft click: controls\nRight click: stop AI and release VRAM"
    onPressed: function(b) {
      if (b === Qt.RightButton) root.runAction("stop")
      else if (b === Qt.LeftButton && panelLoader.item) panelLoader.item.toggle()
    }
  }
}
