// MIconButton — compact icon-only button. Always provide a tooltip;
// icons alone must not carry essential meaning (AGENT.md rule 18).
import QtQuick
import QtQuick.Controls.Basic
import MatrixManager.Theme

Button {
    id: control

    property alias glyph: label.text
    property string tooltip: ""

    implicitWidth: Theme.controlHeightSmall
    implicitHeight: Theme.controlHeightSmall
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    contentItem: Text {
        id: label
        font.pixelSize: Theme.fontSizeLG
        font.family: Theme.monoFamily
        color: control.enabled ? Theme.textSecondary : Theme.textMuted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: Theme.radiusMD
        color: !control.enabled ? "transparent"
             : control.pressed ? Theme.surfaceSunken
             : control.hovered ? Theme.surfaceElevated
             : "transparent"
        border.width: control.visualFocus ? Theme.focusWidth : 0
        border.color: Theme.focus
    }

    ToolTip.visible: tooltip !== "" && hovered
    ToolTip.delay: 500
    ToolTip.text: tooltip
}
