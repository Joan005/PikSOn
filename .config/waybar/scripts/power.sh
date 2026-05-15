#!/bin/bash
CHOICE=$(printf "󰐥  Apagar\n󰜉  Reiniciar\n󰍃  Cerrar sesión" \
    | wofi --dmenu --prompt "" --lines 3 --width 200 --height 120 \
           --x 12 --y 62 --hide-scroll --no-actions \
           --style /home/pikson/.config/wofi/power-style.css)

case "$CHOICE" in
    *Apagar*)    systemctl poweroff ;;
    *Reiniciar*) systemctl reboot ;;
    *Cerrar*)    hyprctl dispatch exit ;;
esac
