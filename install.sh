#!/bin/bash
# PikSOn Install Script
# Uso: ejecutar tras instalar Arch Linux base
# El script instala todo y aplica la configuración automáticamente

set -e
USERNAME=$(whoami)

echo "==> Actualizando sistema..."
sudo pacman -Syu --noconfirm

echo "==> Instalando yay (AUR helper)..."
if ! command -v yay &>/dev/null; then
    sudo pacman -S --needed git base-devel --noconfirm
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd ~
fi

echo "==> Instalando paquetes oficiales..."
sudo pacman -S --needed --noconfirm - < ~/dotfiles/pkglist.txt

echo "==> Instalando paquetes AUR..."
yay -S --needed --noconfirm \
    brave-bin \
    pwvucontrol \
    visual-studio-code-bin

echo "==> Instalando Spotify (Flatpak)..."
flatpak install -y flathub com.spotify.Client

echo "==> Aplicando configuración..."
cp -r ~/dotfiles/.config/* ~/.config/

echo "==> Configurando git..."
git config --global user.name "pikson"
git config --global user.email "joancarmona05@gmail.com"

echo "==> Activando backup automático diario..."
mkdir -p ~/.config/systemd/user
cp ~/dotfiles/.config/systemd/user/dotfiles-backup.* ~/.config/systemd/user/ 2>/dev/null || true
systemctl --user enable --now dotfiles-backup.timer 2>/dev/null || true

echo ""
echo "✓ Instalación completada. Reinicia la sesión para aplicar Hyprland."
