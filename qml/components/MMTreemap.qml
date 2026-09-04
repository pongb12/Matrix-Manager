/*
 * MMTreemap — proportional block view of directory/file sizes (MM-023).
 *
 * Each rectangle is one entry of the scanned directory; its area is
 * proportional to the entry's recursive size. Layout is a binary-split
 * treemap over entries sorted by size (largest first), which keeps aspect
 * ratios reasonable without heavy geometry code. Labels appear only when
 * there is room; hovering shows the full path; clicking a directory
 * activates it (click-to-navigate). The accessible alternative is the
 * plain directory table on the Storage page.
 */
import QtQuick
import QtQuick.Layouts
import MatrixManager.Theme

Rectangle {
    id: treemap

    property var entries: []          // [{name, path, bytes, isDir}]
    property int maxBlocks: 32
    signal activate(string path, bool isDir)
    signal hoverInfo(string text)

    color: Theme.surfaceSunken
    radius: Theme.radiusMD
    implicitHeight: 320
    clip: true

    onEntriesChanged: rebuild()
    onWidthChanged: rebuild()

    // ------------------------------------------------ squarified layout
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
        layout(picked, 0, 0, treemap.width, treemap.height, out)
        blockRepeater.model = out
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
            x: Math.round(modelData.x)
            y: Math.round(modelData.y)
            width: Math.round(modelData.w)
            height: Math.round(modelData.h)
            color: Theme.categoryColors[index % Theme.categoryColors.length]
            border.width: 1
            border.color: treemap.color
            opacity: blockMouse.containsMouse ? 0.85 : 1

            Text {
                anchors.centerIn: parent
                width: parent.width - 8
                text: modelData.entry.name
                      + (block.width > 110 && block.height > 36
                         ? "  ·  " + SystemInfo.formatBytes(modelData.entry.bytes)
                         : "")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Math.max(Theme.fontSizeXS,
                                         Math.min(Theme.fontSizeMD,
                                                  block.height / 5))
                elide: Text.ElideRight
                color: Theme.textPrimary
                visible: block.width > 44 && block.height > 18
            }

            MouseArea {
                id: blockMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: modelData.entry.isDir
                             ? Qt.PointingHandCursor : Qt.ArrowCursor
                onEntered: treemap.hoverInfo(
                               modelData.entry.path + " · "
                               + SystemInfo.formatBytes(modelData.entry.bytes))
                onClicked: {
                    if (modelData.entry.isDir)
                        treemap.activate(modelData.entry.path, true)
                }
            }

            Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
        }
    }
}
