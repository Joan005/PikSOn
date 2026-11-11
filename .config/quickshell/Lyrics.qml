import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: lyr

    property var player: null
    property bool active: false

    property var lines: []
    property string status: "idle"
    property string key: ""
    property var cache: ({})
    property string qArtist: ""
    property string qTrack: ""
    property int qDur: 0

    readonly property bool hasLength: player !== null && player.lengthSupported && player.length > 0
    readonly property string rawKey: player ? (player.trackTitle + "|" + player.trackArtist) : ""
    readonly property int curLine: lineAt(player ? player.position : 0)

    readonly property string url1: "https://lrclib.net/api/search?track_name=" + encodeURIComponent(qTrack) + "&artist_name=" + encodeURIComponent(qArtist)
    readonly property string url2: "https://lrclib.net/api/search?q=" + encodeURIComponent(qArtist + " " + qTrack)

    function cleanTitle(t) {
        return t.replace(/\(.*?\)|\[.*?\]/g, "")
                .replace(/official\s*(music\s*)?(video|audio)|lyric(s)?\s*video|lyrics|\bhd\b|\bhq\b|\b4k\b/ig, "")
                .replace(/\s+/g, " ").trim()
    }

    function cleanArtist(a) {
        return a.replace(/\s*-\s*topic$/i, "").replace(/vevo$/i, "").trim()
    }

    function parseLrc(text) {
        var out = []
        var rows = text.split("\n")
        for (var i = 0; i < rows.length; i++) {
            var re = /\[(\d+):(\d+(?:\.\d+)?)\]/g
            var m
            var stamps = []
            while ((m = re.exec(rows[i])) !== null)
                stamps.push(parseInt(m[1]) * 60 + parseFloat(m[2]))
            if (stamps.length === 0)
                continue
            var txt = rows[i].replace(/\[[^\]]*\]/g, "").trim()
            if (txt === "")
                txt = "♪"
            for (var j = 0; j < stamps.length; j++)
                out.push({ t: stamps[j], text: txt })
        }
        out.sort(function (a, b) { return a.t - b.t })
        return out
    }

    function lineAt(pos) {
        var l = lines
        var p = pos + 0.3
        var lo = 0
        var hi = l.length - 1
        var ans = -1
        while (lo <= hi) {
            var mid = (lo + hi) >> 1
            if (l[mid].t <= p) {
                ans = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return ans < 0 ? 0 : ans
    }

    function pick(arr) {
        var best = null
        var bd = 1e9
        for (var i = 0; i < arr.length; i++) {
            var r = arr[i]
            if (!r.syncedLyrics)
                continue
            var d = lyr.qDur > 0 ? Math.abs((r.duration || 0) - lyr.qDur) : 0
            if (d < bd) {
                bd = d
                best = r
            }
        }
        return best
    }

    function finish(k, rec) {
        if (k !== lyr.key)
            return
        var c = lyr.cache
        if (rec) {
            var l = parseLrc(rec.syncedLyrics)
            c[k] = l
            lyr.lines = l
            lyr.status = l.length > 0 ? "ok" : "none"
        } else {
            c[k] = []
            lyr.lines = []
            lyr.status = "none"
        }
    }

    function ensure() {
        if (!active || !player)
            return
        var t = cleanTitle(player.trackTitle || "")
        var a = cleanArtist(player.trackArtist || "")
        var i = t.indexOf(" - ")
        if (i > 0) {
            a = t.substring(0, i).trim()
            t = t.substring(i + 3).trim()
        }
        if (t === "") {
            status = "none"
            lines = []
            return
        }
        var k = a + "|" + t
        if (k === key)
            return
        key = k
        qArtist = a
        qTrack = t
        qDur = hasLength ? Math.round(player.length) : 0
        if (cache[k] !== undefined) {
            lines = cache[k]
            status = lines.length > 0 ? "ok" : "none"
            return
        }
        lines = []
        status = "loading"
        search1.running = true
    }

    onRawKeyChanged: ensure()
    onActiveChanged: {
        if (active)
            ensure()
    }
    onPlayerChanged: ensure()

    Process {
        id: search1
        command: ["curl", "-s", "-m", "10", lyr.url1]
        stdout: StdioCollector {
            onStreamFinished: {
                var k = lyr.key
                var rec = null
                try {
                    rec = lyr.pick(JSON.parse(this.text))
                } catch (e) {
                }
                if (rec)
                    lyr.finish(k, rec)
                else
                    search2.running = true
            }
        }
    }

    Process {
        id: search2
        command: ["curl", "-s", "-m", "10", lyr.url2]
        stdout: StdioCollector {
            onStreamFinished: {
                var rec = null
                try {
                    rec = lyr.pick(JSON.parse(this.text))
                } catch (e) {
                }
                lyr.finish(lyr.key, rec)
            }
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: lyr.active && lyr.player !== null && lyr.player.isPlaying
        onTriggered: lyr.player.positionChanged()
    }
}
