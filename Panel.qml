import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.ol4vr.odysseus"
  ipcTarget: "io.github.ol4vr.odysseus.panel"
  manageIpc: false
  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string modelState: hostWidget ? hostWidget.modelState : "unknown"
  readonly property bool busy: hostWidget ? hostWidget.busy : false
  readonly property bool active: modelState === "active"
  readonly property string statusLabel: busy ? "WORKING" : active ? "RUNNING" : modelState === "failed" ? "FAILED" : modelState === "inactive" ? "STOPPED" : "UNKNOWN"
  function act(name) { if (hostWidget && !busy) hostWidget.runAction(name) }
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }
  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)
    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "o" || t === "O") root.act("open")
        else if (t === "s" || t === "S") root.act(root.active ? "stop" : "start")
      }
      ScrollView {
        id: scrollArea
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: column.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        Binding {
          target: scrollArea.contentItem
          property: "interactive"
          value: column.implicitHeight > scrollArea.height
        }
        Column {
          id: column
          width: scrollArea.availableWidth
          spacing: Style.space(8)
          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "ODYSSEUS"
            color: Qt.darker(root.contentForeground, 1.4)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            font.letterSpacing: 2
            font.bold: true
          }
          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.statusLabel
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: 36
            font.bold: true
          }
          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Qwen3-14B · local chat"
            color: Qt.darker(root.contentForeground, 1.6)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
          }
          Rectangle {
            width: parent.width
            height: Style.space(6)
            radius: Style.cornerRadius > 0 ? height / 2 : 0
            color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
            Rectangle {
              width: root.active ? parent.width : parent.height
              height: parent.height
              radius: parent.radius
              color: Style.selectedStateColor(root.contentForeground, Color.accent)
            }
          }
          Row {
            width: parent.width
            spacing: Style.space(8)
            Button {
              width: (parent.width - parent.spacing) * 0.65
              text: "Open workspace"
              enabled: !root.busy
              fontFamily: root.contentFontFamily
              foreground: root.contentForeground
              accent: Color.accent
              onClicked: root.act("open")
            }
            Button {
              width: (parent.width - parent.spacing) * 0.35
              text: root.active ? "Stop AI" : "Start AI"
              enabled: !root.busy
              fontFamily: root.contentFontFamily
              foreground: root.contentForeground
              accent: Color.accent
              onClicked: root.act(root.active ? "stop" : "start")
            }
          }
          PanelSeparator { foreground: root.contentForeground }
          Row {
            width: parent.width
            spacing: Style.space(8)
            Repeater {
              model: [{label: "GPU", value: "4090"}, {label: "Context", value: "20k"}, {label: "Format", value: "Q4_K_M"}]
              Item {
                required property var modelData
                width: (parent.width - Style.space(16)) / 3
                height: statColumn.implicitHeight
                Column {
                  id: statColumn
                  anchors.centerIn: parent
                  spacing: Style.space(2)
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.value
                    color: root.contentForeground
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.title
                    font.bold: true
                  }
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.label
                    color: Qt.darker(root.contentForeground, 1.6)
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                  }
                }
              }
            }
          }
          PanelSeparator { foreground: root.contentForeground }
          Column {
            width: Math.min(parent.width, Style.space(300))
            x: Math.round((parent.width - width) / 2)
            spacing: Style.space(8)
            PanelSectionHeader {
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              text: "Controls"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }
            Toggle {
              width: parent.width
              label: "AI model"
              description: root.busy ? "Waiting for the current action" : root.active ? "Running on your GPU" : "Start only when you need it"
              checked: root.active
              enabled: !root.busy
              foreground: root.contentForeground
              accent: Color.accent
              fontFamily: root.contentFontFamily
              onClicked: root.act(root.active ? "stop" : "start")
            }
            Toggle {
              width: parent.width
              label: "Open workspace on start"
              description: "Open the browser when you turn AI on"
              checked: root.hostWidget ? root.hostWidget.openAfterStart : true
              enabled: !root.busy
              foreground: root.contentForeground
              accent: Color.accent
              fontFamily: root.contentFontFamily
              onClicked: root.act(root.hostWidget.openAfterStart ? "auto-open-off" : "auto-open-on")
            }
          }
          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "No model autostart · Stop AI to release VRAM"
            color: Qt.darker(root.contentForeground, 1.6)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
