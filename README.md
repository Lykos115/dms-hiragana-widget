# Jlab sentences — Dank Material Shell plugin

Rotates through the anime sentences of
[Jlab's beginner course](https://ankiweb.net/shared/info/911122782) (the
Anki deck "Japanese course based on Tae Kim's grammar guide & anime" from
[Japanese Like a Breeze](https://www.japanese-like-a-breeze.com/)): the
sentence as written, its hiragana reading, romaji, the English meaning and
the deck's audio clip of the line. Rendered by Dank Material Shell itself.
One plugin, two surfaces (DMS ≥ 1.5.0 composite plugin):

* **Bar pill** — the current sentence in the DankBar (cut with … past a
  set width). Left click opens a popout card with the sentence, reading,
  romaji, meaning and *Play* / *Next* buttons. Right click skips to the next
  sentence. With *open popouts on hover* enabled in the bar settings the
  card opens on hover.
* **Desktop widget** — text on the wallpaper layer, fixed where you put it.
  Right-click drag moves it, the corner handle resizes it, left click skips
  to the next sentence, middle click plays it.

Both surfaces share the settings. By default every instance (all monitors,
bar and desktop) shows the same sentence; turn off *Same sentence everywhere*
for independent rotations.

The kana tables this plugin used to show live in their own plugins now:
[Hiragana / Katakana](https://nemiru.tail2e41a3.ts.net/lykos/dms-katakana-widget)
and [JLPT Kanji](https://nemiru.tail2e41a3.ts.net/lykos/dms-kanji-widget).

## Install

```sh
git clone https://nemiru.tail2e41a3.ts.net/lykos/dms-hiragana-widget.git ~/dms-hiragana-widget
~/dms-hiragana-widget/install.sh          # symlink into ~/.config/DankMaterialShell/plugins
~/dms-hiragana-widget/install.sh copy     # ...or copy, if you want to delete the clone
```

Then import the deck (next section), and in DMS: **Settings → Plugins →
Scan for Plugins**, toggle *Jlab sentences* on. Add `jlabWidget` to a bar
section under **Settings → DankBar → layout**, and/or add the desktop widget
under **Settings → Desktop Widgets**. Settings (timing, sizes, audio) are in
the plugin's accordion in the Plugins tab.

Japanese text needs a CJK font: `sudo pacman -S noto-fonts-cjk`.

Reload after editing the QML: `dms ipc call plugins reload jlabWidget`.
If you had the old Hiragana plugin installed, run `install.sh` again (the
plugin directory is now `JlabWidget`) and remove the stale `HiraganaWidget`
link from `~/.config/DankMaterialShell/plugins/`.

## Importing the deck

The sentences and clips are not in this repo (the audio is the deck's
copyrighted anime audio). AnkiWeb only serves the `.apkg` to a logged-in
account, so:

1. Log in to AnkiWeb in a browser, open
   https://ankiweb.net/shared/info/911122782 and press *Download* (about
   111 MB).
2. Run the importer on the file:

```sh
python3 ~/dms-hiragana-widget/import-jlab ~/Downloads/Japanese_course_based_on_Tae_Kims_grammar_guide__anime.apkg
```

It writes `JlabWidget/data/jlab/`:

| file | content |
|---|---|
| `sentences.json` | one entry per note, in course order: `sentence` (as written, kanji and kana), `hiragana` (words separated by spaces), `words`, `romaji`, `meaning` (first line of the deck's remark), `source` (the anime), `audio` (clip path) |
| `words.json` | every word of those sentences, most common first, with romaji and the deck's gloss where it gives one. The deck has no per-word audio |
| `media/*.mp3` | the sentence clips |

Only the "Part 1: Listening comprehension" subdeck is taken by default.
Useful variants:

```sh
python3 import-jlab deck.apkg --list-fields   # decks, note types and a sample note
python3 import-jlab deck.apkg --deck ''       # every subdeck
python3 import-jlab deck.apkg --limit 300     # only the first 300 sentences
python3 import-jlab deck.apkg --no-media      # text only, no clips
```

Needs only Python 3 plus the `zstd` command (or the `zstandard` module) for
the current package format. `data/jlab/` is git-ignored; never commit it.
Re-running the importer overwrites the JSON and only extracts clips that are
not there yet. Reload the plugin afterwards:
`dms ipc call plugins reload jlabWidget`.

## Settings

| section | keys |
|---|---|
| Content | **seconds per sentence** (3–600), only the first N sentences, random / course order, same sentence everywhere, Japanese font |
| Audio | play automatically, audio player command |
| Bar pill & popout | hiragana reading in the pill, pill max width, popout width, popout sentence size |
| Desktop widget | sentence size, show reading / romaji / meaning / anime, text outline, background opacity |

## Audio

*Play* in the popout (or middle click on the desktop widget) plays the
sentence's clip from `JlabWidget/data/jlab/media/`. The clips are MP3, so
the player is picked at run time as the first of `mpv`, `ffplay`, `pw-play`,
`paplay` on PATH (`pw-play` and `paplay` only decode MP3 with a recent
libsndfile, which is why they come last). *Audio player command* overrides
that, e.g. `mpv --no-video {file}`; it is split on whitespace and run
without a shell, so `{file}` must be a whole argument.

*Play automatically* plays every new sentence as it appears. Only the
instance that picked the sentence plays it, so with *Same sentence
everywhere* on you hear it once even with several pills and widgets.

No sound? (1) `mpv ~/dms-hiragana-widget/JlabWidget/data/jlab/media/0.mp3`
in a terminal must work. (2) Press *Play* and read `~/.cache/jlab-widget.log`:
every attempt logs the clip path, the player it picked and any error. (3) If
the log stays empty DMS is running an old copy of the plugin: `install.sh`
symlinks the clone so pulls apply directly, and `dms kill; dms run -d`
restarts the shell (`dms ipc call plugins reload jlabWidget` keeps
cached QML). (4) A player that only lives in `~/.local/bin` is not on DMS's
PATH: set *Audio player command* to its full path.

## Files

| file | role |
|---|---|
| `import-jlab` | extracts sentences, words and clips from the Jlab `.apkg` into `JlabWidget/data/jlab/` (git-ignored) |
| `JlabWidget/plugin.json` | composite manifest, `widget` + `desktop` surfaces |
| `JlabWidget/JlabDeck.qml` | loads `data/jlab/sentences.json`, rotates on a timer, plays the clip |
| `JlabWidget/JlabBarWidget.qml` | `PluginComponent`: pill + popout |
| `JlabWidget/JlabDesktopWidget.qml` | `DesktopPluginComponent` |
| `JlabWidget/JlabSettings.qml` | settings UI (`PluginSettings`) |
| `JlabWidget/data/jlab/` | the imported deck, not in git |

Status: written against the DMS `master` plugin API and syntax-checked with
`qmllint`, not yet run in a live DMS session with the real deck. If DMS logs
an error on load, `dms ipc call plugins reload jlabWidget` prints it.
