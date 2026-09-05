/*
 * MMTreemap — proportional block view of directory/file sizes (MM-023).
 *
 * Each rectangle is one entry of the scanned directory; its area is
 * proportional to the entry's recursive size. Layout is a binary-split
 * treemap over entries sorted by size (largest first), which keeps aspect
 * ratios reasonable without heavy geometry code.
 *
 * Visual language: blocks are colour-coded by file category (folder,
 * video, audio, image, archive, document, other) with a legend below,
 * rounded corners, small gutters, a hover lift with outline, and a short
 * staggered entrance when NEW data arrives (window resizes relayout
 * without replaying the animation). Clicking a directory activates it
 * (click-to-navigate); the accessible alternative remains the plain
 * directory table on the Storage page.
 */
import QtQuick
import QtQuick.Layouts
import MatrixManager.Theme

Rectangle {
    id: treemap

    property var entries: []          // [{name, path, bytes, isDir}]
    property int maxBlocks: 32
    property bool showLegend: true
    signal activate(string path, bool isDir)
    signal hoverInfo(string text)

    readonly property int legendHeight: showLegend ? 26 : 0
    readonly property int gutter: 2

    color: Theme.surfaceSunken
    radius: Theme.radiusMD
    implicitHeight: 360
    clip: true

    // ------------------------------------------------ category mapping
    function categoryOf(entry) {
        if (entry.isDir)
            return "folder"
        const n = entry.name.toLowerCase()
        const dot = n.lastIndexOf(".")
        const ext = dot >= 0 ? n.substring(dot + 1) : ""
        if (["mp4","mkv","avi","mov","webm","m4v","ts"].indexOf(ext) >= 0)
            return "video"
        if (["mp3","flac","wav","ogg","m4a","opus","aac"].indexOf(ext) >= 0)
            return "audio"
        if (["jpg","jpeg","png","gif","bmp","svg","webp","tiff","heic"].indexOf(ext) >= 0)
            return "image"
        if (["zip","tar","gz","xz","bz2","7z","rar","zst","deb","rpm","iso"].indexOf(ext) >= 0)
            return "archive"
        if (["pdf","doc","docx","xls","xlsx","ppt","pptx","txt","md","epub","odt","csv"].indexOf(ext) >= 0)
            return "document"
        return "other"
    }

    readonly property var categories: [
        { key: "folder",   label: qsTr("Folders"),   color: Theme.categoryColors[0], icon: "folder" },
        { key: "video",    label: qsTr("Videos"),    color: Theme.categoryColors[2], icon: "file-video" },
        { key: "audio",    label: qsTr("Audio"),     color: Theme.categoryColors[1], icon: "file-audio" },
        { key: "image",    label: qsTr("Images"),    color: Theme.categoryColors[4], icon: "file-image" },
        { key: "archive",  label: qsTr("Archives"),  color: Theme.categoryColors[3], icon: "file-archive" },
        { key: "document", label: qsTr("Documents"), color: Theme.categoryColors[6], icon: "file-text" },
        { key: "other",    label: qsTr("Other"),     color: Theme.categoryColors[7], icon: "file" }
    ]

    function colorFor(entry) {
        const key = categoryOf(entry)
        for (let i = 0; i < categories.length; ++i)
            if (categories[i].key === key)
                return categories[i].color
        return Theme.categoryColors[7]
    }

    function iconFor(entry) {
        const key = categoryOf(entry)
        for (let i = 0; i < categories.length; ++i)
            if (categories[i].key === key)
                return categories[i].icon
        return "file"
    }

    // ------------------------------------------------ squarified layout
    // true only when the entries array itself was replaced (new data);
    // relayouts caused by resize keep blocks static.
    property bool _entranceAnimated: false
    property var _lastEntriesRef: null

    onEntriesChanged: rebuild()
    onWidthChanged: rebuild()

    function rebuild() {
        const items = []
        for (let i = 0; i < treemap.entries.length; ++i) {
            const e = treemap.entries[i]
            if (e.bytes > 0)
                items.push(e)
        }
        items.sort((a, b) => b.bytes - a.bytes)
        const picked = items.slice(0, treemap.maxBlocks)
        const out = []
        layout(picked, 0, 0, treemap.width,
               treemap.height - legendHeight, out)
        _entranceAnimated = treemap.entries !== _lastEntriesRef
        _lastEntriesRef = treemap.entries
        blockRepeater.model = out
        overflowChip.visible = treemap.entries.length > treemap.maxBlocks
        overflowChip.text = "+" + (treemap.entries.length - treemap.maxBlocks)
    }

    function sum(items) {
        let total = 0
        for (let i = 0; i < items.length; ++i)
            total += items[i].bytes
        return total
    }

    function layout(items, x, y, w, h, out) {
        if (items.length === 0 || w <= 1 || h <= 1)
            return
        if (items.length === 1) {
            out.push({ entry: items[0], x: x, y: y, w: w, h: h })
            return
        }
        const total = sum(items)
        if (total <= 0)
            return

        // split so the first half holds roughly half of the total area
        let acc = 0
        let split = 1
        for (let i = 0; i < items.length - 1; ++i) {
            acc += items[i].bytes
            split = i + 1
            if (acc >= total / 2)
                break
        }
        const head = items.slice(0, split)
        const tail = items.slice(split)
        const frac = Math.min(0.95, Math.max(0.05, sum(head) / total))

        if (w >= h) {
            layout(head, x, y, w * frac, h, out)
            layout(tail, x + w * frac, y, w * (1 - frac), h, out)
        } else {
            layout(head, x, y, w, h * frac, out)
            layout(tail, x, y + h * frac, w, h * (1 - frac), out)
        }
    }

    Repeater {
        id: blockRepeater
        model: []

        Rectangle {
            id: block
            required property var modelData
            required property int index

            readonly property bool hoveredNow: blockMouse.containsMouse
            readonly property int inset: Math.min(
                treemap.gutter, Math.floor(Math.min(modelData.w, modelData.h) / 4))

            // Entrance animation state (only active for fresh data)
            property real entranceOpacity: treemap._entranceAnimated ? 0.0 : 1.0
            property real entranceScale: treemap._entranceAnimated ? 0.96 : 1.0

            x: Math.round(modelData.x) + inset
            y: Math.round(modelData.y) + inset
            width: Math.max(0, Math.round(modelData.w) - inset * 2)
            height: Math.max(0, Math.round(modelData.h) - inset * 2)
            radius: Math.min(4, height / 4)
            color: treemap.colorFor(modelData.entry)
            border.width: hoveredNow ? 2 : 0
            border.color: Theme.textPrimary
            z: hoveredNow ? 2 : 1
            opacity: (hoveredNow ? 1.0 : 0.92) * entranceOpacity
            scale: entranceScale

            Component.onCompleted: {
                if (treemap._entranceAnimated)
                    entranceTimer.start()
            }

            Timer {
                id: entranceTimer
                interval: 30 + (block.index % 12) * 16
                onTriggered: {
                    block.entranceOpacity = 1.0
                    block.entranceScale = 1.0
                }
            }

            Behavior on entranceOpacity {
                NumberAnimation { duration: Theme.durationSlow; easing.type: Theme.easing }
            }
            Behavior on entranceScale {
                NumberAnimation { duration: Theme.durationSlow; easing.type: Theme.easing }
            }
            Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
            Behavior on border.width { NumberAnimation { duration: Theme.durationFast } }

            // top hairline for depth (no gradients in this design system)
            Rectangle {
                visible: block.height > 10
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 1
                height: 1
                color: "#FFFFFF"
                opacity: 0.18
            }

            Row {
                anchors.centerIn: parent
                spacing: 5
                visible: block.width > 52 && block.height > 22

                MIcon {
                    name: treemap.iconFor(block.modelData.entry)
                    tint: "onaccent"
                    size: Math.max(12, Math.min(20, block.height / 3))
                    visible: block.modelData.entry.isDir || block.width > 90
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, block.width - 12)
                    text: block.modelData.entry.name
                          + (block.width > 110 && block.height > 36
                             ? "  ·  " + SystemInfo.formatBytes(block.modelData.entry.bytes)
                             : "")
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Math.max(Theme.fontSizeXS,
                                             Math.min(Theme.fontSizeMD,
                                                      block.height / 5))
                    font.weight: block.hoveredNow ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                    color: "#FFFFFF"
                    style: Text.Raised
                    styleColor: "#5A000000"
                    visible: block.width > 44 && block.height > 18
                }
            }

            MouseArea {
                id: blockMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: block.modelData.entry.isDir
                             ? Qt.PointingHandCursor : Qt.ArrowCursor
                onEntered: treemap.hoverInfo(
                               block.modelData.entry.path + " · "
                               + SystemInfo.formatBytes(block.modelData.entry.bytes))
                onClicked: {
                    if (block.modelData.entry.isDir)
                        treemap.activate(block.modelData.entry.path, true)
                }
            }
        }
    }

    // "+N" chip for entries that did not fit into maxBlocks
    Rectangle {
        id: overflowChip
        property string text: ""
        anchors.right: parent.right
        anchors.bottom: legend.visible ? legend.top : parent.bottom
        anchors.margins: Theme.spacingSM
        width: chipText.implicitWidth + Theme.spacingMD * 2
        height: 22
        radius: Theme.radiusSM
        color: Theme.surfaceElevated
        border.width: Theme.borderWidth
        border.color: Theme.border
        visible: false

        Text {
            id: chipText
            anchors.centerIn: parent
            text: overflowChip.text
            font.pixelSize: Theme.fontSizeXS
            font.family: Theme.monoFamily
            color: Theme.textSecondary
        }
    }

    // ------------------------------------------------ legend
    Row {
        id: legend
        visible: treemap.showLegend
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: treemap.legendHeight
        leftPadding: Theme.spacingMD
        rightPadding: Theme.spacingMD
        spacing: Theme.spacingLG

        Repeater {
            model: treemap.categories

            Row {
                id: legendItem
                required property var modelData
                spacing: 5

                Rectangle {
                    width: 8
                    height: 8
                    radius: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: legendItem.modelData.color
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: legendItem.modelData.label
                    font.pixelSize: Theme.fontSizeXS
                    color: Theme.textSecondary
                }
            }
        }
    }
}
