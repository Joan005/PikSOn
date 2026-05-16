#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, Gdk, GtkLayerShell, GLib
import subprocess

def run(cmd):
    try:
        return subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout.strip()
    except Exception:
        return ""

CSS = b"""
window {
    background: transparent;
}
.pill {
    background: rgba(30, 30, 46, 0.85);
    border-radius: 12px;
    border: 1px solid rgba(203, 166, 247, 0.3);
}
.vol-icon {
    color: #cdd6f4;
    font-size: 15px;
    min-width: 20px;
}
.vol-icon.muted {
    color: #f38ba8;
}
.vol-pct {
    color: rgba(205, 214, 244, 0.65);
    font-size: 12px;
    min-width: 34px;
}
scale {
    padding: 0;
}
scale trough {
    background: rgba(49, 50, 68, 0.9);
    border-radius: 6px;
    min-height: 6px;
}
scale highlight {
    background: #cba6f7;
    border-radius: 6px;
}
scale slider {
    background: #b4befe;
    border-radius: 50%;
    min-width: 14px;
    min-height: 14px;
    border: none;
    box-shadow: none;
    margin: -4px 0;
}
scale slider:hover {
    background: #cba6f7;
}
"""

class VolumeBar(Gtk.Window):
    def __init__(self):
        super().__init__()

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 13)   # centra verticalmente en la barra de 46px
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, 200) # deja hueco para battery + power
        GtkLayerShell.set_exclusive_zone(self, 0)

        self.set_decorated(False)
        self.set_default_size(220, 34)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)
        self.set_app_paintable(True)
        self.connect("draw", self._on_draw)

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self._updating = False
        self._read_volume()
        self._build_ui()

        GLib.timeout_add(800, self._poll)

    # ── dibujo transparente ──────────────────────────────────────────────────
    def _on_draw(self, widget, cr):
        cr.set_source_rgba(0, 0, 0, 0)
        cr.set_operator(1)
        cr.paint()
        return False

    # ── estado del sistema ───────────────────────────────────────────────────
    def _read_volume(self):
        info = run("wpctl get-volume @DEFAULT_AUDIO_SINK@")
        try:
            self.volume = int(float(info.split()[1]) * 100)
        except Exception:
            self.volume = 50
        self.muted = "MUTED" in info

    def _icon(self):
        if self.muted:   return "󰝟"
        if self.volume <= 30: return "󰕿"
        if self.volume <= 70: return "󰖀"
        return "󰕾"

    # ── UI ───────────────────────────────────────────────────────────────────
    def _build_ui(self):
        pill = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        pill.get_style_context().add_class("pill")
        pill.set_margin_top(2)
        pill.set_margin_bottom(2)
        pill.set_margin_start(10)
        pill.set_margin_end(10)

        # icono (click → mute toggle)
        self.lbl_icon = Gtk.Label(label=self._icon())
        self.lbl_icon.get_style_context().add_class("vol-icon")
        if self.muted:
            self.lbl_icon.get_style_context().add_class("muted")
        evt_icon = Gtk.EventBox()
        evt_icon.add(self.lbl_icon)
        evt_icon.connect("button-press-event", self._on_icon_click)
        pill.pack_start(evt_icon, False, False, 0)

        # slider
        self.scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 150, 1)
        self.scale.set_value(self.volume)
        self.scale.set_draw_value(False)
        self.scale.set_hexpand(True)
        self.scale.add_mark(100, Gtk.PositionType.BOTTOM, None)
        self.scale.connect("value-changed", self._on_slider)
        pill.pack_start(self.scale, True, True, 0)

        # porcentaje
        self.lbl_pct = Gtk.Label(label=f"{self.volume}%")
        self.lbl_pct.get_style_context().add_class("vol-pct")
        pill.pack_start(self.lbl_pct, False, False, 0)

        self.add(pill)

    # ── callbacks ────────────────────────────────────────────────────────────
    def _on_slider(self, scale):
        if self._updating:
            return
        val = int(scale.get_value())
        self.volume = val
        subprocess.run(
            f"wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ {val/100:.2f}",
            shell=True
        )
        self._refresh_labels()

    def _on_icon_click(self, widget, event):
        if event.button == 1:
            subprocess.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", shell=True)
            self.muted = not self.muted
            self._refresh_labels()

    def _refresh_labels(self):
        self.lbl_icon.set_text(self._icon())
        ctx = self.lbl_icon.get_style_context()
        if self.muted:
            ctx.add_class("muted")
        else:
            ctx.remove_class("muted")
        self.lbl_pct.set_text(f"{self.volume}%")

    def _poll(self):
        prev_vol, prev_muted = self.volume, self.muted
        self._read_volume()
        if self.volume != prev_vol or self.muted != prev_muted:
            self._updating = True
            self.scale.set_value(self.volume)
            self._refresh_labels()
            self._updating = False
        return True

win = VolumeBar()
win.show_all()
Gtk.main()
