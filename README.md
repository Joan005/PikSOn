# 🎩 PikSOn — Arch Linux + Hyprland

Guía de instalación **manual (sin script)** de mi entorno de trabajo en Arch Linux con Hyprland y Quickshell.

## 📑 Índice
1. [Instalar Arch Linux](#1--instalar-arch-linux)
2. [Instalar Hyprland](#2--instalar-hyprland)
3. [Ajustes para máquina virtual (VirtualBox)](#3--ajustes-para-máquina-virtual-virtualbox)
4. [Primer arranque](#4--primer-arranque)
5. [Terminal: kitty](#5--terminal-kitty)
6. [Editor de texto](#6--editor-de-texto)
7. [Navegador Brave y atajo de teclado](#7--navegador-brave-y-atajo-de-teclado)
8. [Atajos de teclado personalizados](#8--atajos-de-teclado-personalizados)
9. [Quickshell: barra, panel lateral y fondo](#9--quickshell-barra-panel-lateral-y-fondo)
10. [Programas instalados](#10--programas-instalados)
11. [Git y GitHub](#11--git-y-github)
12. [Herramientas de apoyo](#12--herramientas-de-apoyo)
13. [Restaurar el entorno en otro equipo](#13--restaurar-el-entorno-en-otro-equipo)
14. [Estructura del repositorio](#14--estructura-del-repositorio)
15. [Pendiente](#15--pendiente)

---

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

> 💡 Los programas que dibujan con OpenGL (kitty, Quickshell) fallan en VirtualBox con errores como `invalid arguments for wl_surface#attach` o `Could not create EGL surface`. La solución es la variable `LIBGL_ALWAYS_SOFTWARE=1` (apartados [5](#5--terminal-kitty) y [9](#9--quickshell-barra-panel-lateral-y-fondo)). **No debe usarse en hardware real.**

> 💡 En la VM solo se puede probar la conexión **por cable** (adaptador virtual). El Wi-Fi y el Bluetooth requieren hardware real.

> 💡 El audio virtual de VirtualBox tiene límites (volumen mínimo ≈ 45 % y silencio sin efecto): ver [9.8](#98-chip-de-volumen-en-la-barra).

> 💡 Los diálogos de archivos de GTK (por ejemplo, "Guardar como" en Brave) pueden verse mal en la VM: lista de la raíz del sistema aunque la ruta indique otra carpeta, nombres cortados y botones que no responden. Si no se puede guardar, descarga con `curl` ([9.9](#99-fondo-de-pantalla)).

---

## 4. 🚀 Primer arranque

Desde el TTY:

```bash
start-hyprland
```

> ⚠️ Entra **siempre con `start-hyprland`**, también al volver a entrar tras salir de la sesión. Arrancar `Hyprland` directamente funciona, pero muestra el aviso *"Hyprland was started without start-hyprland. This is strongly discouraged unless you are in a debugging environment"*: el lanzador prepara el entorno de la sesión y vigila el proceso.

---

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

`~/.config/kitty/kitty.conf`:

```conf
# tipografia
font_family     JetBrainsMono Nerd Font Mono
font_size       8.0

# aspecto
background_opacity      0.5
window_padding_width    10
cursor_shape    beam
scrollback_lines        10000
confirm_os_window_close 0
enable_audio_bell       no

# colores
foreground      #cdd6f4
background      #2a2725
selection_foreground    #1e1e2e
selection_background    #f5e0dc
cursor  #f5e0dc
cursor_text_color       #1e1e2e
url_color       #f5e0dc
```

Abre una terminal nueva (`Super + Enter`) o recarga la actual con **`Ctrl + Shift + F5`**.

| Línea | Qué controla |
|---|---|
| `foreground` | Color del **texto** |
| `background` | Color del **relleno** de la ventana |
| `background_opacity` | Transparencia: `1.0` opaco, `0.5` mitad, valores menores = más transparente |
| `font_size` | Tamaño de letra (8 = compacto) |

> 💡 **Probar en caliente** (temporal, no toca el fichero): `Ctrl + Shift + +` / `-` cambian el tamaño de letra, y `Ctrl + Shift + A` seguido de `L` (más transparente), `M` (menos) o `D` (valor del fichero) cambian la opacidad.

> 💡 Si no se ve el color elegido, suele ser la transparencia: con `background_opacity 0.5` la imagen de fondo domina. Sube el valor a 0.8 para que el color del terminal se note.

> 💡 No mezcles `foreground` y `background`: un gris pensado para el texto puesto en `background` da una ventana pálida.

> 💡 La paleta ANSI de 16 colores (`color0` ... `color15`, los que usan `ls`, `git` o los mensajes de error) no está definida: kitty usa la suya por defecto. Se puede añadir más adelante, o moverla a un fichero aparte y cargarla con `include`.

> 💡 Si el resultado de `kitty` muestra errores de configuración: `kitty --debug-config 2>&1 | head -20`.

---

## 6. ✏️ Editor de texto

Instalamos **nano**, un editor de texto sencillo para terminal:

```bash
sudo pacman -S --needed nano
```

Uso básico: `Ctrl+O` guarda, `Ctrl+X` sale y `Ctrl+W` busca.

### Reemplazar un fichero entero en nano

| Paso | Atajo |
|---|---|
| Ir al principio del fichero | `Alt + \` |
| Cortar desde el cursor hasta el final (lo deja vacío) | `Alt + T` |
| Pegar el contenido nuevo | `Ctrl + Shift + V` (o clic derecho / `Shift + Insert`) |
| Guardar y salir | `Ctrl + O`, `Enter`, `Ctrl + X` |

> ⚠️ Pega **solo el contenido del fichero**. Las líneas `cat > fichero <<'EOF'` y `EOF` son parte de otro método (escribir desde la terminal) y **no deben pegarse dentro de nano**: `EOF` quedaría escrito en el fichero y lo rompería.

> 💡 Para ficheros largos, también es fiable escribirlos desde la terminal con `cat > fichero <<'EOF'` ... `EOF`, que evita las erratas de teclear a mano.

> ⚠️ Si editas un fichero **por fuera** (con `sed`, por ejemplo) mientras sigue abierto en nano, el aviso **Modified** indica que nano tiene su propia copia sin guardar: al guardar desde nano, **sobrescribirá** el cambio externo. Cierra nano antes, o corrige dentro de nano (`Ctrl + \` busca y reemplaza).

### Números de línea

`Alt + #` (es decir, `Alt + Shift + 3` en un teclado US) **muestra u oculta** la numeración, y se repite para alternarla. Es muy útil con los avisos de Quickshell, que citan fichero, línea y columna (`@Bar.qml[196:11]`). Para dejarla siempre activa:

```bash
echo "set linenumbers" >> $HOME/.nanorc
```

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
| `Super + Enter` | Abrir terminal (kitty) | `hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))` |
| `Super + B` | Abrir Brave | `hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave"))` |
| `Super + D` | Abrir Discord | `hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("discord"))` |
| `Super + Retroceso` | Cerrar la ventana activa | `hl.bind(mainMod .. " + BACKSPACE", hl.dsp.window.close())` |
| `Super + Shift + E` | Salir de Hyprland | `hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())` |

> 💡 `Super + Q` queda libre (antes abría la terminal y `Super + M` salía de Hyprland, ambos sustituidos).

> 💡 La configuración generada ya incluye las teclas multimedia (volumen, brillo y reproducción). Para que funcionen, deben estar instalados `wpctl` (wireplumber, [apartado 1.2](#12-audio-pipewire)), `brightnessctl` y `playerctl`.

---

## 9. 🧩 Quickshell: barra, panel lateral y fondo

**Quickshell** es un kit para construir la interfaz del escritorio (barras, paneles, widgets) con QML. Aquí se usa para una barra superior, un panel lateral con aplicaciones y el fondo de pantalla.

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
| `Wallpaper.qml` | Fondo de pantalla (una ventana en la capa `Background`) |
| `wallpaper.jpg` | La imagen del fondo |
| `Bar.qml` | Barra superior: contenedor fijo de workspaces, reloj, chips de volumen y de red y panel desplegable de red |
| `Dock.qml` | Panel lateral derecho con botones de aplicaciones (Brave, Discord) |
| `scripts/net.sh` | Resumen de la red para el chip (`tipo\|dispositivo\|ip`) |
| `scripts/netinfo.sh` | Detalle de la red para el panel desplegable (`clave=valor`) |

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

> 💡 Los recuadros numerados de la izquierda de la barra son los **workspaces** (escritorios virtuales) de Hyprland. Solo aparecen los que existen: se crean al usarlos (por ejemplo, `Super + 2`, según la configuración por defecto), y un clic sobre el número cambia de escritorio.

> 💡 Los workspaces van dentro de un **contenedor oscuro de anchura fija** (297 px), calculada para 10 recuadros: `10 × 24 px + 9 × 5 px de separación + 12 px de margen interior`. Así el espacio queda reservado aunque solo exista un workspace, y las piezas que se añadan a su derecha no se desplazan. Para anclar otra pieza junto a él, se usa `anchors.left: wsBox.right`.

> 💡 `Dock.qml` usa `margins { top: 0 }`: Quickshell ya reserva el espacio de la barra superior, y un margen manual lo duplicaría, dejando un hueco entre ambos paneles.

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

### 9.4 Añadir una aplicación al panel

En `Dock.qml`, añade una línea a la lista `model` (todas terminan en coma menos la última):

```qml
{ label: "Kt", cmd: ["kitty"] },
```

El programa debe estar instalado.

### 9.5 Solución de problemas

Si al editar un `.qml` aparece la ventana **"Config reload failed"**:

- Indica fichero, línea y columna del error (por ejemplo, `@Bar.qml[44:2]`).
- `Type Bar unavailable` en `shell.qml` es solo la **consecuencia**: la causa real está en la línea del fichero que se cita debajo.
- Si el mismo error se repite tras editar, probablemente **el fichero no ha cambiado**: comprueba su contenido con `head -3` o `cat -n fichero | sed -n '30,52p'`.
- Los avisos amarillos (`WARN ... ReferenceError`, `TypeError`) no impiden cargar, pero señalan una errata que rompe una función. Se ven con `qs log`.
- Cuando el aviso dice **"is not a type"**, compara letra por letra con una línea idéntica que sí funcione: `Stdio` y `Studio`, o `Rectangle` y `Rectagle`, se parecen demasiado a simple vista.

Erratas reales encontradas al montar esta configuración:

| Síntoma | Causa | Corrección |
|---|---|---|
| `module "QuickQuick" is not installed` | `import QuickQuick` | `import QtQuick` |
| `module "Quicksell" is not installed` | `import Quicksell` (falta la `h`) | `import Quickshell` |
| `Wlrlayershell` no se reconoce | La `L` de `layer` en minúscula | `WlrLayershell` (QML distingue mayúsculas) |
| `mondelData is not defined` | Letras cruzadas | `modelData` |
| `Property 'execDetacged' ... is not a function` | Errata | `execDetached` |
| `Repeat is not a type` | Falta el final | `Repeater` |
| `Rectagle is not a type` | Falta una `n` | `Rectangle` |
| `StudioCollector is not a type` | `Studio` por `Stdio` | `StdioCollector` |
| `Expected token ':'` | `porperty` por `property` | `property` |
| `Invalid property assignment: color expected` | Color sin almohadilla (`"89b4fa"`) | `"#89b4fa"` |
| `Property 'strings' ... is not a function` | Nombre inventado | `substring` |
| `panelWindth is not defined` | Errata | `panelWidth` |
| Un panel que no se coloca bajo el chip | Consecuencia del error anterior | Corregir la errata |
| `Vol undefined%` | La propiedad se declaró como `volPrecent` y se usa `volPercent` | Un único nombre en todo el fichero |
| `Vol --` con audio funcionando | Falta el bloque `Process { id: volProc ... }` (`volProc is not defined`) | Añadir el bloque completo |
| La rueda del volumen no hace nada | `"-1"` (número uno) en lugar de `"-l"` (letra ele) en `set-volume` | `"-l"` |

Y en los scripts de shell y en la terminal:

| Síntoma | Causa | Corrección |
|---|---|---|
| `argument 'TYPE,' not understood` | Espacio tras la coma en `-f DEVICE, TYPE,STATE` | `-f DEVICE,TYPE,STATE` (sin espacios) |
| `[: missing ']'` | Falta el espacio antes del corchete final | `[ -z "$dev" ]` |
| `Device 'dev' not found` | Falta el `$` | `"$dev"` |
| El chip dice "Sin red" con conexión | El script no es ejecutable | `chmod +x` |
| `'@DEFAULT_AUDIO_SNIK@' is not a valid number` | `SNIK` por `SINK` | `@DEFAULT_AUDIO_SINK@` |
| `'10%' is not a valid mute option` | `set-mute` con un porcentaje | `set-volume` para el volumen; `set-mute` solo admite `1`, `0` o `toggle` |
| `no such option: nonmatch` (al abrir zsh) | Esa opción no existe | `unsetopt nomatch` (ver [12](#12-herramientas-de-apoyo)) |

> 💡 Para ficheros largos, lo más seguro es reemplazarlos enteros ([apartado 6](#6--editor-de-texto)) en lugar de retocar llaves a mano.

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
> Git conserva este permiso al subir y clonar el repositorio.

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

### 9.7 Panel desplegable de red

Al **pulsar el chip**, se ilumina y bajo él se despliega una tarjeta con el detalle de la conexión: **conexión, dispositivo, IP, puerta de enlace, DNS, MAC y velocidad**. Un segundo clic la cierra.

Los datos los entrega un segundo script, `netinfo.sh`, en formato `clave=valor`. `~/.config/quickshell/scripts/netinfo.sh`:

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

En `Bar.qml`, el panel se compone de:

| Pieza | Función |
|---|---|
| `Process` (`infoProc`) | Ejecuta `netinfo.sh` y convierte cada línea `clave=valor` en una propiedad (`root.info`) |
| `Timer` (3 s) | Refresca los datos **solo mientras el panel está abierto** |
| `MouseArea` en el chip | Alterna `root.netOpen` |
| `PopupWindow` | La tarjeta, anclada a la barra con `anchor.window: root` |

Posición y tamaño de la tarjeta:

```qml
PopupWindow {
    id: netPanel
    readonly property int panelWidth: 300

    anchor.window: root
    anchor.rect.x: root.width - panelWidth - 8
    anchor.rect.y: root.height + 4
    implicitWidth: panelWidth
    implicitHeight: 215
    visible: root.netOpen
    color: "transparent"
    // ...
}
```

> 💡 La tarjeta cuelga del borde derecho (`root.width - panelWidth - 8`) y 4 px por debajo de la barra (`root.height + 4`). Si el panel aparece en la esquina izquierda, suele ser una errata en `panelWidth`.

> 💡 El panel no usa nombres de interfaz: sirve igual para cable y Wi-Fi. Con Wi-Fi, la velocidad aparecerá como `-` (no existe en `/sys/class/net/.../speed`) hasta que se añadan campos propios del Wi-Fi.

> 💡 El panel se cierra con un segundo clic en el chip; todavía no se cierra al pulsar fuera.

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

### 9.9 Fondo de pantalla

El fondo lo dibuja Quickshell, sin instalar nada más: una ventana que ocupa toda la pantalla en la capa `Background`, por detrás de todo. La imagen viaja con el repositorio, dentro de `~/.config/quickshell/`.

**1. Conseguir la imagen** con el nombre `wallpaper.jpg` en la carpeta de Quickshell:

```bash
mv $HOME/Downloads/IMAGEN.jpg $HOME/.config/quickshell/wallpaper.jpg
file $HOME/.config/quickshell/wallpaper.jpg      # debe decir "JPEG image data"
```

> 💡 `mv` mueve **y** renombra. Usa el tabulador para no teclear el nombre largo. Con **1920 × 1080** y poco peso basta (la imagen se guarda en el historial de git).

> 💡 Si el diálogo "Guardar como" del navegador no deja guardar (ver [apartado 3](#3--ajustes-para-máquina-virtual-virtualbox)), copia la dirección de la imagen con clic derecho → *Copy image address* y descárgala desde la terminal. Sirve la dirección **de la imagen** (acaba en `.jpg`), no la de la página que la muestra:
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

> ⚠️ Cuidado con las mayúsculas: `Quickshell`, no `Quicksell`; `WlrLayershell`, no `Wlrlayershell`.

### 9.10 Barra y panel transparentes (islas flotantes)

En lugar de una franja entera, la barra y el panel lateral tienen la ventana **transparente**, y solo se ven los bloques redondeados (workspaces, reloj, volumen, red, botones) flotando sobre el fondo. Basta con cambiar el color de la ventana raíz:

```qml
// Bar.qml y Dock.qml, en el PanelWindow
color: "transparent"
```

En `Dock.qml`, además: `implicitWidth: 30` y botones de 20 × 20. Para ajustar los chips, se les puede añadir un valor alfa al color, por ejemplo `#cc313244` (los dos primeros dígitos son la opacidad, de `00` a `ff`).

> ⚠️ **Limitación conocida:** la ventana transparente sigue ocupando su franja entera: **reserva espacio** (las ventanas no llegan al borde) y **bloquea los clics** sobre lo que haya debajo. Se resuelve con una máscara de entrada que limite la zona sensible a los bloques (pendiente, [apartado 15](#15--pendiente)).

---

## 10. 📦 Programas instalados

Los programas se instalan automáticamente con las listas de paquetes ([apartado 13](#13--restaurar-el-entorno-en-otro-equipo)). Notas de uso:

| Programa | Cómo abrirlo |
|---|---|
| Kitty | `Super + Enter` |
| Brave | `Super + B`, o el botón **Br** del panel |
| Discord | `Super + D`, o el botón **Dc** del panel |

> 💡 Desde una terminal, para abrir un programa sin dejarla ocupada: `discord & disown`.

---

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

```bash
git pull --no-rebase --no-edit
git add .
git commit -m "descripción del cambio"
git push
```

> 💡 Revisa siempre `git status` antes de hacer `git add .`.

> ⚠️ **No copies nunca `~/.config` completo** al repositorio: contiene el token de GitHub (`gh`), datos del navegador y sesiones. Copia solo las carpetas que configures a propósito. Elimina antes las copias `.bak` (`rm -f ~/.config/quickshell/*.bak`).

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

> 💡 `git status` solo refleja lo último que git descargó, no el estado actual de GitHub. Para consultar si hay novedades sin mezclar nada: `git fetch` y después `git status` (indicará `behind` si hay cambios remotos).

> 💡 Un `commit` sin `git add .` previo no incluye los cambios: los ficheros modificados aparecen en rojo en `git status` hasta que se añaden.

> 💡 Si se sube un fichero por error (por ejemplo, `pklist.txt` por teclear mal `pkglist.txt`), se retira con `git rm -f fichero` y un nuevo `commit` y `push`. Git conserva el historial, así que nada se pierde.

---

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

`exit` vuelve a bash. Para hacerla **la shell por defecto** (se aplica al iniciar sesión de nuevo; sal de Hyprland con `Super + Shift + E` y vuelve con `start-hyprland`):

```bash
chsh -s /usr/bin/zsh
echo $SHELL              # /usr/bin/zsh
```

Para volver a bash: `chsh -s /bin/bash`.

> 💡 Hyprland, Quickshell y los scripts (`net.sh`, `netinfo.sh`) usan `/bin/sh`, **no** la shell del usuario: cambiar a zsh no les afecta.

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
```

El fondo de pantalla viaja dentro de `.config/quickshell/` (`Wallpaper.qml` y `wallpaper.jpg`).

Si el equipo aún usa `systemd-networkd`, cambia a NetworkManager ([apartado 1.1](#11-red-networkmanager)). Activa también el audio ([apartado 1.2](#12-audio-pipewire)): los paquetes de PipeWire llegan con `pkglist.txt`, pero sus servicios de usuario se activan con `systemctl --user enable --now pipewire pipewire-pulse wireplumber`. Para usar zsh como shell: `chsh -s /usr/bin/zsh` ([apartado 12](#12-herramientas-de-apoyo)). Cierra sesión y entra de nuevo con `start-hyprland`: la barra, el panel y el fondo arrancan solos.

| Fichero | Contenido |
|---|---|
| `pkglist.txt` | Paquetes de los repositorios oficiales |
| `aur-pkglist.txt` | Paquetes del AUR |
| `.config/` | Configuración de Hyprland, Quickshell y kitty |
| `zsh/.zshrc` | Configuración de zsh (se copia a `~/.zshrc`) |

> ⚠️ Requiere `yay` instalado ([apartado 7](#7--navegador-brave-y-atajo-de-teclado)). Las listas incluyen `virtualbox-guest-utils`, que solo hace falta en una VM: retíralo en hardware real. En hardware real, quita también `LIBGL_ALWAYS_SOFTWARE=1` de `hyprland.lua` (terminal y Quickshell).

> 💡 Cada vez que instales algo nuevo, regenera las listas. Cuidado con el nombre: es `pkglist.txt` (con **g**); un `pklist.txt` crearía un fichero nuevo y distinto.
> ```bash
> pacman -Qqen > pkglist.txt
> pacman -Qqem > aur-pkglist.txt
> ```

---

## 14. 🗂️ Estructura del repositorio

```
PikSOn/
├── README.md                # Este manual
├── pkglist.txt              # Paquetes de los repositorios oficiales
├── aur-pkglist.txt          # Paquetes del AUR
├── zsh/
│   └── .zshrc               # Configuración de zsh (se copia a ~/.zshrc)
└── .config/                 # Configuraciones (se copian a ~/.config)
    ├── hypr/
    │   └── hyprland.lua     # Hyprland: atajos, terminal y arranque automático
    ├── kitty/
    │   └── kitty.conf       # Terminal: tipografía, colores y transparencia
    └── quickshell/
        ├── shell.qml        # Punto de entrada
        ├── Wallpaper.qml    # Fondo de pantalla
        ├── wallpaper.jpg    # Imagen del fondo
        ├── Bar.qml          # Barra superior (workspaces, reloj, volumen, chip y panel de red)
        ├── Dock.qml         # Panel lateral
        └── scripts/
            ├── net.sh       # Resumen de red para el chip (debe ser ejecutable)
            └── netinfo.sh   # Detalle de red para el panel (debe ser ejecutable)
```

| Elemento | Descripción |
|---|---|
| `README.md` | Manual de instalación y uso |
| `pkglist.txt` | Paquetes oficiales, generada con `pacman -Qqen` |
| `aur-pkglist.txt` | Paquetes del AUR, generada con `pacman -Qqem` |
| `zsh/.zshrc` | Shell zsh con plugins y starship |
| `.config/hypr/` | Configuración de Hyprland, incluidos los atajos |
| `.config/kitty/` | Configuración del terminal |
| `.config/quickshell/` | Barra superior, panel lateral, fondo y scripts de apoyo |

> 💡 Las carpetas de `.config/` replican la ruta que tendrían en `~/.config`. `zsh/` está fuera porque `.zshrc` vive en la carpeta personal; con GNU Stow se enlazará automáticamente.

---

## 15. 📝 Pendiente

- [x] Ajustar el hueco entre la barra superior y el panel lateral
- [x] Workspaces en la barra
- [x] Contenedor fijo para 10 workspaces
- [x] Cambio a NetworkManager
- [x] Chip de red en la barra (cable)
- [x] Panel desplegable de red al pulsar el chip (IP, puerta de enlace, DNS, MAC, velocidad)
- [x] Audio con PipeWire
- [x] Volumen en la barra
- [x] Fondo de pantalla
- [x] `kitty.conf` propio (tipografía, colores y transparencia)
- [x] Barra y panel lateral transparentes (islas flotantes)
- [x] Zsh, plugins y prompt (configurados y probados)
- [ ] Cambiar la shell por defecto a zsh (`chsh -s /usr/bin/zsh`)
- [ ] Máscara de entrada en la barra y el panel transparentes (que los huecos no bloqueen clics ni reserven espacio)
- [ ] Fondo de pantalla: la imagen no se ve centrada ni ocupando todo; revisar `hyprctl monitors` y `hyprctl layers`
- [ ] Transparencia del resto de ventanas desde Hyprland, y bordes, esquinas redondeadas y desenfoque (el desenfoque es pesado en la VM)
- [ ] Revisar el volumen: actualización instantánea al girar la rueda, y probar el silencio y el rango completo en hardware real (quizá un panel con barra deslizante)
- [ ] Cerrar el panel de red al pulsar fuera
- [ ] Pestañas Cable / Wi-Fi / Bluetooth en el panel
- [ ] Probar el Wi-Fi y el Bluetooth en hardware real (`bluez`, `bluez-utils`)
- [ ] Diseño radial del panel de red
- [ ] Fusionar `net.sh` y `netinfo.sh` en un único script
- [ ] Quitar el registro de depuración de la línea de arranque de Quickshell
- [ ] Iconos reales en el panel lateral
- [ ] Lanzador de aplicaciones
- [ ] Gestor de archivos y diálogos de archivos de GTK (se ven mal en la VM)
- [ ] Pantalla de bloqueo
- [ ] Notificaciones
- [ ] Paleta ANSI de 16 colores en kitty
- [ ] GNU Stow para enlazar configuraciones (incluida `zsh/.zshrc`)
- [ ] Script `install.sh` que automatice este manual
- [ ] Probar el manual completo en una VM limpia
