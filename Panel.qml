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
  readonly property string statusLabel: busy ? "WORKING" : active ? "READY" : modelState === "failed" ? "FAILED" : modelState === "inactive" ? "OFF" : "UNKNOWN"
  readonly property color blueTone: "#7AA2F7"
  readonly property color greenTone: "#8FCB9B"
  readonly property color amberTone: "#E0AF68"
  readonly property color redTone: "#F7768E"
  readonly property color statusTone: busy ? amberTone : active ? greenTone : modelState === "failed" ? redTone : blueTone
  function tint(tone, opacity) { return Qt.rgba(tone.r, tone.g, tone.b, opacity) }
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
            text: "󰚩  ODYSSEUS"
            color: root.blueTone
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            font.letterSpacing: 2
            font.bold: true
          }
          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: (root.busy ? "󱎫  " : root.active ? "󰄬  " : "󰐥  ") + root.statusLabel
            color: root.statusTone
            font.family: root.contentFontFamily
            font.pixelSize: 32
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
              color: root.statusTone
            }
          }
          Button {
            width: parent.width
            text: "󰍡  Open chat"
            enabled: !root.busy
            fontFamily: root.contentFontFamily
            foreground: root.contentForeground
            accent: Color.accent
            onClicked: root.act("open")
          }
          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "Loads the model if needed, then opens your browser."
            color: Qt.darker(root.contentForeground, 1.6)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }
          PanelSeparator { foreground: root.contentForeground }
          Row {
            width: parent.width
            spacing: Style.space(8)
            Repeater {
              model: [{label: "GPU", value: "4090", icon: "󰢮", tone: root.greenTone}, {label: "Context", value: "20k", icon: "󰍡", tone: root.blueTone}, {label: "Format", value: "Q4_K_M", icon: "󰆼", tone: root.amberTone}]
              Rectangle {
                required property var modelData
                width: (parent.width - Style.space(16)) / 3
                height: statColumn.implicitHeight + Style.space(20)
                color: root.tint(modelData.tone, 0.07)
                border.color: root.tint(modelData.tone, 0.22)
                border.width: 1
                radius: Style.cornerRadius
                Column {
                  id: statColumn
                  anchors.centerIn: parent
                  spacing: Style.space(2)
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.icon
                    color: modelData.tone
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.title
                  }
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.value
                    color: modelData.tone
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
              text: "󰒓  CONTROLS"
              foreground: root.blueTone
              fontFamily: root.contentFontFamily
            }
            Toggle {
              width: parent.width
              label: "󰐥  Keep model loaded"
              description: root.busy ? "Please wait…" : root.active ? "Switch off to free GPU memory" : "Switch on to get ready to chat"
              checked: root.active
              enabled: !root.busy
              foreground: root.contentForeground
              accent: root.greenTone
              fontFamily: root.contentFontFamily
              onClicked: root.act(root.active ? "stop" : "start")
            }
            Toggle {
              width: parent.width
              label: "󰖟  Open chat when loading"
              description: "Also open the browser when you switch on"
              checked: root.hostWidget ? root.hostWidget.openAfterStart : true
              enabled: !root.busy
              foreground: root.contentForeground
              accent: root.blueTone
              fontFamily: root.contentFontFamily
              onClicked: root.act(root.hostWidget.openAfterStart ? "auto-open-off" : "auto-open-on")
            }
          }
          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "Closing chat keeps the model loaded. Switch it off here to free GPU memory. It stays off at boot."
            color: Qt.darker(root.contentForeground, 1.6)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
