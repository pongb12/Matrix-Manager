// MSearchField — search input with leading search icon and clear action.
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

    MIcon {
        id: searchGlyph
        name: "search"
        size: 15
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingMD
        anchors.verticalCenter: parent.verticalCenter
        opacity: field.text === "" ? 0.9 : 0.6

        Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
    }

    MIconButton {
        id: clearButton
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingXS + 2
        anchors.verticalCenter: parent.verticalCenter
        iconName: "x"
        tooltip: qsTr("Clear")
        visible: field.text !== ""
        onClicked: {
            field.text = ""
            field.forceActiveFocus()
        }
    }

    leftPadding: searchGlyph.width + Theme.spacingMD + Theme.spacingXS
    rightPadding: clearButton.visible ? clearButton.width + Theme.spacingSM : Theme.spacingMD
}
