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
    // See MButton: zero vertical padding so the RowLayout keeps the full
    // height and centres its children instead of sagging past the border.
    topPadding: 0
    bottomPadding: 0
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    // Inverted ink for surfaces above the dim layer (guided tour floating
    // cards): uses the Theme overlay tokens, which in dark mode equal the
    // normal ones and in light mode flip to light ink.
    property bool inverted: false

    scale: control.pressed ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }

    contentItem: RowLayout {
        spacing: Theme.spacingSM

        MIcon {
            name: control.iconName
            visible: control.iconName !== ""
            size: 15
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: control.text
            font.pixelSize: Theme.fontSizeLG
            color: !control.enabled ? Theme.textMuted
                 : control.inverted ? Theme.overlayText
                 : Theme.textPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    background: Rectangle {
        radius: Theme.radiusMD
        color: !control.enabled ? "transparent"
             : control.pressed ? Theme.surfaceSunken
             : control.hovered ? (control.inverted ? Theme.overlayHover
                                                   : Theme.surfaceElevated)
             : "transparent"
        border.width: control.visualFocus ? Theme.focusWidth : Theme.borderWidth
        border.color: control.visualFocus ? Theme.focus
                    : control.inverted ? Theme.overlayTextMuted
                    : control.enabled ? Theme.borderStrong
                    : Theme.border

        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }
}
