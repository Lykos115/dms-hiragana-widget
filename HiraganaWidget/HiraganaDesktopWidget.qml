import QtQuick
import qs.Common
import qs.Modules.Plugins

// Desktop widget: DMS draws it on the bottom layer (above the wallpaper,
// below windows) and remembers position and size. Move/resize it from
// Settings → Desktop Widgets (right-click drag). Left click = next kana,
// middle click = speak it.
DesktopPluginComponent {
    id: root

    minWidth: 100
    minHeight: 80

    readonly property real mainSize: pluginData.desktopMainSize ?? 64
    readonly property real backgroundOpacity: (pluginData.desktopBackgroundOpacity ?? 0) / 100
    readonly property bool showReading: pluginData.showReading ?? true
    readonly property bool showSet: pluginData.showSet ?? false
    readonly property string fontFamily: (pluginData.fontFamily ?? "") !== "" ? pluginData.fontFamily : Theme.fontFamily
    readonly property bool textShadow: pluginData.desktopTextShadow ?? true

    HiraganaDeck {
        id: deck
        settings: root.pluginData
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        opacity: root.backgroundOpacity
    }

    Column {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: 2

        Text {
            width: parent.width
            text: deck.main
            font.family: root.fontFamily
            font.pixelSize: root.mainSize
            font.weight: Font.Bold
            color: Theme.surfaceText
            style: root.textShadow ? Text.Outline : Text.Normal
            styleColor: Theme.withAlpha(Theme.surface, 0.7)
        }

        Text {
            visible: root.showReading && deck.reading !== ""
            width: parent.width
            text: deck.reading
            font.pixelSize: Math.max(Theme.fontSizeSmall, root.mainSize * 0.35)
            color: Theme.primary
            style: root.textShadow ? Text.Outline : Text.Normal
            styleColor: Theme.withAlpha(Theme.surface, 0.7)
        }

        Text {
            visible: root.showSet && deck.tag !== ""
            width: parent.width
            text: deck.tag
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            opacity: 0.8
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton   // right button stays with the DMS drag/resize handler
        onClicked: mouse => mouse.button === Qt.MiddleButton ? deck.play() : deck.next(true)
    }
}
