// MCheckBox — minimal checkbox used in the cleanup rule list.
import QtQuick
import QtQuick.Controls.Basic
import MatrixManager.Theme

CheckBox {
    id: control

    implicitHeight: Theme.controlHeight
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        x: 0
        y: control.height / 2 - height / 2
        radius: Theme.radiusSM
        color: control.checked ? Theme.accent : Theme.surface
        border.width: control.visualFocus ? Theme.focusWidth : Theme.borderWidth
        border.color: control.visualFocus ? Theme.focus
                    : control.checked ? Theme.accent
                    : Theme.borderStrong

        Text {
            anchors.centerIn: parent
            text: "✓"
            font.pixelSize: Theme.fontSizeMD
            color: Theme.onAccent
            visible: control.checked
        }
    }

    contentItem: Text {
        text: control.text
        font.pixelSize: Theme.fontSizeLG
        color: Theme.textPrimary
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + Theme.spacingSM
    }
}
