// MBadge — small status label. Status is communicated by text and colour,
// never colour alone (MM-091 accessibility).
import QtQuick
import MatrixManager.Theme

Rectangle {
    id: badge

    property string text: ""
    // neutral | success | warning | danger | accent
    property string tone: "neutral"

    readonly property color toneColor:
        tone === "success" ? Theme.success
      : tone === "warning" ? Theme.warning
      : tone === "danger"  ? Theme.danger
      : tone === "accent"  ? Theme.accent
      : Theme.textSecondary

    implicitWidth: label.implicitWidth + Theme.spacingMD * 2
    implicitHeight: Theme.controlHeightSmall - 6
    radius: height / 2
    color: Qt.rgba(toneColor.r, toneColor.g, toneColor.b, 0.14)
    border.width: 0

    Text {
        id: label
        anchors.centerIn: parent
        text: badge.text
        font.pixelSize: Theme.fontSizeXS
        font.weight: Font.Medium
        color: badge.toneColor
    }
}
