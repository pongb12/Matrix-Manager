// MSecondaryButton — low-emphasis action (outlined). Optional `icon`.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import MatrixManager.Theme

Button {
    id: control

    property string iconName: ""

    implicitHeight: Theme.controlHeight
    implicitWidth: Math.max(contentItem.implicitWidth + leftPadding + rightPadding, 80)
    leftPadding: Theme.spacingMD + Theme.spacingSM
    rightPadding: Theme.spacingMD + Theme.spacingSM
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    scale: control.pressed ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }

    contentItem: RowLayout {
        spacing: Theme.spacingSM

        MIcon {
            name: control.iconName
            visible: control.iconName !== ""
            size: 16
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: control.text
            font.pixelSize: Theme.fontSizeLG
            color: control.enabled ? Theme.textPrimary : Theme.textMuted
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.fillWidth: true
        }
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
