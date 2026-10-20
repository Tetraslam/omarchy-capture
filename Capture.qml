// Quick capture: one key, type a thought, Enter, and it's at the top of a
// note in your vault. Tab cycles where it goes. Nothing else to look at.
//
// Targets come from ~/.config/omarchy-capture/config.json:
//   { "targets": [ { "label": "todo",  "file": "~/vault/inbox/todo.md",  "format": "task" },
//                  { "label": "notes", "file": "~/vault/inbox/notes.md", "format": "line" } ] }

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool shown: false
  property int target: 0
  readonly property string home: Quickshell.env("HOME")
  readonly property string scriptPath: String(Qt.resolvedUrl("capture.py")).replace("file://", "")

  readonly property var defaultTargets: [
    { label: "todo", file: "~/Documents/tetrawiki/tetrawiki/0-inbox/todo.md", format: "task" },
    { label: "notes", file: "~/Documents/tetrawiki/tetrawiki/0-inbox/notes.md", format: "line" }
  ]
  // Parsed when the file (re)loads: FileView reads asynchronously, so a
  // binding on text() would only ever see the empty file at startup.
  property var targets: defaultTargets

  function loadTargets() {
    try {
      var parsed = JSON.parse(configFile.text())
      if (parsed && Array.isArray(parsed.targets) && parsed.targets.length > 0) {
        targets = parsed.targets
        return
      }
    } catch (error) {}
    targets = defaultTargets
  }

  FileView {
    id: configFile
    path: root.home + "/.config/omarchy-capture/config.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.loadTargets()
    onLoadFailed: root.targets = root.defaultTargets
  }

  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
  function expand(path) { return String(path).replace(/^~(?=\/|$)/, home) }

  function open() {
    if (shown) return
    // Always start on the first target, so a Tab from last time can't send
    // this capture somewhere unexpected.
    target = 0
    input.text = ""
    shown = true
  }
  function close() { shown = false }
  function toggle() { shown ? close() : open() }

  function save() {
    var text = input.text.trim()
    var t = targets[target] || targets[0]
    close()
    if (text === "" || !t) return
    Quickshell.execDetached(["python3", "-I", scriptPath, expand(t.file), t.format === "task" ? "task" : "line", text])
  }

  GlobalShortcut {
    appid: "capture"
    name: "toggle"
    description: "Quick capture"
    onPressed: root.toggle()
  }

  IpcHandler {
    target: "capture"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  readonly property color fg: Color.menu.text
  readonly property color dim: Qt.darker(fg, 1.5)

  PanelWindow {
    id: surface
    visible: root.shown
    screen: {
      var name = Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name || "") : ""
      for (var i = 0; i < Quickshell.screens.length; i++) if (Quickshell.screens[i].name === name) return Quickshell.screens[i]
      return Quickshell.screens[0]
    }
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "capture"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: if (visible) input.forceActiveFocus()

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
      MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      y: parent.height * 0.22
      width: Math.min(parent.width * 0.6, Style.space(620))
      height: Style.space(56)
      radius: Style.space(12)
      color: Color.menu.background
      border.width: Math.max(1, Style.space(1))
      border.color: root.alpha(Color.menu.border, 0.35)

      MouseArea { anchors.fill: parent }

      Row {
        id: chips
        anchors.left: parent.left
        anchors.leftMargin: Style.space(12)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(4)

        Repeater {
          model: root.targets

          Rectangle {
            required property var modelData
            required property int index
            readonly property bool current: index === root.target
            width: chipText.implicitWidth + Style.space(16)
            height: Style.space(26)
            radius: Style.space(6)
            color: current ? Color.menu.selectedBackground : "transparent"
            border.width: current ? 0 : Math.max(1, Style.space(1))
            border.color: root.alpha(root.fg, 0.12)

            Text {
              id: chipText
              anchors.centerIn: parent
              text: (modelData.format === "task" ? "☐ " : "¶ ") + modelData.label
              color: parent.current ? Color.menu.selectedText : root.dim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              anchors.fill: parent
              onClicked: { root.target = parent.index; input.forceActiveFocus() }
            }
          }
        }
      }

      TextInput {
        id: input
        anchors.left: chips.right
        anchors.leftMargin: Style.space(12)
        anchors.right: parent.right
        anchors.rightMargin: Style.space(14)
        anchors.verticalCenter: parent.verticalCenter
        color: root.fg
        selectionColor: root.alpha(root.fg, 0.3)
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        clip: true
        focus: true

        Text {
          visible: input.text === ""
          text: "Capture…   ⇥ switch   ↵ save"
          color: root.dim
          font: input.font
        }

        Keys.onPressed: function(event) {
          var k = event.key
          if (k === Qt.Key_Escape) root.close()
          else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.save()
          else if (k === Qt.Key_Tab) root.target = (root.target + 1) % root.targets.length
          else if (k === Qt.Key_Backtab) root.target = (root.target - 1 + root.targets.length) % root.targets.length
          else return
          event.accepted = true
        }
      }
    }
  }
}
