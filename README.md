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

---

## 4. 🚀 Primer arranque

Desde el TTY:

```bash
start-hyprland
```

> Según la versión también puede lanzarse con `Hyprland`.

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

Sal con `Super + M` (atajo por defecto), vuelve a entrar y abre foot con `Super + Q`.

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

### Reemplazar un fichero entero en nano

| Paso | Atajo |
|---|---|
| Ir al principio del fichero | `Alt + \` |
| Cortar desde el cursor hasta el final (lo deja vacío) | `Alt + T` |
| Pegar el contenido nuevo | `Ctrl + Shift + V` (o clic derecho / `Shift + Insert`) |
| Guardar y salir | `Ctrl + O`, `Enter`, `Ctrl + X` |

> ⚠️ Pega **solo el contenido del fichero**. Las líneas `cat > fichero <<'EOF'` y `EOF` son parte de otro método (escribir desde la terminal) y **no deben pegarse dentro de nano**: `EOF` quedaría escrito en el fichero y lo rompería.

> 💡 Para ficheros largos, también es fiable escribirlos desde la terminal con `cat > fichero <<'EOF'` ... `EOF`, que evita las erratas de teclear a mano.

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
| `Bar.qml` | Barra superior: contenedor fijo de workspaces de Hyprland y reloj |
| `Dock.qml` | Panel lateral derecho con botones de aplicaciones (Brave, Discord) |

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
- Los fallos habituales son una errata de una letra (`QuickQuick`, `mondelData`, `execDetacged`) o una llave `{ }` sin cerrar.
- Si el mismo error se repite tras editar, probablemente **el fichero no ha cambiado**: comprueba su contenido con `head -3` o `cat -n fichero | sed -n '30,52p'`.

> 💡 Para ficheros largos, lo más seguro es reemplazarlos enteros ([apartado 6](#6--editor-de-texto)) en lugar de retocar llaves a mano.

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
```

Cierra sesión y entra de nuevo en Hyprland: la barra y el panel arrancan solos.

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
        ├── Bar.qml        # Barra superior
        └── Dock.qml       # Panel lateral
```

| Elemento | Descripción |
|---|---|
| `README.md` | Manual de instalación y uso |
| `pkglist.txt` | Paquetes oficiales, generada con `pacman -Qqen` |
| `aur-pkglist.txt` | Paquetes del AUR, generada con `pacman -Qqem` |
| `.config/hypr/` | Configuración de Hyprland, incluidos los atajos |
| `.config/quickshell/` | Barra superior y panel lateral |

> 💡 Las carpetas de `.config/` replican la ruta que tendrían en `~/.config`. A medida que se configuren más programas, se añadirán aquí.

---

## 15. 📝 Pendiente

- [x] Ajustar el hueco entre la barra superior y el panel lateral
- [x] Workspaces en la barra
- [x] Contenedor fijo para 10 workspaces
- [ ] Quitar el registro de depuración de la línea de arranque de Quickshell
- [ ] Volumen en la barra
- [ ] Más piezas en la barra, a la derecha del contenedor de workspaces
- [ ] Iconos reales en el panel lateral
- [ ] Lanzador de aplicaciones
- [ ] Fondo de pantalla
- [ ] Gestor de archivos
- [ ] Transparencia de ventanas
- [ ] Pantalla de bloqueo
- [ ] Notificaciones
- [ ] `kitty.conf` propio






import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: root
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 25
    color: "#1e1e2e"

    // Estado de la red, actualizado por net.sh
    property string netType: "none"
    property string netDev: ""
    property string netIp: ""

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Process {
        id: netProc
        command: ["sh", "-c", "$HOME/.config/quickshell/scripts/net.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var p = this.text.trim().split("|")
                if (p[0] === "none" || p.length < 3) {
                    root.netType = "none"
                    root.netDev = ""
                    root.netIp = ""
                } else {
                    root.netType = p[0]
                    root.netDev = p[1]
                    root.netIp = p[2]
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: netProc.running = true
    }

    // Contenedor fijo de workspaces: reserva el espacio de 10 recuadros
    Rectangle {
        id: wsBox
        readonly property int cell: 24
        readonly property int gap: 5
        readonly property int slots: 10
        readonly property int pad: 6

        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: slots * cell + (slots - 1) * gap + 2 * pad
        height: 23
        radius: 7
        color: "#181825"

        Row {
            anchors.left: parent.left
            anchors.leftMargin: wsBox.pad
            anchors.verticalCenter: parent.verticalCenter
            spacing: wsBox.gap

            Repeater {
                model: Hyprland.workspaces

                Rectangle {
                    width: wsBox.cell
                    height: 19
                    radius: 5
                    color: modelData.focused ? "#89b4fa" : "#313244"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.id
                        color: modelData.focused ? "#1e1e2e" : "#cdd6f4"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelData.activate()
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        color: "#cdd6f4"
        font.pixelSize: 15
        text: Qt.formatDateTime(clock.date, "ddd d MMM HH:mm:ss")
    }

    // Derecha: chip de red
    Rectangle {
        id: netChip
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: netText.implicitWidth + 16
        height: 19
        radius: 5
        color: root.netType === "none" ? "#45475a" : "#313244"

        Text {
            id: netText
            anchors.centerIn: parent
            color: "#cdd6f4"
            font.pixelSize: 12
            text: root.netType === "none"
                  ? "Sin red"
                  : (root.netType === "ethernet" ? "Cable" : "Wi-Fi") + " · " + root.netIp.split("/")[0]
        }
    }
}
- [ ] Zsh, plugins y prompt
- [ ] GNU Stow para enlazar configuraciones
- [ ] Script `install.sh` que automatice este manual
- [ ] Probar el manual completo en una VM limpia
