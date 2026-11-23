#!/usr/bin/env bash
# ui.sh: portada y utilidades visuales del instalador de PikSOn.
# Se usa desde install.sh con:   source "$SCRIPT_DIR/ui.sh"; portada
# También puede probarse solo:   bash ui.sh

# ---------- Colores: Pergamino nocturno (y degradado morado para el dibujo) ----------
if [ "${TERM:-}" = "linux" ] || [ -n "${NO_TRUECOLOR:-}" ]; then
    # Consola TTY: solo 16 colores y símbolos básicos
    C_FG=$'\e[97m'; C_GOLD=$'\e[93m'; C_COPPER=$'\e[33m'; C_DIM=$'\e[90m'
    GRAD=("$C_FG" "$C_FG" "$C_GOLD" "$C_GOLD" "$C_COPPER" "$C_COPPER")
    PGRAD=($'\e[95m' $'\e[95m' $'\e[35m' $'\e[35m' $'\e[94m' $'\e[94m')
    S_STEP='>'; S_OK='+'
else
    rgb() { printf '\e[38;2;%s;%s;%sm' "$1" "$2" "$3"; }
    C_FG=$(rgb 246 235 207); C_GOLD=$(rgb 226 181 100)
    C_COPPER=$(rgb 207 123 85); C_DIM=$(rgb 140 109 79)
    GRAD=("$(rgb 246 235 207)" "$(rgb 240 220 170)" "$(rgb 233 200 135)" \
          "$(rgb 226 181 100)" "$(rgb 217 152 92)" "$(rgb 207 123 85)")
    PGRAD=("$(rgb 232 90 255)" "$(rgb 214 80 255)" "$(rgb 190 80 255)" \
           "$(rgb 160 90 255)" "$(rgb 135 100 255)" "$(rgb 110 110 255)")
    S_STEP='▸'; S_OK='✔'
fi
C_OFF=$'\e[0m'; C_BOLD=$'\e[1m'

rep() { local s="" i; for ((i = 0; i < $2; i++)); do s+="$1"; done; printf '%s' "$s"; }

# ---------- Dibujo: el planeador, hecho de letras ----------
ART=()
# planeador (letras): 20 filas, 52 columnas
art_planeador_l() { ART=(
'.1Iti:'
'.OM880Ot;'
' :O888888I;'
'  :O8888888I:'
'   :O88888880;'
'    :088888880i'
'     :O88888888;'
'      :O88888880;'
'       :O88888880:'
'        :O88888880;                     ..'
'         .O88888880;                   1BB1'
'          :O88888888i                 :M@@B:'
'    i1ii.   O888888881                I@@@@I .'
'   I@@@M88800888888888I.        .     0@@@@8.      :'
'  .OMMBM@@@@@B8888888880OIti;:.       O@@@@B: :itO0O'
'     .:;;i1IO8000888888MB@@@@BBM8OI1i:O@@@@BIO8M8Oi.'
'               .::;;i11tIO0MB@@@@@@@@@@@@@@@8M0t:'
'           .             .:itO008888880OO08MO1.'
'                      .       .;i1IO000OI1i;:  .'
'                                    .:;1tttt1;'
); }

show_art() {  # pinta ART con el degradado morado, centrado respecto al logo (46 columnas)
    local n=${#ART[@]} max=0 i pad
    for i in "${!ART[@]}"; do (( ${#ART[$i]} > max )) && max=${#ART[$i]}; done
    pad=$(( (46 - max) / 2 + 2 )); (( pad < 2 )) && pad=2
    for i in "${!ART[@]}"; do
        printf '%*s%s%s%s\n' "$pad" '' "${PGRAD[$(( i * 6 / n ))]}" "${ART[$i]}" "$C_OFF"
    done
}

LOGO=(
'██████╗ ██╗██╗  ██╗███████╗ ██████╗ ███╗   ██╗'
'██╔══██╗██║██║ ██╔╝██╔════╝██╔═══██╗████╗  ██║'
'██████╔╝██║█████╔╝ ███████╗██║   ██║██╔██╗ ██║'
'██╔═══╝ ██║██╔═██╗ ╚════██║██║   ██║██║╚██╗██║'
'██║     ██║██║  ██╗███████║╚██████╔╝██║ ╚████║'
'╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝'
)

# portada  ->  planeador + logo + subtítulo.
# El dibujo solo se muestra si la terminal tiene altura de sobra (o con FORZAR_DIBUJO=1).
portada() {
    local i lines
    art_planeador_l
    lines=$(tput lines 2>/dev/null || echo 25)
    printf '\n'
    if [ -n "${FORZAR_DIBUJO:-}" ] || [ "$lines" -ge $(( ${#ART[@]} + 12 )) ]; then
        show_art
        printf '\n'
    fi
    for i in "${!LOGO[@]}"; do
        printf '  %s%s%s\n' "${GRAD[$i]}" "${LOGO[$i]}" "$C_OFF"
    done
    printf '\n  %sArch Linux · Hyprland · Quickshell%s\n' "$C_FG" "$C_OFF"
    printf '  %s%s%s\n\n' "$C_DIM" "$(rep '─' 46)" "$C_OFF"
}

# ---------- Utilidades para el resto del instalador ----------
paso()  { printf '\n%s%s [%s/%s]%s %s%s%s\n' "$C_GOLD" "$S_STEP" "$1" "$2" "$C_OFF" "$C_BOLD" "$3" "$C_OFF"; }
ok()    { printf '  %s%s%s %s\n' "$C_GOLD" "$S_OK" "$C_OFF" "$1"; }
aviso() { printf '  %s!%s %s\n' "$C_COPPER" "$C_OFF" "$1"; }
barra() {  # barra PORCENTAJE
    local p="$1" w=30 f
    f=$(( p * w / 100 ))
    printf '  %s%s%s%s%s %s%%\n' "$C_GOLD" "$(rep '█' "$f")" "$C_DIM" "$(rep '░' $((w - f)))" "$C_OFF" "$p"
}

# Si se ejecuta directamente (no con source), enseña la portada y las utilidades.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    portada
    paso 3 8 "Instalando paquetes"
    barra 60
    ok "Paquetes oficiales instalados"
    aviso "Un aviso de ejemplo"
    printf '\n'
fi
