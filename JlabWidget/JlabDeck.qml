import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

// Non-visual helper shared by the bar widget and the desktop widget.
// Loads data/jlab/sentences.json (written by import-jlab), rotates on a
// timer and plays the current sentence's clip on request.
Item {
    id: deck
    visible: false
    width: 0
    height: 0

    // plugin settings object (PluginComponent.pluginData / DesktopPluginComponent.pluginData)
    property var settings: ({})

    readonly property int intervalSeconds: Math.max(3, settings.interval ?? 30)
    readonly property bool shuffleOrder: settings.shuffle ?? false
    // only the first N sentences in course order (0 = all); the course gets harder as it goes
    readonly property int maxSentences: Math.max(0, settings.maxSentences ?? 0)
    // keep every bar pill / desktop widget (all monitors) on the same sentence
    readonly property bool syncInstances: settings.syncInstances ?? true
    readonly property bool autoPlay: settings.autoPlay ?? false
    // Audio: the deck's clip in data/jlab/media/ played with playerCommand;
    // empty = pick pw-play / paplay / mpv / ffplay at run time.
    readonly property string playerCommand: String(settings.playerCommand ?? "").trim()
    readonly property string pluginId: "jlabWidget"
    property double lastStamp: 0

    // current item
    property string main: "…"        // sentence as written (kanji and kana)
    property string reading: ""      // hiragana, words separated by spaces
    property string romaji: ""
    property string meaning: ""      // English
    property string source: ""       // the anime it is from
    property string audio: ""        // "media/<n>.mp3", relative to data/jlab
    property bool ready: false
    readonly property bool hasAudio: audio !== ""

    // raw data
    property var sentences: []
    property var items: []
    property int pos: -1

    readonly property string dataDir: Qt.resolvedUrl("data").toString().replace(/^file:\/\//, "")

    FileView {
        path: deck.dataDir + "/jlab/sentences.json"
        onLoaded: { deck.sentences = JSON.parse(text()); deck.rebuild(); }
        onLoadFailed: err => {
            console.warn("jlabWidget: cannot read", path, err, "- run import-jlab first");
            deck.main = "no sentences";
            deck.reading = "run import-jlab (see README)";
        }
    }

    onShuffleOrderChanged: rebuild()
    onMaxSentencesChanged: rebuild()

    Connections {
        target: PluginService
        function onGlobalVarChanged(pid, name) {
            if (pid === deck.pluginId && name === "current")
                deck.applyGlobal();
        }
    }

    function setCurrent(it) {
        main = it.main; reading = it.reading; romaji = it.romaji;
        meaning = it.meaning; source = it.source; audio = it.audio;
    }

    // adopt the shared item if another instance published a newer one
    function applyGlobal() {
        if (!syncInstances) return false;
        const g = PluginService.getGlobalVar(pluginId, "current", null);
        if (!g || !g.stamp || g.stamp === lastStamp) return false;
        lastStamp = g.stamp;
        setCurrent(g);
        ready = true;
        ticker.restart();
        return true;
    }

    Timer {
        id: ticker
        interval: deck.intervalSeconds * 1000
        running: deck.ready
        repeat: true
        onTriggered: deck.next(false)
    }

    function shuffle(a) {
        for (let i = a.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            const t = a[i]; a[i] = a[j]; a[j] = t;
        }
        return a;
    }

    function rebuild() {
        const all = [];
        const limit = maxSentences > 0 ? Math.min(maxSentences, sentences.length) : sentences.length;
        for (let i = 0; i < limit; i++) {
            const s = sentences[i];
            all.push({
                main: s.sentence || s.hiragana || "",
                reading: s.hiragana || "",
                romaji: s.romaji || "",
                meaning: s.meaning || "",
                source: s.source || "",
                audio: s.audio || ""
            });
        }
        // sentences.json is in course order, which is the sequential order
        items = shuffleOrder ? shuffle(all) : all;
        pos = -1;
        ready = all.length > 0;
        if (ready) next(false);
        else { main = "no sentences"; reading = "run import-jlab (see README)"; romaji = ""; meaning = ""; source = ""; audio = ""; }
    }

    function pick() {
        pos = (pos + 1) % items.length;
        if (pos === 0 && shuffleOrder) shuffle(items);
        return items[pos];
    }

    // force=true: user clicked, always advance. force=false: timer tick; if another
    // instance already advanced within this interval, adopt its sentence instead.
    function next(force) {
        if (!ready) return;
        if (syncInstances && !force) {
            const g = PluginService.getGlobalVar(pluginId, "current", null);
            if (g && g.stamp && Date.now() - g.stamp < intervalSeconds * 1000 - 1500) {
                if (g.stamp !== lastStamp) applyGlobal();
                else ticker.restart();
                return;
            }
        }
        const it = pick();
        setCurrent(it);
        ticker.restart();
        if (syncInstances) {
            lastStamp = Date.now();
            PluginService.setGlobalVar(pluginId, "current", {
                main: it.main, reading: it.reading, romaji: it.romaji, meaning: it.meaning,
                source: it.source, audio: it.audio, stamp: lastStamp
            });
        }
        // only the instance that picked the item plays it, so synced instances do not all talk at once
        if (autoPlay) play();
    }

    // --- audio -------------------------------------------------------------
    // The command is split on whitespace, no shell involved; "{file}" must be
    // a whole argument and is replaced with the clip path.
    function argv(cmd, key, value) {
        return cmd.split(/\s+/).filter(t => t.length > 0).map(t => t === key ? value : t);
    }

    readonly property string clipFile: dataDir + "/jlab/" + audio

    // first player found on PATH; each one drains the buffer before exiting.
    // Every call is logged to ~/.cache/jlab-widget.log because stderr goes
    // nowhere under DMS.
    readonly property string autoPlayer:
        'f="$1"; log="${XDG_CACHE_HOME:-$HOME/.cache}/jlab-widget.log"; ' +
        'mkdir -p "$(dirname "$log")"; exec 2>>"$log"; ' +
        'echo "$(date "+%F %T") play $f (PATH=$PATH)" >&2; ' +
        '[ -f "$f" ] || { echo "  clip not found" >&2; exit 1; }; ' +
        'command -v mpv    >/dev/null && { echo "  using mpv" >&2; exec mpv --no-video --really-quiet "$f"; }; ' +
        'command -v ffplay >/dev/null && { echo "  using ffplay" >&2; exec ffplay -nodisp -autoexit -loglevel quiet "$f"; }; ' +
        'for p in pw-play paplay; do command -v "$p" >/dev/null && { echo "  using $p" >&2; exec "$p" "$f"; }; done; ' +
        'echo "  no audio player found (mpv, ffplay, pw-play, paplay)" >&2; exit 1'

    function play() {
        if (!hasAudio) return;
        if (playerCommand !== "")
            Quickshell.execDetached(argv(playerCommand, "{file}", clipFile));
        else
            Quickshell.execDetached(["sh", "-c", autoPlayer, "sh", clipFile]);
    }
}
