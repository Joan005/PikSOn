# PikSOn - Arch Linux + Hyprland

(proceso manual sin script)

- archinstall
- provar que hi ha conexio fent un ping a una web
- istalar git (sudo pacman -Sy git)
- sudo pacman -S --needed hyprland kitty wofi waybar xdg-desktop-portal-hyprland qt5-wayland qt6-wayland pipewire wireplumber ttf-jetbrains-mono-nerd
- useradd -m -G wheel -s /bin/bash pikson
- passwd pikson
- exit
- exit
- (entras con el usuario pikson)
- Hyprland
  
---

# 🎩 dotfiles

Mi entorno de trabajo en **Arch Linux** con **Hyprland**, pensado para programar, estudiar y para el uso diario. Es portable: lo mismo sirve para una máquina virtual que para un PC de sobremesa o un portátil.

<!-- Captura de pantalla: ![Escritorio](docs/escritorio.png) -->

## 📑 Índice
1. [Qué contiene](#-qué-contiene)
2. [Estructura del repositorio](#-estructura-del-repositorio)
3. [Instalación](#-instalación)
4. [Atajos de teclado](#-atajos-de-teclado)
5. [Personalización por hardware](#-personalización-por-hardware)
6. [Solución de problemas](#-solución-de-problemas)
7. [Créditos](#-créditos)

## 🧩 Qué contiene

| Componente | Programa | Por qué |
|---|---|---|
| Compositor / WM | Hyprland | Mosaico dinámico sobre Wayland, fluido y muy configurable |
| Terminal | kitty | Acelerada por GPU, configuración en un solo fichero |
| Shell | zsh | <!-- plugins, prompt (p. ej. starship) --> |
| Barra | waybar | <!-- --> |
| Lanzador | rofi / wofi | <!-- --> |
| Editor | neovim | <!-- --> |
| Notificaciones | mako / dunst | <!-- --> |
| Fondo de pantalla | hyprpaper / swww | <!-- --> |
| Gestor de ficheros | <!-- --> | <!-- --> |

## 📁 Estructura del repositorio

```
dotfiles/
├── README.md
├── install.sh          # Instala paquetes y crea los enlaces simbólicos
├── packages/
│   ├── pacman.txt      # Paquetes de los repositorios oficiales
│   └── aur.txt         # Paquetes del AUR
├── config/             # Un directorio por programa (formato GNU Stow)
│   ├── hypr/.config/hypr/
│   ├── kitty/.config/kitty/
│   ├── waybar/.config/waybar/
│   ├── zsh/.zshrc
│   └── nvim/.config/nvim/
└── docs/               # Capturas y notas
```

Cada carpeta de `config/` replica la ruta que tendría en `$HOME`. **GNU Stow** crea los enlaces simbólicos, de modo que los ficheros reales viven en el repositorio.

## 🚀 Instalación

### 1. Sistema base
Instala Arch Linux (con `archinstall` o a mano) y crea un usuario con permisos de `sudo`.
<!-- Indica aquí tu esquema de particiones, sistema de ficheros, bootloader... -->

### 2. Clonar el repositorio
```bash
sudo pacman -S --needed git stow
git clone https://github.com/<usuario>/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. Instalar paquetes
```bash
sudo pacman -S --needed - < packages/pacman.txt

# Ayudante del AUR (yay)
git clone https://aur.archlinux.org/yay.git /tmp/yay
(cd /tmp/yay && makepkg -si)
yay -S --needed - < packages/aur.txt
```

### 4. Enlazar las configuraciones
```bash
cd ~/dotfiles/config
stow -t ~ hypr kitty waybar zsh nvim
```
Si aparece un conflicto, es que ya existe un fichero real en esa ruta. Muévelo o respáldalo antes de repetir el comando.

### 5. Ajustes finales
```bash
chsh -s /usr/bin/zsh
sudo systemctl enable --now NetworkManager
```
Cierra sesión e inicia Hyprland desde el TTY con `Hyprland`<!-- o mediante un display manager -->.

## ⌨️ Atajos de teclado

| Atajo | Acción |
|---|---|
| `SUPER + Enter` | Abrir terminal (kitty) |
| `SUPER + D` | Lanzador de aplicaciones |
| `SUPER + Q` | Cerrar ventana |
| `SUPER + 1…9` | Cambiar de espacio de trabajo |
<!-- Completa con tus atajos reales -->

## 🖥️ Personalización por hardware

Este entorno debe funcionar en distintos equipos. Lo específico de cada máquina se aísla así:

- **Monitores:** `config/hypr/.config/hypr/monitors.conf`, un fichero por equipo.
- **GPU:** controladores NVIDIA, AMD o Intel según el equipo <!-- paquetes -->.
- **Portátil:** batería, brillo y touchpad <!-- tlp / brightnessctl -->.
- **VM:** puede requerir `WLR_NO_HARDWARE_CURSORS=1` y renderizado por software.

## 🛠️ Solución de problemas

- **Hyprland no arranca en la VM:** activa la aceleración 3D en la VM o usa `WLR_RENDERER_ALLOW_SOFTWARE=1`.
- **Fuentes o iconos rotos:** instala una Nerd Font <!-- cuál --> y ejecuta `fc-cache -fv`.
- <!-- Añade aquí los problemas que vayas encontrando -->

## 🙏 Créditos

<!-- Repositorios, temas y personas que te han inspirado -->

## 📜 Licencia
<!-- MIT, o la que prefieras -->
