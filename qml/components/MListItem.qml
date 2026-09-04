// MListItem — a selectable row with title, subtitle and trailing content.
import QtQuick
import QtQuick.Layouts
import MatrixManager.Theme

Rectangle {
    id: listItem

    property string title: ""
    property string subtitle: ""
    property bool selected: false
    // Optional trailing content, provided as a Component by the caller.
    property alias trailing: trailingLoader.sourceComponent
    signal clicked()

    implicitWidth: 300
    implicitHeight: Math.max(Theme.listItemHeight, content.implicitHeight + Theme.spacingSM * 2)
    color: selected ? Theme.surfaceElevated
         : mouse.containsMouse ? Theme.surfaceSunken
         : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacingMD
        anchors.rightMargin: Theme.spacingMD
        spacing: Theme.spacingMD

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            Text {
                text: listItem.title
                font.pixelSize: Theme.fontSizeLG
                color: Theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: listItem.subtitle
                font.pixelSize: Theme.fontSizeSM
                font.family: Theme.monoFamily
                color: Theme.textMuted
                visible: text !== ""
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }

        Loader {
            id: trailingLoader
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: listItem.clicked()
    }
}
