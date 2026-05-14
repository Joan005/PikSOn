#!/bin/bash
cd ~/dotfiles
cp -r ~/.config/hypr .config/
cp -r ~/.config/waybar .config/
cp -r ~/.config/nwg-dock-hyprland .config/
cp -r ~/.config/wofi .config/ 2>/dev/null
cp -r ~/.config/mako .config/ 2>/dev/null
cp -r ~/.config/kitty .config/ 2>/dev/null
pacman -Qqe > pkglist.txt
pacman -Qqm > aur-pkglist.txt

git add .
git diff --cached --quiet && exit 0
git commit -m "backup $(date '+%Y-%m-%d %H:%M')"
git push
