# 🎩 PikSOn — Arch Linux + Hyprland

Guía de instalación **manual (sin script)** de mi entorno de trabajo en Arch Linux con Hyprland y Quickshell.

<a id="estructura"></a>
## 🗂️ Estructura del repositorio

```
PikSOn/
├── README.md                # Este manual
├── pkglist.txt              # Paquetes de los repositorios oficiales
├── aur-pkglist.txt          # Paquetes del AUR
├── zsh/
│   ├── .zshrc               # Configuración de zsh (se copia a ~/.zshrc)
│   └── .zprofile            # Arranque automático de Hyprland (se copia a ~/.zprofile)
└── .config/                 # Configuraciones (se copian a ~/.config)
    ├── hypr/
    │   └── hyprland.lua     # Hyprland: monitor, atajos, bordes, cursor, terminal y arranque automático
    ├── kitty/
    │   └── kitty.conf       # Terminal: tipografía, colores (Pergamino nocturno) y transparencia
    └── quickshell/
        ├── shell.qml        # Punto de entrada
        ├── Theme.qml        # Tema: colores, tamaños y fuentes (singleton)
        ├── Wallpaper.qml    # Fondo de pantalla
        ├── wallpaper.jpg    # Imagen del fondo
        ├── Bar.qml          # Barra superior: workspaces, música, reloj, tiempo, volumen, red, avisos y apagado
        ├── Player.qml       # Chip de música de la barra (cualquier reproductor MPRIS)
        ├── PlayerPanel.qml  # Panel del reproductor: carátula, progreso, controles y letra
        ├── Lyrics.qml       # Lógica de la letra sincronizada (LRCLIB)
        ├── LyricsFloat.qml  # Columna fija de letra a la derecha de la pantalla
        ├── ThinSlider.qml   # Deslizador fino reutilizable
        ├── SoundPanel.qml   # Panel de sonido: salida, entrada y volúmenes
        ├── NotifPanel.qml   # Historial de avisos (campana)
        ├── NotifToasts.qml  # Avisos emergentes
        ├── Weather.qml      # Datos del tiempo (Open-Meteo)
        ├── WeatherPanel.qml # Panel del tiempo
        ├── NetPanel.qml     # Panel de red y Bluetooth: el medallón
        ├── Calendar.qml     # Calendario con agenda de tareas
        ├── PowerMenu.qml    # Menú de apagado
        ├── Dock.qml         # Dock lateral oculto: ventanas abiertas y bandeja (se despliega al pasar el ratón)
        └── scripts/
            ├── net.sh       # Resumen de red para el chip (debe ser ejecutable)
            ├── netinfo.sh   # Detalle de red para el panel (debe ser ejecutable)
            └── trayquit.sh  # Cierra la app de un icono de la bandeja (debe ser ejecutable)
```

| Elemento | Descripción |
|---|---|
| `README.md` | Manual de instalación y uso |
| `pkglist.txt` | Paquetes oficiales, generada con `pacman -Qqen` |
| `aur-pkglist.txt` | Paquetes del AUR, generada con `pacman -Qqem` |
| `zsh/.zshrc` | Shell zsh con plugins y starship |
| `zsh/.zprofile` | Lanza Hyprland al iniciar sesión en el TTY1 |
| `.config/hypr/` | Configuración de Hyprland, incluidos el monitor, los atajos, los bordes y el cursor |
| `.config/kitty/` | Configuración del terminal |
| `.config/quickshell/` | Tema, barra, paneles, dock lateral, fondo y scripts de apoyo |

> 💡 Las carpetas de `.config/` replican la ruta que tendrían en `~/.config`. `zsh/` está fuera porque `.zshrc` y `.zprofile` viven en la carpeta personal; con GNU Stow se enlazarán automáticamente.

---

## 📑 Índice
1. [Instalar Arch Linux](#s1)
2. [Instalar Hyprland](#s2)
3. [Ajustes para máquina virtual (VirtualBox)](#s3)
4. [Primer arranque](#s4)
5. [Terminal: kitty](#s5)
6. [Editor de texto](#s6)
7. [Navegador Brave y atajo de teclado](#s7)
8. [Atajos de teclado personalizados](#s8)
9. [Quickshell: barra, paneles y fondo](#s9)
10. [Programas instalados](#s10)
11. [Git y GitHub](#s11)
12. [Herramientas de apoyo](#s12)
13. [Restaurar el entorno en otro equipo](#s13)
14. [Pendiente](#s14)

---

<a id="s1"></a>
## 1. 💿 Instalar Arch Linux

```bash
archinstall
```

Una vez instalado, comprueba que hay conexión a internet:

```bash
ping archlinux.org
```

> ⌨️ La distribución del teclado se mantiene en **inglés (US)**: es una decisión deliberada.

### 1.1 Red: NetworkManager

`archinstall` puede dejar la red gestionada por `systemd-networkd`. Se usa **NetworkManager** porque es el estándar en portátiles (Wi-Fi) y ofrece `nmcli`, que sirve igual para cable y Wi-Fi: la misma instalación vale para una VM, una torre con Ethernet y un portátil.

> ⚠️ Haz antes una **instantánea de la VM**: al cambiar de gestor, la interfaz pierde su IP hasta reiniciar o reconectarla.

```bash
sudo pacman -S --needed networkmanager
sudo systemctl disable --now systemd-networkd.service systemd-networkd.socket
sudo systemctl enable --now NetworkManager
sudo reboot
```

Tras reiniciar, comprueba que solo hay un gestor activo y que hay red:

```bash
systemctl is-active NetworkManager systemd-networkd   # active / inactive
nmcli device status
ping -c 3 archlinux.org
```

> 💡 Al deshabilitar `systemd-networkd` aparece un aviso sobre sus *sockets* (`triggering units are still active`): es normal, ya no arrancarán y el reinicio los limpia. Si tras el reinicio `systemd-networkd` siguiera `active`, enmascáralo con `sudo systemctl mask systemd-networkd.service systemd-networkd.socket`.

> 💡 Si la conexión no vuelve sin reiniciar: `sudo nmcli device disconnect enp0s3` y `sudo nmcli device connect enp0s3` (sustituye `enp0s3` por tu interfaz).

> 💡 Los nombres de interfaz cambian de un equipo a otro (`enp0s3` en la VM, `enp3s0` en una torre, `wlan0` o `wlp2s0` en un portátil). Por eso nada de este repositorio escribe un nombre fijo: se detecta por **tipo** (`ethernet` o `wifi`).

### 1.2 Audio: PipeWire

`archinstall` no deja instalado el servidor de sonido. Hace falta **PipeWire**, que además aporta `wpctl`, la herramienta que usan el chip de volumen ([9.8](#98-chip-de-volumen-y-panel-de-sonido)) y las teclas multimedia de Hyprland.

```bash
sudo pacman -S --needed pipewire wireplumber pipewire-pulse
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

| Paquete | Función |
|---|---|
| `pipewire` | El servidor de sonido |
| `wireplumber` | El gestor de dispositivos; incluye `wpctl` |
| `pipewire-pulse` | Compatibilidad con programas que usan PulseAudio (Brave, Discord...) y aporta `pactl`, que usa el panel de sonido |

> 💡 Estos servicios son **de usuario**: se activan **sin `sudo`** y arrancan en cada inicio de sesión. Si tras reiniciar no hay sonido, repite el `systemctl --user enable --now`.

Comprueba que hay una salida de audio y que responde:

```bash
wpctl status                                  # debe haber un dispositivo en "Sinks"
wpctl get-volume @DEFAULT_AUDIO_SINK@         # Volume: 0.40
```

> 💡 En una VM, con la máquina **apagada**, habilita el audio en *Configuración → Audio → Habilitar audio* (controlador Intel HD Audio). Sin tarjeta de sonido virtual, el chip mostrará `Vol --`.

### 1.3 Zona horaria y hora

Tras `archinstall`, la zona horaria puede quedar en **UTC**, y el reloj de la barra marcaría una hora menos (en España, en invierno) o dos (en verano). Se comprueba y se corrige con `timedatectl`:

```bash
timedatectl
sudo timedatectl set-timezone Europe/Madrid
sudo timedatectl set-ntp true     # recomendado en hardware real
```

| Línea de `timedatectl` | Debe decir |
|---|---|
| `Time zone` | `Europe/Madrid (CET, +0100)` (o `CEST, +0200` en verano) |
| `System clock synchronized` | `yes` |
| `RTC in local TZ` | `no` |

Quickshell lee la zona horaria al arrancar: tras cambiarla, reinícialo (`pkill qs` y vuelve a lanzar `qs`), o cierra sesión y vuelve a entrar.

> 💡 Es un ajuste **del sistema**, no un fichero del repositorio: git no lo guarda, y hay que repetirlo en cada equipo nuevo (como `chsh`, [apartado 12](#s12)).

> 💡 `set-ntp true` activa la sincronización automática con internet. En una VM no hace falta, porque VirtualBox ya sincroniza la hora con la del anfitrión.

---

<a id="s2"></a>
## 2. 🪟 Instalar Hyprland

Documentación oficial: <https://wiki.hypr.land/Getting-Started/Installation/>

```bash
sudo pacman -S hyprland
```

---

<a id="s3"></a>
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

> 💡 Los programas que dibujan con OpenGL (kitty, Quickshell) fallan en VirtualBox con errores como `invalid arguments for wl_surface#attach` o `Could not create EGL surface`. La solución es la variable `LIBGL_ALWAYS_SOFTWARE=1` (apartados [5](#s5) y [9](#s9)). **No debe usarse en hardware real.**

> 💡 En la VM solo se puede probar la conexión **por cable** (adaptador virtual). El Wi-Fi y el Bluetooth requieren hardware real.

> 💡 El audio virtual de VirtualBox tiene límites (volumen mínimo ≈ 45 %, silencio sin efecto y quizá sin micrófono): ver [9.8](#98-chip-de-volumen-y-panel-de-sonido).

> 💡 Los diálogos de archivos de GTK (por ejemplo, "Guardar como" en Brave) pueden verse mal en la VM. Si no se puede guardar, descarga con `curl` ([9.9](#99-fondo-de-pantalla)).

> 💡 **Spotify de escritorio no dibuja su ventana en la VM** (el proceso arranca, pero no aparece ventana ni se anuncia): es una limitación de la máquina virtual sin GPU. Ver [9.11](#911-chip-de-música-en-la-barra).

> 💡 **La pantalla de la VM solo ofrece 60 Hz**, y la escala automática de Hyprland sale demasiado alta (1,67) y recorta las aplicaciones: ver [el apartado 8](#otros-ajustes-de-hyprlandlua-monitor-escala-y-frecuencia).

> 💡 Con el renderizado por software de la VM, las animaciones continuas pueden verse entrecortadas y gastar CPU: en hardware real irán fluidas ([apartado 14](#s14)).

---

<a id="s4"></a>
## 4. 🚀 Primer arranque

Desde el TTY:

```bash
start-hyprland
```

> ⚠️ Entra **siempre con `start-hyprland`**, también al volver a entrar tras salir de la sesión. Arrancar `Hyprland` directamente funciona, pero muestra el aviso *"Hyprland was started without start-hyprland. This is strongly discouraged unless you are in a debugging environment"*: el lanzador prepara el entorno de la sesión y vigila el proceso.

### 4.1 Arranque automático de Hyprland

Para no teclear `start-hyprland` cada vez, se puede lanzar solo al iniciar sesión en el TTY. Se sigue escribiendo **usuario y contraseña** (no hay autologin): lo único que se automatiza es el último paso.

Con zsh como shell de inicio de sesión ([apartado 12](#s12)), el fichero que se lee al entrar es `~/.zprofile`:

```zsh
# arranca Hyprland automaticamente al iniciar sesion en el TTY1
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec start-hyprland
fi
```

| Línea | Para qué |
|---|---|
| `-z "$WAYLAND_DISPLAY"` | Solo si **no** hay ya un escritorio en marcha, para no arrancarlo dos veces |
| `"$XDG_VTNR" = "1"` | Solo en el **TTY1**: los demás TTY quedan libres como vía de rescate |
| `exec start-hyprland` | Sustituye la shell por Hyprland; al salir de él, se cierra la sesión |

Para probarlo, sin reiniciar: `Super + Shift + E` para salir de Hyprland, `exit` en el TTY e iniciar sesión de nuevo.

> ⚠️ **Salir de Hyprland ahora cierra la sesión** y vuelve al `login:`. Si necesitas una terminal fuera de Hyprland (por ejemplo, para corregir un fallo), usa el **TTY2**: `Ctrl derecho + F2` (en VirtualBox, *Entrada → Teclado → Insertar Ctrl-Alt-F2*) e inicia sesión ahí; **no** arranca Hyprland. Vuelve al TTY1 con `Ctrl derecho + F1`.

> ⚠️ Si Hyprland falla al arrancar (por ejemplo, por un error en `hyprland.lua`), el TTY1 volverá al `login:` una y otra vez. Repara desde el TTY2, o desactiva temporalmente el arranque automático: `mv ~/.zprofile ~/.zprofile.off`.

> 💡 La comprobación de `$WAYLAND_DISPLAY` lleva `$`. Sin él (`-z "WAYLAND_DISPLAY"`) se compara el texto literal, nunca está vacío y Hyprland no arrancaría solo.

> 💡 Si la shell fuera bash, el fichero equivalente es `~/.bash_profile`.

> 💡 En hardware real se puede sustituir el TTY por un **gestor de inicio gráfico**: si se instala, hay que **quitar este bloque** de `~/.zprofile` para no lanzar Hyprland dos veces ([apartado 14](#s14)).

---

<a id="s5"></a>
## 5. 🔧 Terminal: kitty

### 5.1 Solución si kitty no abre

En VirtualBox, kitty puede cerrarse al instante al pulsar `Super + Q` (atajo por defecto) por falta de OpenGL. Solución en tres pasos.

**Usar foot temporalmente**

```bash
sudo pacman -S --needed foot
```

Localiza la línea del terminal, haz una copia de seguridad y sustitúyelo:

```bash
grep -n -i "kitty" $HOME/.config/hypr/hyprland.lua
cp $HOME/.config/hypr/hyprland.lua $HOME/.config/hypr/hyprland.lua.bak
sed -i 's/"kitty"/"foot"/' $HOME/.config/hypr/hyprland.lua
```

Sal con `Super + M` (atajo por defecto), vuelve a entrar con `start-hyprland` y abre foot con `Super + Q`.

**Probar kitty con renderizado por software**, desde foot:

```bash
LIBGL_ALWAYS_SOFTWARE=1 kitty
```

Si kitty se abre, funciona con esa variable.

**Dejar kitty como terminal definitivo**

```bash
cd $HOME/.config/hypr
sed -i 's/"foot"/"env LIBGL_ALWAYS_SOFTWARE=1 kitty"/' hyprland.lua
grep -n "local terminal" hyprland.lua
```

Recarga saliendo con `Super + M` y ejecutando de nuevo `start-hyprland`. Prueba `Super + Q`.

> ⚠️ `LIBGL_ALWAYS_SOFTWARE=1` solo es necesario en la VM. **No lo uses en hardware real.**

### 5.2 Configuración propia: `kitty.conf`

Sin fichero, kitty usa su configuración por defecto. Todo su aspecto se controla con `~/.config/kitty/kitty.conf`.

Tipografía: **JetBrains Mono Nerd Font**, la misma que usa todo Quickshell. La variante **`Mono`** encaja los iconos de Nerd Font en una sola celda, que es lo que conviene en un terminal:

```bash
sudo pacman -S --needed ttf-jetbrains-mono-nerd
fc-cache -f
fc-list | grep -i jetbrains     # el nombre de familia va entre los dos puntos
```

Los colores son los de la paleta **Pergamino nocturno** (los mismos valores que `Theme.qml`, [9.13](#913-tema-themeqml)).

`~/.config/kitty/kitty.conf`:

```conf
# tipografia
font_family     JetBrainsMono Nerd Font Mono
font_size       10.0

# aspecto
background_opacity      0.7
window_padding_width    10
cursor_shape    beam
scrollback_lines        10000
confirm_os_window_close 0
enable_audio_bell       no

# colores: Pergamino nocturno (mismos valores que Theme.qml)
foreground      #f6ebcf
background      #34261b
selection_foreground    #2d1e12
selection_background    #e2b564
cursor  #e2b564
cursor_text_color       #2d1e12
url_color       #cf7b55

# paleta ANSI (ls, git, mensajes de error...)
color0  #34261b
color1  #c0584a
color2  #8fae66
color3  #e2b564
color4  #7d93ae
color5  #a97b8f
color6  #6fa597
color7  #d9ccae
color8  #6b4f39
color9  #cf7b55
color10 #adc783
color11 #ebc98a
color12 #9fb3c9
color13 #c49aae
color14 #92c2b5
color15 #f6ebcf
```

Abre una terminal nueva (`Super + Enter`) o recarga la actual con **`Ctrl + Shift + F5`**.

| Línea | Qué controla |
|---|---|
| `foreground` | Color del **texto** |
| `background` | Color del **relleno** de la ventana |
| `background_opacity` | Transparencia: `1.0` opaco; se usa `0.7`; valores menores = más transparente |
| `font_size` | Tamaño de letra (10 con la escala 1,25 del monitor) |
| `color0` ... `color15` | La paleta ANSI de 16 colores: los normales (0-7) y los claros (8-15) |

> 💡 **El tamaño de letra depende de la escala del monitor** ([apartado 8](#otros-ajustes-de-hyprlandlua-monitor-escala-y-frecuencia)): con la escala 1,25 queda bien con **10**; con la escala automática de 1,67 hacía falta 8.

> 💡 **Probar en caliente** (temporal, no toca el fichero): `Ctrl + Shift + +` / `-` cambian el tamaño de letra, `Ctrl + Shift + Retroceso` vuelve al valor del fichero, y `Ctrl + Shift + A` seguido de `L` (más transparente), `M` (menos) o `D` (valor del fichero) cambian la opacidad.

> 💡 Si no se ve el color elegido, suele ser la transparencia: con valores bajos (0.5) la imagen de fondo domina.

> 💡 No mezcles `foreground` y `background`: un tono pensado para el texto puesto en `background` da una ventana pálida.

> 💡 **Los colores están repetidos en tres sitios**: `Theme.qml` (barra y paneles), `kitty.conf` (terminal) y `hyprland.lua` (bordes de las ventanas). Si cambias de paleta, hay que tocar los tres a mano ([apartado 14](#s14)).

> 💡 Para ver la configuración que kitty está aplicando y sus errores: **`Ctrl + Shift + F6`** dentro de una terminal de kitty (la opción `kitty --debug-config` ya no existe en kitty 0.49).

> 💡 Al abrir o reajustar ventanas, kitty muestra un instante el tamaño de la ventana en celdas (`233 by 48 cells`). Es inofensivo.

---

<a id="s6"></a>
## 6. ✏️ Editor de texto

Instalamos **nano**, un editor de texto sencillo para terminal:

```bash
sudo pacman -S --needed nano
```

Uso básico: `Ctrl+O` guarda, `Ctrl+X` sale y `Ctrl+W` busca.

### Reemplazar un fichero entero en nano

| Paso | Atajo |
|---|---|
| Desactivar la sangría automática (antes de pegar código) | `Alt + I` (el mismo atajo la vuelve a activar) |
| Ir al principio del fichero | `Alt + \` |
| Cortar desde el cursor hasta el final (lo deja vacío) | `Alt + T` |
| Pegar el contenido nuevo | `Ctrl + Shift + V` (o clic derecho / `Shift + Insert`) |
| Guardar y salir | `Ctrl + O`, `Enter`, `Ctrl + X` |

> ⚠️ Pega **solo el contenido del fichero**. Las líneas `cat > fichero <<'EOF'` y `EOF` son parte de otro método (escribir desde la terminal) y **no deben pegarse dentro de nano**: `EOF` quedaría escrito en el fichero y lo rompería.

> 💡 Para ficheros largos, pegar es más fiable que teclear: las erratas de teclear a mano (letras que faltan o sobran, espacios, líneas partidas) son la causa de casi todos los fallos de la tabla del [apartado 9.5](#95-solución-de-problemas).

> 💡 Para **pegar desde fuera de la VM**, el portapapeles compartido de VirtualBox puede no funcionar con Hyprland (Wayland). Alternativa fiable: abrir el manual en Brave **dentro** de la VM y copiar desde allí.

> ⚠️ Si editas un fichero **por fuera** (con `sed`, por ejemplo) mientras sigue abierto en nano, el aviso **Modified** indica que nano tiene su propia copia sin guardar: al guardar desde nano, **sobrescribirá** el cambio externo. Cierra nano antes, o corrige dentro de nano (`Ctrl + \` busca y reemplaza).

> 💡 **Antes de reemplazar un fichero grande** (`Bar.qml`, `Dock.qml`), haz una copia fuera del repositorio: `cp $HOME/.config/quickshell/Bar.qml $HOME/Bar.qml.bak1`. Así, si algo sale mal, se vuelve atrás con un `cp`. Las copias viven en `~`, **nunca** dentro de `~/.config/quickshell` ni del repositorio.

### Números de línea

`Alt + #` (es decir, `Alt + Shift + 3` en un teclado US) **muestra u oculta** la numeración, y se repite para alternarla. Es muy útil con los avisos de Quickshell, que citan fichero, línea y columna (`@Bar.qml[196:11]`). Para dejarla siempre activa:

```bash
echo "set linenumbers" >> $HOME/.nanorc
```

Para ir directamente a una línea: `Ctrl + _` (barra baja), el número y `Enter`.

Para ver un fichero con sus números de línea **sin abrirlo**, y solo un tramo:

```bash
cat -n $HOME/.config/quickshell/Bar.qml | sed -n '124,190p'
```

### Buscar y reemplazar

`Ctrl + \` pide el texto a buscar y el que lo sustituye. Con `A` en la pregunta de cada coincidencia se reemplazan **todas** de una vez. Es la forma más cómoda de cambiar un valor repetido por muchas líneas (por ejemplo, una tipografía por otra).

> 💡 Si en «Replace with» se pulsa `Enter` **sin escribir nada**, el texto buscado se **borra**. Es la forma rápida de quitar una línea concreta.

> 💡 La búsqueda **no distingue mayúsculas de minúsculas** y encuentra el texto aunque sea parte de otro más largo (`height: 28` también casaría con `implicitHeight: 28`). Para saber cuántas coincidencias habrá, conviene contarlas antes con `grep -n "texto" fichero`.

### Cortar o sustituir un bloque de líneas

| Paso | Atajo |
|---|---|
| Ir a la primera línea del bloque | `Ctrl + _`, el número y `Enter`; después `Home` |
| Marcar el inicio de la selección | `Alt + A` |
| Extender la selección | La flecha `↓` tantas veces como líneas tenga el bloque |
| Cortar la selección | `Ctrl + K` |
| Abrir una línea nueva **debajo** de otra | Ir a esa línea, `End` y `Enter` |

> 💡 **Trabaja de abajo hacia arriba.** Al borrar o añadir líneas, los números de las que quedan por debajo cambian; si se editan primero las de más abajo, los números de las de arriba siguen valiendo.

> 💡 Al **sustituir** un bloque cortado por otro tecleado, termina el bloque nuevo con `Enter`: así la llave de cierre que había debajo queda en su propia línea.

> 💡 Al teclear bloques QML con la sangría automática desactivada (`Alt + I`), se escriben **sin sangría**: a QML no le importa, y se evitan errores al teclear.

---

<a id="s7"></a>
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

<a id="s8"></a>
## 8. ⌨️ Atajos de teclado personalizados

Añadidos a `~/.config/hypr/hyprland.lua`:

| Atajo | Acción | Línea |
|---|---|---|
| `Super + Enter` | Abrir terminal (kitty) | `hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))` |
| `Super + B` | Abrir Brave | `hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave"))` |
| `Super + D` | Abrir Discord | `hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("discord"))` |
| `Super + Retroceso` | Cerrar la ventana activa | `hl.bind(mainMod .. " + BACKSPACE", hl.dsp.window.close())` |
| `Super + Shift + E` | Salir de Hyprland | `hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())` |

> 💡 `Super + Q` queda libre (antes abría la terminal y `Super + M` salía de Hyprland, ambos sustituidos).

> 💡 Los atajos de **workspaces** (`Super + 1…5` para ir a un escritorio y `Super + Shift + 1…5` para mover la ventana activa) llegan solo hasta el **5**, igual que la barra ([9.2](#92-ficheros-de-configuración)).

> 💡 La configuración generada ya incluye las teclas multimedia (volumen, brillo y reproducción). Para que funcionen, deben estar instalados `wpctl` (wireplumber, [apartado 1.2](#12-audio-pipewire)), `brightnessctl` y `playerctl`.

### Otros ajustes de `hyprland.lua`: tamaño del cursor

El puntero del ratón usa el tema **Adwaita** (el de por defecto) y Hyprland arranca con un tamaño de **24**. Para reducirlo, se cambian las variables de entorno de la sección `ENVIRONMENT VARIABLES` de `~/.config/hypr/hyprland.lua`:

```lua
hl.env("XCURSOR_SIZE", "16")
hl.env("HYPRCURSOR_SIZE", "16")
```

| Variable | Qué fija |
|---|---|
| `XCURSOR_SIZE` | Tamaño del cursor para las aplicaciones normales y XWayland |
| `HYPRCURSOR_SIZE` | Tamaño para los temas de cursor propios de Hyprland (*hyprcursor*) |

**Probar un tamaño al instante** (solo dura hasta cerrar la sesión), con el nombre del tema que muestra `ls /usr/share/icons`:

```bash
ls /usr/share/icons                  # Adwaita  AdwaitaLegacy  default  hicolor
hyprctl setcursor Adwaita 16
```

Las variables solo se leen al arrancar: tras cambiarlas, **cierra sesión y vuelve a entrar**. Comprueba con:

```bash
echo "tema=[$XCURSOR_THEME] tamaño=[$XCURSOR_SIZE]"     # tamaño=[16]
```

> 💡 El tema queda vacío (se usa el de por defecto). Para cambiarlo: `hl.env("XCURSOR_THEME", "NombreDelTema")` con el nombre de una carpeta de `/usr/share/icons`.

> 💡 Algunas aplicaciones GTK (como Brave) pueden conservar su propio tamaño de cursor; se ajusta aparte en la configuración de GTK.

### Otros ajustes de `hyprland.lua`: monitor, escala y frecuencia

El monitor se configura en el bloque `hl.monitor` (al principio de `hyprland.lua`, en la sección `MONITORS`):

```lua
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "1.25",
})
```

Con `scale = "auto"`, en la VM Hyprland elige **1,67** (no conoce el tamaño físico de la pantalla). Con una pantalla de 1920 × 955, eso deja unos **1152 × 573 píxeles útiles**, y las aplicaciones con tamaño mínimo se recortan. Por eso la escala se fija a mano:

| Escala | Píxeles útiles (1920 × 955) | Resultado |
|---|---|---|
| `1.67` (automática en la VM) | 1152 × 573 | Todo grande, pero las apps no caben |
| **`1.25`** (la que se usa) | 1536 × 764 | Todo cabe y se lee bien |
| `1` | 1920 × 955 | Todo cabe, pero el texto es muy pequeño |

Comprueba la escala y la resolución con `hyprctl monitors` (líneas `scale:` y la primera, con `@`). Hyprland recarga la configuración al guardar; si no, `hyprctl reload`.

> 💡 Al cambiar la escala hay que **reajustar el tamaño de letra** del terminal ([5.2](#52-configuración-propia-kittyconf)): con 1,25 se usa 10.

> 💡 **Frecuencia (Hz):** la VM solo ofrece **60 Hz**, así que la de un monitor de 165 Hz solo se puede usar en **hardware real**. Allí se fija en `mode`: `mode = "1920x1080@165"`, o `mode = "highrr"` para que Hyprland elija la frecuencia más alta. En un equipo real, revisa también la escala.

> 💡 **Discord necesita ≈ 940 px de ancho:** en pantalla dividida (≈ 750 px por mitad con la escala 1,25) puede recortarse por la derecha. Se resuelve con la distribución de las ventanas, no con la escala.

### Otros ajustes de `hyprland.lua`: bordes y separación

Los bordes de las ventanas usan los colores del tema **Pergamino nocturno** (dorado para la ventana activa, marrón apagado para las inactivas). Están en el bloque `general` de `hl.config`:

```lua
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        active_border = { colors = {"rgba(e2b564ee)", "rgba(cf7b55ee)"}, angle = 45 },
        inactive_border = "rgba(8c6d4faa)",
        -- ...el resto de opciones se deja como estaba
    },
})
```

| Opción | Qué controla |
|---|---|
| `gaps_in` | Separación entre ventanas (5) |
| `gaps_out` | Separación entre las ventanas y el borde de la pantalla (20) |
| `border_size` | Grosor del borde (2) |
| `active_border` | Borde de la ventana activa: degradado dorado → terracota a 45° |
| `inactive_border` | Borde de las demás: marrón apagado |

> 💡 En Hyprland los colores se escriben **`rgba(RRGGBBAA)`**: el alfa va al **final**. En QML (`Theme.qml`) el formato es **`#AARRGGBB`**, con el alfa al **principio**.

> 💡 Si los bordes siguen viéndose de otro color tras cambiarlos, comprueba que no hay otra definición más abajo en el fichero que los sobrescriba: `grep -n "border" $HOME/.config/hypr/hyprland.lua`.

---

<a id="s9"></a>
## 9. 🧩 Quickshell: barra, paneles y fondo

**Quickshell** es un kit para construir la interfaz del escritorio (barras, paneles, widgets) con QML. Aquí se usa para una barra superior **«solo texto»** (sin cajas ni adornos: workspaces en números romanos, música, reloj, tiempo, volumen, red, avisos y apagado), un panel desplegable por cada pieza, una columna lateral con la letra de la canción, un **dock lateral oculto** (ventanas abiertas y bandeja del sistema, que aparece al pasar el ratón por el borde derecho) y el fondo de pantalla. Todo comparte colores, tamaños y **una única tipografía** (JetBrains Mono Nerd Font) a través de un **tema** ([9.13](#913-tema-themeqml)).

### 9.1 Instalación

```bash
sudo pacman -S quickshell
qs --version
```

Para los avisos de escritorio hace falta además `libnotify` (aporta `notify-send`, con el que se prueban):

```bash
sudo pacman -S --needed libnotify
```

### 9.2 Ficheros de configuración

La configuración vive en `~/.config/quickshell/` y se divide en piezas:

| Fichero | Función |
|---|---|
| `shell.qml` | Punto de entrada: carga las demás piezas |
| `Theme.qml` | El tema: paleta, tamaños y fuentes, compartidos por todas las piezas ([9.13](#913-tema-themeqml)) |
| `Wallpaper.qml` | Fondo de pantalla (una ventana en la capa `Background`) |
| `wallpaper.jpg` | La imagen del fondo |
| `Bar.qml` | La barra y el **cerebro** de los paneles: estado, apertura/cierre, avisos, red, volumen |
| `Player.qml` / `PlayerPanel.qml` | Chip de música y su panel ([9.11](#911-chip-de-música-en-la-barra), [9.14](#914-panel-del-reproductor)) |
| `Lyrics.qml` / `LyricsFloat.qml` | Letra sincronizada y su columna lateral ([9.15](#915-letra-sincronizada)) |
| `ThinSlider.qml` | Deslizador fino que reutilizan el reproductor y el sonido |
| `SoundPanel.qml` | Panel de sonido ([9.8](#98-chip-de-volumen-y-panel-de-sonido)) |
| `NotifPanel.qml` / `NotifToasts.qml` | Historial y avisos emergentes ([9.16](#916-avisos-y-campana)) |
| `Weather.qml` / `WeatherPanel.qml` | El tiempo ([9.17](#917-el-tiempo)) |
| `NetPanel.qml` | Panel de red y Bluetooth, el medallón ([9.7](#97-panel-de-red-el-medallón)) |
| `Calendar.qml` | Calendario con agenda de tareas ([9.12](#912-calendario-y-agenda)) |
| `PowerMenu.qml` | Menú de apagado ([9.18](#918-menú-de-apagado)) |
| `Dock.qml` | Dock lateral oculto: ventanas abiertas y bandeja ([9.4](#94-dock-lateral-ventanas-y-bandeja)) |
| `scripts/net.sh` | Resumen de la red para el chip (`tipo\|dispositivo\|ip`) |
| `scripts/netinfo.sh` | Detalle de la red para el panel (`clave=valor`) |
| `scripts/trayquit.sh` | Cierra del todo la app de un icono de la bandeja |

`shell.qml`:

```qml
import Quickshell

ShellRoot {
    Wallpaper {}
    Bar {}
    Dock {}
}
```

Para restaurarla desde este repositorio:

```bash
cp -r .config/quickshell $HOME/.config/
chmod +x $HOME/.config/quickshell/scripts/*.sh
qs
```

Quickshell **recarga solo** al guardar un fichero. Si hay un error, aparece una ventana con la línea y el motivo.

> ⚠️ **Quickshell no se entera de los ficheros `.qml` nuevos o renombrados** si la configuración ya estaba rota. Para forzar la recarga: `touch $HOME/.config/quickshell/Bar.qml`. Y los nombres distinguen mayúsculas: `NotifPanel.qml` y `NotiPanel.qml` son ficheros distintos, y el tipo que se usa en `Bar.qml` debe llamarse igual que el fichero.

> 💡 **Los workspaces son números romanos** (I a V) a la izquierda de la barra: el del escritorio activo va en dorado y negrita, los demás atenuados, y un clic cambia de escritorio. Solo se muestran los que **existen** (aparecen al usarlos con `Super + 1…5`). Se dibujan con un `Row` (`wsRow`) que lee `Hyprland.workspaces` y cambia con `Hyprland.dispatch`. (Se probó una versión de «lomos de libros» y se descartó por recargada.)

> 💡 **Altura:** la ventana de la barra mide **36 px** (`implicitHeight` en `Bar.qml`), con un degradado suave y una línea fina de latón de 1 px abajo. Los grupos de la derecha (tiempo, volumen, red, campana y apagado) se separan con un filete vertical de 1 px.

> 💡 El dock (`Dock.qml`) **no reserva espacio**: está oculto salvo cuando se despliega, y se superpone a lo que haya debajo ([9.4](#94-dock-lateral-ventanas-y-bandeja)).

### 9.3 Arranque automático

Bloque incluido en `hyprland.lua`, dentro de la sección de autoarranque:

```lua
-- Quickshell: barra superior y panel lateral
hl.on("hyprland.start", function ()
    hl.exec_cmd("env LIBGL_ALWAYS_SOFTWARE=1 qs")
end)
```

> ⚠️ `LIBGL_ALWAYS_SOFTWARE=1` solo es necesario en **VirtualBox**, donde sin ella `qs` se cae al arrancar con `Could not create EGL surface`. **En hardware real, usa solo `hl.exec_cmd("qs")`.**

> 💡 Para depurar un fallo de arranque, redirige la salida a un fichero: `hl.exec_cmd("qs > $HOME/qs-arranque.log 2>&1")`. Con Quickshell ya en marcha, `qs log` muestra los avisos.

### 9.4 Dock lateral: ventanas y bandeja

`Dock.qml` es un **dock oculto en el borde derecho**. En reposo **no se ve nada**: solo hay una franja invisible de 6 px pegada al borde. Al llevar el ratón al borde derecho, el dock aparece con una animación corta (180 ms) y muestra, en una columna centrada en vertical:

| Zona | Qué muestra | Acciones |
|---|---|---|
| **Ventanas abiertas** | Un icono y el nombre (`appId`) de cada ventana; la **activa** lleva una raya dorada en el borde y las demás van atenuadas | **Clic izquierdo**: lleva la ventana al frente. **Clic derecho o central**: la cierra |
| **Filete** | Una línea fina, solo si hay ventanas **y** bandeja a la vez | |
| **Bandeja del sistema** | Las apps que siguen abiertas en segundo plano (icono, nombre y «Cerrar») | **Clic** en la fila: abre o muestra la app. **«Cerrar»**: termina la app del todo |

Al sacar el ratón, el dock se oculta de nuevo. Si no hay ninguna ventana ni app en la bandeja, la ventana del dock no existe.

Las ventanas las aporta `ToplevelManager` (módulo `Quickshell.Wayland`, con `appId`, `activated`, `activate()` y `close()`); la bandeja, `SystemTray` (módulo `Quickshell.Services.SystemTray`, protocolo *StatusNotifierItem*): las apps entran y salen solas, sin configurar nada. El icono de cada ventana sale de `DesktopEntries.heuristicLookup(appId)` y `Quickshell.iconPath()`; si no se encuentra, se dibuja la **inicial** del nombre.

| Ajuste | Valor |
|---|---|
| Ventana | `PanelWindow` anclada arriba, derecha y abajo; `implicitWidth` de 176 px (164 del dock desplegado y un margen) |
| Franja de reposo | `railClosed: 6` (px). Si cuesta «cazar» el borde, subirla a 10 |
| Ancho desplegado | `railOpen: 164` (px) |
| Detección del ratón | `HoverHandler` (`hov.hovered`) |
| Zona sensible | `mask: Region { item: rail }`: el resto de la ventana, transparente, deja pasar los clics |
| Espacio reservado | **Ninguno**: `exclusionMode: ExclusionMode.Ignore`. Las ventanas llegan a su margen normal y el dock se superpone al desplegarse |
| Capa | `WlrLayershell.layer: WlrLayer.Overlay`, para quedar **por encima de la columna de letra** y recibir bien el ratón |
| Fondo | Transparente en reposo; al desplegarse, `#f52d1e12` con un filete de latón a la izquierda |

```qml
PanelWindow {
    anchors { top: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: ToplevelManager.toplevels.values.length > 0 || SystemTray.items.values.length > 0
    mask: Region { item: rail }

    Rectangle {
        id: rail
        width: hov.hovered ? win.railOpen : win.railClosed
        clip: true
        HoverHandler { id: hov }
        // columna de ventanas, filete y bandeja (opacity: hov.hovered ? 1 : 0)
    }
}
```

El fichero completo está en `.config/quickshell/Dock.qml`.

> 💡 **Qué aparece en la bandeja:** solo las apps que la usan. **Discord** sí (al cerrar su ventana se queda en segundo plano, con la opción de minimizar a la bandeja activada en sus ajustes). **Brave** no usa la bandeja, pero **sí aparece como ventana abierta**. Para probar con una app pequeña: `sudo pacman -S --needed network-manager-applet` y `nm-applet --indicator &`.

> 💡 Cada ventana tiene su propia fila: dos ventanas de kitty son dos filas. Agruparlas por aplicación está pendiente ([apartado 14](#s14)).

> 💡 Esta es la **tercera versión** del dock: primero una cajita en la esquina inferior derecha que solo mostraba la bandeja; después se estudiaron otras opciones (bandeja en la barra, dock inferior flotante, barra inferior de texto, raíl lateral, bandeja plegable) y se eligió el **raíl lateral derecho que se despliega al pasar el ratón**, sin vista previa de iconos en reposo.

#### El botón "Cerrar": `trayquit.sh`

La bandeja no dice qué proceso hay detrás de cada icono, pero cada icono se registra en **D-Bus**, que sí lo sabe. El script busca el icono por su identificador, obtiene su proceso y lo cierra: primero con `kill` y, si a los 2 segundos sigue vivo, con `kill -9`. Sirve para **cualquier** aplicación de la bandeja.

`~/.config/quickshell/scripts/trayquit.sh`:

```sh
#!/bin/sh
# Cierra del todo la aplicacion de un icono de la bandeja.
# Uso: trayquit.sh ID    (sin ID, lista los iconos: id, pid y servicio)
want="$1"
w=org.kde.StatusNotifierWatcher
bus=org.freedesktop.DBus
items=$(busctl --user get-property $w /StatusNotifierWatcher $w RegisteredStatusNotifierItems 2>/dev/null)
echo "$items" | grep -o '"[^"]*"' | tr -d '"' | while read -r entry; do
    case "$entry" in
        */*) svc=${entry%%/*}; path=/${entry#*/} ;;
        *) svc=$entry; path=/StatusNotifierItem ;;
    esac
    id=$(busctl --user get-property "$svc" "$path" org.kde.StatusNotifierItem Id 2>/dev/null | cut -d'"' -f2)
    pid=$(busctl --user call $bus /org/freedesktop/DBus $bus GetConnectionUnixProcessID s "$svc" 2>/dev/null | awk '{print $2}')
    if [ -z "$want" ]; then
        echo "id=$id pid=$pid servicio=$svc"
    elif [ "$id" = "$want" ] && [ -n "$pid" ] && [ "$pid" -gt 1 ]; then
        kill "$pid"
        sleep 2
        kill -0 "$pid" 2>/dev/null && kill -9 "$pid"
    fi
done
```

Pruébalo **sin argumentos**, con una aplicación en la bandeja (por ejemplo, Discord): solo lista, no cierra nada.

```bash
sh $HOME/.config/quickshell/scripts/trayquit.sh
# id=discord_status_icon_1 pid=52582 servicio=:1.154
```

Con el `id` que muestre, cierra esa aplicación:

```bash
sh $HOME/.config/quickshell/scripts/trayquit.sh discord_status_icon_1
```

El texto **«Cerrar»** de cada fila de la bandeja lanza exactamente esa orden con el identificador del icono:

```qml
Quickshell.execDetached(["sh", "-c", "$HOME/.config/quickshell/scripts/trayquit.sh \"$0\"", trayRow.modelData.id])
```

> ⚠️ **El script debe ser ejecutable** (`chmod +x`), porque el botón lo lanza directamente. Un fichero creado con nano no lo es, y el clic en **Cerrar** no haría nada, aunque desde la terminal con `sh script` sí funcionara.

> ⚠️ Es un cierre brusco, como "Finalizar tarea" en Windows: lo que la aplicación no haya guardado se pierde. (El clic derecho sobre una **ventana** es más suave: le pide que se cierre, como la X de su ventana.)

> 💡 Para revisar la sintaxis del script sin ejecutarlo: `sh -n $HOME/.config/quickshell/scripts/trayquit.sh` (si no imprime nada, está bien).

### 9.5 Solución de problemas

Si al editar un `.qml` aparece la ventana **"Config reload failed"**:

- Indica fichero, línea y columna del error (por ejemplo, `@Bar.qml[44:2]`).
- `Type Bar unavailable` en `shell.qml` es solo la **consecuencia**: la causa real está en la línea del fichero que se cita debajo.
- Si el mismo error se repite tras editar, probablemente **el fichero no ha cambiado**: comprueba su contenido con `head -3` o `cat -n fichero | sed -n '30,52p'`.
- Los avisos amarillos (`WARN ... ReferenceError`, `TypeError`) no impiden cargar, pero señalan una errata que rompe una función. Se ven con `qs log`.
- Cuando el aviso dice **"is not a type"**, compara letra por letra con una línea idéntica que sí funcione, y comprueba que el **fichero existe con ese nombre exacto** (mayúsculas incluidas).
- Un fichero `.qml` que ninguna pieza usa todavía **no se comprueba**: sus erratas solo aparecen cuando otro fichero lo carga.
- Al **añadir** una línea con nano, comprueba que no **sustituyes** la que había.
- Cuando un error cita **una línea justo después de un bloque que acabas de pegar o teclear**, cuenta las llaves de cierre: lo más probable es que sobre o falte una.

Erratas reales encontradas al montar esta configuración:

| Síntoma | Causa | Corrección |
|---|---|---|
| `module "QuickQuick" is not installed` | `import QuickQuick` | `import QtQuick` |
| `module "Quicksell" is not installed` | `import Quicksell` (falta la `h`) | `import Quickshell` |
| `module "Quickshell.Services.StstemTray" is not installed` | `StstemTray` por `SystemTray` | `import Quickshell.Services.SystemTray` |
| `Wlrlayershell` no se reconoce | La `L` de `layer` en minúscula | `WlrLayershell` (QML distingue mayúsculas) |
| `mondelData is not defined` | Letras cruzadas | `modelData` |
| `Property 'execDetacged' ... is not a function` | Errata | `execDetached` |
| `Property 'secondaryActive' ... is not a function` | Falta el final | `secondaryActivate()` |
| `Repeat is not a type` | Falta el final | `Repeater` |
| `Rectagle is not a type` | Falta una `n` | `Rectangle` |
| `StudioCollector is not a type` | `Studio` por `Stdio` | `StdioCollector` |
| `NotifPanel is not a type` | El fichero se creó como `NotiPanel.qml` | Renombrarlo a `NotifPanel.qml` y `touch Bar.qml` |
| `Expected token ':'` | `porperty` por `property`, o `text. valor` con punto en vez de dos puntos, o `Text:` en vez de `Text {` | `property`; `text: valor`; `Text {` |
| `Incomplete binding, expected ':' or '{'` | Propiedad sin los dos puntos: `anchors.left.wsBox.right` | `anchors.left: wsBox.right` |
| `Expected token ','` (en `acceptedButtons`) | Texto duplicado al pegar | `acceptedButtons: Qt.LeftButton \| Qt.RightButton` |
| `Cannot assign to non-existent property "margin"` | Falta la `s` | `anchors.margins` |
| `Cannot assign to non-existent property "boder"` | Falta la `r` en `border.color` | `border.color` |
| `Cannot assign to non-existent property "onNetOpenChanged"` | Se borró `property bool netOpen: false` al añadir otra propiedad | Deben existir **todas** las propiedades `xxxOpen` |
| `Cannot assign a value to a signal (use 'on<Signal>: ...')` en `Theme.qml` | Una propiedad llamada `onAccent`: QML trata cualquier nombre `on` + mayúscula como un manejador de señal | Renombrarla (`fgOnAccent`) |
| `Invalid property assignment: color expected` | Color sin almohadilla (`"89b4fa"`) | `"#89b4fa"` |
| Un círculo o un fondo sale **rosa** en lugar de dorado | El color se escribió como `#e2b56499`, que QML lee con el alfa **delante** | `#99e2b564` (en QML el alfa va primero) |
| `Property 'strings' ... is not a function` | Nombre inventado | `substring` |
| `ReferenceError: i2 is not defined` | Variable sin declarar | El nombre declarado |
| `Vol undefined%` | La propiedad se declaró como `volPrecent` y se usa `volPercent` | Un único nombre en todo el fichero |
| `Vol --` con audio funcionando | Falta el bloque `Process { id: volProc ... }` | Añadir el bloque completo |
| La rueda del volumen no hace nada | `"-1"` (número uno) en lugar de `"-l"` (letra ele) en `set-volume` | `"-l"` |
| Un icono de la bandeja sale duplicado | Bloque `IconImage` repetido al pegar | Dejar uno solo |
| Un botón sale como un cuadro vacío | Código de icono mal escrito (`"\uf4b"` por `"\uf04b"`) | Cuatro cifras tras `\u` |
| Un icono sale como un **rombo** | El código no existe en la fuente (`\uf167` para YouTube) | Probarlo antes con `printf` en kitty y usar otro (`\uf16a`) |
| `impicitWidth` no existe | Falta una `l` | `implicitWidth` |
| Al pulsar en **cualquier sitio** de la barra se abre el calendario | El `MouseArea` del reloj quedó **fuera** del `Text` (con `anchors.fill: parent` cubre toda la barra) | Colocarlo **dentro** del `Text` |
| Se perdió el `onClicked` del reloj | Se pegó la línea `onCloseRequested` **dentro** del `MouseArea` en lugar del bloque `Calendar {}` | Restaurar `onClicked` y poner la línea tras `visible: root.calOpen` |
| `Syntax error` en la primera línea tras un bloque recién tecleado | **Sobra una llave `}`** | Contar las llaves de cierre y borrar la sobrante |
| Un chip o panel se ve con el color equivocado | Se cambiaron los dos nombres a la vez | `bgChip` es para la barra y `bgPopup` para los paneles |
| El texto largo se corta con `…` | Falta permitir el salto de línea | `wrapMode: Text.WordWrap` |
| **Los paneles no se cierran al pulsar fuera** | `HyprlandFocusGrab` **no funciona** en este Hyprland | Ventana «recogedora» transparente, ver [9.19](#919-cerrar-los-paneles-al-pulsar-fuera) |
| La letra deja un hueco enorme arriba o abajo | `highlightRangeMode: ListView.StrictlyEnforceRange` obliga a centrar siempre la línea activa | `ListView.ApplyRange` |
| `grep` con `\|` no encuentra nada | `grep` básico no entiende `\|` sin escapar | `grep -E "a\|b"` (con `-E`) y todo en **una** línea |
| El dock no aparece al pasar el ratón | Está por debajo de otra ventana de capa (la columna de letra) | `WlrLayershell.layer: WlrLayer.Overlay` en `Dock.qml` |
| El dock no existe en absoluto | No hay ventanas ni apps en la bandeja (`visible` es falso) | Abrir una ventana; es lo esperado |
| Un icono del dock sale como una **letra** | No se encuentra el icono de esa app (`iconPath` vacío) | Es el comportamiento previsto; el nombre del `.desktop` debe coincidir con el `appId` (`hyprctl clients` lo muestra como `class`) |
| Cuesta «cazar» el borde del dock | La franja de reposo (6 px) es muy fina | Subir `railClosed` a 10 en `Dock.qml` |

Y en los scripts de shell y en la terminal:

| Síntoma | Causa | Corrección |
|---|---|---|
| `argument 'TYPE,' not understood` | Espacio tras la coma en `-f DEVICE, TYPE,STATE` | `-f DEVICE,TYPE,STATE` (sin espacios) |
| `[: missing ']'` | Falta el espacio antes del corchete final | `[ -z "$dev" ]` |
| `["$id" ...` no se reconoce | Falta el espacio tras `[` | `[ "$id" = "$want" ]` |
| `Device 'dev' not found` | Falta el `$` | `"$dev"` |
| El chip dice "Sin red" con conexión | El script no es ejecutable | `chmod +x` |
| El botón **Cerrar** de la bandeja no cierra la app | `trayquit.sh` sin permiso de ejecución | `chmod +x $HOME/.config/quickshell/scripts/trayquit.sh` |
| `trayquit.sh` no lista nada o falla | Orden partida en varias líneas o nombres mal escritos | Revisar con `sh -n script`; cada orden en **una** línea |
| `'@DEFAULT_AUDIO_SNIK@' is not a valid number` | `SNIK` por `SINK` | `@DEFAULT_AUDIO_SINK@` |
| `'10%' is not a valid mute option` | `set-mute` con un porcentaje | `set-volume` para el volumen; `set-mute` solo admite `1`, `0` o `toggle` |
| `no such option: nonmatch` (al abrir zsh) | Esa opción no existe | `unsetopt nomatch` (ver [12](#s12)) |
| Hyprland no arranca solo tras el login | `-z "WAYLAND_DISPLAY"` sin `$` en `~/.zprofile` | `-z "$WAYLAND_DISPLAY"` ([4.1](#41-arranque-automático-de-hyprland)) |
| `unrecognized argument: --online` (git) | `--online` por `--oneline` | `git log --oneline` |
| `cp: missing destination file operand` | Falta la segunda ruta (el destino) | `cp origen destino` |
| `cp: -r not specified; omitting directory` | Se copia una **carpeta** sin `-r` | `cp -r carpeta destino/` |
| `playerctl` dice `No players found` con música sonando | El reproductor no se anuncia por MPRIS | Probar con otro (Brave con un vídeo) |
| `Unknown flag: --debug-config` (kitty) | Esa opción ya no existe en kitty 0.49 | `Ctrl + Shift + F6` dentro de kitty |
| `zsh: command not found: man` | `man` no viene instalado | `sudo pacman -S --needed man-db` |
| Discord se queda en «Starting...» con la ventana negra | Procesos a medias de pruebas anteriores | Cerrar todo (`hyprctl clients` da el `pid`; `kill`) y reiniciar |
| La hora de la barra va una hora atrasada | Zona horaria del sistema en UTC | `sudo timedatectl set-timezone Europe/Madrid` ([1.3](#13-zona-horaria-y-hora)) |
| Discord o Brave se recortan | Escala del monitor demasiado alta (1,67 en la VM) | `scale = "1.25"` ([apartado 8](#otros-ajustes-de-hyprlandlua-monitor-escala-y-frecuencia)) |
| `notify-send` da error | Falta `libnotify` o no hay servidor de avisos en marcha | `sudo pacman -S --needed libnotify` y comprobar que Quickshell está en marcha |

> 💡 Para ficheros largos, lo más seguro es reemplazarlos enteros ([apartado 6](#s6)) en lugar de retocar llaves a mano.

### 9.6 Chip de red en la barra

A la derecha de la barra se muestra el estado de la red, por ejemplo **`Cable · 10.0.2.15`** (o `Wi-Fi · ...`, o `Sin red`). Los datos los obtiene un script que consulta **NetworkManager** ([apartado 1.1](#11-red-networkmanager)) y que `Bar.qml` ejecuta cada 5 segundos.

`~/.config/quickshell/scripts/net.sh`:

```sh
#!/bin/sh
# Imprime: tipo|dispositivo|ip   (o "none" si no hay conexión)
dev=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$3=="connected" && ($2=="ethernet" || $2=="wifi") {print $1; exit}')
if [ -z "$dev" ]; then
    echo "none"
    exit 0
fi
tipo=$(nmcli -g GENERAL.TYPE device show "$dev")
ip=$(nmcli -g IP4.ADDRESS device show "$dev" | cut -d'|' -f1)
echo "$tipo|$dev|$ip"
```

Pruébalo a mano; debe imprimir algo como `ethernet|enp0s3|10.0.2.15/24`:

```bash
sh $HOME/.config/quickshell/scripts/net.sh
```

> ⚠️ **El script debe ser ejecutable**, porque Quickshell lo lanza directamente. Un fichero creado con nano no lo es, y el chip mostraría **"Sin red"** aunque haya conexión:
> ```bash
> chmod +x $HOME/.config/quickshell/scripts/net.sh
> ls -la $HOME/.config/quickshell/scripts/    # debe verse -rwxr-xr-x
> ```
> Git conserva este permiso al subir y clonar el repositorio (se comprueba con `git ls-files -s`: debe salir `100755`).

> 💡 El script no usa ningún nombre de interfaz: elige la primera conexión activa de tipo `ethernet` o `wifi`, así que sirve igual en la VM, en una torre y en un portátil.

> 💡 Para probar que reacciona: `sudo nmcli device disconnect enp0s3` (en unos 5 s pasa a "Sin red") y `sudo nmcli device connect enp0s3` para volver.

En `Bar.qml`, la pieza se compone de tres partes: un `Process` que ejecuta el script, un `Timer` que lo repite y el texto del chip:

```qml
Process {
    id: netProc
    command: ["sh", "-c", "$HOME/.config/quickshell/scripts/net.sh"]
    running: true
    stdout: StdioCollector {
        onStreamFinished: {
            var p = this.text.trim().split("|")
            // ... actualiza netType, netDev y netIp
        }
    }
}

Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: netProc.running = true
}
```

### 9.7 Panel de red: el medallón

Al **pulsar el chip de red** se abre un panel con un **medallón de latón** en el centro, con el nombre de la conexión, su estado y un **anillo de 24 marcas** que se ilumina según la señal. Alrededor, **cinco fichas de cuero** unidas al medallón por hilos finos de latón, con los detalles. Un segundo clic en el chip, o pulsar fuera, lo cierra.

Abajo hay un selector **Cable | Wi-Fi | Bluetooth** y, a la derecha, un botón redondo de latón.

| Pestaña | Qué muestra | Datos |
|---|---|---|
| **Cable** | Medallón con el nombre de la conexión, «Conectada» y el anillo completo. Fichas: dispositivo, IP, velocidad, puerta de enlace y DNS | **Reales** (los entrega `netinfo.sh`) |
| **Wi-Fi** | Una red de ejemplo (Casa_5G): banda, IP, seguridad e intensidad de señal | **De ejemplo**, marcados como tales |
| **Bluetooth** | Un dispositivo de ejemplo (JBL Tune 720BT): códec, tipo, batería e intensidad | **De ejemplo**, marcados como tales |

Las fichas de la pestaña Cable:

| Ficha | Etiqueta | Dato |
|---|---|---|
| `ETH` | Dispositivo | `dispositivo` (por ejemplo, `enp0s3`) |
| `IP` | Dirección IP | `ip`, sin la máscara |
| `Mb/s` | Velocidad | `velocidad` |
| `GW` | Puerta de enlace | `puerta` |
| `DNS` | Servidores DNS | `dns` (si hay varios, **cada uno baja a su línea** y la ficha crece) |

> ⚠️ **Hoy es solo la mitad real.** La pestaña Cable muestra datos de verdad. **Wi-Fi y Bluetooth son de ejemplo**, porque la VM no tiene ese hardware. El botón de latón solo cambia el aspecto del panel (todavía no apaga nada), y las fichas «Escanear redes» y «Escanear dispositivos» están inertes. Todo ello se conectará a `nmcli` y `bluetoothctl` en hardware real ([apartado 14](#s14)).

Los datos reales los entrega un segundo script, `netinfo.sh`, en formato `clave=valor`. `~/.config/quickshell/scripts/netinfo.sh`:

```sh
#!/bin/sh
# Imprime clave=valor con el detalle de la conexión activa (ethernet o wifi)
dev=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$3=="connected" && ($2=="ethernet" || $2=="wifi") {print $1; exit}')
if [ -z "$dev" ]; then
    echo "estado=none"
    exit 0
fi
speed=$(cat "/sys/class/net/$dev/speed" 2>/dev/null)
case "$speed" in
    ''|-*) speed="-" ;;
    *) speed="$speed Mb/s" ;;
esac
echo "estado=ok"
echo "dispositivo=$dev"
echo "tipo=$(nmcli -g GENERAL.TYPE device show "$dev")"
echo "conexion=$(nmcli -g GENERAL.CONNECTION device show "$dev")"
echo "ip=$(nmcli -g IP4.ADDRESS device show "$dev" | cut -d'|' -f1)"
echo "puerta=$(nmcli -g IP4.GATEWAY device show "$dev")"
echo "dns=$(nmcli -g IP4.DNS device show "$dev" | tr '|' ' ')"
echo "mac=$(nmcli -g GENERAL.HWADDR device show "$dev" | tr -d '\\')"
echo "velocidad=$speed"
```

Dale permiso de ejecución y pruébalo; debe imprimir nueve líneas, empezando por `estado=ok`, **sin ningún mensaje de error**:

```bash
chmod +x $HOME/.config/quickshell/scripts/netinfo.sh
$HOME/.config/quickshell/scripts/netinfo.sh
```

El panel se compone de dos partes: en `Bar.qml`, lo que recoge los datos y coloca el panel; y en `NetPanel.qml`, todo el dibujo.

| Pieza | Dónde | Función |
|---|---|---|
| `Process` (`infoProc`) | `Bar.qml` | Ejecuta `netinfo.sh` y convierte cada línea `clave=valor` en una propiedad de `root.info` |
| `Timer` (3 s) | `Bar.qml` | Refresca los datos **solo mientras el panel está abierto** |
| `MouseArea` en el chip | `Bar.qml` | `root.toggle("netOpen")` |
| `NetPanel { ... }` | `Bar.qml` | Coloca el panel bajo la barra y le pasa `info: root.info` |
| `NetPanel.qml` | Fichero propio | Medallón, fichas, hilos, selector y botón |

Cómo está construido `NetPanel.qml`:

| Elemento | Cómo se dibuja |
|---|---|
| Tamaño | 520 × 450 px; el medallón en el centro (`cx` 260, `cy` 205) |
| Anillos de fondo | Tres círculos con borde fino y poca opacidad |
| Hilos | Un rectángulo estrecho por cada ficha, **rotado** desde el centro (`rotation` con `Math.atan2`, `transformOrigin: Item.Left`) y un punto dorado en el extremo |
| Anillo de marcas | 24 pequeños rectángulos, cada uno dentro de un `Item` **rotado** `índice × 15°`; se iluminan los primeros `intensidad ÷ 100 × 24` |
| Fichas | Un `Repeater` sobre `cards`, que calcula la función `cardsFor()` según la pestaña |
| Texto largo | `wrapMode: Text.WordWrap` y `height: Math.max(46, columna.implicitHeight + 14)`: la ficha crece en lugar de cortar con `…` |
| Selector | Tres botones con forma de píldora; el activo va en dorado |

> 💡 Los iconos del medallón son de Nerd Font: `\uf0e8` (red de nodos, para el cable), `\uf1eb` (Wi-Fi), `\uf293` (Bluetooth) y `\uf011` (el botón de encendido). Las insignias de las fichas son **texto corto** (`ETH`, `IP`, `GW`, `DNS`) en lugar de iconos, para no depender de la fuente.

> 💡 El panel no usa nombres de interfaz: sirve igual para cable y Wi-Fi. Con Wi-Fi, la velocidad aparecerá como `-` hasta que se añadan campos propios del Wi-Fi.

### 9.8 Chip de volumen y panel de sonido

A la izquierda del chip de red se muestra el volumen, por ejemplo **`Vol 40%`**. Requiere PipeWire ([apartado 1.2](#12-audio-pipewire)).

| Acción | Efecto |
|---|---|
| **Clic** en el chip | Abre el **panel de sonido** |
| **Rueda** hacia arriba o abajo | Sube o baja de 5 en 5 %, con tope en el 100 % |
| Sin dispositivo de sonido | `Vol --` (en gris) |

Se apoya en `wpctl`. Las órdenes se pueden probar a mano:

```bash
wpctl get-volume @DEFAULT_AUDIO_SINK@               # Volume: 0.40  (o  Volume: 0.40 [MUTED])
wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+    # sube un 5 % (tope 100 %)
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle          # alterna el silencio
```

En `Bar.qml`, el chip se compone de un `Process` (`volProc`) que ejecuta `wpctl get-volume` y guarda `volPercent` y `volMuted`, un `Timer` de 2 s que lo repite (para reflejar cambios hechos con las teclas multimedia) y un `MouseArea` con la rueda.

```qml
Process {
    id: volProc
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: true
    stdout: StdioCollector {
        onStreamFinished: {
            var t = this.text.trim()
            if (t.indexOf("Volume:") !== 0) {
                root.volPercent = -1
                root.volMuted = false
            } else {
                root.volPercent = Math.round(parseFloat(t.split(" ")[1]) * 100)
                root.volMuted = t.indexOf("MUTED") >= 0
            }
        }
    }
}
```

#### Panel de sonido (`SoundPanel.qml`)

Ventana de 380 px bajo el chip, con dos secciones:

| Sección | Qué hace | Cómo |
|---|---|---|
| **Salida** | Deslizador de volumen (`ThinSlider`), botón de silencio y lista de dispositivos de salida; pulsar uno lo hace el predeterminado | `wpctl get-volume/set-volume/set-mute @DEFAULT_AUDIO_SINK@`, `pactl --format=json list sinks`, `pactl get-default-sink`, `pactl set-default-sink` |
| **Entrada** | El mismo deslizador y silencio para el micrófono | `wpctl ... @DEFAULT_AUDIO_SOURCE@` |

Los deslizadores usan dos `Timer` (uno de «retención» mientras se arrastra, para que la lectura periódica no mueva el pomo, y otro que aplica el valor), y el panel emite las señales `closeRequested` y `changed`.

> ⚠️ En `set-volume`, la opción es **`-l`** (letra *ele*, de *limit*), no el número `-1`.

> ⚠️ **Limitaciones de VirtualBox:** el dispositivo de audio virtual impone un volumen mínimo (≈ 45 %) y **no aplica el silencio**; puede que no haya micrófono. El panel muestra fielmente lo que informa `wpctl`; en hardware real el rango es completo.

> 💡 `set-volume` y `set-mute` son órdenes distintas: la primera recibe un porcentaje y la segunda solo `1`, `0` o `toggle`.

### 9.9 Fondo de pantalla

El fondo lo dibuja Quickshell, sin instalar nada más: una ventana que ocupa toda la pantalla en la capa `Background`, por detrás de todo. La imagen viaja con el repositorio, dentro de `~/.config/quickshell/`.

**1. Conseguir la imagen** con el nombre `wallpaper.jpg` en la carpeta de Quickshell:

```bash
mv $HOME/Downloads/IMAGEN.jpg $HOME/.config/quickshell/wallpaper.jpg
file $HOME/.config/quickshell/wallpaper.jpg      # debe decir "JPEG image data"
```

> 💡 `mv` mueve **y** renombra. Usa el tabulador para no teclear el nombre largo. Con **1920 × 1080** y poco peso basta (la imagen se guarda en el historial de git).

> 💡 Si el diálogo "Guardar como" del navegador no deja guardar, copia la dirección de la imagen con clic derecho → *Copy image address* y descárgala desde la terminal (la dirección **de la imagen**, que acaba en `.jpg`):
> ```bash
> curl -L -A "Mozilla/5.0" -o $HOME/.config/quickshell/wallpaper.jpg "DIRECCION_DE_LA_IMAGEN"
> ```
> Si `file` dice `HTML document`, la web ha rechazado la descarga directa.

**2. `Wallpaper.qml`:**

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "wallpaper"
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "#1e1e2e"

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("wallpaper.jpg")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
}
```

**3.** Añadir `Wallpaper {}` a `shell.qml` ([9.2](#92-ficheros-de-configuración)).

| Línea | Función |
|---|---|
| `WlrLayershell.layer: WlrLayer.Background` | Coloca la ventana **por detrás** de todo |
| `exclusionMode: ExclusionMode.Ignore` | No reserva espacio: las demás ventanas no se apartan |
| `Qt.resolvedUrl("wallpaper.jpg")` | Busca la imagen **junto al propio `.qml`**, sin rutas fijas |
| `fillMode: PreserveAspectCrop` | Rellena sin deformar, recortando lo que sobre |

> 💡 Si la pantalla es de otra proporción que la imagen, se recortan los lados y puede parecer descentrada. Para ver la resolución real: `hyprctl monitors`, y las capas con `hyprctl layers`.

> 💡 El fondo actual tiene tonos azulados y verdosos que chocan con la paleta cálida del tema. Está pendiente elegir uno de tonos marrones o tintarlo hacia sepia ([apartado 14](#s14)).

> ⚠️ Cuidado con las mayúsculas: `Quickshell`, no `Quicksell`; `WlrLayershell`, no `Wlrlayershell`.

### 9.10 Barra transparente «solo texto»

La ventana de la barra es **transparente** (`color: "transparent"`) y no hay cajas: los elementos son texto sobre un degradado muy suave, con una línea fina de latón debajo. Los paneles que se despliegan sí tienen fondo (`Theme.bgPopup`, casi opaco) con borde fino (`Theme.line`) y esquinas redondeadas (`Theme.radius`).

> ⚠️ **Limitación conocida (barra superior):** la ventana transparente sigue ocupando su franja entera: **reserva espacio** (las ventanas no llegan al borde) y puede bloquear clics sobre lo que haya debajo. Se resolverá con una máscara de entrada (pendiente, [apartado 14](#s14)).

> 💡 El dock y la columna de la letra ya usan la técnica: `mask: Region { item: ... }` limita la zona que recibe clics a la caja visible, y el resto deja pasar los clics.

### 9.11 Chip de música en la barra

En la barra, junto a los workspaces, aparece lo que suena, por ejemplo **`Andrea Bocelli - Con Te Partirò / Time To Say Goodbye`**, con tres botones (anterior, pausa/reproducir, siguiente). Funciona con **cualquier reproductor** que se anuncie por **MPRIS**: Spotify, VLC, mpv o el propio navegador (Brave anuncia los vídeos de YouTube).

| Elemento | Efecto |
|---|---|
| Primer botón | Canción anterior |
| Segundo botón | Pausa o reproducir (el icono cambia según el estado) |
| Tercer botón | Canción siguiente |
| Texto | «Canción - Artista», recortado a 180 px con `…`. **Al pulsarlo se abre el panel del reproductor** ([9.14](#914-panel-del-reproductor)) |
| Sin reproductor | El chip no se muestra (hoy; ver [apartado 14](#s14)) |

**Qué reproductor elige:** `Spotify` si está abierto; si no, el que esté sonando; si no, el primero de la lista (`pickPlayer()`).

**Cómo se recorta el texto** (`shortText()`): se quita lo que va entre paréntesis (`(Live From ...)`), y solo se añade el artista si el título aún no lleva un guion.

**Comprobar que el reproductor se anuncia**, con `playerctl` ([apartado 12](#s12)) y algo sonando:

```bash
playerctl -l                                            # brave.instance46441
playerctl status                                        # Playing
playerctl metadata --format '{{artist}} - {{title}}'
```

El chip es `Player.qml`: sin caja ni borde (coherente con la barra «solo texto»), con la propiedad `opened` que abre y cierra el panel. En `Bar.qml` se coloca con `id: playerChip` y se le pasa al panel su reproductor (`player: playerChip.player`).

| Pieza | Función |
|---|---|
| `Mpris.players` | La lista de reproductores que se anuncian (módulo `Quickshell.Services.Mpris`) |
| `pickPlayer()` | Elige el reproductor, con preferencia por Spotify |
| `shortText()` | Compone el texto corto |
| `opened` | Interruptor que abre y cierra el panel del reproductor |
| `"\uf048"`, `"\uf04b"`, `"\uf04c"`, `"\uf051"` | Iconos de anterior, reproducir, pausa y siguiente (Nerd Font) |

> ⚠️ **Spotify de escritorio en la VM:** el cliente (instalado con `sudo pacman -S spotify-launcher`) arranca, pero **no dibuja ventana ni se anuncia por MPRIS**, ni con `LIBGL_ALWAYS_SOFTWARE=1` ni con `--disable-gpu`; es una limitación de la máquina virtual sin GPU. El chip se prueba con **Brave** (un vídeo de YouTube) y debería reconocer a Spotify en hardware real.

> 💡 **Spotify web** (`open.spotify.com` en Brave) también se anuncia por MPRIS, pero necesita **Widevine** activado en `brave://settings/extensions`.

> 💡 **La cola de canciones no se puede mostrar** con MPRIS: ni Spotify ni YouTube en Brave exponen la lista de pistas siguientes ([apartado 14](#s14)).

### 9.12 Calendario y agenda

Al **pulsar el reloj** (fecha y hora, esta última en negrita) se despliega, centrado bajo la barra, un calendario de 620 px con dos mitades:

| Mitad | Qué muestra |
|---|---|
| **Izquierda: el mes** | Cuadrícula con los días en **círculos perfectos** de 28 px; el día de hoy lleva un aro, el elegido va relleno en dorado translúcido (`#33e2b564`) y los días con tareas llevan un punto de color por etiqueta. Flechas para cambiar de mes y de año, y «Volver a hoy» |
| **Derecha: el día** | Las tareas del día elegido: casilla, texto, punto de etiqueta y una X para borrarla. Abajo, «+ Añadir una tarea…» con selector de etiqueta y campo de texto |

Las tareas se guardan en `~/.local/share/pikson/agenda.json` mediante `FileView` (`Quickshell.Io`); un `Process` con `mkdir -p` crea antes la carpeta. Las etiquetas son Pendiente, Lectura y Música.

> ⚠️ **Los datos personales no se versionan.** La agenda vive en `~/.local/share/pikson/`, **fuera** del repositorio, y por eso no viaja con `git push`. Si algún día se quiere una agenda de muestra, se subiría un `agenda.example.json`.

Se engancha al reloj con tres piezas en `Bar.qml`:

```qml
// 1. la propiedad (junto a las demás xxxOpen)
property bool calOpen: false

// 2. dentro del Text del reloj, el clic
MouseArea {
    anchors.fill: parent
    onClicked: root.toggle("calOpen")
}

// 3. fuera del Text, el calendario, centrado bajo la barra
Calendar {
    anchor.window: root
    anchor.rect.x: (root.width - implicitWidth) / 2
    anchor.rect.y: root.height + 4
    visible: root.calOpen
    onCloseRequested: root.calOpen = false
}
```

> ⚠️ **El `MouseArea` va dentro del `Text` del reloj.** Si queda fuera, su `anchors.fill: parent` cubre **toda la barra**: cualquier clic abre el calendario y el resto de chips dejan de responder.

> 💡 La hora de la barra sale del reloj del sistema: si va atrasada, ver [1.3](#13-zona-horaria-y-hora).

> 💡 **Colores con transparencia:** el día elegido usa `#33e2b564`. En QML el alfa va **delante**; `#e2b56433` sería rosa.

> 💡 Escribir texto en la agenda exige que la ventana **reciba el teclado**, y los paneles desplegables no siempre lo reciben en Hyprland. Hay que comprobar que se puede teclear una tarea; si no, la agenda deberá pasar a ser una ventana de capa con `WlrLayershell.keyboardFocus` ([apartado 14](#s14)).

### 9.13 Tema: `Theme.qml`

Toda la apariencia de Quickshell (colores, tamaños y fuentes) vive en **un solo fichero**, `~/.config/quickshell/Theme.qml`, que el resto de piezas consultan con el prefijo `Theme.` (`Theme.fg`, `Theme.bgChip`...). Es un *singleton*: QML lo carga una sola vez y no hace falta ningún `import` ni `qmldir`, porque está en la misma carpeta. Para cambiar el aspecto del escritorio, se edita este fichero y Quickshell recarga solo.

La paleta se llama **Pergamino nocturno**: marrones cálidos de fondo y letra color vainilla, como una biblioteca antigua de noche.

**Tipografía única:** todo el escritorio usa **JetBrains Mono Nerd Font** (texto, iconos y la antigua «serif»). Se decidió así para unificar el aspecto; `fontSerif` se mantiene como nombre pero apunta a la misma fuente.

```bash
sudo pacman -S --needed ttf-jetbrains-mono-nerd
fc-cache -f
fc-list | grep -i jetbrains
```

`~/.config/quickshell/Theme.qml` (resumen de sus valores):

```qml
pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // Pergamino nocturno: marrones cálidos y letra vainilla
    readonly property color bgChip: "#f04a382a"
    readonly property color bgPopup: "#fa4a382a"
    readonly property color bgCell: "#808c6c4e"
    readonly property color line: "#8c6d4f"
    readonly property color fg: "#f6ebcf"
    readonly property color fgMuted: "#d0b992"
    readonly property color accent: "#e2b564"
    readonly property color accent2: "#cf7b55"
    readonly property color ok: "#adc783"
    readonly property color fgOnAccent: "#2d1e12"

    readonly property int radius: 14
    readonly property int radiusSmall: 8

    readonly property string fontSerif: "JetBrainsMono Nerd Font"
    readonly property string fontUi: "JetBrainsMono Nerd Font"
    readonly property string fontIcons: "JetBrainsMono Nerd Font"
}
```

| Propiedad | Para qué se usa |
|---|---|
| `bgChip` | Fondo de los chips (casi opaco) |
| `bgPopup` | Fondo de los paneles desplegables |
| `bgCell` | Fondo de las casillas pequeñas |
| `line` | Bordes finos y filetes |
| `fg` | Texto principal (vainilla) |
| `fgMuted` | Texto secundario y etiquetas |
| `accent` | El color de énfasis (dorado): workspace activo, deslizadores, línea activa de la letra, raya de la ventana activa del dock |
| `accent2` | Segundo énfasis (terracota): «Cerrar» en la bandeja |
| `ok` | Estado correcto (verde apagado) |
| `fgOnAccent` | Texto que va **sobre** `accent` |
| `radius`, `radiusSmall` | Esquinas de paneles y de las casillas pequeñas |
| `fontSerif`, `fontUi`, `fontIcons` | Tipografías (hoy la misma) |

Uso en cualquier pieza:

```qml
Rectangle {
    color: Theme.bgPopup
    radius: Theme.radius
    border.color: Theme.line
    border.width: 1

    Text { color: Theme.fg; text: "Hola" }
}
```

> ⚠️ **Ninguna propiedad puede llamarse `on` + mayúscula** (`onAccent`, `onClick`...): QML la toma por un manejador de señal y falla con `Cannot assign a value to a signal`. Por eso el color del texto sobre el dorado se llama `fgOnAccent`.

> 💡 **Formato de color:** en QML es `#AARRGGBB` (el alfa va **delante**: `#f04a382a` es casi opaco). En Hyprland es `rgba(RRGGBBAA)` (el alfa va **detrás**).

> 💡 **Cambiar los colores = editar este fichero.** Pero el terminal ([5.2](#52-configuración-propia-kittyconf)) y los bordes de las ventanas ([apartado 8](#otros-ajustes-de-hyprlandlua-bordes-y-separación)) tienen sus propias copias de la paleta y hay que cambiarlos aparte.

> 💡 Algunos paneles (medallón de red, carátula del reproductor) y el dock usan además **colores propios** escritos en sus ficheros. Pasarlos al tema está pendiente ([apartado 14](#s14)).

### 9.14 Panel del reproductor

Al **pulsar el texto de la canción** se despliega, bajo el chip, un panel sobrio de 340 px. Un segundo clic, o pulsar fuera, lo cierra.

| Elemento | Qué hace |
|---|---|
| **Carátula** | 68 px con borde dorado; si no hay carátula, un disco dorado |
| **Título, artista y origen** | Título y artista de la canción y el nombre del reproductor (`identity`) |
| **Barra de progreso** | `ThinSlider` con los tiempos; se **arrastra** y al soltar salta a ese punto si `canSeek` es verdadero |
| **Controles** | Anterior, reproducir/pausa (en un círculo dorado), siguiente y **bucle** |
| **Bucle** | Tres estados: apagado, repetir canción, repetir lista |
| **Letra** | Cabecera «Letra» con un botón `↗` (`\uf08e`) que la saca a la columna lateral ([9.15](#915-letra-sincronizada)) y una lista de 120 px con la línea actual resaltada |

El panel es `PlayerPanel.qml` y recibe el reproductor (`player`) y el objeto de letra (`lyr`) desde `Bar.qml`; emite `floatToggled()` al pulsar el botón de la letra.

| Pieza | Función |
|---|---|
| `Timer` (500 ms) | Llama a `player.positionChanged()` mientras suena y el panel está abierto: **la posición no se actualiza sola** |
| `hold` / `applySeek` | Dos temporizadores que evitan que la lectura periódica mueva el pomo mientras se arrastra |
| `nextLoop()` | Recorre `MprisLoopState.None → Track → Playlist → None` |

> ⚠️ **El bucle se ve atenuado con Brave:** el navegador no ofrece el control de repetición por MPRIS (`loopSupported` es falso). Con **Spotify real**, en hardware físico, sí funcionará.

> ⚠️ **El icono de YouTube es `\uf16a`, no `\uf167`.** Antes de usar un icono nuevo, se prueba en kitty: `printf '\uf16a  \uf1bc  \uf001\n'`.

> 💡 La barra de progreso solo aparece si el reproductor informa de su duración (`lengthSupported`).

### 9.15 Letra sincronizada

Mientras suena una canción, el panel muestra su letra **sincronizada**: la línea que se canta va resaltada y la lista se desplaza sola.

| Pieza | Función |
|---|---|
| `Lyrics.qml` | Lógica compartida (un `Scope`): busca la letra, la interpreta y calcula la línea actual |
| `PlayerPanel.qml` | Muestra la letra dentro del panel (120 px) |
| `LyricsFloat.qml` | La muestra en una **columna fija a la derecha de toda la pantalla** |

**Cómo se obtiene:** de [LRCLIB](https://lrclib.net), un servicio libre de letras. Se pide primero `/api/search?track_name=...&artist_name=...` y, si no hay resultado, `/api/search?q=...`; entre los resultados se elige el de **duración más cercana** a la canción. El texto sincronizado viene en formato LRC (`[mm:ss.xx] línea`), que `parseLrc()` convierte en una lista. Las peticiones se hacen con `curl`.

> 🔒 **Privacidad:** a LRCLIB solo se envían el **título y el artista** de la canción. No se envía nada más.

`Lyrics.qml` limpia antes el título y el artista (`cleanTitle`, `cleanArtist`), guarda lo ya buscado en una caché, y tiene un estado (`idle`, `loading`, `ok`, `none`). La línea actual se localiza con una **búsqueda binaria** sobre el tiempo (con 0,3 s de adelanto), y un `Timer` de 250 ms llama a `player.positionChanged()` mientras la letra está activa y el reproductor suena.

#### La columna fija (`LyricsFloat.qml`)

Pulsando `↗` junto a «Letra», la letra pasa a una columna **estática en el lado derecho**, que ocupa toda la altura y empuja las ventanas hacia la izquierda; `↙` la devuelve al panel.

| Ajuste | Valor |
|---|---|
| Ventana | anclada arriba, derecha y abajo; `implicitWidth: 328` |
| Reserva de espacio | `exclusionMode: ExclusionMode.Normal` y `exclusiveZone: 316`: así queda un hueco de 20 px con las ventanas (`316 + gaps_out 20 − 328 = 8`, ajustado al ojo) |
| Tarjeta | 320 px de ancho, 20 px de margen arriba y abajo, para quedar a la par con las ventanas |
| Zona sensible | `mask: Region { item: card }`: el resto no recibe clics |
| Capa | `namespace: "lyrics-side"` |

```qml
ListView {
    highlightRangeMode: ListView.ApplyRange
    preferredHighlightBegin: height / 2 - 12
    preferredHighlightEnd: height / 2 + 12
    highlightMoveDuration: 250
}
```

> 💡 **`ApplyRange`, no `StrictlyEnforceRange`:** con el segundo, la línea activa se fuerza siempre al centro y la lista deja un hueco enorme al empezar y al terminar la canción. Con `ApplyRange` la lista arranca estática desde la primera línea.

> 💡 Si la canción no tiene letra, se muestra «Sin letra» y la lista queda quieta.

> 💡 **Convive con el dock:** el dock ([9.4](#94-dock-lateral-ventanas-y-bandeja)) está en la capa `Overlay` y no reserva espacio, así que, al desplegarse, **se superpone a la columna de letra** sin moverla.

### 9.16 Avisos y campana

Quickshell hace de **servidor de notificaciones** (`NotificationServer` del módulo `Quickshell.Services.Notifications`): cualquier programa que avise con `notify-send` o por D-Bus aparece aquí, sin instalar un demonio aparte.

| Pieza | Función |
|---|---|
| `NotifToasts.qml` | **Avisos emergentes**: tarjetas de 340 px arriba a la derecha (capa `Overlay`); desaparecen a los **6 s** (12 s los críticos) |
| `NotifPanel.qml` | **Historial** de 400 px bajo la campana, con interruptor de «No molestar», botón «Limpiar» y una X por aviso; cada aviso lleva su hora relativa |
| Campana | En la barra: con un punto rojo y el **número de avisos sin leer**; no molestar la apaga |

En `Bar.qml` viven la lista `notifList`, la de emergentes `toastList`, el contador `unread` y el interruptor `dnd`, junto a las funciones `addNotif`, `removeNotif`, `dismissNotif`, `clearNotifs` y `hideToast`. Cada aviso entrante se marca con `n.tracked = true` para que Quickshell lo conserve.

Para probarlo:

```bash
notify-send "Hola" "Esto es una prueba"
notify-send -u critical "Aviso importante" "Debe durar más"
```

> ⚠️ Si `notify-send` da error, falta `libnotify` ([9.1](#91-instalación)); si el aviso no llega, comprueba que Quickshell está en marcha y que no hay **otro servidor de notificaciones** (dunst, mako...) ocupando el bus.

### 9.17 El tiempo

En la barra aparece la temperatura actual con un icono, por ejemplo **`  18°`**. Al pulsarla se abre un panel con el tiempo de Barcelona.

| Elemento | Detalle |
|---|---|
| Datos | **Open-Meteo** (gratuito y sin clave), pedidos con `curl` cada **20 minutos** |
| Ubicación | Barcelona (`41.3851`, `2.1734`), zona horaria `Europe/Madrid` |
| Panel | Temperatura actual y sensación térmica, hora del amanecer y del atardecer, una **franja de 6 horas** y **5 días** con barras de degradado entre la mínima y la máxima |
| Iconos | Glifos de Nerd Font según el código meteorológico: `\ue30d`, `\ue32b`, `\ue302`, `\ue312`, `\ue313`, `\ue318`, `\ue31a`, `\ue31d` (verificados con `printf`) |

`Weather.qml` es un `Scope` con la latitud y la longitud, la descarga, el análisis del JSON, `describe()` (código → texto) y `glyph()` (código → icono), y alimenta a `WeatherPanel.qml`.

> 🔒 **Privacidad:** a Open-Meteo solo se envían las **coordenadas de Barcelona**, fijas en el fichero. Nada personal sale del equipo.

> 💡 Para cambiar de ciudad, se editan `lat` y `lon` (y la zona horaria) en `Weather.qml`.

> 💡 Si el panel sale vacío, se prueba la petición a mano con `curl` y se mira su respuesta.

### 9.18 Menú de apagado

Un botón a la derecha del todo abre un menú de cinco acciones (`PowerMenu.qml`):

| Acción | Orden |
|---|---|
| **Bloquear** | `hyprlock` o, si no existe, `loginctl lock-session` |
| **Suspender** | `systemctl suspend` |
| **Cerrar sesión** | `hyprctl dispatch exit` o `loginctl terminate-user $USER` |
| **Reiniciar** | `systemctl reboot` |
| **Apagar** | `systemctl poweroff` |

Las tres últimas (cerrar sesión, reiniciar y apagar) piden **confirmación con un segundo clic** en 3 segundos: el primero pone el botón en «¿Seguro?» y, si no se repite, vuelve al estado normal. Se lanzan con `Quickshell.execDetached`.

> ⚠️ **`hyprlock` no está instalado:** «Bloquear» no hace nada hasta instalarlo (`sudo pacman -S hyprlock` y su configuración; [apartado 14](#s14)).

### 9.19 Cerrar los paneles al pulsar fuera

`HyprlandFocusGrab` (el mecanismo previsto por Quickshell) **no funcionó** en este Hyprland, así que se resolvió con una **ventana «recogedora»**: un `PanelWindow` transparente que cubre la pantalla **por debajo de la barra** (`margins.top` igual al alto de la barra) y está activo solo cuando hay algún panel abierto; cualquier clic sobre ella ejecuta `closeAll()`.

En `Bar.qml`:

| Pieza | Función |
|---|---|
| `calOpen`, `netOpen`, `powerOpen`, `soundOpen`, `notifOpen`, `weatherOpen` | Un interruptor por panel |
| `anyOpen` | `readonly`: verdadero si cualquiera está abierto |
| `closeAll()` | Cierra todos |
| `toggle(name)` | Abre el panel `name` y cierra los demás (**exclusión mutua**), o lo cierra si ya estaba abierto |
| `catcher` | La ventana transparente, con `visible: root.anyOpen` |

Cada chip llama a `root.toggle("netOpen")`, `root.toggle("soundOpen")`, etc. Los paneles que usan teclado, como el calendario, avisan con la señal `closeRequested`.

> 💡 Al pulsar fuera, el clic **se consume** (no llega a la ventana de debajo): es la contrapartida de este método, y la habitual en otros escritorios.

> 💡 Los bloques `HyprlandFocusGrab` que quedan en algunos paneles no hacen nada y están pendientes de retirar ([apartado 14](#s14)).

---

<a id="s10"></a>
## 10. 📦 Programas instalados

Los programas se instalan automáticamente con las listas de paquetes ([apartado 13](#s13)). Se abren desde la terminal o con sus atajos; el dock lateral solo muestra y gestiona los que ya están abiertos. Notas de uso:

| Programa | Cómo abrirlo | Nota |
|---|---|---|
| Kitty | `Super + Enter` | |
| Brave | `Super + B` | No usa la bandeja: aparece en el dock como **ventana abierta** y se cierra con su **X**, con `Super + Retroceso` o con clic derecho en el dock. Lo que reproduce (YouTube, por ejemplo) aparece en el chip de música |
| Discord | `Super + D` | Al cerrar la ventana queda en la bandeja del dock ([9.4](#94-dock-lateral-ventanas-y-bandeja)); **«Cerrar»** lo termina del todo. Necesita ≈ 940 px de ancho |

> 💡 Desde una terminal, para abrir un programa sin dejarla ocupada: `discord & disown`.

---

<a id="s11"></a>
## 11. 🐙 Git y GitHub

Para acceder al repositorio (privado) desde la terminal.

### 11.1 Instalar herramientas

```bash
sudo pacman -S --needed git github-cli less
```

> 💡 `less` es el visor que usa git para mostrar resultados largos (`git branch`, `git log`...). Sin él, esos comandos fallan con `unable to execute pager 'less'`.

### 11.2 Configurar la identidad

```bash
git config --global user.name "Joan005"
git config --global user.email "tu_correo@ejemplo.com"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor nano
```

### 11.3 Iniciar sesión en GitHub

```bash
gh auth login
```

Respuestas: `GitHub.com` → `HTTPS` → `Yes` → `Login with a web browser`.
Copia el código de 8 caracteres que muestra la terminal e introdúcelo en <https://github.com/login/device>.

> ⚠️ Si la terminal se queda esperando tras autorizar, cierra la ventana del navegador que abrió `gh`.

Comprueba la sesión:

```bash
gh auth status
```

> 💡 La sesión del navegador y la de la terminal son independientes: iniciar sesión en la web no inicia sesión en `gh`.

### 11.4 Clonar el repositorio

```bash
cd $HOME
git clone https://github.com/Joan005/PikSOn
cd PikSOn
```

### 11.5 Subir cambios

Los ficheros de configuración que se editan en `~/.config` hay que **copiarlos al repositorio** antes de subirlos. Desde la carpeta del repositorio, con rutas relativas:

```bash
cd $HOME/PikSOn
cp -r $HOME/.config/quickshell .config/
cp -r $HOME/.config/kitty .config/
cp -r $HOME/.config/hypr .config/
```

Para un **fichero suelto** (cada uno con su origen y su destino, y sin `-r`):

```bash
cp $HOME/.config/quickshell/Bar.qml .config/quickshell/Bar.qml
```

Después:

```bash
git status
git add .
git commit -m "descripción del cambio"
git pull --no-rebase --no-edit
git push
```

> 💡 **`-r` (recursivo)** es lo que permite copiar una **carpeta** con todo lo que contiene; sin él, `cp` responde `omitting directory`. Para un fichero suelto no hace falta.

> 💡 `cp -r` sobrescribe los ficheros del mismo nombre, pero **no borra** del repositorio los que hayas eliminado de tu carpeta local. Por eso conviene mirar `git status` antes de subir.

> 💡 Revisa siempre `git status` antes de hacer `git add .`: deben aparecer solo los ficheros que esperas, sin copias `.bak` ni nombres raros.

> 💡 Los scripts nuevos deben conservar su permiso de ejecución: tras `git add .`, `git ls-files -s .config/quickshell/scripts` debe mostrar `100755` en todos.

> ⚠️ **No copies nunca `~/.config` completo** al repositorio: contiene el token de GitHub (`gh`), datos del navegador y sesiones. Copia solo las carpetas que configures a propósito. Elimina antes las copias `.bak` (`rm -f ~/.config/quickshell/*.bak`).

> ⚠️ Los datos personales (`agenda.json`, la futura `libros.json`...) **viven fuera del repositorio**, en `~/.local/share/pikson/`, y no se suben.

### 11.6 Cómo se sincronizan las copias

Hay **dos copias** del repositorio: la **remota** (GitHub) y la **local** (`~/PikSOn`). Git **no las sincroniza solo**:

| Acción | Efecto |
|---|---|
| Editar en la web | Solo cambia la copia remota; la local no se entera hasta hacer `git pull` |
| Editar en local | Solo cambia la copia local; GitHub no se entera hasta hacer `git push` |

Por eso, si has editado algo desde la web (por ejemplo, el README), `git push` es rechazado con `rejected (fetch first)`. La solución es traer lo remoto primero:

```bash
git pull --no-rebase --no-edit
git push
```

> 💡 `git status` solo refleja lo último que git descargó, no el estado actual de GitHub. Para consultar si hay novedades sin mezclar nada: `git fetch` y después `git status`.

> 💡 Un `commit` sin `git add .` previo no incluye los cambios: los ficheros modificados aparecen en rojo en `git status` hasta que se añaden.

> 💡 Si se sube un fichero por error (por ejemplo, `pklist.txt` por teclear mal `pkglist.txt`), se retira con `git rm -f fichero` y un nuevo `commit` y `push`. Git conserva el historial, así que nada se pierde.

> 💡 Ajustes del sistema, como la shell por defecto (`chsh`) o la zona horaria (`timedatectl`), **no** son ficheros del repositorio: git no los guarda. Se documentan en el README y se repiten en cada equipo.

---

<a id="s12"></a>
## 12. 🛠️ Herramientas de apoyo

### tree

Muestra la estructura de carpetas en forma de árbol:

```bash
sudo pacman -S --needed tree
```

| Comando | Efecto |
|---|---|
| `tree -a -I '.git'` | Árbol completo, con ocultos y sin `.git` |
| `tree -L 2` | Limita la profundidad a 2 niveles |

Atajo opcional, en `~/.bashrc` (bash) o `~/.zshrc` (zsh):

```bash
alias t='tree -a -I ".git"'
```

> 💡 Sin `-a`, `tree` no muestra las carpetas ocultas, como `.config`.

### nmcli

Consulta y gestiona la red con NetworkManager:

| Comando | Efecto |
|---|---|
| `nmcli device status` | Dispositivos de red y su estado |
| `nmcli device show <interfaz>` | Detalle: IP, puerta de enlace, DNS, MAC... |

### wpctl y pactl

Consultan y controlan el audio con PipeWire/WirePlumber:

| Comando | Efecto |
|---|---|
| `wpctl status` | Dispositivos de audio, entradas y salidas |
| `wpctl get-volume @DEFAULT_AUDIO_SINK@` | Volumen de la salida predeterminada |
| `wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%` | Fija el volumen |
| `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` | Alterna el silencio |
| `pactl --format=json list sinks` | Las salidas disponibles (lo usa el panel de sonido) |
| `pactl get-default-sink` / `set-default-sink` | Consulta o cambia la salida predeterminada |

> 💡 Los nombres con arrobas (`@DEFAULT_AUDIO_SINK@`) conviene **copiarlos y pegarlos**: `SINK` se teclea mal con facilidad.

### busctl

Consulta el bus de mensajes del sistema (D-Bus). Lo usa `trayquit.sh` ([9.4](#94-dock-lateral-ventanas-y-bandeja)); viene con systemd y no hace falta instalarlo:

| Comando | Efecto |
|---|---|
| `busctl --user list` | Servicios activos en el bus de la sesión |
| `busctl --user list \| grep -i mpris` | Reproductores que se anuncian por MPRIS |
| `busctl --user list \| grep -i notif` | Quién ocupa el servicio de notificaciones |

### playerctl

Consulta y controla los reproductores que se anuncian por MPRIS (Brave, Spotify, VLC...). Sirve para comprobar que un reproductor llegará al chip de música ([9.11](#911-chip-de-música-en-la-barra)):

```bash
sudo pacman -S --needed playerctl
```

| Comando | Efecto |
|---|---|
| `playerctl -l` | Lista los reproductores disponibles (`No players found` si ninguno se anuncia) |
| `playerctl status` | `Playing`, `Paused` o `Stopped` |
| `playerctl metadata --format '{{artist}} - {{title}}'` | Artista y título de lo que suena |
| `playerctl play-pause`, `next`, `previous` | Controles |

### hyprctl

Consulta y controla Hyprland en marcha:

| Comando | Efecto |
|---|---|
| `hyprctl monitors` | Resolución, frecuencia, **escala** y modos disponibles de cada monitor |
| `hyprctl clients` | Las ventanas abiertas: clase (`class`, que es el `appId` del dock), tamaño, posición, `pid` y si usan XWayland |
| `hyprctl layers` | Las capas de Quickshell (barra, dock, fondo, letra, recogedora) |
| `hyprctl reload` | Recarga la configuración |

### qs (Quickshell)

| Comando | Efecto |
|---|---|
| `qs` | Lanza Quickshell |
| `qs log` | Muestra el registro de la instancia en marcha (avisos y errores) |
| `pkill qs` | Lo cierra |
| `touch ~/.config/quickshell/Bar.qml` | Fuerza una recarga (útil tras añadir o renombrar ficheros) |

### Probar iconos de Nerd Font

Antes de usar un icono nuevo en Quickshell (`"\uf16a"`), se comprueba que **existe en la fuente** escribiéndolo en kitty. Si sale un dibujo, sirve; si sale un rombo o un recuadro vacío, hay que elegir otro código:

```bash
printf '\uf16a  \uf1bc  \uf001  \uf0e8  \uf1eb  \uf011\n'
```

> 💡 Los códigos son los de **Font Awesome** dentro de Nerd Font. Algunos no coinciden con lo que se espera (`\uf167` no es el logotipo de YouTube en esta fuente), por eso conviene probarlos siempre.

### zsh, plugins y starship

**zsh** es una shell más cómoda que bash de forma interactiva: autocompletado con menú, historial compartido y plugins. **starship** es el prompt (carpeta, rama de git, errores, iconos).

```bash
sudo pacman -S --needed zsh zsh-autosuggestions zsh-syntax-highlighting starship
ls /usr/share/zsh/plugins/       # deben verse los dos plugins
```

| Paquete | Función |
|---|---|
| `zsh-autosuggestions` | Muestra en gris el comando anterior que empieza igual; la flecha derecha lo acepta |
| `zsh-syntax-highlighting` | Colorea lo que escribes: **verde** si el comando existe, **rojo** si no (avisa de erratas antes de ejecutar) |
| `starship` | El prompt |

Crea `~/.zshrc` **antes** de abrir zsh por primera vez (si no, lanza un asistente de configuración):

```zsh
# historial
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS

# comodidad
setopt interactivecomments
unsetopt nomatch

# autocompletado
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

# alias
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias t='tree -a -I ".git"'

# prompt
eval "$(starship init zsh)"

# plugins (el resaltado de sintaxis debe ir el último)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

| Línea | Para qué |
|---|---|
| `setopt interactivecomments` | Permite comentarios con `#` al final de una línea: sin ella, los comandos del README con comentario darían error |
| `unsetopt nomatch` | Evita el error `no matches found` cuando un patrón no encuentra nada (`rm *.bak` sin ficheros `.bak`) |
| Los `alias` | Atajos: `t` equivale a `tree -a -I ".git"` |

> ⚠️ La opción se llama **`nomatch`** (siete letras) y se **desactiva** con `unsetopt`. `setopt nonmatch` y `setopt nonomatch` **no existen** y zsh avisa con `no such option`. Para consultar los nombres reales: `set -o | grep -i match`.

**Probar sin cambiar nada**, desde bash:

```bash
zsh
```

| Prueba | Resultado esperado |
|---|---|
| El prompt | Cambia al de starship (`~` y `❯`) |
| Escribir `ls` sin pulsar Enter | En **verde** |
| Escribir `lss` sin pulsar Enter | En **rojo** |
| Un comando ya usado | El resto aparece en **gris** |
| `cd ` y `Tab` | Menú de carpetas navegable |
| Inicio, Fin y Supr | Si no funcionan, añade `bindkey` (ver abajo) |

`exit` vuelve a bash. Escribir `zsh` solo abre una sesión **de prueba** dentro de la terminal.

#### Hacerla la shell por defecto

```bash
chsh -s /usr/bin/zsh
getent passwd $USER | cut -d: -f7     # lo GUARDADO: /usr/bin/zsh (se ve al instante)
```

Pide la contraseña (no se ve al teclear). Para volver a bash: `chsh -s /bin/bash`.

> ⚠️ **Salir de Hyprland no basta.** Tras `chsh`, el TTY desde el que se lanza `start-hyprland` se abrió antes del cambio y conserva `SHELL=/usr/bin/bash`, que heredan Hyprland y kitty. Cierra la sesión del TTY y vuelve a iniciarla (o reinicia el equipo):
> 1. `Super + Shift + E` para salir de Hyprland.
> 2. `exit` en el TTY y vuelve a iniciar sesión con tu usuario.
> 3. `echo $SHELL` debe decir `/usr/bin/zsh`.
> 4. Hyprland arranca solo si tienes el `~/.zprofile` ([apartado 4.1](#41-arranque-automático-de-hyprland)); si no, `start-hyprland`.

| Comprobación | Qué muestra |
|---|---|
| `getent passwd $USER \| cut -d: -f7` | La shell **guardada** para la cuenta (cambia al ejecutar `chsh`) |
| `echo $SHELL` | La shell de la **sesión en marcha** (cambia al iniciar sesión de nuevo) |

> 💡 El cambio de shell es **un ajuste del sistema** (`/etc/passwd`), no un fichero del repositorio: git no lo guarda ni lo restaura. **En cada equipo nuevo hay que repetir `chsh`**.

> 💡 Hyprland, Quickshell y los scripts (`net.sh`, `netinfo.sh`, `trayquit.sh`) usan `/bin/sh`, **no** la shell del usuario: cambiar a zsh no les afecta.

> 💡 Si Inicio, Fin o Supr escriben símbolos raros, añade (con `>>`, dos signos, para no borrar el fichero):
> ```bash
> cat >> $HOME/.zshrc <<'EOF'
> bindkey '^[[H' beginning-of-line
> bindkey '^[OH' beginning-of-line
> bindkey '^[[F' end-of-line
> bindkey '^[OF' end-of-line
> bindkey '^[[3~' delete-char
> EOF
> ```

---

<a id="s13"></a>
## 13. 📥 Restaurar el entorno en otro equipo

Tras clonar el repositorio ([11.4](#114-clonar-el-repositorio)), instala todos los programas guardados:

```bash
sudo pacman -S --needed - < pkglist.txt
yay -S --needed - < aur-pkglist.txt
```

Después, aplica las configuraciones:

```bash
cp -r .config/hypr $HOME/.config/
cp -r .config/quickshell $HOME/.config/
cp -r .config/kitty $HOME/.config/
chmod +x $HOME/.config/quickshell/scripts/*.sh
cp zsh/.zshrc $HOME/.zshrc
cp zsh/.zprofile $HOME/.zprofile      # opcional: arranque automático de Hyprland
```

El fondo de pantalla viaja dentro de `.config/quickshell/` (`Wallpaper.qml` y `wallpaper.jpg`), y el tema en `Theme.qml`.

Si el equipo aún usa `systemd-networkd`, cambia a NetworkManager ([apartado 1.1](#11-red-networkmanager)). Activa también el audio ([apartado 1.2](#12-audio-pipewire)): los paquetes de PipeWire llegan con `pkglist.txt`, pero sus servicios de usuario se activan con `systemctl --user enable --now pipewire pipewire-pulse wireplumber`. Ajusta la **zona horaria** ([1.3](#13-zona-horaria-y-hora)), que tampoco viaja con el repositorio.

**Cambia la shell a zsh** (`chsh -s /usr/bin/zsh`; este ajuste **no viaja con el repositorio**) y **cierra la sesión del TTY** (`exit`) para iniciarla de nuevo: salir de Hyprland no basta ([apartado 12](#s12)). Con el `.zprofile` copiado, Hyprland arranca solo tras el login ([apartado 4.1](#41-arranque-automático-de-hyprland)); si no, entra con `start-hyprland`. La barra y los paneles arrancan solos; el **dock** está oculto y aparece al llevar el ratón al borde derecho (y solo existe cuando hay alguna ventana o app en segundo plano); el chip de música se ve cuando hay algo sonando.

**Datos personales:** la agenda (`~/.local/share/pikson/agenda.json`) **no** viaja con el repositorio. En un equipo nuevo empezará vacía; si se quiere conservar, se copia a mano.

| Fichero | Contenido |
|---|---|
| `pkglist.txt` | Paquetes de los repositorios oficiales |
| `aur-pkglist.txt` | Paquetes del AUR |
| `.config/` | Configuración de Hyprland, Quickshell (con su tema, sus paneles y el dock) y kitty |
| `zsh/.zshrc` | Configuración de zsh (se copia a `~/.zshrc`) |
| `zsh/.zprofile` | Arranque automático de Hyprland en el TTY1 (se copia a `~/.zprofile`) |

> ⚠️ Requiere `yay` instalado ([apartado 7](#s7)). Las listas incluyen `virtualbox-guest-utils`, que solo hace falta en una VM: retíralo en hardware real. En hardware real, quita también `LIBGL_ALWAYS_SOFTWARE=1` de `hyprland.lua` (terminal y Quickshell), y revisa la **escala** y la **frecuencia** del monitor ([apartado 8](#otros-ajustes-de-hyprlandlua-monitor-escala-y-frecuencia)): la escala `1.25` y el tamaño de letra de kitty en `10` están ajustados a la VM.

> 💡 Cada vez que instales algo nuevo, regenera las listas. Cuidado con el nombre: es `pkglist.txt` (con **g**); un `pklist.txt` crearía un fichero nuevo y distinto. Tras regenerarlas, `ttf-cormorant` ya no debería hacer falta (el tema usa solo JetBrains Mono).
> ```bash
> pacman -Qqen > pkglist.txt
> pacman -Qqem > aur-pkglist.txt
> ```

---

<a id="s14"></a>
## 14. 📝 Pendiente

**Hecho hasta ahora**

Barra «solo texto» con workspaces en números romanos; paneles de música (con letra sincronizada y columna lateral), calendario con agenda, sonido, avisos, tiempo, red (medallón) y menú de apagado; cierre al pulsar fuera; tipografía única; dock lateral oculto con ventanas abiertas y bandeja.

**Siguiente, por construir (en este orden)**

- [ ] **Red + camino de la conexión**: conservar el medallón y añadir un esquema *Equipo → Router → Internet* con las IP, la velocidad y la latencia (con `ping`)
- [ ] **Chip de música siempre visible**: miniatura, título y tiempo, sin caja; con un ancho fijo, «Nada suena» cuando no hay reproductor y un estado vacío en el panel (hoy el chip se oculta sin reproductor)
- [ ] **Pantallas**: leer los monitores con `hyprctl monitors -j`, escribir `monitors.lua` y revertir a los 15 s si no se confirma
- [ ] **Batería** (en hardware real)
- [ ] **Sistema**: CPU, RAM, disco y temperatura; al pulsarlo abre Pantallas
- [ ] **Lanzador** (diseño «B»): calculadora, categorías y atajo de teclado
- [ ] **Sonido**: medidor del micrófono en el panel
- [ ] **Bloquear pantalla**: instalar `hyprlock` y configurarlo (hoy «Bloquear» no hace nada)
- [ ] **Comprobar que se puede teclear** en el campo «Añadir una tarea» del calendario; si no, convertirlo en ventana de capa con foco de teclado
- [ ] **Tarjeta de libros**: lo que estoy leyendo, con el porcentaje; los datos personales irían en `libros.json` (fuera del repositorio) con un `libros.example.json` de muestra
- [ ] **Red y Bluetooth, fases 2 y 3 (hardware real)**: conectar las pestañas Wi-Fi y Bluetooth a `nmcli` y `bluetoothctl` en lugar de los datos de ejemplo; «Escanear redes» y «Escanear dispositivos»; la ficha de contraseña para las redes con candado; y que el botón de latón encienda y apague de verdad
- [ ] **Reproductor**: probar el bucle con Spotify real (en Brave se ve atenuado) y la **cola** con la API web de Spotify (MPRIS no la expone)
- [ ] **Animaciones**: 1) una transición común de apertura de los paneles (escala del 92 % al 100 % con aparición suave, aplicada al **contenido**); 2) movimiento discreto en el medallón de red; 3) cierres animados. Las animaciones en bucle solo deben ejecutarse **mientras el panel está abierto**: en la VM, con renderizado por software, pueden ir entrecortadas

**Dock**

- [ ] Agrupar las ventanas de una misma aplicación en una sola fila (hoy hay una fila por ventana)
- [ ] Pasar los iconos de las ventanas a **monocromo** (hoy van a color) para casar con la barra
- [ ] Comprobar el dock con la **columna de letra abierta** y con varias ventanas en distintos workspaces (¿mostrar solo las del workspace actual?)
- [ ] Pasar al tema los colores propios del dock (`#f52d1e12`, filetes) y retirar el posible aviso de `iconPath` en `qs log`

**Limpieza del código**

- [ ] Quitar `Theme.spines` y `Theme.wood` (ya sin uso) y renombrar o eliminar `fontSerif`
- [ ] Quitar los bloques `HyprlandFocusGrab` que ya no hacen nada
- [ ] Sacar `ttf-cormorant` de las listas de paquetes y regenerar `pkglist.txt` y `aur-pkglist.txt`
- [ ] Corregir `tempColor` del panel del tiempo (opcional)
- [ ] Pasar al tema los colores propios de los paneles (el latón del medallón, el papel de la carátula)

**Tema y estética**

- [ ] Fondo de pantalla de tonos cálidos, o tintar el actual hacia sepia
- [ ] Comprobar en `hyprland.lua` las esquinas redondeadas de las ventanas (`rounding`, unos 14 para casar con `Theme.radius`) y la sombra
- [ ] Una única fuente de colores para Quickshell, kitty y Hyprland (hoy están copiados en tres sitios)
- [ ] Desenfoque de las ventanas (es pesado en la VM)

**Escritorio**

- [ ] Máscara de entrada en la barra superior (que los huecos no bloqueen clics ni reserven espacio)
- [ ] Distribución de las ventanas: Discord necesita ≈ 940 px de ancho
- [ ] Gestor de archivos y diálogos de archivos de GTK (se ven mal en la VM)
- [ ] Fusionar `net.sh` y `netinfo.sh` en un único script
- [ ] Quitar el registro de depuración de la línea de arranque de Quickshell

**Repositorio y hardware real**

- [ ] Instalar Spotify de escritorio y probarlo (en la VM no dibuja ventana)
- [ ] Frecuencia del monitor (165 Hz) y revisión de la escala
- [ ] Probar el Wi-Fi y el Bluetooth (`bluez`, `bluez-utils`) con el panel medallón, y revisar el volumen y el silencio con el rango completo
- [ ] GNU Stow para enlazar configuraciones (incluidos `zsh/.zshrc` y `zsh/.zprofile`)
- [ ] Script `install.sh` que automatice este manual, preguntando si es una **VM o un equipo real** para aplicar o quitar lo que depende de ello: `virtualbox-guest-utils`, `LIBGL_ALWAYS_SOFTWARE=1`, la escala y la frecuencia del monitor
- [ ] Probar el manual completo en una VM limpia
- [ ] Login gráfico (SDDM, greetd con un greeter o uno propio con Quickshell), quitando el bloque de `~/.zprofile`

**A largo plazo: un USB instalador con mi Arch**

La idea es un USB booteable, como el de Windows 10 o el de Arch, pero que **instale mi entorno completo** (Hyprland, Quickshell, dotfiles y paquetes) en el disco de cualquier equipo. **No** consiste en clonar la VM, que no es portable (arrastra los controladores de VirtualBox y los identificadores de disco). No se empieza hasta tener el escritorio terminado.

- [ ] 1. Terminar el escritorio, subirlo a GitHub y regenerar las listas de paquetes
- [ ] 2. Escribir `install.sh` (ver arriba) y reutilizarlo como base de todo lo demás
- [ ] 3. Un instalador con mi configuración: un script con `archinstall` (disco, usuario, contraseña, idioma, zona horaria y teclado US) más `install.sh`, o bien **Calamares** (asistente gráfico tipo Windows, más trabajo). Las contraseñas y el usuario se piden al instalar y **nunca** viajan en la imagen
- [ ] 4. Construir la ISO con **archiso** (perfil `releng` más la lista de paquetes y el instalador). Decidir entre instalación **online** (ISO pequeña que descarga al instalar; los paquetes del AUR se compilan o se sirven desde un repositorio propio) y **offline** (ISO grande con todo, con el AUR compilado antes en un repositorio local). Con un **tema de GRUB propio**
- [ ] 5. Grabarla con `dd` en un USB y probarla primero en una VM limpia y luego en hardware real (Wi-Fi, Bluetooth, tarjeta gráfica, UEFI). El *Secure Boot* no funciona con estas ISO
