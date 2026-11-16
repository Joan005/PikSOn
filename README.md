# 🎩 PikSOn

Un escritorio **Arch Linux + Hyprland + Quickshell** con aire de biblioteca antigua de noche: marrones cálidos, letra color vainilla, dorado como único acento y una sola tipografía. Está pensado para instalarse con **un solo script** sobre un Arch recién instalado.

<a id="estructura"></a>
## 🗂️ Estructura del repositorio

```
PikSOn/
├── README.md                # Este documento
├── install.sh               # Instalador: paquetes, configuración, servicios y ajustes (debe ser ejecutable)
├── pkglist.txt              # Paquetes de los repositorios oficiales
├── aur-pkglist.txt          # Paquetes del AUR
├── zsh/
│   ├── .zshrc               # Configuración de zsh (se copia a ~/.zshrc)
│   └── .zprofile            # Arranque automático de Hyprland (se copia a ~/.zprofile)
└── .config/                 # Configuraciones (se copian a ~/.config)
    ├── gtk-3.0/
    │   ├── settings.ini     # Aplicaciones GTK: tema oscuro, tipografía y cursor
    │   └── gtk.css          # Aspecto de Thunar y demás apps GTK (Pergamino nocturno)
    ├── hypr/
    │   └── hyprland.lua     # Hyprland: monitor, atajos, bordes, cursor, terminal y arranque automático
    ├── kitty/
    │   └── kitty.conf       # Terminal: tipografía, colores (Pergamino nocturno) y transparencia
    └── quickshell/
        ├── shell.qml        # Punto de entrada
        ├── Theme.qml        # Tema: colores, tamaños y fuentes (singleton)
        ├── Wallpaper.qml    # Fondo de pantalla
        ├── wallpaper.jpg    # Imagen del fondo
        ├── Bar.qml          # Barra superior y cerebro de los paneles
        ├── Player.qml       # Chip de música (siempre visible; cualquier reproductor MPRIS)
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
        ├── SettingsPanel.qml # Ajustes (la tuerca): gestión de pantallas
        ├── PowerMenu.qml    # Menú de apagado
        ├── Dock.qml         # Dock lateral oculto: ventanas abiertas y bandeja
        └── scripts/
            ├── net.sh       # Resumen de red para el chip (debe ser ejecutable)
            ├── netinfo.sh   # Detalle de red para el panel (debe ser ejecutable)
            ├── trayquit.sh  # Cierra la app de un icono de la bandeja (debe ser ejecutable)
            └── monitor-set.sh # Aplica en caliente la configuración de un monitor (debe ser ejecutable)
```

| Elemento | Descripción |
|---|---|
| `install.sh` | Instala el entorno completo sobre un Arch recién instalado |
| `pkglist.txt` | Paquetes oficiales, generada con `pacman -Qqen` |
| `aur-pkglist.txt` | Paquetes del AUR, generada con `pacman -Qqem` |
| `zsh/` | Shell zsh con plugins y starship, y el arranque automático de Hyprland en el TTY1 |
| `.config/gtk-3.0/` | Aspecto de Thunar y de las aplicaciones GTK |
| `.config/hypr/` | Configuración de Hyprland: monitor, atajos, bordes y cursor |
| `.config/kitty/` | Configuración del terminal |
| `.config/quickshell/` | Tema, barra, paneles, ajustes, dock lateral, fondo y scripts de apoyo |

> 💡 Las carpetas de `.config/` replican la ruta que tendrían en `~/.config`.

> ⚠️ **`~/.config/hypr/monitors.lua` no está en el repositorio, a propósito:** lo genera el panel de Pantallas y es propio de cada equipo. De la carpeta de GTK solo se guardan `settings.ini` y `gtk.css`.

---

## 📑 Índice
1. [Instalación](#instalacion)
2. [Qué es](#que-es)
3. [Qué incluye](#que-incluye)
4. [Atajos de teclado](#atajos)
5. [Pendiente](#pendiente)

---

<a id="instalacion"></a>
## 1. Instalación

El camino es: **instalar Arch con `archinstall`, clonar este repositorio y lanzar `install.sh`**.

### Paso 0. Si es una máquina virtual (VirtualBox)

Con la máquina **apagada**, en *Configuración → Pantalla*:

| Opción | Valor |
|---|---|
| Controlador gráfico | **VMSVGA** |
| Aceleración 3D | **Habilitada** |
| Memoria de vídeo | **128 MB** |

> ⚠️ Sin esto, **Hyprland aborta al arrancar** y vuelve al `login:`. El script no puede cambiarlo desde dentro.

### Paso 1. Instalar Arch

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

### Paso 2. Clonar y ejecutar

Reinicia, entra con tu usuario y, si el repositorio es privado, inicia sesión en GitHub (el código de 8 caracteres se introduce desde otro dispositivo):

```bash
gh auth login
git clone https://github.com/Joan005/PikSOn
cd PikSOn
bash install.sh --vm        # o --real en un equipo físico
```

Sin opción, el script pregunta si es una máquina virtual. Con `--dry-run` solo muestra lo que haría, sin cambiar nada. **No lo ejecutes como root.**

### Paso 3. Qué hace el script

1. Actualiza el sistema e instala `base-devel`, `git` y `yay`.
2. Instala los paquetes de `pkglist.txt` y `aur-pkglist.txt`.
3. Copia la configuración (guardando antes una copia de lo existente en `~/.config-backup-FECHA`).
4. Activa NetworkManager y PipeWire, y fija la zona horaria y zsh como shell.
5. Aplica lo propio de **VM o equipo real** (la variable de renderizado por software, `virtualbox-guest-utils`...).
6. Ajusta GTK (tipografía, tema oscuro y cursor) con `gsettings`.

Todo queda registrado en `~/pikson-install.log`, con una lista de avisos al final.

### Paso 4. Lo que queda a mano

Reiniciar; los **controladores de la GPU** si es un equipo real; ajustar los **monitores** desde la tuerca; y volver a iniciar sesión en Brave y Discord. Los datos personales (agenda, sesiones) no viajan con el repositorio.

### Cómo arranca el escritorio

Se entra por el **TTY1** con usuario y contraseña; el `~/.zprofile` lanza `start-hyprland` automáticamente. Si Hyprland falla, vuelve al `login:`: pasa al **TTY2** (`Ctrl derecho + F2` en VirtualBox), donde no se lanza, para ver el error con `start-hyprland`.

---

<a id="que-es"></a>
## 2. Qué es

| Pieza | Qué hace |
|---|---|
| **Hyprland** | El compositor (gestor de ventanas en mosaico), configurado en Lua |
| **Quickshell** | Construye la barra, los paneles y el dock con QML |
| **kitty** + **zsh** + **starship** | Terminal, shell y prompt |
| **Thunar** | Gestor de archivos, vestido como una extensión de la barra |
| **Brave**, **Discord**, **imv** | Navegador, chat y visor de imágenes |
| **PipeWire** y **NetworkManager** | Sonido y red |

**La estética** se llama *Pergamino nocturno*: fondo `#34261b`, texto `#f6ebcf`, acento dorado `#e2b564`. Todo el escritorio usa **JetBrains Mono Nerd Font**. El tema vive en un solo fichero (`Theme.qml`) y se repite, adaptado, en kitty, en los bordes de Hyprland y en Thunar.

> Se desarrolla y prueba en **VirtualBox**. El salto a un equipo real (arranque dual con Windows) está en marcha; ver [Pendiente](#pendiente).

---

<a id="que-incluye"></a>
## 3. Qué incluye

### La barra «solo texto»

Sin cajas ni adornos: texto sobre un degradado suave, con un filete fino de latón debajo. De izquierda a derecha: **workspaces en números romanos** (I a V), el **chip de música**, el **reloj** (en el centro), el **tiempo**, el **volumen**, la **red**, la **campana de avisos**, la **tuerca de ajustes** y el **apagado**. Cada uno abre su panel al pulsarlo, y un clic fuera los cierra.

### Música y letra sincronizada

El chip de música funciona con **cualquier reproductor MPRIS** (Spotify, VLC, el propio Brave con YouTube...). Siempre está visible: con miniatura, título y tiempo, o «Nada suena». Su panel muestra la carátula, el progreso y los controles, y la **letra sincronizada**, que se puede sacar a una columna fija a la derecha de la pantalla.

> 🔒 Las letras vienen de [LRCLIB](https://lrclib.net). Solo se envían el **título y el artista**.

### Dock lateral oculto

En reposo no se ve. Al llevar el ratón al **borde derecho** aparece, con las **ventanas abiertas** (clic para llevarlas al frente, clic derecho para cerrarlas) y la **bandeja del sistema** (las apps que siguen en segundo plano, con un botón para cerrarlas del todo).

### Calendario y agenda

Se abre al pulsar el reloj: el mes a la izquierda y las tareas del día a la derecha, con etiquetas de color. Las tareas se guardan en `~/.local/share/pikson/agenda.json`, **fuera del repositorio**.

### Sonido, avisos, tiempo y red

- **Sonido:** salida y micrófono con su volumen y silencio, y la lista de dispositivos de salida.
- **Avisos:** Quickshell hace de servidor de notificaciones, con avisos emergentes, historial y «No molestar».
- **Tiempo:** el actual, las próximas 6 horas y 5 días (datos de Open-Meteo; solo se envían las coordenadas fijas de Barcelona).
- **Red:** un **medallón** de latón con los datos de la conexión. La pestaña de cable muestra datos reales; Wi-Fi y Bluetooth son, de momento, de ejemplo.

### Ajustes: gestión de pantallas

La **tuerca** abre el panel de Pantallas: un esquema a escala de los monitores, y selectores de **resolución, frecuencia, escala y rotación**. Con dos o más monitores se pueden **arrastrar** para colocarlos. Todo cambio pasa por **Aplicar**, con una **cuenta atrás de 15 segundos** que revierte sola si no se confirma, como en Windows. «Conservar y guardar» escribe `~/.config/hypr/monitors.lua`.

### Thunar

El gestor de archivos (`Super + E`), con el mismo lenguaje visual que la barra: fondo semitransparente, menús de solo texto, selección dorada y la misma tipografía.

---

<a id="atajos"></a>
## 4. Atajos de teclado

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

<a id="pendiente"></a>
## 5. 📝 Pendiente

**Hecho hasta ahora**

Barra «solo texto» con workspaces en números romanos; chip de música siempre visible; paneles de música (con letra sincronizada y columna lateral), calendario con agenda, sonido, avisos, tiempo, red (medallón) y menú de apagado; cierre al pulsar fuera; tipografía única; dock lateral oculto con ventanas abiertas y bandeja; **tuerca de ajustes con el panel de Pantallas** (esquema a escala, resolución, frecuencia, escala, rotación, arrastre con imán, cuenta atrás de 15 s y guardado permanente en `monitors.lua`); **Thunar** con aspecto de la barra y visor de imágenes `imv`; **`install.sh` v1**, **probado con éxito en una VM limpia**.

**Lo más inmediato: pasar a un equipo real**

- [ ] Revisar los **avisos del registro** (`grep -n '!!' ~/pikson-install.log`) de la VM de prueba y recorrer una lista de comprobación (kitty, Thunar, Brave, Discord, `imv`, tipografía GTK, tuerca)
- [ ] **`install.sh` v2**: controladores de la GPU, `multilib` (Steam), iconos de Thunar, `hyprlock` y `hypridle`
- [ ] Piezas del escritorio que aún no están y conviene añadir **antes de pasar a un equipo real**: capturas de pantalla (`grim` y `slurp`), portapapeles (`wl-clipboard`), agente de autenticación (polkit, por ejemplo `hyprpolkitagent`), fuente de emojis (`noto-fonts-emoji`) y decidir cómo se entra (TTY con `.zprofile` o un gestor gráfico)
- [ ] **Preparar Windows para el arranque dual**: copia de seguridad, **clave de recuperación de BitLocker**, desactivar el «Inicio rápido», reducir la partición **desde Windows**, ajustar la hora (`timedatectl set-local-rtc 1`), GRUB con `os-prober` y, si se puede, **instalar en otro disco físico** para no tocar el arranque de Windows
- [ ] En el equipo real: GPU (NVIDIA, AMD o Intel), sus **dos monitores** (3440×1440 a 165 Hz y uno vertical), Wi-Fi y Bluetooth, audio completo y Steam

**Siguiente, por construir (en este orden)**

- [ ] **Red + camino de la conexión**: conservar el medallón y añadir un esquema *Equipo → Router → Internet* con las IP, la velocidad y la latencia (con `ping`)
- [ ] **Pantallas, siguientes fases**: 1) filtrar las **escalas válidas** para cada resolución (las que dan un tamaño lógico entero) en lugar de la lista fija; 2) **encender y apagar** monitores (los apagados no salen en `hyprctl monitors -j`; habrá que leer también `hyprctl monitors all -j`); 3) espejo y monitor principal; 4) probar el **arrastre y la rotación con dos monitores** (hoy solo probados con uno)
- [ ] **Más secciones en la tuerca**: apariencia (fondo y tema), teclado, energía; y un resumen del sistema
- [ ] **Descargador de vídeos** (idea): panel o app para descargar vídeos de internet con `yt-dlp` y `ffmpeg` (formatos, carpeta, cola de descargas), solo con contenido propio, libre o con permiso
- [ ] **Batería** (en hardware real, si es un portátil)
- [ ] **Sistema**: CPU, RAM, disco y temperatura; al pulsarlo abre Pantallas
- [ ] **Lanzador** (diseño «B»): calculadora, categorías y atajo de teclado
- [ ] **Sonido**: medidor del micrófono en el panel
- [ ] **Bloquear pantalla**: instalar `hyprlock` y configurarlo (hoy «Bloquear» no hace nada)
- [ ] **Comprobar que se puede teclear** en el campo «Añadir una tarea» del calendario; si no, convertirlo en ventana de capa con foco de teclado
- [ ] **Tarjeta de libros**: lo que estoy leyendo, con el porcentaje; los datos personales irían en `libros.json` (fuera del repositorio) con un `libros.example.json` de muestra
- [ ] **Red y Bluetooth, fases 2 y 3 (hardware real)**: conectar las pestañas Wi-Fi y Bluetooth a `nmcli` y `bluetoothctl` en lugar de los datos de ejemplo; «Escanear redes» y «Escanear dispositivos»; la ficha de contraseña para las redes con candado; y que el botón de latón encienda y apague de verdad
- [ ] **Reproductor**: probar el bucle con Spotify real (en Brave se ve atenuado) y la **cola** con la API web de Spotify (MPRIS no la expone)
- [ ] **Animaciones**: 1) una transición común de apertura de los paneles (escala del 92 % al 100 % con aparición suave, aplicada al **contenido**); 2) movimiento discreto en el medallón de red; 3) cierres animados. Las animaciones en bucle solo deben ejecutarse **mientras el panel está abierto**: en la VM, con renderizado por software, pueden ir entrecortadas

**Thunar**

- [ ] **Iconos Papirus** con `papirus-folders` (carpetas marrones): `sudo pacman -S papirus-icon-theme`, `yay -S papirus-folders`, `sudo papirus-folders -C brown --theme Papirus-Dark` y `gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'`; aparcado por ahora
- [ ] La **franja gris de la papelera**: localizar el nodo con `GTK_DEBUG=interactive thunar`
- [ ] Comprobar que el diálogo **«Guardar como» de Brave** se ve bien tras instalar los portales y volver a entrar
- [ ] Opcional: regla de ventana para que `imv` se abra flotando; `mpv` (vídeo) y `zathura` (PDF) con `xdg-mime`

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
- [ ] Pasar al tema los colores propios de los paneles (el latón del medallón, el papel de la carátula, los del panel de Pantallas)

**Tema y estética**

- [ ] Fondo de pantalla de tonos cálidos, o tintar el actual hacia sepia
- [ ] Comprobar en `hyprland.lua` las esquinas redondeadas de las ventanas (`rounding`, unos 14 para casar con `Theme.radius`) y la sombra
- [ ] Una única fuente de colores para Quickshell, kitty, Hyprland y GTK (hoy están copiados en cuatro sitios)
- [ ] Desenfoque de las ventanas (es pesado en la VM)

**Escritorio**

- [ ] Máscara de entrada en la barra superior (que los huecos no bloqueen clics ni reserven espacio)
- [ ] Distribución de las ventanas: Discord necesita ≈ 940 px de ancho
- [ ] Fusionar `net.sh` y `netinfo.sh` en un único script
- [ ] Quitar el registro de depuración de la línea de arranque de Quickshell

**Repositorio y hardware real**

- [ ] Instalar Spotify de escritorio y probarlo (en la VM no dibuja ventana)
- [ ] Frecuencia del monitor (165 Hz) y revisión de la escala, ahora desde el panel de Pantallas
- [ ] Probar el Wi-Fi y el Bluetooth (`bluez`, `bluez-utils`) con el panel medallón, y revisar el volumen y el silencio con el rango completo
- [ ] GNU Stow para enlazar configuraciones (incluidos `zsh/.zshrc` y `zsh/.zprofile`)
- [ ] Login gráfico (SDDM, greetd con un greeter o uno propio con Quickshell), quitando el bloque de `~/.zprofile`

**A largo plazo: una ISO propia con mi Arch**

El flujo de hoy es **sencillo**: ISO oficial de Arch con Rufus, `archinstall`, clonar el repositorio y `bash install.sh`. La idea de **una ISO propia**, que ya lleve dentro el instalador y los dotfiles, se construiría con **archiso** en una VM de Arch y se grabaría después con Rufus en modo DD. **No** consiste en clonar la VM, que no es portable (arrastra los controladores de VirtualBox y los identificadores de disco). No se empieza hasta tener el escritorio terminado e `install.sh` probado en equipo real.

- [ ] 1. Terminar el escritorio, probar `install.sh` en un equipo real y mantener las listas de paquetes al día
- [ ] 2. Perfil de **archiso** (copia del perfil `releng`) con los paquetes necesarios, los dotfiles y el `install.sh` dentro de `airootfs/`, y un `instalar.sh` que arranque solo y lance `archinstall`
- [ ] 3. Compilar los paquetes del **AUR** con `makepkg` y guardarlos en un repositorio local dentro de la ISO (`repo-add`); decidir entre instalación **online** (ISO pequeña; los paquetes oficiales se descargan al instalar) y **offline** (ISO grande con todo)
- [ ] 4. Construir la ISO con `mkarchiso`, probarla en una VM limpia (con y sin UEFI) y, solo entonces, grabarla con Rufus (modo DD) y probar en hardware real. Opcional: un **tema de GRUB propio**
- [ ] Cuidados: **nada secreto dentro** (ni el token de `gh`, ni `agenda.json`, ni `monitors.lua`), la ISO **caduca** (Arch es rolling) y el *Secure Boot* no funciona con estas ISO
