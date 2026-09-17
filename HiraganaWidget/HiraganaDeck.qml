import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

// Non-visual helper shared by the bar widget and the desktop widget.
// Loads data/kana.json, keeps the hiragana (plus katakana if enabled),
// rotates on a timer and plays the kana's clip on request.
Item {
    id: deck
    visible: false
    width: 0
    height: 0

    // plugin settings object (PluginComponent.pluginData / DesktopPluginComponent.pluginData)
    property var settings: ({})

    readonly property bool showHiragana: settings.showHiragana ?? true
    readonly property bool showKatakana: settings.showKatakana ?? false
    // ゃゅょ combinations (きゃ, しゅ, ...) and voiced kana (が, ぱ, ...)
    readonly property bool showCombos: settings.showCombos ?? true
    readonly property bool showVoiced: settings.showVoiced ?? true
    readonly property int intervalSeconds: Math.max(3, settings.interval ?? 20)
    readonly property bool shuffleOrder: settings.shuffle ?? true
    // keep every bar pill / desktop widget (all monitors) on the same kana
    readonly property bool syncInstances: settings.syncInstances ?? true
    readonly property bool autoPlay: settings.autoPlay ?? false
    // Audio: recorded clips in data/audio/<romaji>.wav (see gen-audio) played
    // with playerCommand; empty = pick pw-play / paplay / mpv / ffplay at run time.
    readonly property string playerCommand: String(settings.playerCommand ?? "").trim()
    readonly property string pluginId: "hiraganaWidget"
    property double lastStamp: 0

    // current item
    property string main: "…"
    property string reading: ""    // romaji
    property string tag: ""        // "hiragana" / "katakana"
    property bool ready: false
    readonly property bool hasAudio: main !== "" && main !== "…" && main !== "—"

    // raw data
    property var kana: []
    property var items: []
    property int pos: -1

    readonly property string dataDir: Qt.resolvedUrl("data").toString().replace(/^file:\/\//, "")

    FileView {
        path: deck.dataDir + "/kana.json"
        onLoaded: { deck.kana = JSON.parse(text()); deck.rebuild(); }
        onLoadFailed: err => console.warn("hiraganaWidget: cannot read", path, err)
    }

    onShowKatakanaChanged: rebuild()
    onShowHiraganaChanged: rebuild()
    onShowCombosChanged: rebuild()
    onShowVoicedChanged: rebuild()
    onShuffleOrderChanged: rebuild()

    Connections {
        target: PluginService
        function onGlobalVarChanged(pid, name) {
            if (pid === deck.pluginId && name === "current")
                deck.applyGlobal();
        }
    }

    function setCurrent(it) {
        main = it.main; reading = it.reading; tag = it.tag;
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

    function isCombo(k) {
        return k.length > 1 && /[ゃゅょャュョ]$/.test(k);
    }

    function isVoiced(k) {
        // dakuten / handakuten rows
        return /^[がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポ]/.test(k);
    }

    function rebuild() {
        const all = [];
        for (const k of kana) {
            if (k.set === "katakana" && !showKatakana) continue;
            if (k.set === "hiragana" && !showHiragana) continue;
            if (!showCombos && isCombo(k.kana)) continue;
            if (!showVoiced && isVoiced(k.kana)) continue;
            all.push({ main: k.kana, reading: k.romaji, tag: k.set });
        }
        // data is in gojūon order, which is the sequential order
        items = shuffleOrder ? shuffle(all) : all;
        pos = -1;
        ready = all.length > 0;
        if (ready) next(false);
        else { main = "—"; reading = "nothing selected"; tag = ""; }
    }

    function pick() {
        pos = (pos + 1) % items.length;
        if (pos === 0 && shuffleOrder) shuffle(items);
        return items[pos];
    }

    // force=true: user clicked, always advance. force=false: timer tick; if another
    // instance already advanced within this interval, adopt its kana instead.
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
                main: it.main, reading: it.reading, tag: it.tag, stamp: lastStamp
            });
        }
        // only the instance that picked the item plays it, so synced instances do not all talk at once
        if (autoPlay) play();
    }

    // jump straight to a kana (chart tap): publish it like next(true) and play it
    function show(it) {
        setCurrent(it);
        ready = true;
        ticker.restart();
        if (syncInstances) {
            lastStamp = Date.now();
            PluginService.setGlobalVar(pluginId, "current", {
                main: it.main, reading: it.reading, tag: it.tag, stamp: lastStamp
            });
        }
        play();
    }

    // --- chart -------------------------------------------------------------
    // The whole set as the gojūon table, flattened for a 5-column Grid: rows
    // of a i u e o, the ya row in columns a/u/o, the wa row in a/o, ん alone,
    // then the voiced rows and the ゃゅょ combinations (3 per row). Empty
    // cells have main "". kana.json lists each set in exactly this order.
    readonly property int chartColumns: 5

    function chartCells(set) {
        const list = kana.filter(k => k.set === set)
                         .map(k => ({ main: k.kana, reading: k.romaji, tag: k.set }));
        const gap = { main: "", reading: "", tag: "" };
        const cells = [];
        let i = 0;
        const row = pattern => {                     // pattern: 1 = next kana, 0 = empty cell
            if (i >= list.length) return;
            for (const p of pattern) cells.push(p && i < list.length ? list[i++] : gap);
        };
        for (let r = 0; r < 7; r++) row([1, 1, 1, 1, 1]);   // あ か さ た な は ま
        row([1, 0, 1, 0, 1]);                                // や
        row([1, 1, 1, 1, 1]);                                // ら
        row([1, 0, 0, 0, 1]);                                // わ
        row([1, 0, 0, 0, 0]);                                // ん
        for (let r = 0; r < 5; r++) row([1, 1, 1, 1, 1]);   // が ざ だ ば ぱ
        while (i < list.length) row([1, 1, 1, 0, 0]);       // きゃ …
        return cells;
    }

    // --- audio -------------------------------------------------------------
    // The command is split on whitespace, no shell involved; "{file}" must be
    // a whole argument and is replaced with the clip path.
    function argv(cmd, key, value) {
        return cmd.split(/\s+/).filter(t => t.length > 0).map(t => t === key ? value : t);
    }

    readonly property string clipFile: dataDir + "/audio/" + reading + ".wav"

    // first player found on PATH; each one drains the buffer before exiting,
    // so a 0.4 s clip is not cut short. Every call is logged to
    // ~/.cache/hiragana-widget.log because stderr goes nowhere under DMS.
    readonly property string autoPlayer:
        'f="$1"; log="${XDG_CACHE_HOME:-$HOME/.cache}/hiragana-widget.log"; ' +
        'mkdir -p "$(dirname "$log")"; exec 2>>"$log"; ' +
        'echo "$(date "+%F %T") play $f (PATH=$PATH)" >&2; ' +
        '[ -f "$f" ] || { echo "  clip not found" >&2; exit 1; }; ' +
        'for p in pw-play paplay; do command -v "$p" >/dev/null && { echo "  using $p" >&2; exec "$p" "$f"; }; done; ' +
        'command -v mpv    >/dev/null && { echo "  using mpv" >&2; exec mpv --no-video --really-quiet "$f"; }; ' +
        'command -v ffplay >/dev/null && { echo "  using ffplay" >&2; exec ffplay -nodisp -autoexit -loglevel quiet -af apad=pad_dur=0.3 "$f"; }; ' +
        'echo "  no audio player found (pw-play, paplay, mpv, ffplay)" >&2; exit 1'

    function play() {
        if (!hasAudio) return;
        if (playerCommand !== "")
            Quickshell.execDetached(argv(playerCommand, "{file}", clipFile));
        else
            Quickshell.execDetached(["sh", "-c", autoPlayer, "sh", clipFile]);
    }
}
