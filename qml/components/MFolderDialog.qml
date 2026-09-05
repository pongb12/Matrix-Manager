// MFolderDialog — version-adaptive folder picker.
//
// QtQuick.Dialogs.FolderDialog exists only from Qt 6.3 onward, but this
// project supports Qt 6.2 (distro Qt on Mint 21). On 6.3+ the pure-QML
// implementation is used everywhere (also works offscreen); on Qt 6.2 the
// wrapper falls back to the native Qt.labs.platform dialog. Callers use
// open() and the acceptedPath(path) signal — the URL-to-path conversion
// is handled here.
import QtQuick
import MatrixManager.Core

Item {
    id: root

    property string title: ""
    signal acceptedPath(string path)

    readonly property bool _useQuickDialogs: {
        const parts = SystemInfo.qtVersion.split(".")
        const major = parts.length > 0 ? parseInt(parts[0], 10) : 0
        const minor = parts.length > 1 ? parseInt(parts[1], 10) : 0
        return major > 6 || (major === 6 && minor >= 3)
    }

    function urlToPath(url) {
        const s = url.toString()
        return s.indexOf("file://") === 0
            ? decodeURIComponent(s.substring(7)) : s
    }

    function open() {
        loader.item.open()
    }

    Loader {
        id: loader
        // Runtime URL on purpose: the implementation for the OTHER Qt
        // version must never be parsed. QtQuick.Dialogs has no FolderDialog
        // before 6.3, and Qt.labs.platform is deprecated after 6.2 — each
        // side only loads on the Qt range it supports.
        source: root._useQuickDialogs ? "MFolderDialogQuick.qml"
                                      : "MFolderDialogLabs.qml"
        onLoaded: {
            item.title = Qt.binding(function() { return root.title })
            item.accepted.connect(function() {
                root.acceptedPath(root.urlToPath(item.chosenPath))
            })
        }
    }
}
