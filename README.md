# 🎩 PikSOn — Arch Linux + Hyprland

Guía de instalación **manual (sin script)** de mi entorno de trabajo en Arch Linux con Hyprland.

## 📑 Índice
1. [Instalar Arch Linux](#1--instalar-arch-linux)
2. [Instalar Hyprland](#2--instalar-hyprland)
3. [Ajustes para máquina virtual (VirtualBox)](#3--ajustes-para-máquina-virtual-virtualbox)
4. [Primer arranque](#4--primer-arranque)
5. [Terminal: solución si kitty no abre](#5--terminal-solución-si-kitty-no-abre)
6. [Editor de texto](#6--editor-de-texto)
7. [Navegador Brave y atajo de teclado](#7--navegador-brave-y-atajo-de-teclado)
8. [Atajos de teclado personalizados](#8--atajos-de-teclado-personalizados)

---

## 1. 💿 Instalar Arch Linux

```bash
archinstall
```

Una vez instalado, comprueba que hay conexión a internet:

```bash
ping archlinux.org
```

---

## 2. 🪟 Instalar Hyprland

Documentación oficial: <https://wiki.hypr.land/Getting-Started/Installation/>

```bash
sudo pacman -S hyprland
```

---

## 3. 🖥️ Ajustes para máquina virtual (VirtualBox)

> ⚠️ Solo si trabajas desde una VM. Hazlo **después** de instalar Hyprland.

**Paquetes** (si habías instalado antes las herramientas de QEMU, retíralas):

```bash
sudo pacman -Rns qemu-guest-agent spice-vdagent   # solo si estaban instalados
sudo pacman -S --needed virtualbox-guest-utils
sudo systemctl enable --now vboxservice
```

**Configuración de la VM** (con la máquina **apagada**), en *Configuración → Pantalla*:

| Opción | Valor |
|---|---|
| Controlador gráfico | **VMSVGA** |
| Aceleración 3D | **Habilitada** |
| Memoria de vídeo | **128 MB** (el máximo) |

---

## 4. 🚀 Primer arranque

Desde el TTY:

```bash
start-hyprland
```

> Según la versión también puede lanzarse con `Hyprland`.

---

## 5. 🔧 Terminal: solución si kitty no abre

En VirtualBox, kitty puede cerrarse al instante al pulsar `Super + Q` por falta de OpenGL. Solución en tres pasos.

### 5.1 Usar foot temporalmente

```bash
sudo pacman -S --needed foot
```

Localiza la línea del terminal, haz una copia de seguridad y sustitúyelo:

```bash
grep -n -i "kitty" $HOME/.config/hypr/hyprland.lua
cp $HOME/.config/hypr/hyprland.lua $HOME/.config/hypr/hyprland.lua.bak
sed -i 's/"kitty"/"foot"/' $HOME/.config/hypr/hyprland.lua
```

Sal con `Super + M`, vuelve a entrar y abre foot con `Super + Q`.

### 5.2 Probar kitty con renderizado por software

Desde foot:

```bash
LIBGL_ALWAYS_SOFTWARE=1 kitty
```

Si kitty se abre, funciona con esa variable.

### 5.3 Dejar kitty como terminal definitivo

```bash
cd $HOME/.config/hypr
sed -i 's/"foot"/"env LIBGL_ALWAYS_SOFTWARE=1 kitty"/' hyprland.lua
grep -n "local terminal" hyprland.lua
```

Recarga saliendo con `Super + M` y ejecutando de nuevo `Hyprland`. Prueba `Super + Q`.

> ⚠️ `LIBGL_ALWAYS_SOFTWARE=1` solo es necesario en la VM. **No lo uses en hardware real.**

---

## 6. ✏️ Editor de texto

Instalamos **nano**, un editor de texto sencillo para terminal:

```bash
sudo pacman -S --needed nano
```

Uso básico: `Ctrl+O` guarda, `Ctrl+X` sale y `Ctrl+W` busca.

---

## 7. 🌐 Navegador Brave y atajo de teclado

Brave está en el **AUR**, por lo que primero hace falta instalar `yay`:

```bash
sudo pacman -S --needed base-devel git
cd /tmp
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
yay -S brave-bin
```

Después, abre el fichero de configuración y añade el atajo `Super + B`:

```bash
nano $HOME/.config/hypr/hyprland.lua
```

```lua
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave"))
```

---

## 8. ⌨️ Atajos de teclado personalizados

Añadidos a `~/.config/hypr/hyprland.lua`:

| Atajo | Acción | Línea |
|---|---|---|
| `Super + Q` | Abrir terminal | *(por defecto)* |
| `Super + B` | Abrir Brave | `hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave"))` |
| `Super + Retroceso` | Cerrar la ventana activa | `hl.bind(mainMod .. " + BACKSPACE", hl.dsp.window.close())` |
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("discord"))
> `Super + M` sale de Hyprland.
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())

PROGRAMAS INSTALADOS:

discord:

sudo pacman -S discord
discord

------

instalar github para acceder al repositorio

sudo pacman -S --needed git github-cli

git config --global user.name "Joan005"
git config --global user.email "joancarmona05@gmail.com"
git config --global init.defaultBranch main

cd $HOME
git clone https://github.com/Joan005/PikSOn
cd PikSOn
ls -R | head -50


ejecutar comando para descargar los programas que tenga instalados:

sudo pacman -S --needed - < pkglist.txt
yay -S --needed - < aur-pkglist.txt











- istalar git
```bash
sudo pacman -Sy git
```
- sudo pacman -S --needed hyprland kitty wofi waybar xdg-desktop-portal-hyprland qt5-wayland qt6-wayland pipewire wireplumber ttf-jetbrains-mono-nerd
- useradd -m -G wheel -s /bin/bash pikson
- passwd pikson
- exit
- exit
- (entras con el usuario pikson)
- Hyprland
  
---

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
