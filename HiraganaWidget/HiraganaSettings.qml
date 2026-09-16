import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "hiraganaWidget"

    StyledText {
        width: parent.width
        text: "Content"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    ToggleSetting { settingKey: "showHiragana"; label: "Hiragana"; defaultValue: true }
    ToggleSetting { settingKey: "showKatakana"; label: "Katakana too"; defaultValue: false }
    ToggleSetting {
        settingKey: "showVoiced"
        label: "Voiced kana (が, ざ, だ, ば, ぱ …)"
        defaultValue: true
    }
    ToggleSetting {
        settingKey: "showCombos"
        label: "Combination kana (きゃ, しゅ, ちょ …)"
        defaultValue: true
    }

    SliderSetting {
        settingKey: "interval"
        label: "Seconds per kana"
        defaultValue: 20
        minimum: 3
        maximum: 600
        unit: "s"
    }

    ToggleSetting {
        settingKey: "shuffle"
        label: "Random order"
        description: "Off = go through the table in gojūon order (あ い う え お, か き …)"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "syncInstances"
        label: "Same kana everywhere"
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
        label: "Speak automatically"
        description: "Say every new kana as it appears (only the instance that picked it speaks)"
        defaultValue: false
    }

    StringSetting {
        settingKey: "ttsCommand"
        label: "Text-to-speech command"
        description: "{text} is replaced by the kana. espeak-ng: pacman -S espeak-ng. See the README for piper"
        placeholder: "espeak-ng -v ja -s 110 {text}"
        defaultValue: ""
    }

    StyledText {
        width: parent.width
        text: "Bar pill & popout"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    ToggleSetting { settingKey: "barRomaji"; label: "Romaji in the pill"; defaultValue: true }

    SliderSetting {
        settingKey: "popoutWidth"
        label: "Popout width"
        defaultValue: 280
        minimum: 200
        maximum: 600
        unit: "px"
    }

    SliderSetting {
        settingKey: "popoutMainSize"
        label: "Popout kana size"
        defaultValue: 96
        minimum: 32
        maximum: 200
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
        label: "Kana size"
        defaultValue: 64
        minimum: 16
        maximum: 200
        unit: "px"
    }

    ToggleSetting { settingKey: "showReading"; label: "Show romaji"; defaultValue: true }
    ToggleSetting { settingKey: "showSet"; label: "Show hiragana / katakana tag"; defaultValue: false }
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
