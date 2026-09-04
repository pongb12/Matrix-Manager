// MSegmented — compact segmented control for mutually exclusive options.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import MatrixManager.Theme

Rectangle {
    id: segmented

    property var model: []
    property int currentIndex: 0
    signal activated(int index)

    implicitWidth: row.implicitWidth + Theme.spacingXS * 2
    implicitHeight: Theme.controlHeightSmall + Theme.spacingXS * 2
    radius: Theme.radiusMD
    color: Theme.surfaceSunken
    border.width: Theme.borderWidth
    border.color: Theme.border

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: Theme.spacingXS
        spacing: Theme.spacingXS

        Repeater {
            model: segmented.model

            Button {
                id: segmentButton
                required property int index
                required property string modelData

                property bool selected: segmented.currentIndex === index

                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                Layout.fillHeight: true

                onClicked: {
                    segmented.currentIndex = index
                    segmented.activated(index)
                }

                contentItem: Text {
                    text: segmentButton.modelData
                    font.pixelSize: Theme.fontSizeSM
                    font.weight: segmentButton.selected ? Font.DemiBold : Font.Normal
                    color: segmentButton.selected ? Theme.accent
                         : segmentButton.hovered ? Theme.textPrimary
                         : Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: Theme.radiusSM
                    color: segmentButton.selected ? Theme.surface
                         : segmentButton.hovered ? Qt.darker(Theme.surface, 1.04)
                         : "transparent"
                    border.width: segmentButton.visualFocus ? Theme.focusWidth : 0
                    border.color: Theme.focus
                }
            }
        }
    }
}
