import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: w

    property real lat: 41.3851
    property real lon: 2.1734
    property bool ready: false
    property bool failed: false
    property real temp: 0
    property real feels: 0
    property int code: 0
    property bool isDay: true
    property string sunrise: ""
    property string sunset: ""
    property var hours: []
    property var days: []

    readonly property string url: "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,apparent_temperature,weather_code,is_day&hourly=temperature_2m,weather_code,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset&timezone=Europe%2FMadrid&forecast_days=6"

    function describe(c) {
        if (c === 0)
            return "Despejado"
        if (c === 1)
            return "Mayormente despejado"
        if (c === 2)
            return "Parcialmente nublado"
        if (c === 3)
            return "Nublado"
        if (c === 45 || c === 48)
            return "Niebla"
        if (c >= 51 && c <= 57)
            return "Llovizna"
        if (c >= 61 && c <= 67)
            return "Lluvia"
        if (c >= 71 && c <= 77)
            return "Nieve"
        if (c >= 80 && c <= 82)
            return "Chubascos"
        if (c === 85 || c === 86)
            return "Chubascos de nieve"
        if (c >= 95)
            return "Tormenta"
        return "—"
    }

    function glyph(c, day) {
        if (c === 0 || c === 1)
            return day ? "\ue30d" : "\ue32b"
        if (c === 2)
            return day ? "\ue302" : "\ue312"
        if (c === 3)
            return "\ue312"
        if (c === 45 || c === 48)
            return "\ue313"
        if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82))
            return "\ue318"
        if ((c >= 71 && c <= 77) || c === 85 || c === 86)
            return "\ue31a"
        if (c >= 95)
            return "\ue31d"
        return "\ue312"
    }

    function refresh() {
        proc.running = true
    }

    function parse(text) {
        try {
            var j = JSON.parse(text)
            var c = j.current
            var d = j.daily
            var h = j.hourly
            w.temp = c.temperature_2m
            w.feels = c.apparent_temperature
            w.code = c.weather_code
            w.isDay = c.is_day === 1
            w.sunrise = d.sunrise[0].slice(11, 16)
            w.sunset = d.sunset[0].slice(11, 16)

            var now = c.time.slice(0, 13) + ":00"
            var start = h.time.indexOf(now)
            var hs = []
            if (start >= 0) {
                for (var i = start + 1; i <= start + 6 && i < h.time.length; i++)
                    hs.push({ h: h.time[i].slice(11, 13) + "h", t: h.temperature_2m[i], code: h.weather_code[i], day: h.is_day[i] === 1 })
            }
            w.hours = hs

            var names = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
            var ds = []
            for (var k = 1; k < d.time.length; k++) {
                var dt = new Date(d.time[k] + "T12:00:00")
                ds.push({ d: names[dt.getDay()], min: d.temperature_2m_min[k], max: d.temperature_2m_max[k], code: d.weather_code[k] })
            }
            w.days = ds
            w.ready = true
            w.failed = false
        } catch (e) {
            w.failed = true
        }
    }

    Process {
        id: proc
        command: ["curl", "-s", "-m", "15", w.url]
        stdout: StdioCollector {
            onStreamFinished: w.parse(this.text)
        }
    }

    Timer {
        interval: 1200000
        running: true
        repeat: true
        onTriggered: w.refresh()
    }

    Component.onCompleted: refresh()
}
