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

  readonly property string statusLabel: busy ? "Working" : modelState === "active" ? "Ready" : modelState === "inactive" ? "Off" : modelState === "failed" ? "Failed" : "Checking"
  readonly property color statusTone: busy ? "#E0AF68" : modelState === "active" ? "#8FCB9B" : modelState === "failed" ? "#F7768E" : "#7AA2F7"

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
    tooltipText: ""
    foreground: root.statusTone
    property bool aiTooltipReady: false

    HoverHandler {
      id: aiTooltipHover
      onHoveredChanged: {
        if (hovered) aiTooltipDelay.restart()
        else {
          aiTooltipDelay.stop()
          button.aiTooltipReady = false
        }
      }
    }

    Timer {
      id: aiTooltipDelay
      interval: 500
      onTriggered: button.aiTooltipReady = aiTooltipHover.hovered
    }

    PopupWindow {
      id: aiTooltipWindow

      visible: button.aiTooltipReady && !root.opened
      color: "transparent"
      implicitWidth: Math.ceil(aiTooltipBubble.implicitWidth)
      implicitHeight: Math.ceil(aiTooltipBubble.implicitHeight)

      anchor {
        id: aiTooltipAnchor
        window: button.QsWindow.window
        adjustment: PopupAdjustment.Slide
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        rect.width: 1
        rect.height: 1

        onAnchoring: {
          var window = button.QsWindow.window
          if (!window || !root.bar) return

          var popupWidth = aiTooltipWindow.implicitWidth
          var popupHeight = aiTooltipWindow.implicitHeight
          var localX = button.width / 2 - popupWidth / 2
          var localY = button.height + 6

          if (root.bar.position === "bottom") {
            localY = -popupHeight - 6
          } else if (root.bar.position === "left") {
            localX = button.width + 6
            localY = button.height / 2 - popupHeight / 2
          } else if (root.bar.position === "right") {
            localX = -popupWidth - 6
            localY = button.height / 2 - popupHeight / 2
          }

          var point = window.contentItem.mapFromItem(button, localX, localY)
          aiTooltipAnchor.rect.x = Math.round(point.x)
          aiTooltipAnchor.rect.y = Math.round(point.y)
        }
      }

      Rectangle {
        id: aiTooltipBubble
        anchors.fill: parent
        implicitWidth: aiTooltipContent.implicitWidth + 20
        implicitHeight: aiTooltipContent.implicitHeight + 14
        color: root.bar ? root.bar.background : "#1A1B26"
        border.color: Qt.rgba(root.statusTone.r, root.statusTone.g, root.statusTone.b, 0.35)
        border.width: 1
        radius: 0

        Column {
          id: aiTooltipContent
          anchors.centerIn: parent
          spacing: Style.space(6)
          Row {
            spacing: Style.space(12)
            Text {
              text: "󰚩  ODYSSEUS"
              color: "#7AA2F7"
              font.family: button.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }
            Text {
              text: "● " + root.statusLabel
              color: root.statusTone
              font.family: button.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }
          }
          Text {
            text: root.modelState === "active" ? "Qwen3-14B · loaded on your GPU" : root.modelState === "inactive" ? "Model unloaded · GPU memory released" : root.busy ? "Please wait for the current action" : "Open controls to check model status"
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: button.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
          Rectangle {
            width: Style.space(260)
            height: 1
            color: Qt.rgba(0.48, 0.64, 0.97, 0.2)
          }
          Text {
            text: "Left click  ·  Controls\nRight click  ·  Unload model"
            color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.foreground
            font.family: button.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
      }
    }

    onPressed: function(b) {
      if (b === Qt.RightButton) root.runAction("stop")
      else if (b === Qt.LeftButton && panelLoader.item) panelLoader.item.toggle()
    }
  }
}
