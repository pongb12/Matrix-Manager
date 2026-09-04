// MErrorState — actionable error display (AGENT.md rule 19, DOC.md rule 25).
// Shows what failed, why, and offers a retry. Technical details can be
// expanded separately.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import MatrixManager.Theme

ColumnLayout {
    id: errorState

    property string title: qsTr("Operation failed")
    property string message: ""
    property string details: ""
    property bool detailsVisible: false
    signal retry()

    spacing: Theme.spacingSM

    Text {
        text: "!"
        font.pixelSize: Theme.fontSizeDisplay
        font.weight: Font.DemiBold
        font.family: Theme.monoFamily
        color: Theme.danger
        Layout.alignment: Qt.AlignHCenter
    }
    Text {
        text: errorState.title
        font.pixelSize: Theme.fontSizeXL
        font.weight: Font.DemiBold
        color: Theme.textPrimary
        Layout.alignment: Qt.AlignHCenter
    }
    Text {
        text: errorState.message
        font.pixelSize: Theme.fontSizeMD
        color: Theme.textSecondary
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        Layout.maximumWidth: 440
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }

    MSecondaryButton {
        text: errorState.detailsVisible
              ? qsTr("Hide technical details")
              : qsTr("Show technical details")
        visible: errorState.details !== ""
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spacingSM
        onClicked: errorState.detailsVisible = !errorState.detailsVisible
    }

    // Expanded technical details (collapsed by default).
    Rectangle {
        visible: errorState.detailsVisible && errorState.details !== ""
        Layout.fillWidth: true
        Layout.maximumWidth: 440
        Layout.preferredHeight: 120
        color: Theme.surfaceSunken
        radius: Theme.radiusMD
        border.width: Theme.borderWidth
        border.color: Theme.border

        ScrollView {
            anchors.fill: parent
            anchors.margins: Theme.spacingMD

            Text {
                text: errorState.details
                font.pixelSize: Theme.fontSizeSM
                font.family: Theme.monoFamily
                color: Theme.textSecondary
                wrapMode: Text.WrapAnywhere
            }
        }
    }

    MButton {
        text: qsTr("Retry")
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spacingSM
        onClicked: errorState.retry()
    }
}
