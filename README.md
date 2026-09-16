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
voice is robotic but the single syllables are clear.

For a natural voice use [Piper](https://github.com/OHF-Voice/piper1-gpl)
(the maintained successor of rhasspy/piper) with its Japanese voice:

```sh
pipx install "piper-tts[http,ja]"       # ja = Japanese phonemizer (OpenJTalk), http = server
install -Dm755 ~/dms-hiragana-widget/say-ja ~/.local/bin/say-ja
say-ja setup                            # downloads the ja_JA-hi_fi_captain-medium voice
say-ja テスト                            # try it
```

Already installed without the `ja` extra (error `No module named
'pyopenjtalk'`)? Add it: `pipx inject piper-tts pyopenjtalk-plus`.

and set the *Text-to-speech command* to `say-ja {text}`. `say-ja` plays the clip with `pw-play`, `paplay`, `mpv` or `ffplay`, whichever exists;
through `ffplay` (`sudo pacman -S ffmpeg`). The CLI reloads the model on
every call, about a second of delay; for instant playback run `say-ja server`
once, e.g. from niri's `spawn-at-startup`, and `say-ja` uses it automatically.
`say-ja setup` / `say-ja server` run Piper's modules with the Python that owns
the `piper` command, so `python3 -m piper ...` is never needed (with pipx it
fails: the system Python cannot see the package). `PIPER_VOICE`,
`PIPER_DATA_DIR` and `PIPER_PORT` override the defaults.

No sound from the widget? `say-ja` adds `~/.local/bin` to its own PATH and
logs every call to `~/.cache/say-ja.log`, so: (1) `say-ja テスト` in a
terminal must work first; (2) click *Play* in the popout (or middle-click the
desktop widget), *Speak automatically* is off by default; (3) if the log stays
empty DMS did not find the script, set the command to the full path
`/home/YOU/.local/bin/say-ja {text}`; (4) otherwise the log says what failed.
The command is split on whitespace and run without a shell, so `{text}` must
be a whole argument.

*Speak automatically* says every new kana as it appears. Only the instance
that picked the kana speaks, so with *Same kana everywhere* on you hear it
once even with several pills and widgets.

## Files

| file | role |
|---|---|
| `say-ja` | Piper text-to-speech wrapper, see Audio |
| `HiraganaWidget/plugin.json` | composite manifest, `widget` + `desktop` surfaces |
| `HiraganaWidget/HiraganaDeck.qml` | loads `data/kana.json`, filters, rotates on a timer, speaks |
| `HiraganaWidget/HiraganaBarWidget.qml` | `PluginComponent`: pill + popout |
| `HiraganaWidget/HiraganaDesktopWidget.qml` | `DesktopPluginComponent` |
| `HiraganaWidget/HiraganaSettings.qml` | settings UI (`PluginSettings`) |
| `HiraganaWidget/data/kana.json` | hiragana + katakana with romaji, in gojūon order |

Status: written against the DMS `master` plugin API and syntax-checked with
`qmllint`, not yet run in a live DMS session. If DMS logs an error on load,
`dms ipc call plugins reload hiraganaWidget` prints it.
