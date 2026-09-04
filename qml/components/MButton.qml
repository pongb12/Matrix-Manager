// MButton — primary action button.
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

    contentItem: Text {
        text: control.text
        font.pixelSize: Theme.fontSizeLG
        font.weight: Font.Medium
        color: control.enabled ? Theme.onAccent : Theme.textMuted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: Theme.radiusMD
        color: !control.enabled ? Theme.surfaceSunken
             : control.pressed ? Theme.accentPressed
             : control.hovered ? Theme.accentHover
             : Theme.accent
        border.width: control.visualFocus ? Theme.focusWidth : 0
        border.color: Theme.focus

        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }
}
