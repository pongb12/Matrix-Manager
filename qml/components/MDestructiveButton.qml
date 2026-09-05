// MDestructiveButton — for actions that remove or clean data.
// Danger is communicated through colour, not noise (AGENT.md rule 17).
import QtQuick
import QtQuick.Controls.Basic
import MatrixManager.Theme

Button {
    id: control

    implicitHeight: Theme.controlHeight
    implicitWidth: Math.max(contentItem.implicitWidth + leftPadding + rightPadding, 96)
    leftPadding: Theme.spacingLG
    rightPadding: Theme.spacingLG
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    scale: control.pressed ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }

    contentItem: Text {
        text: control.text
        font.pixelSize: Theme.fontSizeLG
        font.weight: Font.Medium
        color: control.enabled ? "#FFFFFF" : Theme.textMuted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: Theme.radiusMD
        color: !control.enabled ? Theme.surfaceSunken
             : control.pressed ? Theme.dangerHover
             : control.hovered ? Theme.dangerHover
             : Theme.danger
        border.width: control.visualFocus ? Theme.focusWidth : 0
        border.color: Theme.focus

        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }
}
