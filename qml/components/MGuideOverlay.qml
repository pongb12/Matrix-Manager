/*
 * MGuideOverlay — animated guided tour (1.0.3-1, user request).
 *
 * Flow: brief app introduction card → spotlight steps over the real UI
 * (the ring morphs to each target with a pulsing glow, a card explains
 * the feature, Back/Next/Skip navigate, steps prepare the UI they
 * demonstrate: navigating to the page and selecting the relevant mode)
 * → closing card. All strings are translatable; the tour is replayable
 * from Settings → Guide.
 *
 * Targets are resolved by objectName at step-apply time, after prepare()
 * has made them visible. If a target cannot be found (unexpected layout,
 * scan missing, ...) the step degrades to a centered card instead of
 * pointing at nothing.
 */
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import MatrixManager.Core
import MatrixManager.Theme

Rectangle {
    id: guide

    anchors.fill: parent
    visible: false
    color: "transparent"
    opacity: 0.0
    z: 500

    // dimming layer sits under ring + card; whole overlay fades as one
    Rectangle {
        anchors.fill: parent
        color: Theme.overlay
        opacity: 0.72
    }

    property int step: -1
    readonly property bool running: visible
    signal closed()

    // Intro/outro steps render as a "floating" card: no fill, light ink and
    // a themed outline that sits directly on the dimmed backdrop (1.0.3-3).
    readonly property bool floatStep: {
        const def = guide.step >= 0 ? steps[guide.step] : null
        return def ? def.kind !== "target" : false
    }
    // Bullet icons only ever appear on the floating intro card, where the
    // backdrop is the dim layer: light mode needs the white on-accent ink,
    // dark mode already has light auto ink.
    readonly property string floatIconTint: Theme.dark ? "auto" : "onaccent"

    function openGuide() {
        step = 0
        visible = true
        opacity = 1.0
        forceActiveFocus()
        applyStep()
    }

    function closeGuide() {
        opacity = 0.0
        hideTimer.restart()
    }

    function nextStep() {
        if (step < steps.length - 1) {
            step = step + 1
            applyStep()
        } else {
            closeGuide()
        }
    }

    function prevStep() {
        if (step > 0) {
            step = step - 1
            applyStep()
        }
    }

    // ---------------------------------------------------- step model
    readonly property var steps: [
        {
            kind: "intro",
            title: qsTr("Welcome to Matrix Manager"),
            body: qsTr("A local-first desktop utility for disk space and .deb applications. Everything runs on this machine: no background scans, no accounts, no network access."),
            bullets: [
                { icon: "shield-check", text: qsTr("Nothing is ever scanned or deleted on its own — every action needs your explicit confirmation.") },
                { icon: "hard-drive",   text: qsTr("Storage, large files, duplicates and installed packages are shown honestly, including read errors.") },
                { icon: "info",         text: qsTr("This short animated guide walks you through every section. You can replay it anytime from Settings.") }
            ]
        },
        {
            kind: "target", target: "sidebarNav",
            title: qsTr("Navigation"),
            body: qsTr("The sidebar switches between sections: Overview, Storage, Applications, Cleanup, Large Files, Duplicates and Settings. Your choice is remembered while the window is open.")
        },
        {
            kind: "target", target: "storagePathRow", page: "storage",
            title: qsTr("Scanning a folder"),
            body: qsTr("Pick a folder by typing a path or pressing Browse, then press Scan. Scanning starts only on your request, updates live and can be cancelled at any time. The table shows every subfolder with its size."),
            prepare: function () {
                appWindow.navigate("storage")
                const p = appWindow.findPage("pageStorage")
                if (p)
                    p.setMode(0)
            }
        },
        {
            kind: "target", target: "storageModes", page: "storage",
            title: qsTr("Three ways to look"),
            body: qsTr("The modes switch the results view. Treemap draws each folder as a proportional block — click a block to step inside it, hover for the full path. The legend explains the colours."),
            prepare: function () {
                appWindow.navigate("storage")
                const p = appWindow.findPage("pageStorage")
                if (p)
                    p.setMode(2)
            }
        },
        {
            kind: "target", target: "storageSearchCard", page: "storage",
            title: qsTr("Searching files"),
            body: qsTr("The Search mode finds files by name and extension, with minimum and maximum size filters. Press Search — results stream in incrementally and are capped at 5000 entries."),
            prepare: function () {
                appWindow.navigate("storage")
                const p = appWindow.findPage("pageStorage")
                if (p)
                    p.setMode(1)
            }
        },
        {
            kind: "target", target: "largeControls", page: "largefiles",
            title: qsTr("Large Files"),
            body: qsTr("Find files above a size threshold: pick a preset or type your own size in the custom field. Results can be opened, located in the file manager, or moved to the trash after an explicit confirmation."),
            prepare: function () { appWindow.navigate("largefiles") }
        },
        {
            kind: "target", target: "dupControls", page: "duplicates",
            title: qsTr("Duplicate files"),
            body: qsTr("The duplicate scanner groups files with identical content, regardless of name. It hashes only what is needed: size first, then a partial hash, then a full hash on collision. Review each group and trash what you do not need."),
            prepare: function () { appWindow.navigate("duplicates") }
        },
        {
            kind: "target", target: "appsRefresh", page: "applications",
            title: qsTr("Applications"),
            body: qsTr("Lists the .deb packages installed on this system via dpkg-query, grouped into categories for quick browsing. Uninstalling always goes through the system package manager with a password prompt and a confirmation dialog. The arrow button refreshes the list."),
            prepare: function () { appWindow.navigate("applications") }
        },
        {
            kind: "target", target: "cleanupHeader", page: "cleanup",
            title: qsTr("Cleanup"),
            body: qsTr("A small set of safe-to-remove rules (user trash, apt cache, thumbnail cache). Each rule shows what it would delete and how much space it frees; cleaning requires a confirmation. Every action lands in the Activity Log."),
            prepare: function () { appWindow.navigate("cleanup") }
        },
        {
            kind: "target", target: "guideButton", page: "settings",
            title: qsTr("Replay anytime"),
            body: qsTr("The Guide button in Settings reopens this tour. Settings also holds the theme, the interface language and the safety options."),
            prepare: function () { appWindow.navigate("settings") }
        },
        {
            kind: "outro",
            title: qsTr("You are all set"),
            body: qsTr("Start with an Overview scan or jump straight into Storage. Matrix Manager will always ask before it changes anything.")
        }
    ]

    // ---------------------------------------------------- helpers
    function findTarget(name, root) {
        if (!root)
            return null
        if (root.objectName === name)
            return root
        const kids = root.children
        for (let i = 0; i < kids.length; ++i) {
            const found = findTarget(name, kids[i])
            if (found)
                return found
        }
        return null
    }

    function applyStep() {
        const def = steps[step]
        if (!def)
            return
        ring.visible = false
        if (def.prepare) {
            // A failing prepare (unexpected layout, missing page) must never
            // abort the tour before the locate timer is scheduled — degrade
            // to a centered card instead of freezing mid-walkthrough.
            try {
                def.prepare()
            } catch (e) {
                console.warn("Guide: prepare failed for step", step, "-", e)
            }
        }
        // let navigation / mode switches lay out their targets
        locateTimer.restart()
    }

    // Scrolls the target into view inside any scrollable ancestor. Out-of-view
    // targets are centred so the step card fits above or below without
    // covering the spotlight. Without this the Settings step pointed at empty
    // space: the Guide button sits in a scrollable column below the fold, its
    // mapped rect landed below the window and the ring highlighted nothing
    // (1.0.3-2 fix).
    function scrollIntoView(item) {
        for (let p = item.parent; p; p = p.parent) {
            // Detect Flickable-like ancestors (Flickable, ScrollView content)
            // by their scrolling properties instead of type checks, which QML
            // JS does not support for QML-defined types.
            if (p.contentY === undefined || p.height === undefined)
                continue
            const pos = p.contentItem.mapFromItem(item, 0, 0)
            const viewTop = p.contentY
            const viewBottom = p.contentY + p.height
            if (pos.y >= viewTop && pos.y + item.height <= viewBottom)
                continue // already fully visible
            const targetY = pos.y + item.height / 2 - p.height / 2
            const max = Math.max(0, (p.contentHeight || 0) - p.height)
            p.contentY = Math.max(0, Math.min(targetY, max))
        }
    }

    function locateTarget() {
        const def = steps[step]
        if (!def)
            return
        if (def.kind !== "target") {
            card.positionCentered()
            card.show()
            return
        }
        const item = findTarget(def.target, appWindow.contentItem)
        if (!item) {
            card.positionCentered()
            card.show()
            return
        }
        scrollIntoView(item)
        const r = guide.mapFromItem(item, 0, 0, item.width, item.height)
        ring.x = r.x - 6
        ring.y = r.y - 6
        ring.width = r.width + 12
        ring.height = r.height + 12
        ring.visible = true
        card.positionFor(r)
        card.show()
    }

    // Re-locates continuously while the tour is open. The first tick runs
    // right after prepare(); the repeats keep the spotlight honest while the
    // page-enter transition settles, list content streams in, the window is
    // resized or the card changes height between steps.
    Timer {
        id: locateTimer
        interval: 170
        repeat: true
        running: guide.visible
        onTriggered: guide.locateTarget()
    }

    Timer {
        id: hideTimer
        interval: 220
        onTriggered: {
            guide.visible = false
            guide.closed()
        }
    }

    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Theme.easing } }

    Shortcut {
        sequence: StandardKey.Cancel
        enabled: guide.visible
        onActivated: guide.closeGuide()
    }

    Keys.onEscapePressed: guide.closeGuide()

    // blocks interaction with the app below
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: { }
    }

    // ---------------------------------------------------- spotlight ring
    Rectangle {
        id: ring
        visible: false
        radius: 8
        color: "transparent"
        border.width: 2
        border.color: Theme.focus

        // pulsing glow — draws attention to the highlighted control
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 14
            height: parent.height + 14
            radius: parent.radius + 7
            color: "transparent"
            border.width: 2
            border.color: Theme.focus
            opacity: 0.0

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: ring.visible
                NumberAnimation { from: 0.0; to: 0.55; duration: 700; easing.type: Easing.OutCubic }
                NumberAnimation { from: 0.55; to: 0.0; duration: 700; easing.type: Easing.InCubic }
            }
            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: ring.visible
                NumberAnimation { from: 1.0; to: 1.05; duration: 700; easing.type: Easing.OutCubic }
                NumberAnimation { from: 1.05; to: 1.0; duration: 700; easing.type: Easing.InCubic }
            }
        }

        // small demo dot that bounces on the left edge — "look here"
        // Bound to ring visibility so re-locates never restart its loop.
        Rectangle {
            id: demoDot
            width: 10
            height: 10
            radius: 5
            color: Theme.accent
            opacity: ring.visible ? 0.95 : 0

            Behavior on opacity { NumberAnimation { duration: 120 } }

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: ring.visible
                alwaysRunToEnd: false
                NumberAnimation { from: -20; to: 2; duration: 420; easing.type: Easing.OutCubic }
                PauseAnimation { duration: 240 }
                NumberAnimation { from: 2; to: -20; duration: 420; easing.type: Easing.InCubic }
                PauseAnimation { duration: 160 }
            }
            y: parent.height / 2 - 5
        }

        Behavior on x { NumberAnimation { duration: 240; easing.type: Theme.easing } }
        Behavior on y { NumberAnimation { duration: 240; easing.type: Theme.easing } }
        Behavior on width { NumberAnimation { duration: 240; easing.type: Theme.easing } }
        Behavior on height { NumberAnimation { duration: 240; easing.type: Theme.easing } }
    }

    // ---------------------------------------------------- step card
    Rectangle {
        id: card

        function positionFor(targetRect) {
            // Prefer below the target, then above. Tall targets (e.g. the
            // full-height sidebar) fit neither — place the card beside them,
            // vertically centred. The final clamps guarantee the card is
            // always fully on screen (1.0.3-2: the sidebar step previously
            // fell through to a negative y and vanished off the top).
            const gap = 16
            const ch = card.height
            const cw = card.width
            const fitsBelow = targetRect.y + targetRect.height + gap + ch
                              <= guide.height - 24
            const fitsAbove = targetRect.y - gap - ch >= 24
            if (fitsBelow) {
                card.y = targetRect.y + targetRect.height + gap
            } else if (fitsAbove) {
                card.y = targetRect.y - gap - ch
            } else if (targetRect.height > guide.height * 0.6
                       && targetRect.x + targetRect.width + gap + cw
                              <= guide.width - 16) {
                card.y = Math.max(16, (guide.height - ch) / 2)
                card.x = Math.min(targetRect.x + targetRect.width + gap,
                                  guide.width - cw - 16)
                return
            } else {
                card.y = guide.height - ch - 16
            }
            card.y = Math.max(16, Math.min(card.y, guide.height - ch - 16))
            let x = targetRect.x + targetRect.width / 2 - cw / 2
            card.x = Math.max(16, Math.min(x, guide.width - cw - 16))
        }

        function positionCentered() {
            // Floating card: a touch above centre so it reads lighter and
            // leaves the dashboard visible below, clamped to stay fully on
            // screen even with tall translated content (1.0.3-3 realign).
            card.x = Math.max(16, (guide.width - card.width) / 2)
            const y = (guide.height - card.height) * 0.42
            card.y = Math.max(16, Math.min(y, guide.height - card.height - 16))
        }

        function show() {
            card.opacity = 1.0
            card.scale = 1.0
        }

        x: (guide.width - width) / 2
        y: guide.height
        width: Math.min(560, guide.width - 32)
        height: cardLayout.implicitHeight + Theme.spacingXL * 2
        radius: Theme.radiusLG
        // Floating intro/outro steps: no fill and a themed outline straight
        // on the dim layer — the old filled card was hard to tell apart from
        // the page in both themes and blocked the view (1.0.3-3). Dark mode
        // outlines white with a green inner hairline; light mode green.
        color: guide.floatStep ? "transparent" : Theme.surface
        border.width: guide.floatStep ? 2 : Theme.borderWidth
        border.color: guide.floatStep ? Theme.overlayBorder : Theme.borderStrong
        opacity: 0.0
        scale: 0.97

        // green inner hairline for the dark floating outline
        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            radius: Theme.radiusLG + 3
            color: "transparent"
            border.width: 1
            border.color: Theme.overlayAccent
            visible: guide.floatStep && Theme.dark
        }

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Theme.easing } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Theme.easing } }
        Behavior on x { NumberAnimation { duration: 240; easing.type: Theme.easing } }
        Behavior on y { NumberAnimation { duration: 240; easing.type: Theme.easing } }

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: Theme.spacingXL
            spacing: Theme.spacingMD

            // dynamic content
            RowLayout {
                spacing: Theme.spacingMD
                Layout.fillWidth: true

                MIcon {
                    name: {
                        const def = guide.steps[guide.step]
                        if (!def)
                            return "info"
                        if (def.kind === "intro")
                            return "info"
                        if (def.kind === "outro")
                            return "check"
                        return "help-circle"
                    }
                    size: 26
                    // "onaccent" is white in light mode and near-black in
                    // dark mode — invisible on the matching surfaces. Auto
                    // ink is correct for surface cards; floating cards need
                    // the explicit light-theme white (see floatIconTint).
                    tint: guide.floatStep ? guide.floatIconTint : "auto"
                }
                Text {
                    text: guide.step >= 0 ? guide.steps[guide.step].title : ""
                    font.pixelSize: Theme.fontSizeXL
                    font.weight: Font.DemiBold
                    color: guide.floatStep ? Theme.overlayText : Theme.textPrimary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Text {
                text: guide.step >= 0 ? guide.steps[guide.step].body : ""
                font.pixelSize: Theme.fontSizeMD
                color: guide.floatStep ? Theme.overlayTextMuted : Theme.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ColumnLayout {
                spacing: Theme.spacingSM
                Layout.fillWidth: true
                visible: {
                    const def = guide.step >= 0 ? guide.steps[guide.step] : null
                    return def && def.kind === "intro"
                }

                Repeater {
                    model: {
                        const def = guide.step >= 0 ? guide.steps[guide.step] : null
                        return def && def.bullets ? def.bullets : []
                    }

                    RowLayout {
                        id: bulletRow
                        required property var modelData
                        spacing: Theme.spacingSM
                        Layout.fillWidth: true

                        MIcon {
                            name: bulletRow.modelData.icon
                            size: 16
                            tint: guide.floatIconTint
                            Layout.alignment: Qt.AlignTop
                        }
                        Text {
                            text: bulletRow.modelData.text
                            font.pixelSize: Theme.fontSizeSM
                            color: Theme.overlayTextMuted
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // step dots
            Row {
                spacing: 5
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.spacingXS

                Repeater {
                    model: guide.steps.length

                    Rectangle {
                        required property int index
                        width: index === guide.step ? 16 : 6
                        height: 6
                        radius: 3
                        color: index === guide.step ? Theme.accent
                             : guide.floatStep ? Theme.overlayTextMuted
                             : Theme.borderStrong

                        Behavior on width { NumberAnimation { duration: 160; easing.type: Theme.easing } }
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                }
            }

            // buttons
            RowLayout {
                spacing: Theme.spacingSM
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacingXS

                MSecondaryButton {
                    text: guide.step >= guide.steps.length - 1 ? qsTr("Close")
                        : qsTr("Skip tour")
                    inverted: guide.floatStep
                    onClicked: guide.closeGuide()
                }
                Item { Layout.fillWidth: true }
                MSecondaryButton {
                    text: qsTr("Back")
                    iconName: "arrow-left"
                    visible: guide.step > 0
                    inverted: guide.floatStep
                    onClicked: guide.prevStep()
                }
                MButton {
                    text: guide.step >= guide.steps.length - 1 ? qsTr("Done")
                        : guide.step === 0 ? qsTr("Start tour")
                        : qsTr("Next")
                    iconName: guide.step >= guide.steps.length - 1 ? "check" : "arrow-right"
                    onClicked: guide.nextStep()
                }
            }
        }
    }

    // QA support: open directly at a step for automated screenshots.
    Component.onCompleted: {
        if (typeof qaGuideStep !== "undefined" && qaGuideStep !== "") {
            const n = parseInt(qaGuideStep, 10)
            if (!isNaN(n) && n >= 0 && n < steps.length) {
                step = n
                visible = true
                opacity = 1.0
                applyStep()
                locateTimer.interval = 600 // give QA scans time to start
            }
        }
    }
}
