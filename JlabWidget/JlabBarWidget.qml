import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Bar pill: shows the current sentence (optionally with its hiragana reading).
// Left click (or hover, if the bar has "open popouts on hover" enabled) opens a
// card with the sentence, its reading, romaji, meaning and Play / Next buttons.
// Right click skips to the next sentence.
PluginComponent {
    id: root

    layerNamespacePlugin: "jlab-widget"

    readonly property bool barReading: pluginData.barReading ?? false
    readonly property real barMaxWidth: pluginData.barMaxWidth ?? 360
    readonly property string fontFamily: (pluginData.fontFamily ?? "") !== "" ? pluginData.fontFamily : Theme.fontFamily
    readonly property real popoutMainSize: pluginData.popoutMainSize ?? 28

    JlabDeck {
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
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.primary
                elide: Text.ElideRight
                width: Math.min(implicitWidth, root.barMaxWidth)
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.barReading && deck.reading !== ""
                text: deck.reading
                font.family: root.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                elide: Text.ElideRight
                width: Math.min(implicitWidth, root.barMaxWidth)
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
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: Theme.primary
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 120)
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: card
            headerText: deck.source !== "" ? deck.source.toUpperCase() : "JLAB"
            showCloseButton: true

            Column {
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
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    visible: deck.reading !== "" && deck.reading.replace(/ /g, "") !== deck.main
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    text: deck.reading
                    font.family: root.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.primary
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    visible: deck.romaji !== ""
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    text: deck.romaji
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    visible: deck.meaning !== ""
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    text: deck.meaning
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    wrapMode: Text.Wrap
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
        }
    }

    popoutWidth: pluginData.popoutWidth ?? 380
}
