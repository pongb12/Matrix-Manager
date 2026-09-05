// MFolderDialogLabs — native folder picker via Qt.labs.platform, used on
// Qt 6.2 only, where QtQuick.Dialogs has no FolderDialog yet. Requires a
// desktop session with a native dialog helper (standard on Mint/Ubuntu).
// MFolderDialog reads chosenPath on accepted and converts the URL.
import QtQuick
import Qt.labs.platform

FolderDialog {
    id: dialog

    property string chosenPath: ""

    onAccepted: dialog.chosenPath = dialog.folder.toString()
}
