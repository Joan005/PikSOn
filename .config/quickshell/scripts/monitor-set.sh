#!/bin/sh	
# Aplica la configuracion de un monitor en caliente.
# Uso: monitor-set.sh NOMBRE MODO POSICION ESCALA [TRANSFORM]
# Ejemplo: monitor-set.sh Virtual-1 1920x1080@60 0x0 1.25
name="$1"
mode="$2"
pos="$3"
scale="$4"
tr="${5:-0}"
spec="$name,$mode,$pos,$scale"
if [ "$tr" != "0" ]; then
    spec="$spec,transform,$tr"
fi
out=$(hyprctl keyword monitor "$spec" 2>&1)
if [ "$out" = "ok" ]; then
    echo "ok"
    exit 0
fi
lua="hl.monitor({ output = \"$name\", mode = \"$mode\", position = \"$pos\", scale = \"$scale\" })"
out2=$(hyprctl eval "$lua" 2>&1)
if [ "$out2" = "ok" ]; then
    echo "ok"
    exit 0
fi
echo "keyword: $out | eval: $out2"
