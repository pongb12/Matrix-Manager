// MProgressBar — determinate/indeterminate progress with context label.
// Loading UI must explain what is happening (DOC.md rule 24).
import QtQuick
import MatrixManager.Theme

Rectangle {
    id: bar

    property real from: 0        // 0..1 when determinate
    property bool indeterminate: false
    property color fillColor: Theme.accent

    implicitWidth: 200
    implicitHeight: 6
    radius: height / 2
    color: Theme.surfaceSunken
    clip: true

    Rectangle {
        id: fill
        height: parent.height
        radius: parent.radius
        color: bar.fillColor
        width: bar.indeterminate ? parent.width * 0.25 : Math.max(0, Math.min(1, bar.from)) * parent.width
        x: bar.indeterminate ? -parent.width * 0.25 : 0

        SequentialAnimation on x {
            running: bar.indeterminate && bar.visible
            loops: Animation.Infinite

            NumberAnimation {
                from: -bar.width * 0.25
                to: bar.width
                duration: 900
                easing.type: Easing.InOutQuad
            }
        }
    }
}
