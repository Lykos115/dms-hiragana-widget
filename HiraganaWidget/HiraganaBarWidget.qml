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
        }
    }

    popoutWidth: pluginData.popoutWidth ?? 280
}
