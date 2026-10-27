# 🎩 PikSOn — Arch Linux + Hyprland

Guía de instalación **manual (sin script)** de mi entorno de trabajo en Arch Linux con Hyprland y Quickshell.

## 📑 Índice
1. [Instalar Arch Linux](#1--instalar-arch-linux)
2. [Instalar Hyprland](#2--instalar-hyprland)
3. [Ajustes para máquina virtual (VirtualBox)](#3--ajustes-para-máquina-virtual-virtualbox)
4. [Primer arranque](#4--primer-arranque)
5. [Terminal: solución si kitty no abre](#5--terminal-solución-si-kitty-no-abre)
6. [Editor de texto](#6--editor-de-texto)
7. [Navegador Brave y atajo de teclado](#7--navegador-brave-y-atajo-de-teclado)
8. [Atajos de teclado personalizados](#8--atajos-de-teclado-personalizados)
9. [Quickshell: barra y panel lateral](#9--quickshell-barra-y-panel-lateral)
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

> 💡 Los programas que dibujan con OpenGL (kitty, Quickshell) fallan en VirtualBox con errores como `invalid arguments for wl_surface#attach` o `Could not create EGL surface`. La solución es la variable `LIBGL_ALWAYS_SOFTWARE=1` (apartados [5](#5--terminal-solución-si-kitty-no-abre) y [9](#9--quickshell-barra-y-panel-lateral)). **No debe usarse en hardware real.**

> 💡 En la VM solo se puede probar la conexión **por cable** (adaptador virtual). El Wi-Fi y el Bluetooth requieren hardware real.

---

## 4. 🚀 Primer arranque

Desde el TTY:

```bash
start-hyprland
```

> ⚠️ Entra **siempre con `start-hyprland`**, también al volver a entrar tras salir de la sesión. Arrancar `Hyprland` directamente funciona, pero muestra el aviso *"Hyprland was started without start-hyprland. This is strongly discouraged unless you are in a debugging environment"*: el lanzador prepara el entorno de la sesión y vigila el proceso.

---

## 5. 🔧 Terminal: solución si kitty no abre

En VirtualBox, kitty puede cerrarse al instante al pulsar `Super + Q` (atajo por defecto) por falta de OpenGL. Solución en tres pasos.

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

Sal con `Super + M` (atajo por defecto), vuelve a entrar con `start-hyprland` y abre foot con `Super + Q`.

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

Recarga saliendo con `Super + M` y ejecutando de nuevo `start-hyprland`. Prueba `Super + Q`.

> ⚠️ `LIBGL_ALWAYS_SOFTWARE=1` solo es necesario en la VM. **No lo uses en hardware real.**

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

> 💡 La configuración generada ya incluye las teclas multimedia (volumen, brillo y reproducción). Para que funcionen, deben estar instalados `wpctl` (wireplumber), `brightnessctl` y `playerctl`.

---

## 9. 🧩 Quickshell: barra y panel lateral

**Quickshell** es un kit para construir la interfaz del escritorio (barras, paneles, widgets) con QML. Aquí se usa para una barra superior y un panel lateral con aplicaciones.

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
| `Bar.qml` | Barra superior: contenedor fijo de workspaces, reloj, chip de red y panel desplegable de red |
| `Dock.qml` | Panel lateral derecho con botones de aplicaciones (Brave, Discord) |
| `scripts/net.sh` | Resumen de la red para el chip (`tipo\|dispositivo\|ip`) |
| `scripts/netinfo.sh` | Detalle de la red para el panel desplegable (`clave=valor`) |

`shell.qml`:

```qml
import Quickshell

ShellRoot {
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

Erratas reales encontradas al montar esta configuración:

| Síntoma | Causa | Corrección |
|---|---|---|
| `module "QuickQuick" is not installed` | `import QuickQuick` | `import QtQuick` |
| `mondelData is not defined` | Letras cruzadas | `modelData` |
| `Property 'execDetacged' ... is not a function` | Errata | `execDetached` |
| `Repeat is not a type` | Falta el final | `Repeater` |
| `Invalid property assignment: color expected` | Color sin almohadilla (`"89b4fa"`) | `"#89b4fa"` |
| `Property 'strings' ... is not a function` | Nombre inventado | `substring` |
| `panelWindth is not defined` | Errata | `panelWidth` |
| Un panel que no se coloca bajo el chip | Consecuencia del error anterior | Corregir la errata |

Y en los scripts de shell:

| Síntoma | Causa | Corrección |
|---|---|---|
| `argument 'TYPE,' not understood` | Espacio tras la coma en `-f DEVICE, TYPE,STATE` | `-f DEVICE,TYPE,STATE` (sin espacios) |
| `[: missing ']'` | Falta el espacio antes del corchete final | `[ -z "$dev" ]` |
| `Device 'dev' not found` | Falta el `$` | `"$dev"` |
| El chip dice "Sin red" con conexión | El script no es ejecutable | `chmod +x` |

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

> ⚠️ **No copies nunca `~/.config` completo** al repositorio: contiene el token de GitHub (`gh`), datos del navegador y sesiones. Copia solo las carpetas que configures a propósito.

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

Atajo opcional en `~/.bashrc`:

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
chmod +x $HOME/.config/quickshell/scripts/*.sh
```

Si el equipo aún usa `systemd-networkd`, cambia a NetworkManager ([apartado 1.1](#11-red-networkmanager)). Cierra sesión y entra de nuevo con `start-hyprland`: la barra y el panel arrancan solos.

| Fichero | Contenido |
|---|---|
| `pkglist.txt` | Paquetes de los repositorios oficiales |
| `aur-pkglist.txt` | Paquetes del AUR |
| `.config/` | Configuración de Hyprland y Quickshell |

> ⚠️ Requiere `yay` instalado ([apartado 7](#7--navegador-brave-y-atajo-de-teclado)). Las listas incluyen `virtualbox-guest-utils`, que solo hace falta en una VM: retíralo en hardware real. En hardware real, quita también `LIBGL_ALWAYS_SOFTWARE=1` de `hyprland.lua` (terminal y Quickshell).

> 💡 Cada vez que instales algo nuevo, regenera las listas:
> ```bash
> pacman -Qqen > pkglist.txt
> pacman -Qqem > aur-pkglist.txt
> ```

---

## 14. 🗂️ Estructura del repositorio

```
PikSOn/
├── README.md              # Este manual
├── pkglist.txt            # Paquetes de los repositorios oficiales
├── aur-pkglist.txt        # Paquetes del AUR
└── .config/               # Configuraciones (se copian a ~/.config)
    ├── hypr/
    │   └── hyprland.lua   # Hyprland: atajos, terminal y arranque automático
    └── quickshell/
        ├── shell.qml      # Punto de entrada
        ├── Bar.qml        # Barra superior (workspaces, reloj, chip y panel de red)
        ├── Dock.qml       # Panel lateral
        └── scripts/
            ├── net.sh     # Resumen de red para el chip (debe ser ejecutable)
            └── netinfo.sh # Detalle de red para el panel (debe ser ejecutable)
```

| Elemento | Descripción |
|---|---|
| `README.md` | Manual de instalación y uso |
| `pkglist.txt` | Paquetes oficiales, generada con `pacman -Qqen` |
| `aur-pkglist.txt` | Paquetes del AUR, generada con `pacman -Qqem` |
| `.config/hypr/` | Configuración de Hyprland, incluidos los atajos |
| `.config/quickshell/` | Barra superior, panel lateral y scripts de apoyo |

> 💡 Las carpetas de `.config/` replican la ruta que tendrían en `~/.config`. A medida que se configuren más programas, se añadirán aquí.

---

## 15. 📝 Pendiente

- [x] Ajustar el hueco entre la barra superior y el panel lateral
- [x] Workspaces en la barra
- [x] Contenedor fijo para 10 workspaces
- [x] Cambio a NetworkManager
- [x] Chip de red en la barra (cable)
- [x] Panel desplegable de red al pulsar el chip (IP, puerta de enlace, DNS, MAC, velocidad)
- [ ] Cerrar el panel de red al pulsar fuera
- [ ] Pestañas Cable / Wi-Fi / Bluetooth en el panel
- [ ] Probar el Wi-Fi y el Bluetooth en hardware real (`bluez`, `bluez-utils`)
- [ ] Diseño radial del panel de red
- [ ] Fusionar `net.sh` y `netinfo.sh` en un único script
- [ ] Quitar el registro de depuración de la línea de arranque de Quickshell
- [ ] Volumen en la barra
- [ ] Iconos reales en el panel lateral
- [ ] Lanzador de aplicaciones
- [ ] Fondo de pantalla
- [ ] Gestor de archivos
- [ ] Transparencia de ventanas
- [ ] Pantalla de bloqueo
- [ ] Notificaciones
- [ ] `kitty.conf` propio
- [ ] Zsh, plugins y prompt
- [ ] GNU Stow para enlazar configuraciones
- [ ] Script `install.sh` que automatice este manual
- [ ] Probar el manual completo en una VM limpia
