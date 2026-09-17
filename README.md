# Hiragana — Dank Material Shell plugin

Rotates through the hiragana table (104 kana including voiced and combination
kana; katakana can be switched on too) with romaji, rendered by Dank Material
Shell itself. One plugin, two surfaces (DMS ≥ 1.5.0 composite plugin):

* **Bar pill** — the current kana (plus romaji) in the DankBar. Left click
  opens a popout with two tabs: *Card* (the kana, its romaji and *Play* /
  *Next* buttons) and *Chart* (the whole gojūon table; tap a kana to make it
  the current one and hear it). Right click skips to the next kana. With
  *open popouts on hover* enabled in the bar settings the popout opens on
  hover.
* **Desktop widget** — text on the wallpaper layer, fixed where you put it.
  Right-click drag moves it, the corner handle resizes it, left click skips
  to the next kana, middle click plays it.

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
| Audio | play automatically, audio player command |
| Bar pill & popout | romaji in the pill, open the popout on the chart, popout width, popout kana size, chart height |
| Desktop widget | kana size, show romaji, show set tag, text outline, background opacity |

## Audio

*Play* in the popout (or middle click on the desktop widget) plays a recording
of the kana from `HiraganaWidget/data/audio/<romaji>.wav`. The recordings are
by a native speaker, from
[Learn Japanese Adventure](https://www.learn-japanese-adventure.com/learn-to-speak-japanese-online.html)
(the kana sound files on that page). They remain that site's property and are
bundled here with credit only. `gen-audio` downloads them, trims the silence,
levels them all to the same loudness and writes the WAVs; one clip per romaji
reading, shared by hiragana and katakana. To re-fetch:

```sh
python3 -m venv .venv && .venv/bin/pip install numpy    # plus ffmpeg and curl on PATH
.venv/bin/python gen-audio
```

The player is picked at run time: the first of `pw-play`, `paplay`, `mpv`,
`ffplay` on PATH (all of them drain the buffer before exiting, so short clips
are not cut). *Audio player command* overrides that, e.g. `pw-play {file}`;
it is split on whitespace and run without a shell, so `{file}` must be a
whole argument.

*Play automatically* plays every new kana as it appears. Only the instance
that picked the kana plays it, so with *Same kana everywhere* on you hear it
once even with several pills and widgets.

No sound? (1) `pw-play ~/dms-hiragana-widget/HiraganaWidget/data/audio/ka.wav`
in a terminal must work. (2) Press *Play* and read `~/.cache/hiragana-widget.log`:
every attempt logs the clip path, the player it picked and any error. (3) If
the log stays empty DMS is running an old copy of the plugin: `install.sh`
symlinks the clone so pulls apply directly, and `dms kill; dms run -d`
restarts the shell (`dms ipc call plugins reload hiraganaWidget` keeps
cached QML). (4) A player that only lives in `~/.local/bin` is not on DMS's
PATH: set *Audio player command* to its full path.

Why recordings and not text-to-speech: no offline engine says a lone mora
well. Piper's Japanese voice is trained on sentences and on a single kana
returns a different length every call, chops the vowel and renders ン as a
click (a speech recogniser identified 5 of 104 kana); espeak-ng and Open
JTalk are steadier but their consonants are weak (21 and 30 of 104).

## Files

| file | role |
|---|---|
| `gen-audio` | builds `data/audio/*.wav` from the Learn Japanese Adventure recordings, see Audio |
| `HiraganaWidget/plugin.json` | composite manifest, `widget` + `desktop` surfaces |
| `HiraganaWidget/HiraganaDeck.qml` | loads `data/kana.json`, filters, rotates on a timer, lays out the chart, plays the clip |
| `HiraganaWidget/HiraganaBarWidget.qml` | `PluginComponent`: pill + popout (Card / Chart tabs) |
| `HiraganaWidget/HiraganaDesktopWidget.qml` | `DesktopPluginComponent` |
| `HiraganaWidget/HiraganaSettings.qml` | settings UI (`PluginSettings`) |
| `HiraganaWidget/data/kana.json` | hiragana + katakana with romaji, in gojūon order |
| `HiraganaWidget/data/audio/` | one clip per romaji reading (hiragana and katakana share them), recordings © Learn Japanese Adventure |

Status: written against the DMS `master` plugin API and syntax-checked with
`qmllint`, not yet run in a live DMS session. If DMS logs an error on load,
`dms ipc call plugins reload hiraganaWidget` prints it.
