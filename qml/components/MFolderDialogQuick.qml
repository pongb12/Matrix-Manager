// MFolderDialogQuick — pure-QML folder picker (QtQuick.Dialogs.FolderDialog,
// available since Qt 6.3). Selected via MFolderDialog on Qt 6.3+.
// MFolderDialog reads chosenPath on accepted and converts the URL.
import QtQuick
import QtQuick.Dialogs

FolderDialog {
    id: dialog

    property string chosenPath: ""

    onAccepted: dialog.chosenPath = dialog.selectedFolder.toString()
}
