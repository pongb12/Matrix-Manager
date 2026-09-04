/*
 * CleanupPage.qml — explicit, reviewable cleanup (MM-050..MM-054).
 *
 * Every rule shows what it is, why it is safe and what will happen.
 * Nothing runs until the user selects rules, reviews the summary and
 * confirms. Running rules are clearly indicated; no silent deletions.
 */
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import MatrixManager.Core
import MatrixManager.Theme
import MatrixManager.Components

Page {
    id: page

    background: null

    property var selectedRules: ({})
    property var estimates: ({})
    property var runningRule: ""

    function isSelected(id) {
        return page.selectedRules[id] === true
    }

    function setSelected(id, value) {
        const copy = Object.assign({}, page.selectedRules)
        if (value)
            copy[id] = true
        else
            delete copy[id]
        page.selectedRules = copy
    }

    function selectedCount() {
        return Object.keys(page.selectedRules).length
    }

    function selectedTotalBytes() {
        let total = 0
        for (const id in page.selectedRules) {
            const est = page.estimates[id]
            if (est && est.bytes)
                total += est.bytes
        }
        return total
    }

    function refreshEstimates() {
        const rules = CleanupService.rules()
        let est = {}
        for (let i = 0; i < rules.length; ++i)
            est[rules[i].id] = CleanupService.estimate(rules[i].id)
        page.estimates = est
    }

    Component.onCompleted: refreshEstimates()

    Connections {
        target: CleanupService

        function onRuleStarted(ruleId) {
            page.runningRule = ruleId
        }

        function onRuleFinished(ruleId, success, freedBytes, error) {
            page.runningRule = ""
            if (success)
                appWindow.showToast(
                    qsTr("%1: freed %2").arg(ruleName(ruleId)).arg(
                        SystemInfo.formatBytes(freedBytes)), "success")
            else
                appWindow.showToast(
                    qsTr("%1: %2").arg(ruleName(ruleId)).arg(error), "danger")
            refreshEstimates()
        }

        function onAllFinished() {
            page.runningRule = ""
            page.selectedRules = {}
        }
    }

    function ruleName(id) {
        const rules = CleanupService.rules()
        for (let i = 0; i < rules.length; ++i) {
            if (rules[i].id === id)
                return rules[i].name
        }
        return id
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingLG

        MPageHeader {
            title: qsTr("Cleanup")
            subtitle: qsTr("Only clearly identified, safe-to-remove data is listed — each rule is explicit")

            MIconButton {
                glyph: "⟳"
                tooltip: qsTr("Recalculate sizes")
                enabled: !CleanupService.running
                onClicked: refreshEstimates()
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: Math.max(implicitWidth, page.availableWidth)
                spacing: Theme.spacingLG

                // --------------------------------------------- rule list
                Repeater {
                    model: CleanupService.rules()

                    MCard {
                        id: ruleCard
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: ruleContent.implicitHeight + Theme.spacingLG * 2
                        opacity: CleanupService.running && page.runningRule !== modelData.id ? 0.55 : 1

                        readonly property var estimate: page.estimates[modelData.id] || null

                        border.color: page.runningRule === modelData.id ? Theme.accent : Theme.border

                        RowLayout {
                            id: ruleContent
                            anchors.fill: parent
                            anchors.margins: Theme.spacingLG
                            spacing: Theme.spacingMD

                            MCheckBox {
                                checked: page.isSelected(modelData.id)
                                enabled: !CleanupService.running
                                onToggled: page.setSelected(modelData.id, checked)
                            }

                            ColumnLayout {
                                spacing: 4
                                Layout.fillWidth: true

                                RowLayout {
                                    spacing: Theme.spacingSM
                                    Layout.fillWidth: true

                                    Text {
                                        text: modelData.name
                                        font.pixelSize: Theme.fontSizeLG
                                        font.weight: Font.DemiBold
                                        color: Theme.textPrimary
                                    }
                                    MBadge {
                                        text: modelData.risk
                                        tone: modelData.riskLevel === 0 ? "success"
                                            : modelData.riskLevel === 1 ? "warning" : "danger"
                                    }
                                    MBadge {
                                        visible: modelData.requiresPrivilege
                                        text: qsTr("Requires authorization")
                                        tone: "neutral"
                                    }
                                    MBadge {
                                        visible: page.runningRule === modelData.id
                                        text: qsTr("Running…")
                                        tone: "accent"
                                    }
                                }

                                Text {
                                    text: modelData.description
                                    font.pixelSize: Theme.fontSizeMD
                                    color: Theme.textSecondary
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.targets.join("  ·  ")
                                    font.pixelSize: Theme.fontSizeXS
                                    font.family: Theme.monoFamily
                                    color: Theme.textMuted
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }
                            }

                            ColumnLayout {
                                spacing: 4
                                Layout.alignment: Qt.AlignTop

                                Text {
                                    text: ruleCard.estimate === null
                                          ? qsTr("Not calculated")
                                          : SystemInfo.formatBytes(ruleCard.estimate.bytes)
                                    font.pixelSize: Theme.fontSizeLG
                                    font.weight: Font.Medium
                                    font.family: Theme.monoFamily
                                    color: Theme.textPrimary
                                    horizontalAlignment: Text.AlignRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: ruleCard.estimate === null
                                          ? ""
                                          : qsTr("%1 items").arg(
                                                Qt.locale().toString(ruleCard.estimate.itemCount))
                                    font.pixelSize: Theme.fontSizeXS
                                    color: Theme.textMuted
                                    horizontalAlignment: Text.AlignRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }

                // -------------------------------------- safety note
                Text {
                    text: qsTr("Matrix Manager never classifies your documents, downloads or projects as junk. Cleanup candidates come from fixed rules only — no age heuristics, no guessing.")
                    font.pixelSize: Theme.fontSizeMD
                    color: Theme.textMuted
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                // -------------------------------------- review summary
                MCard {
                    visible: !CleanupService.running
                    Layout.fillWidth: true
                    implicitHeight: review.implicitHeight + Theme.spacingLG * 2
                    border.color: page.selectedCount() > 0 ? Theme.danger : Theme.border

                    RowLayout {
                        id: review
                        anchors.fill: parent
                        anchors.margins: Theme.spacingLG
                        spacing: Theme.spacingMD

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true

                            Text {
                                text: page.selectedCount() === 0
                                      ? qsTr("Nothing selected")
                                      : qsTr("%1 rule(s) selected").arg(page.selectedCount())
                                font.pixelSize: Theme.fontSizeLG
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                            }
                            Text {
                                text: page.selectedCount() === 0
                                      ? qsTr("Select rules above to review what will be cleaned.")
                                      : qsTr("Estimated reclaimable space: %1").arg(
                                            SystemInfo.formatBytes(page.selectedTotalBytes()))
                                font.pixelSize: Theme.fontSizeMD
                                color: Theme.textSecondary
                            }
                        }

                        MSecondaryButton {
                            text: qsTr("Select all")
                            visible: page.selectedCount() < CleanupService.rules().length
                            onClicked: {
                                const rules = CleanupService.rules()
                                let sel = {}
                                for (let i = 0; i < rules.length; ++i)
                                    sel[rules[i].id] = true
                                page.selectedRules = sel
                            }
                        }

                        MDestructiveButton {
                            text: qsTr("Clean selected…")
                            enabled: page.selectedCount() > 0
                            onClicked: reviewDialog.openReview()
                        }
                    }
                }
            }
        }
    }

    // ----------------------------- review dialog (MM-054)
    MConfirmationDialog {
        id: reviewDialog

        function openReview() {
            const rules = CleanupService.rules()
            const rows = []
            for (let i = 0; i < rules.length; ++i) {
                if (page.isSelected(rules[i].id)) {
                    const est = page.estimates[rules[i].id]
                    rows.push({
                        label: rules[i].name,
                        value: est ? SystemInfo.formatBytes(est.bytes) : "?"
                    })
                }
            }
            reviewDialog.title = qsTr("Clean selected data?")
            reviewDialog.message = qsTr("Review what will happen. Each action uses its own safe mechanism:")
            reviewDialog.rows = rows
            reviewDialog.consequence = rulesSummary()
            reviewDialog.confirmText = qsTr("Clean %1 rule(s)").arg(page.selectedCount())
            open()
        }

        function rulesSummary() {
            const parts = []
            for (const id in page.selectedRules) {
                if (id === "user-trash")
                    parts.push(qsTr("Trash: emptied permanently"))
                else if (id === "apt-cache")
                    parts.push(qsTr("APT cache: 'apt-get clean' (authorization requested)"))
                else if (id === "thumbnail-cache")
                    parts.push(qsTr("Thumbnails: deleted, regenerated on demand"))
            }
            return parts.join("\n")
        }

        onAccepted: {
            const ids = []
            for (const id in page.selectedRules)
                ids.push(id)
            CleanupService.clean(ids)
        }
    }

    // Stop-after-current control shown while running.
    MCard {
        visible: CleanupService.running
        Layout.fillWidth: true
        implicitHeight: runningRow.implicitHeight + Theme.spacingLG * 2

        RowLayout {
            id: runningRow
            anchors.fill: parent
            anchors.margins: Theme.spacingLG

            MProgressBar {
                Layout.preferredWidth: 200
                indeterminate: true
            }
            Text {
                text: page.runningRule !== ""
                      ? qsTr("Running: %1").arg(page.ruleName(page.runningRule))
                      : qsTr("Working…")
                font.pixelSize: Theme.fontSizeMD
                color: Theme.textSecondary
                Layout.fillWidth: true
            }
            MSecondaryButton {
                text: qsTr("Stop after current rule")
                onClicked: CleanupService.stopAfterCurrent()
            }
        }
    }
}
