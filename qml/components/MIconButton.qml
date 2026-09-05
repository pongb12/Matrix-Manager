// MIconButton — compact icon-only button. Always provide a tooltip;
// icons alone must not carry essential meaning (AGENT.md rule 18).
// `icon` renders an MIcon by name; `glyph` stays as a text fallback.
import QtQuick
import QtQuick.Controls.Basic
import MatrixManager.Theme

Button {
    id: control

    property alias glyph: label.text
    property string iconName: ""
    property string tooltip: ""

    implicitWidth: Theme.controlHeightSmall
    implicitHeight: Theme.controlHeightSmall
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    scale: control.pressed ? 0.92 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }

    contentItem: Item {
        implicitWidth: iconImage.visible ? iconImage.width : label.implicitWidth
        implicitHeight: Math.max(iconImage.height, label.implicitHeight)

        MIcon {
            id: iconImage
            anchors.centerIn: parent
            name: control.iconName
            visible: control.iconName !== ""
            size: 16
        }

        Text {
            id: label
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeLG
            font.family: Theme.monoFamily
            color: control.enabled ? Theme.textSecondary : Theme.textMuted
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            visible: control.iconName === ""
        }
    }

    background: Rectangle {
        radius: Theme.radiusMD
        color: !control.enabled ? "transparent"
             : control.pressed ? Theme.surfaceSunken
             : control.hovered ? Theme.surfaceElevated
             : "transparent"
        border.width: control.visualFocus ? Theme.focusWidth : 0
        border.color: Theme.focus

        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    ToolTip.visible: tooltip !== "" && hovered
    ToolTip.delay: 500
    ToolTip.text: tooltip
}
