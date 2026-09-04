// MSecondaryButton — low-emphasis action (outlined).
import QtQuick
import QtQuick.Controls.Basic
import MatrixManager.Theme

Button {
    id: control

    implicitHeight: Theme.controlHeight
    implicitWidth: Math.max(contentItem.implicitWidth + leftPadding + rightPadding, 80)
    leftPadding: Theme.spacingMD + Theme.spacingSM
    rightPadding: Theme.spacingMD + Theme.spacingSM
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    contentItem: Text {
        text: control.text
        font.pixelSize: Theme.fontSizeLG
        color: control.enabled ? Theme.textPrimary : Theme.textMuted
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: Theme.radiusMD
        color: !control.enabled ? "transparent"
             : control.pressed ? Theme.surfaceSunken
             : control.hovered ? Theme.surfaceElevated
             : "transparent"
        border.width: control.visualFocus ? Theme.focusWidth : Theme.borderWidth
        border.color: control.visualFocus ? Theme.focus
                    : control.enabled ? Theme.borderStrong
                    : Theme.border

        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }
}
