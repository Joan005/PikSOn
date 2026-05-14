#!/bin/bash
# Cambia los 3 monitores al grupo de workspaces indicado
# Grupo 1: WS1 (AOC) + WS2 (Samsung) + WS3 (LG)
# Grupo 2: WS4 (AOC) + WS5 (Samsung) + WS6 (LG)
# etc.

GROUP=$1
WS_AOC=$(( (GROUP - 1) * 3 + 1 ))
WS_SAMSUNG=$(( (GROUP - 1) * 3 + 2 ))
WS_LG=$(( (GROUP - 1) * 3 + 3 ))

hyprctl dispatch workspace $WS_AOC
hyprctl dispatch workspace $WS_SAMSUNG
hyprctl dispatch workspace $WS_LG

# Devolver el foco al monitor principal (AOC)
hyprctl dispatch focusmonitor DP-1
