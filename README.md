# PikSOn - Arch Linux + Hyprland

Configuración completa del sistema. Sigue estos pasos en orden para tener el sistema listo desde cero.

---

-------------------------------
(actu de 24/10 sobre test en VM)

- provar que hi ha conexio fent un ping a una web
- istalar git per a clonar el repositori (sudo pacman -Sy git)
- 


-------------------------------

## 1. Instalar Arch Linux base

### Arrancar desde USB
Descarga la ISO de https://archlinux.org/download/ y grábala en un USB.
Arranca desde el USB (F11/F12 en el arranque para elegir dispositivo).

### Conectar a internet
```bash
# WiFi
iwctl
station wlan0 connect "NombreRed"
exit

# Comprobar conexión
ping archlinux.org
```

### Particionar el disco
```bash
# Ver discos disponibles
lsblk

# Particionar (sustituye nvme0n1 por tu disco)
fdisk /dev/nvme0n1
```
Dentro de fdisk:
- `g` → crear tabla GPT
- `n` → nueva partición EFI: `+1G`
- `t` → tipo `1` (EFI System)
- `n` → nueva partición swap: `+8G`
- `t` → tipo `19` (Linux swap)
- `n` → nueva partición raíz: resto del disco (Enter)
- `w` → guardar y salir

### Formatear y montar
```bash
mkfs.fat -F32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
mkfs.ext4 /dev/nvme0n1p3

mount /dev/nvme0n1p3 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
swapon /dev/nvme0n1p2
```

### Instalar sistema base
```bash
pacstrap -K /mnt base linux linux-firmware networkmanager sudo git nano
```

### Configurar el sistema
```bash
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

Dentro del chroot:
```bash
# Zona horaria
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc

# Idioma
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf

# Nombre del equipo
echo "archlinux" > /etc/hostname

# Contraseña root
passwd
# Introduce: root

# Crear usuario
useradd -m -G wheel -s /bin/bash pikson
passwd pikson
# Introduce: root

# Sudo para el grupo wheel
EDITOR=nano visudo
# Descomenta la línea: %wheel ALL=(ALL:ALL) ALL

# Bootloader
pacman -S grub efibootmgr --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Activar red al arrancar
systemctl enable NetworkManager

exit
umount -R /mnt
reboot
```

---

## 2. Primer arranque

Inicia sesión como `pikson` y conecta a internet:
```bash
# WiFi
nmcli device wifi connect "NombreRed" password "contraseña"

# O con interfaz gráfica (más adelante)
nmtui
```

---

## 3. Instalar todo con un comando

```bash
git clone https://github.com/Joan005/PikSOn
cd PikSOn
bash install.sh
```

El script instala automáticamente:
- Hyprland y todo el entorno de escritorio
- Todos los programas (Brave, Discord, Steam, VS Code, Spotify...)
- La configuración completa (Waybar, Kitty, Wofi, Mako...)
- El backup automático diario a GitHub

**Reinicia al terminar y el sistema estará listo.**

---

## 4. Aplicaciones instaladas

### Entorno de escritorio
| App | Función |
|-----|---------|
| Hyprland | Compositor Wayland |
| Waybar | Barra de estado |
| nwg-dock-hyprland | Dock lateral |
| Wofi | Lanzador de apps |
| Mako | Notificaciones |
| Kitty | Terminal |
| Hyprpaper | Fondos de pantalla |
| Hypridle | Suspensión automática |
| Hyprlock | Pantalla de bloqueo |
| Hyprswitch | Cambio de ventanas |

### Navegadores
| App | Función |
|-----|---------|
| Brave | Navegador principal (AUR) |

### Multimedia
| App | Función |
|-----|---------|
| Showtime | Reproductor de vídeo |
| Decibels | Reproductor de audio |
| GNOME Music | Biblioteca musical |
| Loupe | Visor de imágenes |
| Snapshot | Cámara |
| Papers | Visor de PDFs |

### Productividad y desarrollo
| App | Función |
|-----|---------|
| Visual Studio Code | Editor de código (AUR) |
| GitHub CLI | Git desde terminal |
| Node.js + npm | Runtime JavaScript |
| Python + pip | Runtime Python |

### Comunicación y gaming
| App | Función |
|-----|---------|
| Discord | Chat y voz |
| Steam | Videojuegos |
| Spotify | Música (Flatpak) |

### Utilidades
| App | Función |
|-----|---------|
| Grim + Slurp | Capturas de pantalla |
| Pavucontrol / Pwvucontrol | Control de audio |
| Piper | Configuración del ratón |
| Playerctl | Control de medios |
| Brightnessctl | Brillo de pantalla |
| Baobab | Analizador de disco |
| Nautilus | Gestor de archivos |
| Wl-clipboard | Portapapeles Wayland |

### Fuentes
- JetBrains Mono Nerd (terminal)
- Cormorant
- Unifraktur
- Noto Fonts

---

## 5. Atajos de teclado

> `Super` = tecla Windows

### Abrir aplicaciones
| Atajo | Acción |
|-------|--------|
| `Super + Enter` | Terminal (Kitty) |
| `Super + C` | Claude (en terminal) |
| `Super + B` | Brave |
| `Super + W` | WhatsApp Web (Brave) |
| `Super + D` | Discord |
| `Super + V` | VS Code |
| `Super + E` | Nautilus (archivos) |
| `Super + S` | Spotify |
| `Super + Shift + S` | Steam |
| `Super + Space` | Lanzador de apps (Wofi) |
| `Super + Q` | Transcripción por voz (Whisper) |

### Gestión de ventanas
| Atajo | Acción |
|-------|--------|
| `Super + Shift + Q` | Cerrar ventana activa |
| `Super + Backspace` | Cerrar ventana activa |
| `Super + F` | Pantalla completa |
| `Super + Shift + F` | Flotante / fijo |
| `Super + P` | Pseudotile |
| `Super + J` | Cambiar split |
| `Super + L` | Bloquear pantalla (Hyprlock) |
| `Super + Shift + E` | Salir de Hyprland |

### Foco y movimiento
| Atajo | Acción |
|-------|--------|
| `Super + ←↑↓→` | Mover foco entre ventanas |
| `Super + Shift + ←↑↓→` | Mover ventana |
| `Super + Ctrl + ←↑↓→` | Redimensionar ventana |

### Workspaces
| Atajo | Acción |
|-------|--------|
| `Super + 1-5` | Ir al workspace 1-5 |
| `Super + Shift + 1-5` | Mover ventana al workspace 1-5 |
| `Super + Rueda arriba/abajo` | Workspace siguiente/anterior |

### Capturas de pantalla
| Atajo | Acción |
|-------|--------|
| `Impr Pant` | Captura completa → `~/Imágenes/` |
| `Shift + Impr Pant` | Captura de área → `~/Imágenes/` |
| `Shift_R` | Captura de área → `~/Imágenes/` |
| `Super + Impr Pant` | Captura de área → portapapeles |

### Multimedia y sistema
| Atajo | Acción |
|-------|--------|
| `Subir volumen` | +5% volumen |
| `Bajar volumen` | -5% volumen |
| `Silenciar` | Mute/unmute |
| `Play/Pausa` | Reproducir / pausar |
| `Siguiente` | Canción siguiente |
| `Anterior` | Canción anterior |
| `Brillo +` | +5% brillo |
| `Brillo -` | -5% brillo |

### Ratón
| Atajo | Acción |
|-------|--------|
| `Super + Clic izquierdo` | Mover ventana flotante |
| `Super + Clic derecho` | Redimensionar ventana |
