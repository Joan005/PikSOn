#!/bin/bash
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
PIDFILE=/tmp/whisper_record.pid
AUDIOFILE=/tmp/whisper_audio.wav
LOG=/tmp/whisper.log

notify() {
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus" notify-send "$@" 2>/dev/null || true
}

if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm "$PIDFILE"
    sleep 0.3
    notify "Transcribiendo..." -t 6000
    echo "=== $(date) ===" >> "$LOG"
    echo "Audio file size: $(stat -c%s "$AUDIOFILE" 2>/dev/null || echo 'no existe')" >> "$LOG"
    whisper "$AUDIOFILE" --language es --model small --output_format txt --output_dir /tmp --fp16 False >> "$LOG" 2>&1
    echo "Whisper exit: $?" >> "$LOG"
    TEXT=$(cat /tmp/whisper_audio.txt 2>/dev/null | tr -d '\n' | xargs)
    echo "Text: $TEXT" >> "$LOG"
    if [ -n "$TEXT" ]; then
        wtype "$TEXT"
    else
        notify "Sin texto detectado" -t 3000
    fi
    rm -f "$AUDIOFILE" /tmp/whisper_audio.txt
else
    notify "Grabando... (W+Q para parar)" -t 60000
    ffmpeg -f pulse -i default -ar 16000 -ac 1 "$AUDIOFILE" -y 2>/dev/null &
    echo $! > "$PIDFILE"
fi
