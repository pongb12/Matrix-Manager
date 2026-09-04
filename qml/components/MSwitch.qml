// MSwitch — minimal switch for settings.
import QtQuick
import QtQuick.Controls.Basic
import MatrixManager.Theme

Switch {
    id: control

    implicitHeight: Theme.controlHeight
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    indicator: Rectangle {
        implicitWidth: 38
        implicitHeight: 20
        x: 0
        y: control.height / 2 - height / 2
        radius: height / 2
        color: control.checked ? Theme.accent : Theme.surfaceSunken
        border.width: control.visualFocus ? Theme.focusWidth : Theme.borderWidth
        border.color: control.visualFocus ? Theme.focus
                    : control.checked ? Theme.accent
                    : Theme.borderStrong

        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

        Rectangle {
            x: control.checked ? parent.width - width - 2 : 2
            y: (parent.height - height) / 2
            width: 16
            height: 16
            radius: width / 2
            color: control.enabled ? "#FFFFFF" : Theme.textMuted

            Behavior on x { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }
        }
    }

    contentItem: Text {
        text: control.text
        font.pixelSize: Theme.fontSizeLG
        color: Theme.textPrimary
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + Theme.spacingMD
    }
}
