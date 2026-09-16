# Hiragana — Dank Material Shell plugin

Rotates through the hiragana table (104 kana including voiced and combination
kana; katakana can be switched on too) with romaji, rendered by Dank Material
Shell itself. One plugin, two surfaces (DMS ≥ 1.5.0 composite plugin):

* **Bar pill** — the current kana (plus romaji) in the DankBar. Left click
  opens a popout card with the kana, its romaji and *Play* / *Next* buttons.
  Right click skips to the next kana. With *open popouts on hover* enabled
  in the bar settings the card opens on hover.
* **Desktop widget** — text on the wallpaper layer, fixed where you put it.
  Right-click drag moves it, the corner handle resizes it, left click skips
  to the next kana, middle click speaks it.

Both surfaces share the settings. By default every instance (all monitors,
bar and desktop) shows the same kana; turn off *Same kana everywhere* for
independent rotations.

Sibling plugins: [Katakana](https://nemiru.tail2e41a3.ts.net/lykos/dms-katakana-widget),
[JLPT Kanji](https://nemiru.tail2e41a3.ts.net/lykos/dms-kanji-widget) and [JLPT vocab + Jlab listening](https://nemiru.tail2e41a3.ts.net/lykos/jlpt-kanji-widget)
(the `dms-plugin` branch).

## Install

```sh
git clone https://nemiru.tail2e41a3.ts.net/lykos/dms-hiragana-widget.git ~/dms-hiragana-widget
~/dms-hiragana-widget/install.sh          # symlink into ~/.config/DankMaterialShell/plugins
~/dms-hiragana-widget/install.sh copy     # ...or copy, if you want to delete the clone
```

Then in DMS: **Settings → Plugins → Scan for Plugins**, toggle *Hiragana* on.
Add `hiraganaWidget` to a bar section under **Settings → DankBar → layout**,
and/or add the desktop widget under **Settings → Desktop Widgets**. Settings
(sets, timing, sizes, audio) are in the plugin's accordion in the Plugins tab.

Japanese text needs a CJK font: `sudo pacman -S noto-fonts-cjk`.

Reload after editing the QML: `dms ipc call plugins reload hiraganaWidget`.

## Settings

| section | keys |
|---|---|
| Content | hiragana, katakana too, voiced kana, combination kana, **seconds per kana** (3–600), random / gojūon order, same kana everywhere, Japanese font |
| Audio | speak automatically, text-to-speech command |
| Bar pill & popout | romaji in the pill, popout width, popout kana size |
| Desktop widget | kana size, show romaji, show set tag, text outline, background opacity |

## Audio

*Play* in the popout (or middle click on the desktop widget) says the kana
with the *Text-to-speech command*, `{text}` replaced by the kana. Default is
`espeak-ng -v ja -s 110 {text}` — `sudo pacman -S espeak-ng`. Its Japanese
voice is robotic but the single syllables are clear. For a natural voice
install [piper](https://github.com/rhasspy/piper) with a Japanese model and
set the command to a small wrapper, e.g. `~/.local/bin/say-ja {text}` with

```sh
#!/bin/sh
echo "$1" | piper --model ~/piper/ja_JP-test-medium.onnx --output-raw | aplay -r 22050 -f S16_LE -t raw -
```

The command is split on whitespace and run without a shell, so `{text}` must
be a whole argument.

*Speak automatically* says every new kana as it appears. Only the instance
that picked the kana speaks, so with *Same kana everywhere* on you hear it
once even with several pills and widgets.

## Files

| file | role |
|---|---|
| `HiraganaWidget/plugin.json` | composite manifest, `widget` + `desktop` surfaces |
| `HiraganaWidget/HiraganaDeck.qml` | loads `data/kana.json`, filters, rotates on a timer, speaks |
| `HiraganaWidget/HiraganaBarWidget.qml` | `PluginComponent`: pill + popout |
| `HiraganaWidget/HiraganaDesktopWidget.qml` | `DesktopPluginComponent` |
| `HiraganaWidget/HiraganaSettings.qml` | settings UI (`PluginSettings`) |
| `HiraganaWidget/data/kana.json` | hiragana + katakana with romaji, in gojūon order |

Status: written against the DMS `master` plugin API and syntax-checked with
`qmllint`, not yet run in a live DMS session. If DMS logs an error on load,
`dms ipc call plugins reload hiraganaWidget` prints it.
