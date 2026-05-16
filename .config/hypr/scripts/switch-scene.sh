#!/bin/bash
# Cambia los 3 monitores a la escena N (como escritorios virtuales de Windows)
# Escena 1: ws1+ws6+ws11, Escena 2: ws2+ws7+ws12, etc.
SCENE=$1
WS_AOC=$SCENE
WS_SAM=$(( SCENE + 5 ))
WS_LG=$(( SCENE + 10 ))

hyprctl --batch "dispatch focusmonitor DP-1 ; dispatch workspace $WS_AOC ; dispatch focusmonitor HDMI-A-1 ; dispatch workspace $WS_SAM ; dispatch focusmonitor DP-2 ; dispatch workspace $WS_LG"
