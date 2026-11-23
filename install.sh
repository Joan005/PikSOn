#!/usr/bin/env bash
# install.sh: instala el escritorio PikSOn (Arch Linux + Hyprland + Quickshell).
#
# Uso:
#   bash install.sh --vm | --real        tipo de equipo (si se omite, el script pregunta)
#   bash install.sh --dry-run            muestra lo que haría, sin cambiar nada
#   bash install.sh --all                instala todas las aplicaciones opcionales
#   bash install.sh --minimal            solo la base, sin aplicaciones opcionales
#   bash install.sh --apps brave,imv     solo esas aplicaciones opcionales
#   (sin opciones de aplicaciones, el script ofrece un menú para elegirlas)
#
# No lo ejecute como root. Todo queda registrado en ~/pikson-install.log

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$HOME/pikson-install.log"
DATE="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup-$DATE"

MODE=""          # vm | real
DRY=0
APPS_MODE="ask"  # ask | all | minimal | list
APPS_LIST=""
FAILS=()

# ---------- Portada y utilidades visuales (ui.sh) ----------
if [ -f "$SCRIPT_DIR/ui.sh" ]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/ui.sh"
else
    portada() { printf '\n  PikSOn · Arch Linux + Hyprland + Quickshell\n\n'; }
    paso()  { printf '\n> [%s/%s] %s\n' "$1" "$2" "$3"; }
    ok()    { printf '  + %s\n' "$1"; }
    aviso() { printf '  ! %s\n' "$1"; }
    C_FG=''; C_GOLD=''; C_COPPER=''; C_DIM=''; C_OFF=''; C_BOLD=''
fi

uso() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; }

# ---------- Argumentos ----------
while [ $# -gt 0 ]; do
    case "$1" in
        --vm)      MODE=vm ;;
        --real)    MODE=real ;;
        --dry-run) DRY=1 ;;
        --all)     APPS_MODE=all ;;
        --minimal) APPS_MODE=minimal ;;
        --apps)    shift; APPS_MODE=list; APPS_LIST="${1:-}" ;;
        -h|--help) uso; exit 0 ;;
        *) printf 'Opción desconocida: %s\n\n' "$1"; uso; exit 1 ;;
    esac
    shift
done

# ---------- Portada (antes de redirigir la salida al registro) ----------
portada

# ---------- Registro: todo lo que sale por pantalla queda en el log ----------
exec > >(tee -a "$LOG") 2>&1
printf '=== PikSOn install.sh · %s · dry-run=%s ===\n' "$DATE" "$DRY"

# ---------- Comprobaciones previas ----------
if [ "$(id -u)" -eq 0 ]; then
    printf 'No ejecute este script como root; use su usuario normal (usa sudo cuando hace falta).\n'
    exit 1
fi
if [ ! -f /etc/arch-release ]; then
    printf 'Esto no parece Arch Linux (falta /etc/arch-release).\n'
    exit 1
fi
if [ ! -f "$SCRIPT_DIR/pkglist.txt" ]; then
    printf 'Falta pkglist.txt junto al script. Ejecútelo desde la carpeta del repositorio.\n'
    exit 1
fi
if ! ping -c1 -W3 archlinux.org > /dev/null 2>&1 && ! ping -c1 -W3 1.1.1.1 > /dev/null 2>&1; then
    if [ "$DRY" = 1 ]; then
        aviso "Sin conexión a internet (se ignora en --dry-run)."
    else
        printf 'No hay conexión a internet.\n'
        exit 1
    fi
fi

# ---------- Tipo de equipo ----------
if [ -z "$MODE" ]; then
    if [ -t 0 ]; then
        read -r -p "  ¿Es una máquina virtual? [s/N] " resp
        case "$resp" in [sSyY]*) MODE=vm ;; *) MODE=real ;; esac
    else
        printf 'Indique el tipo de equipo con --vm o --real.\n'
        exit 1
    fi
fi
ok "Tipo de equipo: $MODE"

# ---------- Ejecutar o simular ----------
run() {
    if [ "$DRY" = 1 ]; then
        printf '  [dry-run] %s\n' "$*"
        return 0
    fi
    if ! "$@"; then
        aviso "Falló: $*"
        FAILS+=("$*")
        return 1
    fi
}

# ---------- Aplicaciones opcionales (opcionales.txt) ----------
OPT_ID=(); OPT_PKG=(); OPT_DESC=(); OPT_SEL=()

load_opcionales() {
    local f="$SCRIPT_DIR/opcionales.txt" id pk desc
    [ -f "$f" ] || return 0
    while IFS='|' read -r id pk desc; do
        case "$id" in ''|\#*) continue ;; esac
        OPT_ID+=("$id"); OPT_PKG+=("$pk"); OPT_DESC+=("$desc"); OPT_SEL+=(1)
    done < "$f"
}

set_all() {  # set_all 0|1
    local i
    for i in "${!OPT_ID[@]}"; do OPT_SEL[$i]="$1"; done
}

show_menu() {
    local i mark col
    printf '\n  %sElija qué aplicaciones instalar%s\n' "$C_BOLD$C_GOLD" "$C_OFF"
    printf '  %snúmero = marcar/desmarcar · a = todas · n = ninguna · Enter = continuar · q = salir%s\n\n' "$C_DIM" "$C_OFF"
    for i in "${!OPT_ID[@]}"; do
        if [ "${OPT_SEL[$i]}" = 1 ]; then mark='[x]'; col="$C_FG"; else mark='[ ]'; col="$C_DIM"; fi
        printf '   %s%d)%s %s%s %-9s %s%s\n' "$C_GOLD" "$((i + 1))" "$C_OFF" "$col" "$mark" "${OPT_ID[$i]}" "${OPT_DESC[$i]}" "$C_OFF"
    done
    printf '\n  %sLa base (Hyprland, Quickshell, kitty, zsh, tema...) se instala siempre.%s\n' "$C_DIM" "$C_OFF"
}

menu_apps() {
    local r t idx n=${#OPT_ID[@]}
    while true; do
        show_menu
        read -r -p "  > " r || break
        case "$r" in
            '') break ;;
            a|A) set_all 1 ;;
            n|N) set_all 0 ;;
            q|Q) printf 'Cancelado.\n'; exit 0 ;;
            *)
                for t in $r; do
                    if [[ "$t" =~ ^[0-9]+$ ]]; then
                        idx=$((t - 1))
                        if (( idx >= 0 && idx < n )); then
                            if [ "${OPT_SEL[$idx]}" = 1 ]; then OPT_SEL[$idx]=0; else OPT_SEL[$idx]=1; fi
                        fi
                    fi
                done
                ;;
        esac
    done
}

choose_apps() {
    local a i found
    load_opcionales
    [ "${#OPT_ID[@]}" -gt 0 ] || return 0
    case "$APPS_MODE" in
        all)     set_all 1 ;;
        minimal) set_all 0 ;;
        list)
            set_all 0
            for a in ${APPS_LIST//,/ }; do
                found=0
                for i in "${!OPT_ID[@]}"; do
                    if [ "${OPT_ID[$i]}" = "$a" ]; then OPT_SEL[$i]=1; found=1; fi
                done
                [ "$found" = 1 ] || aviso "Aplicación opcional desconocida: $a"
            done
            ;;
        ask)
            if [ -t 0 ]; then menu_apps; else set_all 1; fi
            ;;
    esac
    printf '\n  Aplicaciones elegidas:'
    for i in "${!OPT_ID[@]}"; do
        [ "${OPT_SEL[$i]}" = 1 ] && printf ' %s' "${OPT_ID[$i]}"
    done
    printf '\n'
}

# Listas de paquetes filtradas: quita las apps no elegidas y, en equipo real, lo de VirtualBox.
F_OFFICIAL=""; F_AUR=""; F_REMOVE=""
cleanup() { rm -f "$F_OFFICIAL" "$F_AUR" "$F_REMOVE" 2> /dev/null; }
trap cleanup EXIT

build_lists() {
    local i p
    F_REMOVE="$(mktemp)"; F_OFFICIAL="$(mktemp)"; F_AUR="$(mktemp)"
    for i in "${!OPT_ID[@]}"; do
        if [ "${OPT_SEL[$i]}" = 0 ]; then
            for p in ${OPT_PKG[$i]}; do printf '%s\n' "$p" >> "$F_REMOVE"; done
        fi
    done
    [ "$MODE" = real ] && printf '%s\n' virtualbox-guest-utils >> "$F_REMOVE"
    grep -vxFf "$F_REMOVE" "$SCRIPT_DIR/pkglist.txt" > "$F_OFFICIAL"
    if [ -f "$SCRIPT_DIR/aur-pkglist.txt" ]; then
        grep -vxFf "$F_REMOVE" "$SCRIPT_DIR/aur-pkglist.txt" > "$F_AUR"
    fi
}

install_list() {  # install_list ARCHIVO COMANDO...   (instala en bloque; si falla, uno a uno)
    local file="$1" p; shift
    local -a pk=()
    mapfile -t pk < <(grep -v '^[[:space:]]*#' "$file" | grep -v '^[[:space:]]*$')
    [ "${#pk[@]}" -gt 0 ] || { aviso "Lista vacía: $(basename "$file")"; return 0; }
    if [ "$DRY" = 1 ]; then
        printf '  [dry-run] %s (%d paquetes)\n' "$*" "${#pk[@]}"
        return 0
    fi
    if "$@" "${pk[@]}"; then
        ok "${#pk[@]} paquetes instalados"
    else
        aviso "Falló la instalación en bloque; se prueba uno a uno."
        for p in "${pk[@]}"; do
            "$@" "$p" || { aviso "No se pudo instalar: $p"; FAILS+=("paquete $p"); }
        done
    fi
}

# ---------- Elección de aplicaciones ----------
choose_apps
build_lists

# ---------- Permisos de administrador (se mantienen mientras dure el script) ----------
if [ "$DRY" = 0 ]; then
    printf '\n  Se necesitará su contraseña para instalar paquetes.\n'
    sudo -v || { printf 'Sin permisos de administrador.\n'; exit 1; }
    ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2> /dev/null || exit; done ) &
fi

# ======================================================================
paso 1 8 "Actualizando el sistema"
run sudo pacman -Syu --noconfirm
run sudo pacman -S --needed --noconfirm base-devel git

paso 2 8 "yay (ayudante del AUR)"
if command -v yay > /dev/null 2>&1; then
    ok "yay ya está instalado"
else
    YAYDIR="$(mktemp -d)"
    run git clone https://aur.archlinux.org/yay-bin.git "$YAYDIR/yay-bin"
    run bash -c 'cd "$1" && makepkg -si --noconfirm' _ "$YAYDIR/yay-bin"
fi

paso 3 8 "Instalando paquetes"
install_list "$F_OFFICIAL" sudo pacman -S --needed --noconfirm
if [ -s "$F_AUR" ]; then
    install_list "$F_AUR" yay -S --needed --noconfirm
fi

paso 4 8 "Copiando la configuración (copia de lo anterior en $BACKUP)"
for d in hypr kitty quickshell gtk-3.0; do
    if [ ! -d "$SCRIPT_DIR/.config/$d" ]; then
        aviso "Falta .config/$d en el repositorio"
        continue
    fi
    if [ -d "$HOME/.config/$d" ]; then
        run mkdir -p "$BACKUP/.config"
        run cp -a "$HOME/.config/$d" "$BACKUP/.config/"
    fi
    run mkdir -p "$HOME/.config/$d"
    run cp -a "$SCRIPT_DIR/.config/$d/." "$HOME/.config/$d/"
done
for f in .zshrc .zprofile; do
    if [ -f "$SCRIPT_DIR/zsh/$f" ]; then
        if [ -f "$HOME/$f" ]; then
            run mkdir -p "$BACKUP"
            run cp -a "$HOME/$f" "$BACKUP/"
        fi
        run cp -a "$SCRIPT_DIR/zsh/$f" "$HOME/$f"
    fi
done
run chmod +x "$HOME/.config/quickshell/scripts/"*.sh
ok "Configuración copiada"

paso 5 8 "Servicios"
run sudo systemctl enable NetworkManager
run sudo systemctl disable systemd-networkd
run systemctl --user enable pipewire pipewire-pulse wireplumber

paso 6 8 "Zona horaria y shell"
run sudo timedatectl set-timezone Europe/Madrid
[ "$MODE" = real ] && run sudo timedatectl set-ntp true
if command -v zsh > /dev/null 2>&1 || [ "$DRY" = 1 ]; then
    run chsh -s /usr/bin/zsh
else
    aviso "zsh no está instalado; no se cambia la shell."
fi

paso 7 8 "Ajustes según el tipo de equipo ($MODE)"
if [ "$MODE" = real ]; then
    run sed -i 's/env LIBGL_ALWAYS_SOFTWARE=1 //g' "$HOME/.config/hypr/hyprland.lua"
    run sed -i '/screencopy_mode/d' "$HOME/.config/hypr/hyprlock.conf"
    run rm -f "$HOME/.local/share/applications/imv.desktop"
else
    run sudo pacman -S --needed --noconfirm virtualbox-guest-utils
    run sudo systemctl enable vboxservice
    if [ -f /usr/share/applications/imv.desktop ] || [ "$DRY" = 1 ]; then
        run mkdir -p "$HOME/.local/share/applications"
        run bash -c 'sed "s|^Exec=imv|Exec=env LIBGL_ALWAYS_SOFTWARE=1 imv|" /usr/share/applications/imv.desktop > "$HOME/.local/share/applications/imv.desktop"'
    fi
fi

paso 8 8 "Aspecto de las aplicaciones GTK"
run dbus-run-session -- gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10'
run dbus-run-session -- gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
run dbus-run-session -- gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
run dbus-run-session -- gsettings set org.gnome.desktop.interface cursor-size 16

# ======================================================================
printf '\n%s%s%s\n' "$C_GOLD" "$(rep '═' 46 2> /dev/null || printf '==============================================')" "$C_OFF"
if [ "${#FAILS[@]}" -gt 0 ]; then
    aviso "Hubo ${#FAILS[@]} avisos:"
    for f in "${FAILS[@]}"; do printf '     - %s\n' "$f"; done
else
    ok "Instalación terminada sin avisos"
fi

cat << 'FIN'

  Lo que queda a mano:
    1. Reinicie el equipo.
    2. Si es un equipo real: instale los controladores de la GPU.
    3. Ajuste los monitores desde la tuerca de la barra.
    4. Vuelva a iniciar sesión en Brave y Discord.
    5. Al entrar en el TTY1, Hyprland arranca solo.

  Registro completo: ~/pikson-install.log
FIN
