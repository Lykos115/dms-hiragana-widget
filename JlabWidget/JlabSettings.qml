import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "jlabWidget"

    StyledText {
        width: parent.width
        text: "Content"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Sentences come from data/jlab/sentences.json, written by import-jlab from the Jlab .apkg (see README)."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.Wrap
    }

    SliderSetting {
        settingKey: "interval"
        label: "Seconds per sentence"
        defaultValue: 30
        minimum: 3
        maximum: 600
        unit: "s"
    }

    SliderSetting {
        settingKey: "maxSentences"
        label: "Only the first N sentences"
        description: "The course gets harder as it goes; 0 = all of them"
        defaultValue: 0
        minimum: 0
        maximum: 2500
        unit: ""
    }

    ToggleSetting {
        settingKey: "shuffle"
        label: "Random order"
        description: "Off = go through the course in order"
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "syncInstances"
        label: "Same sentence everywhere"
        description: "Keep the bar pills on every monitor and the desktop widgets in step"
        defaultValue: true
    }

    StringSetting {
        settingKey: "fontFamily"
        label: "Japanese font"
        description: "Leave empty to use the DMS font (fontconfig falls back to Noto Sans CJK for Japanese)"
        placeholder: "Noto Sans CJK JP"
        defaultValue: ""
    }

    StyledText {
        width: parent.width
        text: "Audio"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    ToggleSetting {
        settingKey: "autoPlay"
        label: "Play automatically"
        description: "Play every new sentence as it appears (only the instance that picked it plays)"
        defaultValue: false
    }

    StringSetting {
        settingKey: "playerCommand"
        label: "Audio player command"
        description: "Plays the deck's mp3 clip, {file} is replaced by its path. Empty: first of mpv, ffplay, pw-play, paplay found on PATH"
        placeholder: "mpv --no-video {file}"
        defaultValue: ""
    }

    StyledText {
        width: parent.width
        text: "Bar pill & popout"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    ToggleSetting { settingKey: "barReading"; label: "Hiragana reading in the pill"; defaultValue: false }

    SliderSetting {
        settingKey: "barMaxWidth"
        label: "Pill max width"
        description: "Longer sentences are cut with …"
        defaultValue: 360
        minimum: 120
        maximum: 1200
        unit: "px"
    }

    SliderSetting {
        settingKey: "popoutWidth"
        label: "Popout width"
        defaultValue: 380
        minimum: 240
        maximum: 800
        unit: "px"
    }

    SliderSetting {
        settingKey: "popoutMainSize"
        label: "Popout sentence size"
        defaultValue: 28
        minimum: 14
        maximum: 72
        unit: "px"
    }

    StyledText {
        width: parent.width
        text: "Desktop widget"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    SliderSetting {
        settingKey: "desktopMainSize"
        label: "Sentence size"
        defaultValue: 28
        minimum: 12
        maximum: 96
        unit: "px"
    }

    ToggleSetting { settingKey: "showReading"; label: "Show hiragana reading"; defaultValue: true }
    ToggleSetting { settingKey: "showRomaji"; label: "Show romaji"; defaultValue: false }
    ToggleSetting { settingKey: "showMeaning"; label: "Show English meaning"; defaultValue: true }
    ToggleSetting { settingKey: "showSource"; label: "Show the anime it is from"; defaultValue: false }
    ToggleSetting {
        settingKey: "desktopTextShadow"
        label: "Text outline"
        description: "Keeps text readable on light wallpapers"
        defaultValue: true
    }

    SliderSetting {
        settingKey: "desktopBackgroundOpacity"
        label: "Background opacity"
        description: "0 = fully transparent, text straight on the wallpaper"
        defaultValue: 0
        minimum: 0
        maximum: 100
        unit: "%"
    }
}
