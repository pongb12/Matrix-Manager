// MToast — transient notification. Explains what happened, disappears
// automatically; used for operation results (success and error).
import QtQuick
import QtQuick.Layouts
import MatrixManager.Theme

Rectangle {
    id: toast

    property string text: ""
    property string tone: "neutral"   // neutral | success | danger

    readonly property color toneColor:
        tone === "success" ? Theme.success
      : tone === "danger"  ? Theme.danger
      : Theme.borderStrong

    implicitWidth: row.implicitWidth + Theme.spacingLG * 2
    implicitHeight: row.implicitHeight + Theme.spacingMD * 2
    radius: Theme.radiusMD
    color: Theme.surfaceElevated
    border.width: Theme.borderWidth
    border.color: Theme.border

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacingSM

        Rectangle {
            width: 3
            height: toastLabel.implicitHeight + Theme.spacingXS
            radius: 1.5
            color: toast.toneColor
        }
        Text {
            id: toastLabel
            text: toast.text
            font.pixelSize: Theme.fontSizeMD
            color: Theme.textPrimary
            elide: Text.ElideRight
            Layout.maximumWidth: 420
        }
    }
}
