// MConfirmationDialog — explicit confirmation for destructive operations.
// Always shows action, target, size and consequence (AGENT.md rule 7,
// DOC.md rule 26). Never a vague "Are you sure?".
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import QtQuick.Layouts
import MatrixManager.Theme

Dialog {
    id: dialog

    property string message: ""
    property var rows: []            // [{label, value}]
    property string consequence: ""
    property string confirmText: qsTr("Confirm")
    property bool danger: true

    modal: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(480, Overlay.overlay ? Overlay.overlay.width - 48 : 480)
    padding: 0

    background: Rectangle {
        color: Theme.surfaceElevated
        radius: Theme.radiusLG
        border.width: Theme.borderWidth
        border.color: Theme.border
    }

    contentItem: ColumnLayout {
        spacing: Theme.spacingMD

        // Title
        Text {
            text: dialog.title
            font.pixelSize: Theme.fontSizeXL
            font.weight: Font.DemiBold
            color: dialog.danger ? Theme.danger : Theme.textPrimary
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingLG
            Layout.rightMargin: Theme.spacingLG
            Layout.topMargin: Theme.spacingLG
            wrapMode: Text.WordWrap
        }

        Text {
            text: dialog.message
            font.pixelSize: Theme.fontSizeLG
            color: Theme.textSecondary
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingLG
            Layout.rightMargin: Theme.spacingLG
            wrapMode: Text.WordWrap
            visible: text !== ""
        }

        // Target rows: what exactly will be affected.
        ColumnLayout {
            spacing: Theme.spacingXS
            visible: dialog.rows.length > 0
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingLG
            Layout.rightMargin: Theme.spacingLG

            Repeater {
                model: dialog.rows

                RowLayout {
                    required property var modelData
                    spacing: Theme.spacingSM
                    Layout.fillWidth: true

                    Text {
                        text: modelData.label
                        font.pixelSize: Theme.fontSizeMD
                        color: Theme.textMuted
                        Layout.preferredWidth: 120
                        elide: Text.ElideRight
                    }
                    Text {
                        text: modelData.value
                        font.pixelSize: Theme.fontSizeMD
                        font.family: Theme.monoFamily
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingLG
            Layout.rightMargin: Theme.spacingLG
            height: 1
            color: Theme.border
            visible: dialog.consequence !== ""
        }

        // Consequence: what happens when confirmed.
        Text {
            text: dialog.consequence
            font.pixelSize: Theme.fontSizeMD
            color: dialog.danger ? Theme.danger : Theme.textSecondary
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingLG
            Layout.rightMargin: Theme.spacingLG
            wrapMode: Text.WordWrap
            visible: text !== ""
        }

        // Footer actions
        RowLayout {
            spacing: Theme.spacingSM
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacingLG
            Layout.rightMargin: Theme.spacingLG
            Layout.bottomMargin: Theme.spacingLG
            Layout.topMargin: Theme.spacingSM

            Item { Layout.fillWidth: true; height: 1 }

            MSecondaryButton {
                text: qsTr("Cancel")
                onClicked: dialog.reject()
            }
            Loader {
                sourceComponent: dialog.danger ? confirmDanger : confirmPrimary
            }
        }
    }

    Component {
        id: confirmDanger
        MDestructiveButton {
            text: dialog.confirmText
            onClicked: dialog.accept()
        }
    }
    Component {
        id: confirmPrimary
        MButton {
            text: dialog.confirmText
            onClicked: dialog.accept()
        }
    }
}
