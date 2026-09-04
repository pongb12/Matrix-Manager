// MSearchField — search input with clear action.
import QtQuick
import QtQuick.Controls.Basic
import MatrixManager.Theme

TextField {
    id: field

    implicitHeight: Theme.controlHeight
    implicitWidth: 220
    selectByMouse: true
    font.pixelSize: Theme.fontSizeMD
    color: Theme.textPrimary
    placeholderTextColor: Theme.textMuted

    background: Rectangle {
        radius: Theme.radiusMD
        color: Theme.surface
        border.width: field.activeFocus ? Theme.focusWidth : Theme.borderWidth
        border.color: field.activeFocus ? Theme.focus : Theme.border
    }

    MIconButton {
        id: clearButton
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingXS + 2
        anchors.verticalCenter: parent.verticalCenter
        glyph: "✕"
        tooltip: qsTr("Clear")
        visible: field.text !== ""
        onClicked: {
            field.text = ""
            field.forceActiveFocus()
        }
    }

    rightPadding: clearButton.visible ? clearButton.width + Theme.spacingSM : Theme.spacingMD
}
