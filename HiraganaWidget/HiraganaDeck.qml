import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

// Non-visual helper shared by the bar widget and the desktop widget.
// Loads data/kana.json, keeps the hiragana (plus katakana if enabled),
// rotates on a timer and speaks the kana on request.
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
    readonly property string ttsCommand: (settings.ttsCommand ?? "") !== "" ? settings.ttsCommand : "espeak-ng -v ja -s 110 {text}"
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

    // --- audio -------------------------------------------------------------
    // The command is split on whitespace, no shell involved; "{text}" must be
    // a whole argument and is replaced with the kana.
    function argv(cmd, key, value) {
        return cmd.split(/\s+/).filter(t => t.length > 0).map(t => t === key ? value : t);
    }

    function play() {
        if (!hasAudio) return;
        Quickshell.execDetached(argv(ttsCommand, "{text}", main));
    }
}
