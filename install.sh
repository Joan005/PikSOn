#!/bin/bash
# install.sh - instala el entorno PikSOn sobre un Arch recien instalado.
# Uso: bash install.sh [--vm | --real] [--dry-run]
set -u

REPO="$(cd "$(dirname "$0")" && pwd)"
LOG="$HOME/pikson-install.log"
MODE=""
DRY=0
FAILS=()

for a in "$@"; do
    case "$a" in
        --vm) MODE=vm ;;
        --real) MODE=real ;;
        --dry-run) DRY=1 ;;
        *) echo "Opcion desconocida: $a"; exit 1 ;;
    esac
done

exec > >(tee -a "$LOG") 2>&1

say()  { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;31m!! %s\033[0m\n' "$*"; FAILS+=("$*"); }
run()  { if [ "$DRY" = 1 ]; then echo "[dry-run] $*"; else "$@" || warn "Fallo: $*"; fi; }

# --- comprobaciones previas ---
if [ "$(id -u)" = 0 ]; then
    echo "No lo ejecutes como root: usa tu usuario normal (con sudo)."
    exit 1
fi
[ -f /etc/arch-release ] || { echo "Esto solo vale para Arch Linux."; exit 1; }
[ -f "$REPO/pkglist.txt" ] || { echo "Ejecutalo desde el repositorio (falta pkglist.txt)."; exit 1; }
ping -c1 -W3 archlinux.org >/dev/null 2>&1 || { echo "No hay conexion a internet."; exit 1; }

if [ -z "$MODE" ]; then
    read -r -p "Es una maquina virtual (VirtualBox)? [s/N] " r
    case "$r" in
        s|S|y|Y) MODE=vm ;;
        *) MODE=real ;;
    esac
fi
say "Modo: $MODE   (dry-run: $DRY)   registro: $LOG"
[ "$DRY" = 1 ] || sudo -v

# --- 1. sistema base ---
say "1/8 Actualizando el sistema"
run sudo pacman -Syu --noconfirm
run sudo pacman -S --needed --noconfirm base-devel git

# --- 2. yay ---
say "2/8 Instalando yay (AUR)"
if ! command -v yay >/dev/null 2>&1; then
    if [ "$DRY" = 1 ]; then
        echo "[dry-run] compilar e instalar yay-bin desde el AUR"
    else
        tmp="$(mktemp -d)"
        if git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"; then
            (cd "$tmp/yay-bin" && makepkg -si --noconfirm) || warn "No se pudo instalar yay"
        else
            warn "No se pudo descargar yay-bin"
        fi
        rm -rf "$tmp"
    fi
fi

# --- 3. paquetes ---
install_list() {
    local file="$1" tool="$2" pkgs p
    pkgs="$(grep -v -E '^[[:space:]]*(#|$)' "$file")"
    if [ "$MODE" = real ]; then
        pkgs="$(echo "$pkgs" | grep -v -E '^virtualbox-guest-utils$')"
    fi
    if [ "$DRY" = 1 ]; then
        echo "[dry-run] $tool: $(echo "$pkgs" | wc -l) paquetes de $(basename "$file")"
        return
    fi
    if [ "$tool" = pacman ]; then
        sudo pacman -S --needed --noconfirm - <<<"$pkgs" && return
    else
        yay -S --needed --noconfirm - <<<"$pkgs" && return
    fi
    warn "La instalacion en bloque de $(basename "$file") fallo: probando uno a uno"
    for p in $pkgs; do
        if [ "$tool" = pacman ]; then
            sudo pacman -S --needed --noconfirm "$p" || warn "Paquete no instalado: $p"
        else
            yay -S --needed --noconfirm "$p" || warn "Paquete AUR no instalado: $p"
        fi
    done
}

say "3/8 Instalando los paquetes oficiales"
install_list "$REPO/pkglist.txt" pacman
say "3/8 Instalando los paquetes del AUR"
if [ -f "$REPO/aur-pkglist.txt" ]; then
    install_list "$REPO/aur-pkglist.txt" yay
fi

# --- 4. configuracion ---
say "4/8 Copiando la configuracion"
BK="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
run mkdir -p "$BK"
run mkdir -p "$HOME/.config"
for d in hypr kitty quickshell gtk-3.0; do
    if [ -d "$REPO/.config/$d" ]; then
        [ -e "$HOME/.config/$d" ] && run cp -a "$HOME/.config/$d" "$BK/"
        run cp -a "$REPO/.config/$d" "$HOME/.config/"
    fi
done
if [ "$DRY" != 1 ] && [ -d "$HOME/.config/quickshell/scripts" ]; then
    chmod +x "$HOME/.config/quickshell/scripts/"*.sh
fi
for f in .zshrc .zprofile; do
    if [ -f "$REPO/zsh/$f" ]; then
        [ -e "$HOME/$f" ] && run cp -a "$HOME/$f" "$BK/"
        run cp "$REPO/zsh/$f" "$HOME/$f"
    fi
done

# --- 5. servicios ---
say "5/8 Servicios (surten efecto al reiniciar)"
run sudo systemctl enable NetworkManager
run sudo systemctl disable systemd-networkd.service systemd-networkd.socket
run systemctl --user enable pipewire pipewire-pulse wireplumber

# --- 6. ajustes del sistema ---
say "6/8 Zona horaria y shell"
run sudo timedatectl set-timezone Europe/Madrid
[ "$MODE" = real ] && run sudo timedatectl set-ntp true
run chsh -s /usr/bin/zsh

# --- 7. maquina virtual o equipo real ---
say "7/8 Ajustes segun el tipo de equipo ($MODE)"
if [ "$MODE" = real ]; then
    run sed -i 's/env LIBGL_ALWAYS_SOFTWARE=1 //g' "$HOME/.config/hypr/hyprland.lua"
    run rm -f "$HOME/.local/share/applications/imv.desktop"
else
    run sudo pacman -S --needed --noconfirm virtualbox-guest-utils
    run sudo systemctl enable vboxservice
    if [ "$DRY" != 1 ] && [ -f /usr/share/applications/imv.desktop ]; then
        mkdir -p "$HOME/.local/share/applications"
        sed 's|^Exec=imv|Exec=env LIBGL_ALWAYS_SOFTWARE=1 imv|' /usr/share/applications/imv.desktop > "$HOME/.local/share/applications/imv.desktop"
    fi
fi

# --- 8. ajustes de GTK ---
say "8/8 Ajustes de GTK (GSettings)"
gset() { run dbus-run-session -- gsettings set org.gnome.desktop.interface "$@"; }
gset font-name 'JetBrainsMono Nerd Font 10'
gset color-scheme 'prefer-dark'
gset gtk-theme 'Adwaita-dark'
gset cursor-size 16

# --- final ---
say "Terminado"
if [ ${#FAILS[@]} -gt 0 ]; then
    echo "Avisos (revisalos):"
    printf ' - %s\n' "${FAILS[@]}"
fi
cat <<'FIN'

Pasos MANUALES que el script no puede hacer:
  1. Reiniciar (para NetworkManager, zsh y los servicios).
  2. Iniciar sesion de GitHub: gh auth login
  3. Controladores de la GPU (NVIDIA, AMD o Intel) en un equipo real.
  4. Pantallas: ajustar con la tuerca de la barra y "Conservar y guardar".
  5. Iniciar sesion en Brave y Discord.
Registro completo en: ~/pikson-install.log
FIN
