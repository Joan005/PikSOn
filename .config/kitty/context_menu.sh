#!/bin/bash
CHOICE=$(printf "Copiar\nPegar\nRecortar" | wofi --dmenu --prompt "" --height 130 --width 200 --hide-scroll)
case "$CHOICE" in
    "Copiar")
        kitty @ --to "$KITTY_LISTEN_ON" copy-to-clipboard
        ;;
    "Pegar")
        kitty @ --to "$KITTY_LISTEN_ON" paste-from-clipboard
        ;;
    "Recortar")
        kitty @ --to "$KITTY_LISTEN_ON" copy-to-clipboard
        kitty @ --to "$KITTY_LISTEN_ON" send-text $'\x7f'
        ;;
esac
