#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import subprocess

def run(cmd):
    try:
        return subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout.strip()
    except Exception:
        return ""

def playerctl(cmd):
    subprocess.run(f"playerctl {cmd} --player=spotify", shell=True)

CSS = b"""
window {
    background: rgba(30, 30, 46, 0.97);
    border-radius: 18px;
    border: 1px solid rgba(203, 166, 247, 0.45);
}
.title {
    color: #cdd6f4;
    font-weight: bold;
    font-size: 15px;
}
.artist {
    color: rgba(205, 214, 244, 0.5);
    font-size: 12px;
}
.btn {
    background: rgba(49, 50, 68, 0.85);
    color: #cdd6f4;
    border-radius: 10px;
    border: 1px solid rgba(203, 166, 247, 0.2);
    font-size: 20px;
    padding: 8px 0;
    min-width: 72px;
}
.btn:hover {
    background: rgba(203, 166, 247, 0.2);
    color: #cba6f7;
    border-color: rgba(203, 166, 247, 0.5);
}
.shuffle-on {
    background: rgba(203, 166, 247, 0.28);
    color: #cba6f7;
    border-color: rgba(203, 166, 247, 0.7);
}
.vol-icon {
    color: rgba(205, 214, 244, 0.6);
    font-size: 16px;
    min-width: 24px;
}
scale trough {
    background: rgba(49, 50, 68, 0.9);
    border-radius: 6px;
    min-height: 8px;
}
scale highlight {
    background: #cba6f7;
    border-radius: 6px;
}
scale slider {
    background: #b4befe;
    border-radius: 50%;
    min-width: 16px;
    min-height: 16px;
    border: none;
    box-shadow: none;
}
scale slider:hover {
    background: #cba6f7;
}
"""

class SpotifyPopup(Gtk.Window):
    def __init__(self):
        super().__init__(title="spotify-popup")
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_resizable(False)
        self.set_default_size(310, -1)

        # Soporte RGBA para esquinas redondeadas
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)
        self.set_app_paintable(True)
        self.connect("draw", self.on_draw)

        self.connect("key-press-event", self.on_key)
        # Delay para que el ratón pueda llegar a la ventana sin cerrarla
        GLib.timeout_add(500, self._enable_focus_out)

        # CSS
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # Estado actual
        self.song   = run("playerctl metadata --player=spotify --format '{{title}}'") or "Sin reproducción"
        self.artist = run("playerctl metadata --player=spotify --format '{{artist}}'")
        vol_raw = run("playerctl volume --player=spotify")
        try:
            self.volume = int(float(vol_raw) * 100)
        except Exception:
            self.volume = 50
        # Máximo: un poco por encima del actual, pero nunca más de 100
        self.vol_max = min(self.volume + 10, 100)
        shuffle = run("playerctl shuffle --player=spotify")
        self.shuffle_on = shuffle.lower() == "on"

        self._build_ui()

    def on_draw(self, widget, cr):
        cr.set_source_rgba(0, 0, 0, 0)
        cr.set_operator(1)  # CAIRO_OPERATOR_SOURCE
        cr.paint()
        return False

    def _build_ui(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(16)
        box.set_margin_bottom(16)
        box.set_margin_start(16)
        box.set_margin_end(16)

        # Título de la canción
        lbl_song = Gtk.Label(label=self.song)
        lbl_song.get_style_context().add_class("title")
        lbl_song.set_ellipsize(3)
        lbl_song.set_max_width_chars(26)
        lbl_song.set_halign(Gtk.Align.CENTER)
        box.pack_start(lbl_song, False, False, 0)

        # Artista
        if self.artist:
            lbl_artist = Gtk.Label(label=self.artist)
            lbl_artist.get_style_context().add_class("artist")
            lbl_artist.set_halign(Gtk.Align.CENTER)
            box.pack_start(lbl_artist, False, False, 0)

        # Fila de controles: ⏮  ⇄  ⏭
        btn_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        btn_row.set_homogeneous(True)

        btn_prev = Gtk.Button(label="⏮")
        btn_prev.get_style_context().add_class("btn")
        btn_prev.connect("clicked", self.on_prev)

        self.btn_shuffle = Gtk.Button(label="⇄")
        self.btn_shuffle.get_style_context().add_class("btn")
        if self.shuffle_on:
            self.btn_shuffle.get_style_context().add_class("shuffle-on")
        self.btn_shuffle.connect("clicked", self.on_shuffle)

        btn_next = Gtk.Button(label="⏭")
        btn_next.get_style_context().add_class("btn")
        btn_next.connect("clicked", self.on_next)

        btn_row.pack_start(btn_prev, True, True, 0)
        btn_row.pack_start(self.btn_shuffle, True, True, 0)
        btn_row.pack_start(btn_next, True, True, 0)
        box.pack_start(btn_row, False, False, 0)

        # Slider de volumen
        vol_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        vol_row.set_valign(Gtk.Align.CENTER)

        lbl_vol = Gtk.Label(label="🔊")
        lbl_vol.get_style_context().add_class("vol-icon")

        self.scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, self.vol_max, 1)
        self.scale.set_value(self.volume)
        self.scale.set_draw_value(True)
        self.scale.set_value_pos(Gtk.PositionType.RIGHT)
        self.scale.set_hexpand(True)
        self.scale.connect("value-changed", self.on_volume)

        vol_row.pack_start(lbl_vol, False, False, 0)
        vol_row.pack_start(self.scale, True, True, 0)
        box.pack_start(vol_row, False, False, 0)

        self.add(box)

    def on_prev(self, *_):
        playerctl("previous")
        Gtk.main_quit()

    def on_next(self, *_):
        playerctl("next")
        Gtk.main_quit()

    def on_shuffle(self, btn):
        playerctl("shuffle toggle")
        self.shuffle_on = not self.shuffle_on
        ctx = btn.get_style_context()
        if self.shuffle_on:
            ctx.add_class("shuffle-on")
        else:
            ctx.remove_class("shuffle-on")

    def on_volume(self, scale):
        val = scale.get_value() / 100.0
        subprocess.run(f"playerctl volume {val:.2f} --player=spotify", shell=True)

    def _enable_focus_out(self):
        self.connect("focus-out-event", lambda *_: Gtk.main_quit())
        return False  # no repetir el timeout

    def on_key(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()

win = SpotifyPopup()
win.show_all()
win.present()
win.grab_focus()
Gtk.main()
