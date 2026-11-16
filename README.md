# 🎩 PikSOn

Un escritorio **Arch Linux + Hyprland + Quickshell** con aire de biblioteca antigua de noche: marrones cálidos, letra color vainilla, dorado como único acento y una sola tipografía. Está pensado para instalarse con **un solo script** sobre un Arch recién instalado.

![El escritorio](capturas/escritorio.png)

---

## Qué es

| Pieza | Qué hace |
|---|---|
| **Hyprland** | El compositor (gestor de ventanas en mosaico), configurado en Lua |
| **Quickshell** | Construye la barra, los paneles y el dock con QML |
| **kitty** + **zsh** + **starship** | Terminal, shell y prompt |
| **Thunar** | Gestor de archivos, vestido como una extensión de la barra |
| **Brave**, **Discord**, **imv** | Navegador, chat y visor de imágenes |
| **PipeWire** y **NetworkManager** | Sonido y red |

**La estética** se llama *Pergamino nocturno*: fondo `#34261b`, texto `#f6ebcf`, acento dorado `#e2b564`. Todo el escritorio usa **JetBrains Mono Nerd Font**. El tema vive en un solo fichero (`Theme.qml`) y se repite, adaptado, en kitty, en los bordes de Hyprland y en Thunar.

> Se desarrolla y prueba en **VirtualBox**. El salto a un equipo real (arranque dual con Windows) está en marcha; ver la [hoja de ruta](#hoja-de-ruta).

---

## Qué incluye

### La barra «solo texto»

Sin cajas ni adornos: texto sobre un degradado suave, con un filete fino de latón debajo. De izquierda a derecha: **workspaces en números romanos** (I a V), el **chip de música**, el **reloj** (en el centro), el **tiempo**, el **volumen**, la **red**, la **campana de avisos**, la **tuerca de ajustes** y el **apagado**. Cada uno abre su panel al pulsarlo, y un clic fuera los cierra.

![La barra](capturas/barra.png)

### Música y letra sincronizada

El chip de música funciona con **cualquier reproductor MPRIS** (Spotify, VLC, el propio Brave con YouTube...). Siempre está visible: con miniatura, título y tiempo, o «Nada suena». Su panel muestra la carátula, el progreso y los controles, y la **letra sincronizada**, que se puede sacar a una columna fija a la derecha de la pantalla.

![Música y letra](capturas/musica.png)

> 🔒 Las letras vienen de [LRCLIB](https://lrclib.net). Solo se envían el **título y el artista**.

### Dock lateral oculto

En reposo no se ve. Al llevar el ratón al **borde derecho** aparece, con las **ventanas abiertas** (clic para llevarlas al frente, clic derecho para cerrarlas) y la **bandeja del sistema** (las apps que siguen en segundo plano, con un botón para cerrarlas del todo).

![El dock](capturas/dock.png)

### Calendario y agenda

Se abre al pulsar el reloj: el mes a la izquierda y las tareas del día a la derecha, con etiquetas de color. Las tareas se guardan en `~/.local/share/pikson/agenda.json`, **fuera del repositorio**.

![El calendario](capturas/calendario.png)

### Sonido, avisos, tiempo y red

- **Sonido:** salida y micrófono con su volumen y silencio, y la lista de dispositivos de salida.
- **Avisos:** Quickshell hace de servidor de notificaciones, con avisos emergentes, historial y «No molestar».
- **Tiempo:** el actual, las próximas 6 horas y 5 días (datos de Open-Meteo; solo se envían las coordenadas fijas de Barcelona).
- **Red:** un **medallón** de latón con los datos de la conexión. La pestaña de cable muestra datos reales; Wi-Fi y Bluetooth son, de momento, de ejemplo.

![El panel de red](capturas/red.png)

### Ajustes: gestión de pantallas

La **tuerca** abre el panel de Pantallas: un esquema a escala de los monitores, y selectores de **resolución, frecuencia, escala y rotación**. Con dos o más monitores se pueden **arrastrar** para colocarlos. Todo cambio pasa por **Aplicar**, con una **cuenta atrás de 15 segundos** que revierte sola si no se confirma, como en Windows. «Conservar y guardar» escribe `~/.config/hypr/monitors.lua`.

![Pantallas](capturas/pantallas.png)

### Thunar

El gestor de archivos (`Super + E`), con el mismo lenguaje visual que la barra: fondo semitransparente, menús de solo texto, selección dorada y la misma tipografía.

![Thunar](capturas/thunar.png)

---

## Instalación

El camino es: **instalar Arch con `archinstall`, clonar este repositorio y lanzar `install.sh`**.

### 0. Si es una máquina virtual (VirtualBox)

Con la máquina **apagada**, en *Configuración → Pantalla*:

| Opción | Valor |
|---|---|
| Controlador gráfico | **VMSVGA** |
| Aceleración 3D | **Habilitada** |
| Memoria de vídeo | **128 MB** |

> ⚠️ Sin esto, **Hyprland aborta al arrancar** y vuelve al `login:`. El script no puede cambiarlo desde dentro.

### 1. Instalar Arch

Arranca con la ISO oficial de Arch (grabada con Rufus en modo *Imagen DD*, o con Ventoy) y ejecuta `archinstall`, eligiendo:

| Apartado | Elección |
|---|---|
| Disco y cargador de arranque | A tu medida (GRUB si hay arranque dual) |
| Usuario | Con permisos de **superusuario** (`sudo`) |
| Teclado | **Inglés (US)** |
| Perfil | **Mínimo**, sin escritorio |
| Red | **NetworkManager** |
| **Paquetes adicionales** | **`git nano base-devel github-cli`** |

> ⚠️ Los paquetes adicionales se olvidan con facilidad. Sin `git`, no se puede clonar el repositorio.

### 2. Clonar y ejecutar

Reinicia, entra con tu usuario y, si el repositorio es privado, inicia sesión en GitHub (el código de 8 caracteres se introduce desde otro dispositivo):

```bash
gh auth login
git clone https://github.com/Joan005/PikSOn
cd PikSOn
bash install.sh --vm        # o --real en un equipo físico
```

Sin opción, el script pregunta si es una máquina virtual. Con `--dry-run` solo muestra lo que haría, sin cambiar nada. **No lo ejecutes como root.**

### 3. Qué hace el script

1. Actualiza el sistema e instala `base-devel`, `git` y `yay`.
2. Instala los paquetes de `pkglist.txt` y `aur-pkglist.txt`.
3. Copia la configuración (guardando antes una copia de lo existente en `~/.config-backup-FECHA`).
4. Activa NetworkManager y PipeWire, y fija la zona horaria y zsh como shell.
5. Aplica lo propio de **VM o equipo real** (la variable de renderizado por software, `virtualbox-guest-utils`...).
6. Ajusta GTK (tipografía, tema oscuro y cursor) con `gsettings`.

Todo queda registrado en `~/pikson-install.log`, con una lista de avisos al final.

### 4. Lo que queda a mano

Reiniciar; los **controladores de la GPU** si es un equipo real; ajustar los **monitores** desde la tuerca; y volver a iniciar sesión en Brave y Discord. Los datos personales (agenda, sesiones) no viajan con el repositorio.

### Cómo arranca el escritorio

Se entra por el **TTY1** con usuario y contraseña; el `~/.zprofile` lanza `start-hyprland` automáticamente. Si Hyprland falla, vuelve al `login:`: pasa al **TTY2** (`Ctrl derecho + F2` en VirtualBox), donde no se lanza, para ver el error con `start-hyprland`.

---

## Atajos de teclado

| Atajo | Acción |
|---|---|
| `Super + Enter` | Terminal (kitty) |
| `Super + E` | Gestor de archivos (Thunar) |
| `Super + B` | Brave |
| `Super + D` | Discord |
| `Super + Retroceso` | Cerrar la ventana activa |
| `Super + 1…5` | Ir al escritorio 1…5 |
| `Super + Shift + 1…5` | Mover la ventana al escritorio 1…5 |
| `Super + clic izquierdo` y arrastrar | Mover la ventana |
| `Super + clic derecho` y arrastrar | Redimensionar la ventana |
| `Super + Shift + E` | Salir de Hyprland |

---

## Estructura del repositorio

```
PikSOn/
├── README.md
├── install.sh              # el instalador
├── pkglist.txt             # paquetes oficiales (pacman -Qqen)
├── aur-pkglist.txt         # paquetes del AUR (pacman -Qqem)
├── capturas/               # imágenes de este README
├── zsh/                    # .zshrc y .zprofile
└── .config/
    ├── hypr/hyprland.lua   # Hyprland
    ├── kitty/kitty.conf    # terminal
    ├── gtk-3.0/            # aspecto de Thunar: settings.ini y gtk.css
    └── quickshell/         # barra, paneles, dock, tema y scripts
        ├── Theme.qml       # la paleta y las tipografías
        ├── Bar.qml         # la barra y el cerebro de los paneles
        ├── *Panel.qml, Calendar.qml, Dock.qml, ...
        └── scripts/        # red y monitores
```

> ⚠️ **`~/.config/hypr/monitors.lua` no está en el repositorio, a propósito:** lo genera el panel de Pantallas y es propio de cada equipo. De la carpeta de GTK solo se guardan `settings.ini` y `gtk.css`.

---

## Decisiones de diseño

- **Una sola tipografía** (JetBrains Mono Nerd Font) en todas partes. Se probó una serif y se descartó.
- **Barra «solo texto».** Se probaron lomos de libros y placas de latón; resultaban recargados.
- **Los paneles son sobrios** (fondo liso, filete fino, esquinas redondeadas), sin cuero ni latón.
- **El dock se oculta.** Antes era una cajita fija; ahora solo aparece al tocar el borde derecho.
- **Cerrar al pulsar fuera** se hace con una ventana transparente bajo la barra, porque `HyprlandFocusGrab` no funciona en este Hyprland.
- **Los monitores**: `hyprland.lua` carga `monitors.lua` con un respaldo (`pcall(dofile, ...)`), así que nunca se queda sin pantalla. Hyprland **solo acepta escalas con las que el tamaño lógico sea un entero** (1,5 no vale en una pantalla de 955 px de alto).
- **GTK:** su configuración por GSettings **manda sobre `settings.ini`**, por eso `install.sh` fija también `gsettings`.
- **`LIBGL_ALWAYS_SOFTWARE=1`** solo se usa en la máquina virtual; en un equipo real se quita.
- **Datos personales fuera del repositorio**: la agenda y las sesiones.
- **Thunar en lugar de Yazi:** se valoró un gestor de terminal, pero Thunar gana con el ratón, Discord, los USB y la partición de Windows.

---

## Problemas conocidos

| Síntoma | Causa y solución |
|---|---|
| Hyprland arranca y vuelve al `login:` | Ajustes de vídeo de la VM (ver [instalación, paso 0](#0-si-es-una-máquina-virtual-virtualbox)) |
| `pacman` da `failed retrieving file ... 404` | Base de datos anticuada: `sudo pacman -Syu` |
| El escritorio se ve enorme tras cambiar la escala | Se aplicó una escala inválida: pulsar **Revertir** en el panel |
| `imv` no abre imágenes desde Thunar (solo en VM) | Necesita `LIBGL_ALWAYS_SOFTWARE=1`; `install.sh --vm` crea el lanzador |
| Spotify de escritorio no dibuja ventana (solo en VM) | Limitación de la VM sin GPU; en hardware real se espera que funcione |
| La franja inferior de la papelera de Thunar sigue gris | Pendiente de localizar su elemento en la hoja de estilo |

---

## Hoja de ruta

- [ ] **Equipo real** con arranque dual: controladores de la GPU, sus dos monitores, Wi-Fi y Bluetooth
- [ ] `install.sh` **v2**: GPU, `multilib` (Steam), `hyprlock` y `hypridle`
- [ ] Capturas de pantalla, portapapeles, agente de autenticación y fuente de emojis
- [ ] **Red**: esquema *Equipo → Router → Internet* con latencia
- [ ] **Pantallas**: filtrar escalas válidas, encender y apagar monitores, espejo
- [ ] Panel de **Sistema** (CPU, RAM, disco, temperatura) y **lanzador** con calculadora
- [ ] Tarjeta de **libros** y animaciones de los paneles
- [ ] Iconos **Papirus** para Thunar
- [ ] Una **ISO propia** con archiso, que lleve dentro el instalador
