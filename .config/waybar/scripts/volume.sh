#!/bin/bash
SINK_INFO=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
VOLUME=$(echo "$SINK_INFO" | awk '{print int($2 * 100)}')
MUTED=$(echo "$SINK_INFO" | grep -c "MUTED")

if [ "$MUTED" -gt 0 ]; then
    ICON="󰝟"
    CLASS="muted"
elif [ "$VOLUME" -le 30 ]; then
    ICON="󰕿"
    CLASS="low"
elif [ "$VOLUME" -le 70 ]; then
    ICON="󰖀"
    CLASS="medium"
else
    ICON="󰕾"
    CLASS="high"
fi

printf '{"text":"%s %d%%","class":"%s","tooltip":"Volumen: %d%%"}\n' \
    "$ICON" "$VOLUME" "$CLASS" "$VOLUME"
