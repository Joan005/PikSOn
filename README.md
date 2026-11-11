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
        ├── Bar.qml          # Barra superior (workspaces como lomos de libros, música, reloj, volumen y red)
        ├── Player.qml       # Chip de música de la barra (cualquier reproductor MPRIS)
        ├── PlayerPanel.qml  # Panel del reproductor: marco, placa de latón, progreso y controles
        ├── NetPanel.qml     # Panel de red y Bluetooth: el medallón
        ├── Calendar.qml     # Agenda de cuero desplegable del reloj
        ├── Dock.qml         # Panel lateral: bandeja del sistema (apps en segundo plano)
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
| `.config/quickshell/` | Tema, barra superior, chip y panel del reproductor, panel de red, agenda, bandeja del sistema, fondo y scripts de apoyo |

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

`archinstall` no deja instalado el servidor de sonido. Hace falta **PipeWire**, que además aporta `wpctl`, la herramienta que usan el chip de volumen ([9.8](#98-chip-de-volumen-en-la-barra)) y las teclas multimedia de Hyprland.

```bash
sudo pacman -S --needed pipewire wireplumber pipewire-pulse
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

| Paquete | Función |
|---|---|
| `pipewire` | El servidor de sonido |
| `wireplumber` | El gestor de dispositivos; incluye `wpctl` |
| `pipewire-pulse` | Compatibilidad con programas que usan PulseAudio (Brave, Discord...) |

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

> 💡 `set-ntp true` activa la sincronización automática con internet, para que el reloj no se desajuste. En una VM no hace falta, porque VirtualBox ya sincroniza la hora con la del anfitrión.

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

> 💡 El audio virtual de VirtualBox tiene límites (volumen mínimo ≈ 45 % y silencio sin efecto): ver [9.8](#98-chip-de-volumen-en-la-barra).

> 💡 Los diálogos de archivos de GTK (por ejemplo, "Guardar como" en Brave) pueden verse mal en la VM: lista de la raíz del sistema aunque la ruta indique otra carpeta, nombres cortados y botones que no responden. Si no se puede guardar, descarga con `curl` ([9.9](#99-fondo-de-pantalla)).

> 💡 **Spotify de escritorio no dibuja su ventana en la VM** (el proceso arranca, pero no aparece ventana ni se anuncia): es una limitación de la máquina virtual sin GPU. Ver [9.11](#911-chip-de-música-en-la-barra) para cómo se prueba el chip de música sin él.

> 💡 **La pantalla de la VM solo ofrece 60 Hz** (VirtualBox no expone otras frecuencias), aunque el monitor real vaya a más. Y la escala automática de Hyprland sale demasiado alta (1,67) y recorta las aplicaciones: ver [el apartado 8](#otros-ajustes-de-hyprlandlua-monitor-escala-y-frecuencia).

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

> 💡 El TTY negro de `login:` es solo un login en modo texto. En hardware real se puede sustituir por un **gestor de inicio gráfico** (SDDM, greetd con un greeter, etc.): si se instala, hay que **quitar este bloque** de `~/.zprofile` para no lanzar Hyprland dos veces ([apartado 14](#s14)).

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

Tipografía: **JetBrains Mono Nerd Font**. La variante **`Mono`** encaja los iconos de Nerd Font en una sola celda, que es lo que conviene en un terminal:

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

> 💡 **El tamaño de letra depende de la escala del monitor** ([apartado 8](#otros-ajustes-de-hyprlandlua-monitor-escala-y-frecuencia)): con la escala 1,25 queda bien con **10**; con la escala automática de 1,67 hacía falta 8. Si cambias la escala, ajusta el tamaño de letra (el equivalente es `tamaño × escala anterior ÷ escala nueva`).

> 💡 **Probar en caliente** (temporal, no toca el fichero): `Ctrl + Shift + +` / `-` cambian el tamaño de letra, `Ctrl + Shift + Retroceso` vuelve al valor del fichero, y `Ctrl + Shift + A` seguido de `L` (más transparente), `M` (menos) o `D` (valor del fichero) cambian la opacidad.

> 💡 Si no se ve el color elegido, suele ser la transparencia: con valores bajos (0.5) la imagen de fondo domina. Con `0.7` el color del terminal se nota y el fondo sigue asomando.

> 💡 No mezcles `foreground` y `background`: un tono pensado para el texto puesto en `background` da una ventana pálida.

> 💡 **Los colores están repetidos en tres sitios**: `Theme.qml` (barra y paneles), `kitty.conf` (terminal) y `hyprland.lua` (bordes de las ventanas). Si cambias de paleta, hay que tocar los tres a mano; unificarlos en una sola fuente está pendiente ([apartado 14](#s14)).

> 💡 Para ver la configuración que kitty está aplicando y sus errores: **`Ctrl + Shift + F6`** dentro de una terminal de kitty (la opción de línea de órdenes `kitty --debug-config` ya no existe en kitty 0.49).

> 💡 Al abrir o reajustar ventanas, kitty muestra un instante el tamaño de la ventana en celdas (`233 by 48 cells`). Es inofensivo; no se ha encontrado una opción para ocultarlo.

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

> 💡 Para **pegar desde fuera de la VM**, el portapapeles compartido de VirtualBox (*Dispositivos → Portapapeles compartido → Bidireccional*) puede no funcionar con Hyprland (Wayland). Alternativa fiable: abrir el manual en Brave **dentro** de la VM y copiar desde allí.

> ⚠️ Si editas un fichero **por fuera** (con `sed`, por ejemplo) mientras sigue abierto en nano, el aviso **Modified** indica que nano tiene su propia copia sin guardar: al guardar desde nano, **sobrescribirá** el cambio externo. Cierra nano antes, o corrige dentro de nano (`Ctrl + \` busca y reemplaza).

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

`Ctrl + \` pide el texto a buscar y el que lo sustituye. Con `A` en la pregunta de cada coincidencia se reemplazan **todas** de una vez. Es la forma más cómoda de cambiar un valor repetido por muchas líneas (por ejemplo, un color por `Theme.fg`).

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

> 💡 Al **sustituir** un bloque cortado por otro tecleado, termina el bloque nuevo con `Enter`: así la llave de cierre que había debajo queda en su propia línea y no pegada a la última del bloque.

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

> 💡 Los atajos de **workspaces** (`Super + 1…5` para ir a un escritorio y `Super + Shift + 1…5` para mover la ventana activa) llegan solo hasta el **5**, igual que la barra ([9.2](#92-ficheros-de-configuración)): así no se pueden crear escritorios que la barra no muestra.

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

Con `scale = "auto"`, en la VM Hyprland elige **1,67** (no conoce el tamaño físico de la pantalla). Con una pantalla de 1920 × 955, eso deja unos **1152 × 573 píxeles útiles**, y las aplicaciones con tamaño mínimo se recortan: Discord (≈ 940 × 500) y Brave pierden el borde derecho o el panel de usuario de abajo a la izquierda, y el fondo puede verse descentrado. Por eso la escala se fija a mano:

| Escala | Píxeles útiles (1920 × 955) | Resultado |
|---|---|---|
| `1.67` (automática en la VM) | 1152 × 573 | Todo grande, pero las apps no caben |
| **`1.25`** (la que se usa) | 1536 × 764 | Todo cabe y se lee bien |
| `1` | 1920 × 955 | Todo cabe, pero el texto es muy pequeño |

Comprueba la escala y la resolución con `hyprctl monitors` (líneas `scale:` y la primera, con `@`). Hyprland recarga la configuración al guardar; si no, `hyprctl reload`.

> 💡 Al cambiar la escala hay que **reajustar el tamaño de letra** del terminal ([5.2](#52-configuración-propia-kittyconf)): con 1,25 se usa 10.

> 💡 **Frecuencia (Hz):** la VM solo ofrece **60 Hz** (VirtualBox no expone más), así que la de un monitor de 165 Hz solo se puede usar en **hardware real**. Allí se fija en `mode`: `mode = "1920x1080@165"`, o `mode = "highrr"` para que Hyprland elija la frecuencia más alta. Con `"preferred"`, muchos monitores se quedan en 60 Hz. En un equipo real, revisa también la escala: Hyprland suele acertar solo con ella, al conocer el tamaño físico.

> 💡 **Discord necesita ≈ 940 px de ancho:** en pantalla dividida (≈ 750 px por mitad con la escala 1,25) puede recortarse por la derecha. Se resuelve con la distribución de las ventanas (por ejemplo, Discord a pantalla completa en su propio workspace), no con la escala.

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

> 💡 En Hyprland los colores se escriben **`rgba(RRGGBBAA)`**: el alfa va al **final**. En QML (`Theme.qml`) y en las demás piezas el formato es **`#AARRGGBB`**, con el alfa al **principio**.

> 💡 Si los bordes siguen viéndose de otro color tras cambiarlos, comprueba que no hay otra definición más abajo en el fichero que los sobrescriba: `grep -n "border" $HOME/.config/hypr/hyprland.lua`.

---

<a id="s9"></a>
## 9. 🧩 Quickshell: barra, paneles y fondo

**Quickshell** es un kit para construir la interfaz del escritorio (barras, paneles, widgets) con QML. Aquí se usa para una barra superior (con los workspaces como lomos de libros, un chip de música y un reloj con agenda), tres paneles desplegables (reproductor, red y agenda), un panel lateral que hace de **bandeja del sistema** (las aplicaciones que siguen abiertas en segundo plano) y el fondo de pantalla. Todos comparten colores, tamaños y fuentes a través de un **tema** ([9.13](#913-tema-themeqml)).

### 9.1 Instalación

```bash
sudo pacman -S quickshell
qs --version
```

### 9.2 Ficheros de configuración

La configuración vive en `~/.config/quickshell/` y se divide en piezas:

| Fichero | Función |
|---|---|
| `shell.qml` | Punto de entrada: carga las demás piezas |
| `Theme.qml` | El tema: paleta, tamaños y fuentes, compartidos por todas las piezas ([9.13](#913-tema-themeqml)) |
| `Wallpaper.qml` | Fondo de pantalla (una ventana en la capa `Background`) |
| `wallpaper.jpg` | La imagen del fondo |
| `Bar.qml` | Barra superior: contenedor fijo con los workspaces como lomos, chip de música, reloj (con la agenda desplegable), chips de volumen y de red, y los paneles de reproductor y de red |
| `Player.qml` | Chip de música de la barra: canción que suena y botones anterior, pausa y siguiente ([9.11](#911-chip-de-música-en-la-barra)) |
| `PlayerPanel.qml` | Panel del reproductor: marco, placa de latón, progreso y controles ([9.14](#914-panel-del-reproductor)) |
| `NetPanel.qml` | Panel de red y Bluetooth, el medallón ([9.7](#97-panel-de-red-el-medallón)) |
| `Calendar.qml` | Agenda de cuero que se abre al pulsar el reloj ([9.12](#912-agenda-de-cuero-del-reloj)) |
| `Dock.qml` | Panel lateral derecho = **bandeja del sistema**: muestra solo las apps que siguen abiertas en segundo plano ([9.4](#94-bandeja-del-sistema-panel-lateral)) |
| `scripts/net.sh` | Resumen de la red para el chip (`tipo\|dispositivo\|ip`) |
| `scripts/netinfo.sh` | Detalle de la red para el panel desplegable (`clave=valor`) |
| `scripts/trayquit.sh` | Cierra del todo la app de un icono de la bandeja (lo usa el botón "Cerrar") |

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

> 💡 **Los workspaces son lomos de libros.** En la izquierda de la barra, cada workspace que existe es un lomo de 22 px de ancho con su **número romano** (I a V) y dos bandas doradas, sobre una balda de madera. El lomo del workspace activo es más alto (25 px frente a 20) y lleva borde dorado; un clic sobre cualquiera cambia de escritorio. Solo hay **5**. Los cinco colores (burdeos, azul petróleo, ocre, ciruela y cuero) están en `Theme.spines` y se asignan por posición: `Theme.spines[((id - 1) % 5 + 5) % 5]`.

> 💡 Los lomos van dentro de un **contenedor oscuro de anchura fija** (152 px), calculada para 5 lomos: `5 × 24 px + 4 × 5 px de separación + 12 px de margen interior`. Así el espacio queda reservado aunque solo exista un workspace, y las piezas que se añadan a su derecha no se desplazan. El número de lomos es la propiedad **`slots`** de `wsBox` en `Bar.qml` (`cell` es el ancho de cada lomo y `gap` la separación): al cambiarla, el contenedor se recalcula solo. Para anclar otra pieza junto a él, se usa `anchors.left: wsBox.right` (así está colocado el chip de música). La balda es un pequeño rectángulo de madera (`Theme.wood`) en el borde inferior del contenedor, y la fila de lomos se apoya en ella (`anchors.bottom` con un margen de 5 px). La barra solo muestra los workspaces que **existen**: aparecen conforme se usan con `Super + 1…5`.

> 💡 **Alturas.** La ventana de la barra mide **40 px** (`implicitHeight` en `Bar.qml`) y los chips (volumen, red, música) y el contenedor de lomos miden **32 px**, todos iguales. Si algo se ve «achatado» o apretado, esos son los números que hay que tocar: la ventana en `Bar.qml` y la altura de cada chip en su bloque (`Player.qml` para el de música).

> 💡 El panel lateral (`Dock.qml`) está anclado arriba, a la derecha y abajo: así reserva una franja de 34 px y las ventanas no pasan por debajo de los iconos. Quickshell ya descuenta el espacio de la barra superior, por lo que no hace falta ningún margen manual arriba.

### 9.3 Arranque automático

Bloque incluido en `hyprland.lua`, dentro de la sección de autoarranque:

```lua
-- Quickshell: barra superior y panel lateral
hl.on("hyprland.start", function ()
    hl.exec_cmd("env LIBGL_ALWAYS_SOFTWARE=1 qs")
end)
```

> ⚠️ `LIBGL_ALWAYS_SOFTWARE=1` solo es necesario en **VirtualBox**, donde sin ella `qs` se cae al arrancar con `Could not create EGL surface`. **En hardware real, usa solo `hl.exec_cmd("qs")`.**

> 💡 Para depurar un fallo de arranque, redirige la salida a un fichero: `hl.exec_cmd("qs > $HOME/qs-arranque.log 2>&1")`.

### 9.4 Bandeja del sistema (panel lateral)

`Dock.qml` ya no es un lanzador con botones fijos: es la **bandeja del sistema**, como los iconos junto al reloj en Windows. Las aplicaciones se abren desde la terminal o con sus atajos (`Super + B`, `Super + D`...), y en el panel aparecen **solo las que siguen abiertas en segundo plano**.

Cada aplicación se anuncia por sí misma a la bandeja (protocolo *StatusNotifierItem*) y Quickshell las recoge con su módulo `Quickshell.Services.SystemTray`: entran y salen solas, sin configurar nada.

| Acción | Efecto |
|---|---|
| **Clic izquierdo** en un icono | Abre o muestra la aplicación |
| **Clic derecho** en un icono | Aparece el botón **Cerrar**, que termina la aplicación del todo |
| Ninguna app en la bandeja | El panel no se muestra |

El panel queda en la esquina **inferior derecha**, con un pequeño margen con los bordes. Los iconos van en una caja redondeada; el resto de la franja es transparente y deja pasar los clics (`mask: Region { item: box }`).

```qml
Repeater {
    model: SystemTray.items

    delegate: MouseArea {
        // clic izquierdo: modelData.activate()
        // clic derecho: abre el panel con el botón "Cerrar"
        IconImage { source: trayItem.modelData.icon }
    }
}
```

El fichero completo está en `.config/quickshell/Dock.qml`.

> 💡 **Qué aplicaciones aparecen:** solo las que usan la bandeja. **Discord** sí (al cerrar su ventana se queda en segundo plano, con la opción de minimizar a la bandeja activada en sus ajustes). **Brave** no: se cierra con su propia **X** o con `Super + Retroceso`. **Steam** probablemente sí; **Plex** depende de la versión. Para probar el panel con una app pequeña: `sudo pacman -S --needed network-manager-applet` y `nm-applet --indicator &`.

#### El botón "Cerrar": `trayquit.sh`

La bandeja no dice qué proceso hay detrás de cada icono, pero cada icono se registra en **D-Bus**, que sí lo sabe. El script busca el icono por su identificador, obtiene su proceso y lo cierra: primero con `kill` y, si a los 2 segundos sigue vivo, con `kill -9`. Sirve para **cualquier** aplicación de la bandeja, sin depender de su nombre.

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

Pruébalo **sin argumentos**, con una aplicación en la bandeja (por ejemplo, Discord): solo lista, no cierra nada. Debe salir una línea por icono:

```bash
sh $HOME/.config/quickshell/scripts/trayquit.sh
# id=discord_status_icon_1 pid=52582 servicio=:1.154
```

Con el `id` que muestre, cierra esa aplicación:

```bash
sh $HOME/.config/quickshell/scripts/trayquit.sh discord_status_icon_1
```

El botón **Cerrar** del panel lanza exactamente esa orden con el identificador del icono pulsado:

```qml
Quickshell.execDetached(["sh", "-c", "$HOME/.config/quickshell/scripts/trayquit.sh \"$0\"", trayItem.modelData.id])
```

> ⚠️ **El script debe ser ejecutable** (`chmod +x`), porque el botón lo lanza directamente. Un fichero creado con nano no lo es, y el clic en **Cerrar** no haría nada, aunque desde la terminal con `sh script` sí funcionara.

> ⚠️ Es un cierre brusco, como "Finalizar tarea" en Windows: lo que la aplicación no haya guardado se pierde.

> 💡 Para revisar la sintaxis del script sin ejecutarlo: `sh -n $HOME/.config/quickshell/scripts/trayquit.sh` (si no imprime nada, está bien).

### 9.5 Solución de problemas

Si al editar un `.qml` aparece la ventana **"Config reload failed"**:

- Indica fichero, línea y columna del error (por ejemplo, `@Bar.qml[44:2]`).
- `Type Bar unavailable` en `shell.qml` es solo la **consecuencia**: la causa real está en la línea del fichero que se cita debajo.
- Si el mismo error se repite tras editar, probablemente **el fichero no ha cambiado**: comprueba su contenido con `head -3` o `cat -n fichero | sed -n '30,52p'`.
- Los avisos amarillos (`WARN ... ReferenceError`, `TypeError`) no impiden cargar, pero señalan una errata que rompe una función. Se ven con `qs log`.
- Cuando el aviso dice **"is not a type"**, compara letra por letra con una línea idéntica que sí funcione: `Stdio` y `Studio`, o `Rectangle` y `Rectagle`, se parecen demasiado a simple vista.
- Un fichero `.qml` que ninguna pieza usa todavía **no se comprueba**: sus erratas solo aparecen cuando otro fichero lo carga (por ejemplo, `Player.qml` hasta que `Bar.qml` incluye `Player {}`, o `PlayerPanel.qml` y `NetPanel.qml` hasta que `Bar.qml` incluye sus bloques).
- Al **añadir** una línea con nano, comprueba que no **sustituyes** la que había (por ejemplo, al añadir `calOpen` se perdió `netOpen`).
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
| `Expected token ':'` | `porperty` por `property`, o `text. valor` con punto en vez de dos puntos, o `Text:` en vez de `Text {` | `property`; `text: valor`; `Text {` |
| `Incomplete binding, expected ':' or '{'` | Propiedad sin los dos puntos: `anchors.left.wsBox.right` | `anchors.left: wsBox.right` |
| `Expected token ','` (en `acceptedButtons`) | Texto duplicado al pegar: `Qt.LeftButtons: Qt.LeftButton \| ...` | `acceptedButtons: Qt.LeftButton \| Qt.RightButton` |
| `Cannot assign to non-existent property "margin"` | Falta la `s` | `anchors.margins` |
| `Cannot assign to non-existent property "boder"` | Falta la `r` en `border.color` | `border.color` |
| `Cannot assign to non-existent property "onNetOpenChanged"` | Se borró `property bool netOpen: false` al añadir `calOpen` | Deben existir **las dos** propiedades |
| `Cannot assign a value to a signal (use 'on<Signal>: ...')` en `Theme.qml` | Una propiedad llamada `onAccent`: QML trata cualquier nombre `on` + mayúscula como un manejador de señal | Renombrarla (`fgOnAccent`) en `Theme.qml` y en todos los sitios donde se use |
| `Invalid property assignment: color expected` | Color sin almohadilla (`"89b4fa"`) | `"#89b4fa"` |
| Un círculo o un fondo sale **rosa** en lugar de dorado | El color se escribió como `#e2b56499`, que QML lee con el alfa **delante** (`e2`) y el color `b56499` | `#99e2b564` (en QML el alfa va primero) |
| `Property 'strings' ... is not a function` | Nombre inventado | `substring` |
| `ReferenceError: i2 is not defined` | Se usa una variable que no se declaró (`i2` por `i1`) | El nombre declarado |
| `panelWindth is not defined` | Errata | `panelWidth` |
| Un panel que no se coloca bajo el chip | Consecuencia del error anterior | Corregir la errata |
| `Vol undefined%` | La propiedad se declaró como `volPrecent` y se usa `volPercent` | Un único nombre en todo el fichero |
| `Vol --` con audio funcionando | Falta el bloque `Process { id: volProc ... }` (`volProc is not defined`) | Añadir el bloque completo |
| La rueda del volumen no hace nada | `"-1"` (número uno) en lugar de `"-l"` (letra ele) en `set-volume` | `"-l"` |
| Un icono de la bandeja sale duplicado | Bloque `IconImage` repetido al pegar | Dejar uno solo |
| El chip de música no se coloca junto a los workspaces | El bloque `Player {}` quedó **dentro** del `Rectangle` del `wsBox` | Ponerlo fuera, justo encima, al mismo nivel |
| Un botón del chip de música sale como un cuadro vacío | Código de icono mal escrito (`"\uf4b"` por `"\uf04b"`) | Cuatro cifras tras `\u` |
| Un icono sale como un **rombo** o un recuadro | El código no existe en la fuente (por ejemplo, `\uf167` para YouTube) | Probarlo antes con `printf '\uf16a\n'` en kitty y usar otro código (`\uf16a`) |
| El chip de música sigue mostrando el texto largo | La etiqueta no usa la función | `text: chip.shortText()` |
| `impicitWidth` no existe | Falta una `l` | `implicitWidth` |
| Al pulsar en **cualquier sitio** de la barra se abre el calendario, y los chips dejan de responder | El `MouseArea` del reloj quedó **fuera** del `Text` (con `anchors.fill: parent` cubre toda la barra) | Colocarlo **dentro** del `Text` del reloj, antes de su `}` |
| `Syntax error` en la primera línea tras un bloque recién tecleado (`Type Bar unavailable`) | **Sobra una llave `}`**: cierra la barra entera antes de tiempo y lo que sigue queda fuera | Contar las llaves de cierre del bloque (`Item`, `Repeater`, `Row`, contenedor) y borrar la sobrante |
| Un chip o panel se ve con el color equivocado (por ejemplo, el panel con el color del chip) | Se cambiaron los dos nombres a la vez y quedaron cruzados | `bgChip` es para los chips de la barra y `bgPopup` para los paneles desplegables |
| El texto largo de una ficha se corta con `…` y no se ve entero | Falta permitir el salto de línea | `wrapMode: Text.WordWrap` (y que la altura de la ficha dependa de su contenido) |

Y en los scripts de shell y en la terminal:

| Síntoma | Causa | Corrección |
|---|---|---|
| `argument 'TYPE,' not understood` | Espacio tras la coma en `-f DEVICE, TYPE,STATE` | `-f DEVICE,TYPE,STATE` (sin espacios) |
| `[: missing ']'` | Falta el espacio antes del corchete final | `[ -z "$dev" ]` |
| `["$id" ...` no se reconoce | Falta el espacio tras `[` | `[ "$id" = "$want" ]` |
| `Device 'dev' not found` | Falta el `$` | `"$dev"` |
| El chip dice "Sin red" con conexión | El script no es ejecutable | `chmod +x` |
| El botón **Cerrar** de la bandeja no cierra la app | `trayquit.sh` sin permiso de ejecución (se prueba bien con `sh script`, pero el botón lo lanza directamente) | `chmod +x $HOME/.config/quickshell/scripts/trayquit.sh` |
| `trayquit.sh` no lista nada o falla | Orden partida en varias líneas, nombres mal escritos (`org.kde.StatusNotifierWatcher`), falta una `}` en `awk '{print $2}'` o un espacio en el patrón `'"[^"]*"'` | Revisar con `sh -n script`; cada orden en **una** línea |
| `'@DEFAULT_AUDIO_SNIK@' is not a valid number` | `SNIK` por `SINK` | `@DEFAULT_AUDIO_SINK@` |
| `'10%' is not a valid mute option` | `set-mute` con un porcentaje | `set-volume` para el volumen; `set-mute` solo admite `1`, `0` o `toggle` |
| `no such option: nonmatch` (al abrir zsh) | Esa opción no existe | `unsetopt nomatch` (ver [12](#s12)) |
| Hyprland no arranca solo tras el login | `-z "WAYLAND_DISPLAY"` sin `$` en `~/.zprofile` (compara texto literal, nunca vacío) | `-z "$WAYLAND_DISPLAY"` ([4.1](#41-arranque-automático-de-hyprland)) |
| `unrecognized argument: --online` (git) | `--online` por `--oneline` | `git log --oneline` |
| `cp: missing destination file operand` | Falta la segunda ruta (el destino) | `cp origen destino` |
| `cp: -r not specified; omitting directory` | Se copia una **carpeta** sin `-r` | `cp -r carpeta destino/` |
| `playerctl` dice `No players found` con música sonando | El reproductor no se anuncia por MPRIS (o aún no ha iniciado sesión) | Probar con otro (Brave con un vídeo); ver [9.11](#911-chip-de-música-en-la-barra) |
| `Unknown flag: --debug-config` (kitty) | Esa opción ya no existe en kitty 0.49 | `Ctrl + Shift + F6` dentro de kitty |
| `zsh: command not found: man` | `man` no viene instalado | `sudo pacman -S --needed man-db` |
| Discord se queda en «Starting...» con la ventana negra | Procesos a medias de pruebas anteriores, o sesión inestable | Cerrar todo (`hyprctl clients` da el `pid`; `kill`) y reiniciar el equipo |
| La hora de la barra va una hora atrasada | Zona horaria del sistema en UTC | `sudo timedatectl set-timezone Europe/Madrid` ([1.3](#13-zona-horaria-y-hora)) |
| Discord o Brave se recortan (falta el panel de usuario, el borde derecho...) | Escala del monitor demasiado alta (1,67 en la VM) | `scale = "1.25"` en `hl.monitor` ([apartado 8](#otros-ajustes-de-hyprlandlua-monitor-escala-y-frecuencia)) |

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

En `Bar.qml`, la pieza se compone de tres partes: un `Process` que ejecuta el script, un `Timer` que lo repite y un `Rectangle` con el texto:

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

El fichero completo está en `.config/quickshell/Bar.qml`.

### 9.7 Panel de red: el medallón

Al **pulsar el chip de red** se abre un panel con un **medallón de latón** en el centro, con el nombre de la conexión, su estado y un **anillo de 24 marcas** que se ilumina según la señal. Alrededor, **cinco fichas de cuero** unidas al medallón por hilos finos de latón, con los detalles. Un segundo clic en el chip lo cierra.

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

> ⚠️ **Hoy es solo la mitad real.** La pestaña Cable muestra datos de verdad. **Wi-Fi y Bluetooth son de ejemplo**, porque la VM no tiene ese hardware. El botón de latón solo cambia el aspecto del panel (todavía no apaga nada), y las fichas «Escanear redes» y «Escanear dispositivos» están inertes («Próximamente»). Todo ello se conectará a `nmcli` y `bluetoothctl` en hardware real ([apartado 14](#s14)).

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
| `MouseArea` en el chip | `Bar.qml` | Alterna `root.netOpen` |
| `NetPanel { ... }` | `Bar.qml` | Coloca el panel bajo la barra y le pasa `info: root.info` |
| `NetPanel.qml` | Fichero propio | Medallón, fichas, hilos, selector y botón |

El bloque de `Bar.qml` (el panel de red está a la derecha, bajo el chip):

```qml
NetPanel {
    id: netPanel
    anchor.window: root
    anchor.rect.x: root.width - implicitWidth - 8
    anchor.rect.y: root.height + 4
    visible: root.netOpen
    info: root.info
}
```

Cómo está construido `NetPanel.qml` (el fichero completo está en `.config/quickshell/NetPanel.qml`):

| Elemento | Cómo se dibuja |
|---|---|
| Tamaño | 520 × 450 px; el medallón en el centro (`cx` 260, `cy` 205) |
| Anillos de fondo | Tres círculos con borde fino y poca opacidad |
| Hilos | Un rectángulo estrecho por cada ficha, **rotado** desde el centro (`rotation` con `Math.atan2`, `transformOrigin: Item.Left`) y un punto dorado en el extremo |
| Anillo de marcas | 24 pequeños rectángulos, cada uno dentro de un `Item` **rotado** `índice × 15°`; se iluminan los primeros `intensidad ÷ 100 × 24` |
| Fichas | Un `Repeater` sobre `cards`, que calcula la función `cardsFor()` según la pestaña; las posiciones salen de la lista `slots` |
| Texto largo | `wrapMode: Text.WordWrap` y `height: Math.max(46, columna.implicitHeight + 14)`: la ficha crece en lugar de cortar con `…` |
| Selector | Tres botones con forma de píldora; el activo va en dorado |

> 💡 Los iconos del medallón son de Nerd Font: `\uf0e8` (red de nodos, para el cable), `\uf1eb` (Wi-Fi), `\uf293` (Bluetooth) y `\uf011` (el botón de encendido). Se comprueban antes con `printf '\uf0e8  \uf1eb  \uf293  \uf011\n'` en kitty (los de cable, Wi-Fi y encendido están verificados; el de Bluetooth conviene comprobarlo). Las insignias de las fichas son **texto corto** (`ETH`, `IP`, `GW`, `DNS`) en lugar de iconos, para no depender de la fuente.

> 💡 El panel no usa nombres de interfaz: sirve igual para cable y Wi-Fi. Con Wi-Fi, la velocidad aparecerá como `-` (no existe en `/sys/class/net/.../speed`) hasta que se añadan campos propios del Wi-Fi.

> 💡 La tarjeta cuelga del borde derecho (`root.width - implicitWidth - 8`) y 4 px por debajo de la barra (`root.height + 4`). El panel se cierra con un segundo clic en el chip; todavía no se cierra al pulsar fuera.

### 9.8 Chip de volumen en la barra

A la izquierda del chip de red se muestra el volumen, por ejemplo **`Vol 40%`**. Requiere PipeWire ([apartado 1.2](#12-audio-pipewire)).

| Acción | Efecto |
|---|---|
| **Clic** en el chip | Silencia o reactiva el sonido (`Vol mute`) |
| **Rueda** hacia arriba o abajo | Sube o baja de 5 en 5 %, con tope en el 100 % |
| Sin dispositivo de sonido | `Vol --` (en gris) |

Se apoya en `wpctl`, que no necesita ningún script aparte. Las órdenes se pueden probar a mano:

```bash
wpctl get-volume @DEFAULT_AUDIO_SINK@               # Volume: 0.40  (o  Volume: 0.40 [MUTED])
wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+    # sube un 5 % (tope 100 %)
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle          # alterna el silencio
```

En `Bar.qml`, el chip se compone de estas piezas:

| Pieza | Función |
|---|---|
| `Process` (`volProc`) | Ejecuta `wpctl get-volume` y guarda `volPercent` y `volMuted` |
| `Timer` (2 s) | Vuelve a leer el volumen, para reflejar cambios hechos con las teclas multimedia |
| `Timer` (`volRefresh`) | Lee el volumen justo después de un clic o un giro de rueda |
| `MouseArea` | Clic: `set-mute toggle`; rueda: `set-volume -l 1.0 ... 5%+` o `5%-` |

Lectura del volumen:

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

> ⚠️ En `set-volume`, la opción es **`-l`** (letra *ele*, de *limit*), no el número `-1`. Con `-1`, `wpctl` rechaza la orden y la rueda no hace nada.

> ⚠️ **Limitaciones de VirtualBox:** el dispositivo de audio virtual impone un volumen mínimo (≈ 45 %: pedir un 10 % deja 0.45) y **no aplica el silencio** (`set-mute` no cambia nada). El chip muestra fielmente lo que informa `wpctl`; en hardware real el rango es completo y el silencio funciona.

> 💡 `set-volume` y `set-mute` son órdenes distintas: la primera recibe un porcentaje y la segunda solo `1`, `0` o `toggle`.

> 💡 El definitivo será una **perilla de latón con números romanos**, con el silencio dentro del panel ([apartado 14](#s14)).

### 9.9 Fondo de pantalla

El fondo lo dibuja Quickshell, sin instalar nada más: una ventana que ocupa toda la pantalla en la capa `Background`, por detrás de todo. La imagen viaja con el repositorio, dentro de `~/.config/quickshell/`.

**1. Conseguir la imagen** con el nombre `wallpaper.jpg` en la carpeta de Quickshell:

```bash
mv $HOME/Downloads/IMAGEN.jpg $HOME/.config/quickshell/wallpaper.jpg
file $HOME/.config/quickshell/wallpaper.jpg      # debe decir "JPEG image data"
```

> 💡 `mv` mueve **y** renombra. Usa el tabulador para no teclear el nombre largo. Con **1920 × 1080** y poco peso basta (la imagen se guarda en el historial de git).

> 💡 Si el diálogo "Guardar como" del navegador no deja guardar (ver [apartado 3](#s3)), copia la dirección de la imagen con clic derecho → *Copy image address* y descárgala desde la terminal. Sirve la dirección **de la imagen** (acaba en `.jpg`), no la de la página que la muestra:
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

> 💡 Si la pantalla es de otra proporción que la imagen (por ejemplo, 16:10 frente a 16:9), se recortan los lados y puede parecer descentrada. Para ver la resolución real: `hyprctl monitors`, y las capas con `hyprctl layers`.

> 💡 El fondo actual tiene tonos azulados y verdosos que chocan con la paleta cálida del tema. Está pendiente elegir uno de tonos marrones o tintarlo hacia sepia ([apartado 14](#s14)).

> ⚠️ Cuidado con las mayúsculas: `Quickshell`, no `Quicksell`; `WlrLayershell`, no `Wlrlayershell`.

### 9.10 Barra y panel transparentes (islas flotantes)

En lugar de una franja entera, la barra y el panel lateral tienen la ventana **transparente**, y solo se ven los bloques redondeados (workspaces, música, reloj, volumen, red, iconos de la bandeja) flotando sobre el fondo. Basta con cambiar el color de la ventana raíz:

```qml
// Bar.qml y Dock.qml, en el PanelWindow
color: "transparent"
```

Para ajustar los bloques, se les da transparencia con un valor alfa en el color. Esos valores viven en el tema: `Theme.bgChip` (`#f04a382a`) para los chips de la barra y `Theme.bgPopup` (`#fa4a382a`) para los paneles desplegables; los dos primeros dígitos son la opacidad, de `00` a `ff`. Todos los chips llevan además un borde fino (`border.color: Theme.line`, `border.width: 1`) para que se distingan sobre un fondo oscuro, y miden **32 px** de alto ([9.2](#92-ficheros-de-configuración)).

> ⚠️ **Limitación conocida (barra superior):** la ventana transparente sigue ocupando su franja entera: **reserva espacio** (las ventanas no llegan al borde) y **bloquea los clics** sobre lo que haya debajo. Se resuelve con una máscara de entrada que limite la zona sensible a los bloques (pendiente, [apartado 14](#s14)).

> 💡 **El panel lateral ya la tiene resuelta:** `mask: Region { item: box }` limita la zona que recibe clics a la caja de iconos, así que el resto de la franja transparente deja pasar los clics. La franja de 34 px sigue reservada a propósito, para que las ventanas no pasen por debajo de los iconos. La misma técnica servirá para la barra superior.

### 9.11 Chip de música en la barra

A la derecha de los workspaces aparece un chip con lo que suena ahora, por ejemplo **`Andrea Bocelli - Con Te Partirò / Time To Say Goodbye`**, y tres botones. Funciona con **cualquier reproductor** que se anuncie por **MPRIS**, el estándar con el que los reproductores avisan al sistema de lo que reproducen: Spotify, VLC, mpv o el propio navegador (Brave anuncia los vídeos de YouTube).

| Elemento | Efecto |
|---|---|
| Primer botón | Canción anterior |
| Segundo botón | Pausa o reproducir (el icono cambia según el estado) |
| Tercer botón | Canción siguiente |
| Texto | «Canción - Artista», recortado a 180 px con `...`. **Al pulsarlo se abre o se cierra el panel del reproductor** ([9.14](#914-panel-del-reproductor)) |
| Sin reproductor | El chip no se muestra |

**Qué reproductor elige:** `Spotify` si está abierto; si no, el que esté sonando; si no, el primero de la lista.

**Cómo se recorta el texto:** se quita lo que va entre paréntesis (`(Live From ...)`), y solo se añade el artista si el título aún no lleva un guion. Los vídeos de YouTube ya traen «Artista - Canción» en el título, y su «artista» es el nombre del canal, por lo que no se añade.

**Comprobar que el reproductor se anuncia**, con `playerctl` ([apartado 12](#s12)) y algo sonando:

```bash
playerctl -l                                            # brave.instance46441
playerctl status                                        # Playing
playerctl metadata --format '{{artist}} - {{title}}'
```

`~/.config/quickshell/Player.qml`:

```qml
import Quickshell.Services.Mpris
import QtQuick

Rectangle {
    id: chip

    property bool opened: false

    function pickPlayer() {
        var list = Mpris.players.values
        var pick = null
        for (var i = 0; i < list.length; i++) {
            var p = list[i]
            if (p.identity === "Spotify")
                return p
            if (pick === null || (p.isPlaying && !pick.isPlaying))
                pick = p
        }
        return pick
    }

    function shortText() {
        if (!chip.player)
            return ""
        var t = chip.player.trackTitle || ""
        var a = chip.player.trackArtist || ""
        var i1 = t.indexOf("(")
        if (i1 > 0)
            t = t.substring(0, i1).trim()
        if (a !== "" && t.indexOf(" - ") < 0)
            return t + " - " + a
        return t
    }

    readonly property var player: pickPlayer()

    visible: player !== null
    height: 32
    width: row.implicitWidth + 20
    radius: Theme.radius
    color: Theme.bgChip
    border.color: Theme.line
    border.width: 1

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Item {
            width: 22
            height: 28

            Text {
                anchors.centerIn: parent
                text: "\uf048"
                color: Theme.fg
                font.family: Theme.fontIcons
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: if (chip.player) chip.player.previous()
            }
        }

        Item {
            width: 22
            height: 28

            Text {
                anchors.centerIn: parent
                text: chip.player && chip.player.isPlaying ? "\uf04c" : "\uf04b"
                color: Theme.fg
                font.family: Theme.fontIcons
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: if (chip.player) chip.player.togglePlaying()
            }
        }

        Item {
            width: 22
            height: 28

            Text {
                anchors.centerIn: parent
                text: "\uf051"
                color: Theme.fg
                font.family: Theme.fontIcons
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: if (chip.player) chip.player.next()
            }
        }

        Item {
            width: Math.min(label.implicitWidth, 180)
            height: 28

            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                elide: Text.ElideRight
                color: Theme.fg
                font.pixelSize: 12
                text: chip.shortText()
            }

            MouseArea {
                anchors.fill: parent
                onClicked: chip.opened = !chip.opened
            }
        }
    }
}
```

Se coloca en `Bar.qml` **fuera** del `Rectangle` del `wsBox` y justo **encima** de él, al mismo nivel. Lleva un `id` (`playerChip`) porque el panel del reproductor necesita su posición y su reproductor:

```qml
Player {
    id: playerChip
    anchors.left: wsBox.right
    anchors.leftMargin: 8
    anchors.verticalCenter: wsBox.verticalCenter
}

PlayerPanel {
    anchor.window: root
    anchor.rect.x: playerChip.x
    anchor.rect.y: root.height + 4
    visible: playerChip.opened && playerChip.player !== null
    player: playerChip.player
}

Rectangle {
    id: wsBox
    // ...
}
```

| Pieza | Función |
|---|---|
| `Mpris.players` | La lista de reproductores que se anuncian (módulo `Quickshell.Services.Mpris`) |
| `pickPlayer()` | Elige el reproductor, con preferencia por Spotify |
| `shortText()` | Compone el texto corto |
| `visible: player !== null` | Muestra el chip solo si hay reproductor |
| `opened` | Interruptor que abre y cierra el panel del reproductor |
| `"\uf048"`, `"\uf04b"`, `"\uf04c"`, `"\uf051"` | Iconos de anterior, reproducir, pausa y siguiente (fuente Nerd Font) |

> 💡 El chip usa el tema: los colores (`Theme.fg`, `Theme.bgChip`, `Theme.line`), el radio (`Theme.radius`) y la fuente de iconos (`Theme.fontIcons`) vienen de `Theme.qml` ([9.13](#913-tema-themeqml)). Si alguna línea de tu `Player.qml` difiere en detalles de este bloque, manda siempre el fichero del repositorio.

> 💡 Los títulos con corchetes (`[Official Video]`) no se recortan: solo se recorta lo que va entre paréntesis.

> ⚠️ **Spotify de escritorio en la VM:** el cliente (instalado con `sudo pacman -S spotify-launcher`) arranca, pero **no dibuja ventana ni se anuncia por MPRIS**, ni con `LIBGL_ALWAYS_SOFTWARE=1` ni con `--disable-gpu`; es una limitación de la máquina virtual sin GPU. El chip se prueba con **Brave** (un vídeo de YouTube) y debería reconocer a Spotify en hardware real. Cuidado con `spotify-launcher -- --opcion`: las opciones tras `--` se toman como una dirección (`--uri=`) y no se aplican.

> 💡 **Spotify web** (`open.spotify.com` en Brave) también se anuncia por MPRIS, pero necesita **Widevine** activado en `brave://settings/extensions` para reproducir.

> 💡 **La cola de canciones no se puede mostrar** con MPRIS: ni Spotify ni YouTube en Brave exponen la lista de pistas siguientes. Solo sería posible con la API web de Spotify, en hardware real ([apartado 14](#s14)).

### 9.12 Agenda de cuero del reloj

Al **pulsar el reloj** del centro de la barra se despliega, justo debajo y centrado, una **agenda de cuero abierta**, de doble página, como un libro:

| Elemento | Efecto |
|---|---|
| **Página izquierda: el mes** | Título del mes en versalitas con su año, doble filete, los días de la semana con los **domingos en rojo**, el día de hoy rodeado a tinta y el día elegido resaltado en dorado |
| `«` y `»` | Año anterior y siguiente |
| `‹` y `›` | Mes anterior y siguiente |
| «Volver a hoy» | Vuelve al mes y al día actuales |
| Pulsar un día | Abre **su página** a la derecha |
| **Página derecha: el día** | El número grande, el día de la semana y el mes, y debajo la lista de tareas de ese día |
| Una tarea | Casilla, texto y una **etiqueta de color** (Pendiente, Lectura o Música); al pulsarla se **tacha** y se atenúa |
| Puntos de color | Bajo los días que tienen algo apuntado, uno por etiqueta |
| Cinta roja y pestañas | El marcapáginas de la página derecha y las pestañas de índice de colores en el borde |
| Segundo clic en el reloj | Cierra la agenda (todavía no se cierra al pulsar fuera) |

> ⚠️ **Hoy es solo la parte visual.** La agenda está vacía («Nada apuntado para este día») y todavía **no se pueden añadir tareas ni se guarda nada**; el aviso al pie lo dice. La parte funcional (guardar en `~/.local/share/pikson/agenda.json`, añadir, tachar y borrar) está pendiente ([apartado 14](#s14)).

La ventana mide 664 × 410 px: una cubierta de cuero oscuro con un pespunte dorado y dos páginas de papel color vitela (310 × 386 px cada una), con una sombra en el lomo. El fichero completo está en `.config/quickshell/Calendar.qml`.

Cómo se organiza por dentro:

| Pieza | Función |
|---|---|
| `shown`, `today`, `selected` | El mes que se está viendo, la fecha de hoy y el día elegido |
| `agenda` | Un objeto cuyas claves son fechas (`año-mes-día`, con el mes empezando en 0) y cuyos valores son listas de tareas `{ t, tag, done }` |
| `tags` | Las etiquetas y su color: Pendiente (rojo), Lectura (verde azulado), Música (ocre) |
| `firstOffset`, `daysInMonth` | Día de la semana en que empieza el mes (lunes = 0) y su número de días |
| `selectedTasks` | Las tareas del día elegido |
| `dotsFor(día)` | Los colores de los puntos de un día |
| `toggle(i)` | Tacha o destacha una tarea (reasigna `agenda` para que la vista se actualice) |
| `seed()` | Crea tareas de ejemplo; **ya no se llama**, se deja por si hace falta probar |
| `goToday()` | Vuelve a hoy; se ejecuta también al abrir la agenda |

Se engancha al reloj con **tres inserciones en `Bar.qml`**:

**1.** Junto a `netOpen`, la propiedad que abre y cierra la agenda (**las dos deben existir**):

```qml
property bool netOpen: false
property bool calOpen: false
```

**2.** Dentro del `Text` del reloj (el que usa `Qt.formatDateTime(clock.date, ...)`), antes de su llave de cierre, el clic:

```qml
Text {
    anchors.centerIn: parent
    color: Theme.fg
    font.pixelSize: 15
    text: Qt.formatDateTime(clock.date, "ddd d MMM HH:mm:ss")

    MouseArea {
        anchors.fill: parent
        onClicked: root.calOpen = !root.calOpen
    }
}
```

**3.** Justo después del `Text` del reloj, **fuera** de él, la agenda, centrada bajo la barra:

```qml
Calendar {
    anchor.window: root
    anchor.rect.x: (root.width - implicitWidth) / 2
    anchor.rect.y: root.height + 4
    visible: root.calOpen
}
```

> ⚠️ **El `MouseArea` va dentro del `Text` del reloj.** Si queda fuera, su `anchors.fill: parent` cubre **toda la barra**: cualquier clic abre la agenda y los chips de volumen y de red dejan de responder.

> 💡 La hora de la barra sale del reloj del sistema: si va atrasada, ver [1.3](#13-zona-horaria-y-hora).

> 💡 **Colores con transparencia:** el día elegido usa `#99e2b564` (dorado a media opacidad). En QML el alfa va **delante**; `#e2b56499` sería rosa.

> 💡 Escribir texto en la agenda (para añadir tareas) puede exigir que la ventana **reciba el teclado**, y los paneles desplegables de Quickshell no siempre lo reciben en Hyprland. Habrá que probarlo antes de seguir, y quizá convertir la agenda en otro tipo de ventana ([apartado 14](#s14)).

### 9.13 Tema: `Theme.qml`

Toda la apariencia de Quickshell (colores, tamaños y fuentes) vive en **un solo fichero**, `~/.config/quickshell/Theme.qml`, que el resto de piezas consultan con el prefijo `Theme.` (`Theme.fg`, `Theme.bgChip`...). Es un *singleton*: QML lo carga una sola vez y no hace falta ningún `import` ni `qmldir`, porque está en la misma carpeta. Para cambiar el aspecto del escritorio, se edita este fichero y Quickshell recarga solo.

La paleta se llama **Pergamino nocturno**: marrones cálidos de fondo y letra color vainilla, como una biblioteca antigua de noche. Se eligió tras descartar otras (verdes y azules) por comodidad visual.

**Fuentes** (una serif para detalles elegantes y una monoespaciada para el resto):

```bash
sudo pacman -S --needed ttf-cormorant ttf-jetbrains-mono-nerd
fc-cache -f
fc-list | grep -i cormorant     # debe aparecer "Cormorant Garamond"
```

`~/.config/quickshell/Theme.qml`:

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

    // Lomos de los workspaces y su balda
    readonly property var spines: ["#8a3b32", "#3d5566", "#a8793f", "#5e3d52", "#6f4a32"]
    readonly property color wood: "#7a5638"

    readonly property int radius: 14
    readonly property int radiusSmall: 8

    readonly property string fontSerif: "Cormorant Garamond"
    readonly property string fontUi: "JetBrainsMono Nerd Font"
    readonly property string fontIcons: "JetBrainsMono Nerd Font"

    readonly property int sizeText: 12
    readonly property int sizeClock: 15
    readonly property int chipHeight: 28
}
```

| Propiedad | Para qué se usa |
|---|---|
| `bgChip` | Fondo de los chips de la barra (casi opaco) |
| `bgPopup` | Fondo de los paneles desplegables (red, reproductor) |
| `bgCell` | Fondo de las casillas pequeñas (por ejemplo, las insignias de las fichas de red) |
| `line` | Bordes finos |
| `fg` | Texto principal (vainilla) |
| `fgMuted` | Texto secundario y etiquetas |
| `accent` | El color de énfasis (dorado): lomo activo, anillo de señal |
| `accent2` | Segundo énfasis (terracota): al pasar el ratón por la bandeja |
| `ok` | Estado correcto (verde apagado) |
| `fgOnAccent` | Texto que va **sobre** `accent` o sobre el latón |
| `spines` | Los cinco colores de los lomos de los workspaces (burdeos, azul petróleo, ocre, ciruela y cuero) |
| `wood` | La madera: la balda de los lomos y el marco cuadrado del reproductor |
| `radius`, `radiusSmall` | Esquinas de paneles y chips, y de las casillas pequeñas |
| `fontSerif`, `fontUi`, `fontIcons` | Tipografías: serif de detalle, texto y iconos |
| `sizeText`, `sizeClock`, `chipHeight` | Tamaños de letra y altura de los chips (hoy los chips se miden en cada fichero: 32; está pendiente unificarlos aquí) |

Uso en cualquier pieza:

```qml
Rectangle {
    color: Theme.bgChip
    radius: Theme.radius
    border.color: Theme.line
    border.width: 1

    Text { color: Theme.fg; text: "Hola" }
}
```

> ⚠️ **Ninguna propiedad puede llamarse `on` + mayúscula** (`onAccent`, `onClick`...): QML la toma por un manejador de señal y falla con `Cannot assign a value to a signal`. Por eso el color del texto sobre el dorado se llama `fgOnAccent` y no `onAccent`.

> 💡 **Formato de color:** en QML es `#AARRGGBB` (el alfa va **delante**: `#f04a382a` es casi opaco). En Hyprland es `rgba(RRGGBBAA)` (el alfa va **detrás**).

> 💡 **Cambiar los colores = editar este fichero.** Quickshell se actualiza al guardar. Pero el terminal ([5.2](#52-configuración-propia-kittyconf)) y los bordes de las ventanas ([apartado 8](#otros-ajustes-de-hyprlandlua-bordes-y-separación)) tienen sus propias copias de la paleta y hay que cambiarlos aparte.

> 💡 Los paneles del reproductor, de la red y de la agenda usan además algunos **colores propios** (los degradados del latón, el papel vitela, el cuero de la cubierta) escritos directamente en sus ficheros. Pasarlos al tema, para tener un único punto de verdad, está pendiente ([apartado 14](#s14)).

### 9.14 Panel del reproductor

Al **pulsar el texto de la canción** en el chip de música se despliega, bajo el chip, un **retrato con marco** y una **placa de latón**. Un segundo clic en el texto lo cierra.

| Elemento | Qué hace |
|---|---|
| **Marco** | Depende de la carátula: si es **cuadrada** (Spotify), un marco de **madera con paspartú crema**; si es **de vídeo 16:9** (YouTube), un marco **dorado clásico con cuatro remaches** en las esquinas |
| **Disco dorado** | Si no hay carátula, un disco de latón con sus surcos |
| **Placa de latón** | El título en versalitas (hasta dos líneas), el artista en cursiva y el icono de la fuente |
| **Icono de la fuente** | YouTube (`\uf16a`) si es un navegador, Spotify (`\uf1bc`) o una nota musical (`\uf001`) |
| **Barra de progreso** | Con pomo y los tiempos (`7:44` y `13:52`); se **arrastra** y al soltar salta a ese punto |
| **Controles** | Anterior, reproducir/pausa (en un disco oscuro), siguiente y **bucle** |
| **Bucle** | Tres estados: apagado, repetir canción (se enciende con un «1») y repetir lista (se enciende) |

El panel es el fichero `.config/quickshell/PlayerPanel.qml`. Se conecta a `Bar.qml` con el bloque de [9.11](#911-chip-de-música-en-la-barra) y recibe el reproductor con `player: playerChip.player`.

| Pieza | Función |
|---|---|
| `player` | El reproductor MPRIS que le pasa la barra |
| `wide` | Es verdadero cuando la carátula tiene una proporción mayor de 1,3: activa el marco dorado y los remaches |
| `hasLength` | Verdadero si el reproductor informa de la duración: muestra la barra de progreso |
| `frac` | La posición relativa (de 0 a 1), o la del arrastre en curso |
| `Timer` (500 ms) | Llama a `player.positionChanged()` mientras suena y el panel está abierto: **la posición no se actualiza sola** |
| `MouseArea` de la barra | Mientras se arrastra, guarda la fracción en `dragFrac`; al soltar, ejecuta `player.position = fracción × duración` si `canSeek` es verdadero |
| `nextLoop()` | Recorre `MprisLoopState.None → Track → Playlist → None` |

```qml
function nextLoop() {
    if (!panel.player || !panel.player.loopSupported)
        return
    var s = panel.player.loopState
    if (s === MprisLoopState.None)
        panel.player.loopState = MprisLoopState.Track
    else if (s === MprisLoopState.Track)
        panel.player.loopState = MprisLoopState.Playlist
    else
        panel.player.loopState = MprisLoopState.None
}
```

> ⚠️ **El bucle se ve atenuado con Brave:** el navegador no ofrece el control de repetición por MPRIS (`loopSupported` es falso), así que el botón queda apagado. Con **Spotify real**, en hardware físico, sí funcionará.

> ⚠️ **El icono de YouTube es `\uf16a`, no `\uf167`.** Este último sale como un rombo en JetBrains Mono Nerd Font. Antes de usar un icono nuevo, se prueba en kitty: `printf '\uf16a  \uf1bc  \uf001\n'`.

> 💡 La barra de progreso solo aparece si el reproductor informa de su duración (`lengthSupported`). Los vídeos de Brave la dan; algunos directos, no.

> 💡 Las carátulas de YouTube Music vienen en 16:9 con franjas laterales de color. El marco dorado las recoge sin recortarlas.

---

<a id="s10"></a>
## 10. 📦 Programas instalados

Los programas se instalan automáticamente con las listas de paquetes ([apartado 13](#s13)). Se abren desde la terminal o con sus atajos, y no desde el panel lateral. Notas de uso:

| Programa | Cómo abrirlo | Nota |
|---|---|---|
| Kitty | `Super + Enter` | |
| Brave | `Super + B` | No usa la bandeja: se cierra con su **X** o con `Super + Retroceso`. Lo que reproduce (YouTube, por ejemplo) aparece en el chip de música |
| Discord | `Super + D` | Al cerrar la ventana queda en la bandeja ([9.4](#94-bandeja-del-sistema-panel-lateral)); clic derecho → **Cerrar** lo termina del todo. Necesita ≈ 940 px de ancho: en pantalla dividida puede recortarse ([apartado 8](#otros-ajustes-de-hyprlandlua-monitor-escala-y-frecuencia)) |

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

> ⚠️ Los datos personales (la futura `agenda.json`, `libros.json`...) **viven fuera del repositorio**, en `~/.local/share/pikson/`, y no se suben.

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

> 💡 `git status` solo refleja lo último que git descargó, no el estado actual de GitHub. Para consultar si hay novedades sin mezclar nada: `git fetch` y después `git status` (indicará `behind` si hay cambios remotos). Si `git fetch` no imprime nada y `git status` sigue limpio, local y remoto coinciden.

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

### wpctl

Consulta y controla el audio con PipeWire/WirePlumber:

| Comando | Efecto |
|---|---|
| `wpctl status` | Dispositivos de audio, entradas y salidas |
| `wpctl get-volume @DEFAULT_AUDIO_SINK@` | Volumen de la salida predeterminada |
| `wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%` | Fija el volumen |
| `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` | Alterna el silencio |

> 💡 Los nombres con arrobas (`@DEFAULT_AUDIO_SINK@`) conviene **copiarlos y pegarlos**: `SINK` se teclea mal con facilidad.

### busctl

Consulta el bus de mensajes del sistema (D-Bus). Lo usa `trayquit.sh` ([9.4](#94-bandeja-del-sistema-panel-lateral)) para averiguar qué aplicación hay detrás de cada icono de la bandeja; viene con systemd y no hace falta instalarlo:

| Comando | Efecto |
|---|---|
| `busctl --user list` | Servicios activos en el bus de la sesión |
| `busctl --user list \| grep -i mpris` | Reproductores que se anuncian por MPRIS |

### playerctl

Consulta y controla los reproductores que se anuncian por MPRIS (Brave, Spotify, VLC...). Es la herramienta que sirve para comprobar que un reproductor llegará al chip de música ([9.11](#911-chip-de-música-en-la-barra)):

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
| `hyprctl clients` | Las ventanas abiertas: clase, tamaño, posición, `pid` y si usan XWayland |
| `hyprctl layers` | Las capas de Quickshell (barra, panel, fondo) |
| `hyprctl reload` | Recarga la configuración |

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

> 💡 El cambio de shell es **un ajuste del sistema** (`/etc/passwd`), no un fichero del repositorio: git no lo guarda ni lo restaura. Con el `.zshrc` se clona la configuración de zsh, pero **en cada equipo nuevo hay que repetir `chsh`**.

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

**Cambia la shell a zsh** (`chsh -s /usr/bin/zsh`; este ajuste **no viaja con el repositorio**) y **cierra la sesión del TTY** (`exit`) para iniciarla de nuevo: salir de Hyprland no basta ([apartado 12](#s12)). Con el `.zprofile` copiado, Hyprland arranca solo tras el login ([apartado 4.1](#41-arranque-automático-de-hyprland)); si no, entra con `start-hyprland`. La barra (con los lomos de libros, el chip de música y la agenda), la bandeja del sistema y el fondo arrancan solos; la bandeja solo se ve cuando hay alguna aplicación en segundo plano, y el chip de música cuando hay algo sonando.

| Fichero | Contenido |
|---|---|
| `pkglist.txt` | Paquetes de los repositorios oficiales |
| `aur-pkglist.txt` | Paquetes del AUR |
| `.config/` | Configuración de Hyprland, Quickshell (con su tema y sus paneles) y kitty |
| `zsh/.zshrc` | Configuración de zsh (se copia a `~/.zshrc`) |
| `zsh/.zprofile` | Arranque automático de Hyprland en el TTY1 (se copia a `~/.zprofile`) |

> ⚠️ Requiere `yay` instalado ([apartado 7](#s7)). Las listas incluyen `virtualbox-guest-utils`, que solo hace falta en una VM: retíralo en hardware real. En hardware real, quita también `LIBGL_ALWAYS_SOFTWARE=1` de `hyprland.lua` (terminal y Quickshell), y revisa la **escala** y la **frecuencia** del monitor ([apartado 8](#otros-ajustes-de-hyprlandlua-monitor-escala-y-frecuencia)): la escala `1.25` y el tamaño de letra de kitty en `10` están ajustados a la VM.

> 💡 Cada vez que instales algo nuevo, regenera las listas. Cuidado con el nombre: es `pkglist.txt` (con **g**); un `pklist.txt` crearía un fichero nuevo y distinto. La fuente serif del tema (`ttf-cormorant`, [9.13](#913-tema-themeqml)) debe aparecer en `pkglist.txt` tras regenerarla.
> ```bash
> pacman -Qqen > pkglist.txt
> pacman -Qqem > aur-pkglist.txt
> ```

---

<a id="s14"></a>
## 14. 📝 Pendiente

**Diseños decididos, por construir (en este orden)**

La estética es una **biblioteca antigua**: cuero, latón, madera y números romanos. Cada pieza tiene su boceto aprobado.

- [ ] **Barra «A · Latón y placas»**: vestir por fuera los chips de la barra con placas de latón con tornillos, como ya están el reproductor y el medallón. Se construye por pasos:
  1. Un componente nuevo, `Plate.qml` (rectángulo de 32 px de alto, esquinas de 6 px, degradado de latón, borde oscuro y dos tornillos), reutilizable en toda la barra
  2. **Música:** la raíz de `Player.qml` pasa a ser `Plate`, con la canción en versalitas serif y los iconos en tinta oscura
  3. **Reloj:** una placa con el día en versalitas serif («mié 11 nov») y la hora en letra de máquina pequeña; sigue abriendo la agenda al pulsar
  4. **Red:** una placa con un mini medallón (`ETH` o el icono de Wi-Fi) y la IP; sigue abriendo el panel
  5. **Volumen:** una placa con una mini perilla de latón cuya aguja gira según el volumen, y el porcentaje; conserva el clic y la rueda
- [ ] **Volumen: perilla de latón con números romanos**: se abre al pulsar el chip; la perilla se arrastra, muestra el porcentaje y lleva un botón de silencio; la rueda del ratón sobre el chip se mantiene
- [ ] **Red y Bluetooth, fases 2 y 3 (hardware real)**: conectar las pestañas Wi-Fi y Bluetooth a `nmcli` y `bluetoothctl` en lugar de los datos de ejemplo; «Escanear redes» y «Escanear dispositivos» (las fichas pasan a ser las redes o dispositivos disponibles, y al elegir uno el medallón muestra «Conectando…»); la ficha de contraseña para las redes con candado; y que el botón de latón encienda y apague de verdad
- [ ] **Agenda de cuero, fase 2 (funcional)**: guardar las notas, tareas y etiquetas en `~/.local/share/pikson/agenda.json` (fuera del repositorio, con `FileView` de `Quickshell.Io`); añadir una tarea con «+ Añadir…» eligiendo su etiqueta; tachar (ya funciona en memoria) y borrar con el botón derecho; los puntos de los días salen de los datos. **Riesgo:** escribir texto en un panel desplegable puede no recibir el teclado en Hyprland; si falla, convertir la agenda en una ventana de capa con `WlrLayershell.keyboardFocus` bajo demanda
- [ ] **Tarjeta de libros**: lo que estoy leyendo, con el porcentaje; los datos personales irían en `libros.json` (fuera del repositorio) con un `libros.example.json` de muestra
- [ ] **Reproductor:** probar el botón de bucle con Spotify real en hardware físico (en Brave se ve atenuado)
- [ ] **Cola de canciones**: solo posible con la API web de Spotify (MPRIS no la expone), en hardware real
- [ ] **Animaciones** (en este orden): 1) una transición común de apertura de los paneles (escala del 92 % al 100 % con aparición suave, aplicada al **contenido**, no al tamaño de la ventana); 2) un movimiento discreto en el medallón de red (las marcas del anillo que se iluminan en secuencia y un latido lento de los anillos de fondo); 3) cierres animados (hay que retener la ventana un instante mientras acaba la animación) y el giro de página de la agenda. Las animaciones en bucle solo deben ejecutarse **mientras el panel está abierto**, porque en la VM, con renderizado por software, pueden ir entrecortadas y gastar CPU

**Tema y estética**

- [ ] Usar los tamaños y fuentes del tema en todas las piezas (`Theme.sizeText`, `Theme.sizeClock`, la altura de los chips) y poner el reloj en la fuente serif (`Theme.fontSerif`)
- [ ] Pasar al tema los colores propios de los paneles (el degradado del latón, el papel vitela, el cuero de la cubierta)
- [ ] Fondo de pantalla de tonos cálidos, o tintar el actual hacia sepia
- [ ] Comprobar en `hyprland.lua` las esquinas redondeadas de las ventanas (`rounding`, unos 14 para casar con `Theme.radius`) y la sombra (`0xee1a110d`)
- [ ] Una única fuente de colores para Quickshell, kitty y Hyprland (hoy están copiados en tres sitios)
- [ ] Desenfoque de las ventanas (es pesado en la VM)

**Otras mejoras de la barra**

- [ ] Tiempo (meteorología) en la barra
- [ ] Panel de audio con salida y micrófono lado a lado, y silencio para cada uno
- [ ] Panel de notificaciones con avisos emergentes e historial
- [ ] Gestor de pantalla para elegir resolución, frecuencia y escala del monitor físico (hardware real)
- [ ] Piezas nuevas: CPU y RAM, título de ventana activa y menú de apagado

**Escritorio**

- [ ] Máscara de entrada en la barra superior (que los huecos no bloqueen clics ni reserven espacio)
- [ ] Cerrar los paneles al pulsar fuera (red, reproductor, agenda y los que vengan)
- [ ] Distribución de las ventanas: Discord necesita ≈ 940 px de ancho; decidir entre Discord a pantalla completa en su propio workspace o una distribución con una ventana más ancha
- [ ] Lanzador de aplicaciones
- [ ] Gestor de archivos y diálogos de archivos de GTK (se ven mal en la VM)
- [ ] Pantalla de bloqueo
- [ ] Fusionar `net.sh` y `netinfo.sh` en un único script
- [ ] Quitar el registro de depuración de la línea de arranque de Quickshell

**Repositorio y hardware real**

- [ ] Instalar Spotify de escritorio y probarlo (en la VM no dibuja ventana); el chip de música ya lo reconocerá
- [ ] Frecuencia del monitor (165 Hz) y revisión de la escala del monitor
- [ ] Probar el Wi-Fi y el Bluetooth (`bluez`, `bluez-utils`) con el panel medallón, y revisar el volumen y el silencio con el rango completo
- [ ] Regenerar `pkglist.txt` y `aur-pkglist.txt` (debe aparecer `ttf-cormorant`)
- [ ] GNU Stow para enlazar configuraciones (incluidos `zsh/.zshrc` y `zsh/.zprofile`)
- [ ] Script `install.sh` que automatice este manual, preguntando si es una **VM o un equipo real** para aplicar o quitar lo que depende de ello: `virtualbox-guest-utils`, `LIBGL_ALWAYS_SOFTWARE=1`, la escala y la frecuencia del monitor
- [ ] Probar el manual completo en una VM limpia
- [ ] Login gráfico (SDDM, greetd con un greeter o uno propio con Quickshell), quitando el bloque de `~/.zprofile`

**A largo plazo: un USB instalador con mi Arch**

La idea es un USB booteable, como el de Windows 10 o el de Arch, pero que **instale mi entorno completo** (Hyprland, Quickshell, dotfiles y paquetes) en el disco de cualquier equipo. **No** consiste en clonar la VM, que no es portable (arrastra los controladores de VirtualBox y los identificadores de disco). No se empieza hasta tener el escritorio terminado.

- [ ] 1. Terminar el escritorio, subirlo a GitHub y regenerar las listas de paquetes
- [ ] 2. Escribir `install.sh` (ver arriba) y reutilizarlo como base de todo lo demás
- [ ] 3. Un instalador con mi configuración: un script con `archinstall` (disco, usuario, contraseña, idioma, zona horaria y teclado US) más `install.sh`, o bien **Calamares** (asistente gráfico tipo Windows, más trabajo). Las contraseñas y el usuario se piden al instalar y **nunca** viajan en la imagen
- [ ] 4. Construir la ISO con **archiso** (perfil `releng` más la lista de paquetes y el instalador). Decidir entre instalación **online** (ISO pequeña que descarga al instalar; los paquetes del AUR se compilan o se sirven desde un repositorio propio) y **offline** (ISO grande con todo, con el AUR compilado antes en un repositorio local)
- [ ] 5. Grabarla con `dd` en un USB y probarla primero en una VM limpia y luego en hardware real (Wi-Fi, Bluetooth, tarjeta gráfica, UEFI). El *Secure Boot* no funciona con estas ISO

> ⚠️ Cuidados: no meter tokens (`gh`), contraseñas ni datos personales en la imagen; Arch es de actualización continua, así que la ISO caduca y hay que reconstruirla de vez en cuando; y lo ajustado a la VM no debe llegar a equipos reales.
