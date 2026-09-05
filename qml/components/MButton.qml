// MButton — primary action button. Optional `icon` (MIcon name) is drawn
// with the on-accent ink; `text` stays the accessible label.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import MatrixManager.Theme

Button {
    id: control

    property string iconName: ""

    implicitHeight: Theme.controlHeight
    implicitWidth: Math.max(contentItem.implicitWidth + leftPadding + rightPadding, 96)
    leftPadding: Theme.spacingLG
    rightPadding: Theme.spacingLG
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
            tint: "onaccent"
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: control.text
            font.pixelSize: Theme.fontSizeLG
            font.weight: Font.Medium
            color: control.enabled ? Theme.onAccent : Theme.textMuted
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.fillWidth: true
        }
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
