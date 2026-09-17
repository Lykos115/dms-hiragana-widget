import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Bar pill: shows the current kana (optionally with its romaji).
// Left click (or hover, if the bar has "open popouts on hover" enabled) opens a
// card with the kana, its romaji and Play / Next buttons.
// Right click skips to the next kana.
PluginComponent {
    id: root

    layerNamespacePlugin: "hiragana-widget"

    readonly property bool barRomaji: pluginData.barRomaji ?? true
    readonly property string fontFamily: (pluginData.fontFamily ?? "") !== "" ? pluginData.fontFamily : Theme.fontFamily
    readonly property real popoutMainSize: pluginData.popoutMainSize ?? 96
    readonly property bool openOnChart: pluginData.openOnChart ?? false
    readonly property real chartMaxHeight: pluginData.chartMaxHeight ?? 480

    HiraganaDeck {
        id: deck
        settings: root.pluginData
    }

    pillRightClickAction: () => deck.next(true)

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            StyledText {
                text: deck.main
                font.family: root.fontFamily
                font.pixelSize: Theme.fontSizeXLarge
                font.weight: Font.Bold
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.barRomaji && deck.reading !== ""
                text: deck.reading
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 0

            StyledText {
                text: deck.main
                font.family: root.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.primary
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: card
            headerText: deck.tag !== "" ? deck.tag.toUpperCase() : "KANA"
            showCloseButton: true

            // "card" = the current kana with Play / Next, "chart" = the whole table
            property string tab: root.openOnChart ? "chart" : "card"
            property string chartSet: "hiragana"

            // tab strip
            Row {
                leftPadding: Theme.spacingS
                spacing: Theme.spacingXS
                bottomPadding: Theme.spacingS

                Repeater {
                    model: [
                        { key: "card",  label: "Card",  icon: "style" },
                        { key: "chart", label: "Chart", icon: "grid_view" }
                    ]

                    Rectangle {
                        required property var modelData
                        readonly property bool active: card.tab === modelData.key
                        width: tabRow.implicitWidth + Theme.spacingM * 2
                        height: 30
                        radius: 15
                        color: active ? Theme.primary
                             : tabArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                        Row {
                            id: tabRow
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DankIcon {
                                name: modelData.icon
                                size: Theme.iconSize - 4
                                color: active ? Theme.primaryText : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: modelData.label
                                color: active ? Theme.primaryText : Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: tabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.tab = modelData.key
                        }
                    }
                }
            }

            // --- Card tab -------------------------------------------------
            Column {
                visible: card.tab === "card"
                width: parent.width
                spacing: Theme.spacingS
                leftPadding: Theme.spacingS
                rightPadding: Theme.spacingS
                bottomPadding: Theme.spacingS

                StyledText {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    text: deck.main
                    font.family: root.fontFamily
                    font.pixelSize: root.popoutMainSize
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    visible: deck.reading !== ""
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    text: deck.reading
                    font.pixelSize: Theme.fontSizeXLarge
                    color: Theme.primary
                    horizontalAlignment: Text.AlignHCenter
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingS
                    topPadding: Theme.spacingXS

                    Rectangle {
                        visible: deck.hasAudio
                        width: playLabel.implicitWidth + Theme.spacingL * 2 + Theme.iconSize
                        height: 34
                        radius: 17
                        color: playArea.containsMouse ? Qt.lighter(Theme.primary, 1.15) : Theme.primary

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DankIcon {
                                name: "volume_up"
                                size: Theme.iconSize
                                color: Theme.primaryText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                id: playLabel
                                text: "Play"
                                color: Theme.primaryText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: playArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: deck.play()
                        }
                    }

                    Rectangle {
                        width: nextLabel.implicitWidth + Theme.spacingL * 2
                        height: 34
                        radius: 17
                        color: nextArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                        StyledText {
                            id: nextLabel
                            anchors.centerIn: parent
                            text: "Next"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: deck.next(true)
                        }
                    }
                }
            }

            // --- Chart tab ------------------------------------------------
            // The full gojūon table. Tap a kana to make it the current one
            // (everywhere, if "same kana everywhere" is on) and hear it.
            Column {
                id: chart
                visible: card.tab === "chart"
                width: parent.width
                spacing: Theme.spacingXS
                leftPadding: Theme.spacingS
                rightPadding: Theme.spacingS
                bottomPadding: Theme.spacingS

                readonly property real cellGap: 3
                readonly property real innerW: width - leftPadding - rightPadding
                readonly property real cellSize: Math.floor((innerW - cellGap * 4) / 5)

                // hiragana / katakana switch, only when katakana is enabled in the settings
                Row {
                    visible: deck.showKatakana
                    spacing: Theme.spacingXS
                    bottomPadding: Theme.spacingXS

                    Repeater {
                        model: [ { key: "hiragana", label: "ひらがな" }, { key: "katakana", label: "カタカナ" } ]

                        Rectangle {
                            required property var modelData
                            readonly property bool active: card.chartSet === modelData.key
                            width: setLabel.implicitWidth + Theme.spacingM * 2
                            height: 26
                            radius: 13
                            color: active ? Theme.surfaceContainerHighest : "transparent"
                            border.width: 1
                            border.color: active ? Theme.primary : Theme.outline

                            StyledText {
                                id: setLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: root.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                color: active ? Theme.primary : Theme.surfaceVariantText
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: card.chartSet = modelData.key
                            }
                        }
                    }
                }

                // the table is ~27 rows, taller than most screens: scroll it
                DankFlickable {
                    width: chart.innerW
                    height: Math.min(chartColumn.implicitHeight, root.chartMaxHeight)
                    contentWidth: width
                    contentHeight: chartColumn.implicitHeight
                    clip: true

                    Column {
                        id: chartColumn
                        width: parent.width
                        spacing: chart.cellGap

                        Repeater {
                            model: deck.kana.length > 0 ? deck.chartRows(card.chartSet) : []

                            Row {
                                id: chartRow
                                required property var modelData
                                spacing: chart.cellGap

                                Repeater {
                                    model: chartRow.modelData

                                    Rectangle {
                                        required property var modelData
                                        readonly property bool present: modelData.main !== ""
                                        readonly property bool current: present && modelData.main === deck.main && modelData.tag === deck.tag
                                        width: chart.cellSize
                                        height: chart.cellSize
                                        radius: Theme.cornerRadius / 2
                                        color: !present ? "transparent"
                                             : current ? Theme.primary
                                             : cellArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 0
                                            visible: present

                                            StyledText {
                                                text: modelData.main
                                                font.family: root.fontFamily
                                                font.pixelSize: chart.cellSize * (modelData.main.length > 1 ? 0.36 : 0.5)
                                                font.weight: Font.Bold
                                                color: current ? Theme.primaryText : Theme.surfaceText
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }

                                            StyledText {
                                                text: modelData.reading
                                                font.pixelSize: Math.max(8, chart.cellSize * 0.22)
                                                color: current ? Theme.primaryText : Theme.surfaceVariantText
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }
                                        }

                                        MouseArea {
                                            id: cellArea
                                            anchors.fill: parent
                                            enabled: present
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: deck.show(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: pluginData.popoutWidth ?? 280
}
