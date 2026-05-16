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

CSS = b"""
window {
    background: rgba(30, 30, 46, 0.97);
    border-radius: 18px;
    border: 1px solid rgba(203, 166, 247, 0.45);
}
.title {
    color: #cdd6f4;
    font-weight: bold;
    font-size: 14px;
}
.subtitle {
    color: rgba(205, 214, 244, 0.5);
    font-size: 11px;
}
.btn {
    background: rgba(49, 50, 68, 0.85);
    color: #cdd6f4;
    border-radius: 10px;
    border: 1px solid rgba(203, 166, 247, 0.2);
    font-size: 18px;
    padding: 6px 0;
    min-width: 60px;
}
.btn:hover {
    background: rgba(203, 166, 247, 0.2);
    color: #cba6f7;
    border-color: rgba(203, 166, 247, 0.5);
}
.btn-muted {
    background: rgba(243, 139, 168, 0.2);
    color: #f38ba8;
    border-color: rgba(243, 139, 168, 0.5);
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

class VolumePopup(Gtk.Window):
    def __init__(self):
        super().__init__(title="volume-popup")
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_resizable(False)
        self.set_default_size(310, -1)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)
        self.set_app_paintable(True)
        self.connect("draw", self.on_draw)
        self.connect("key-press-event", self.on_key)

        # Allow dragging the window by clicking anywhere on it
        self.connect("button-press-event", self.on_button_press)
        self.add_events(Gdk.EventMask.BUTTON_PRESS_MASK)

        GLib.timeout_add(500, self._enable_focus_out)

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_screen(
            screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        sink_info = run("wpctl get-volume @DEFAULT_AUDIO_SINK@")
        try:
            self.volume = int(float(sink_info.split()[1]) * 100)
        except Exception:
            self.volume = 50
        self.muted = "MUTED" in sink_info

        sink_name = run("wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep 'node.nick\\|node.description' | head -1 | sed 's/.*= \"//;s/\"//'")
        self.sink_name = sink_name or "Salida de audio"

        self._build_ui()

    def on_draw(self, widget, cr):
        cr.set_source_rgba(0, 0, 0, 0)
        cr.set_operator(1)
        cr.paint()
        return False

    def on_button_press(self, widget, event):
        if event.button == 1:
            # Start window drag — lets Hyprland (or GTK) handle the move
            self.begin_move_drag(event.button, int(event.x_root), int(event.y_root), event.time)

    def _build_ui(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_margin_top(16)
        box.set_margin_bottom(16)
        box.set_margin_start(16)
        box.set_margin_end(16)

        lbl_title = Gtk.Label(label="Volumen del sistema")
        lbl_title.get_style_context().add_class("title")
        lbl_title.set_halign(Gtk.Align.CENTER)
        box.pack_start(lbl_title, False, False, 0)

        lbl_sink = Gtk.Label(label=self.sink_name)
        lbl_sink.get_style_context().add_class("subtitle")
        lbl_sink.set_halign(Gtk.Align.CENTER)
        lbl_sink.set_ellipsize(3)
        lbl_sink.set_max_width_chars(30)
        box.pack_start(lbl_sink, False, False, 0)

        # Slider de volumen
        vol_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        vol_row.set_valign(Gtk.Align.CENTER)

        self.lbl_vol = Gtk.Label(label=self._vol_icon())
        self.lbl_vol.get_style_context().add_class("vol-icon")

        self.scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 150, 1)
        self.scale.set_value(self.volume)
        self.scale.set_draw_value(True)
        self.scale.set_value_pos(Gtk.PositionType.RIGHT)
        self.scale.set_hexpand(True)
        # Add marks at 100% so user knows the "safe" limit
        self.scale.add_mark(100, Gtk.PositionType.BOTTOM, None)
        self.scale.connect("value-changed", self.on_volume)

        vol_row.pack_start(self.lbl_vol, False, False, 0)
        vol_row.pack_start(self.scale, True, True, 0)
        box.pack_start(vol_row, False, False, 0)

        # Botón mute
        btn_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        btn_row.set_homogeneous(True)

        self.btn_mute = Gtk.Button(label=self._mute_label())
        self.btn_mute.get_style_context().add_class("btn")
        if self.muted:
            self.btn_mute.get_style_context().add_class("btn-muted")
        self.btn_mute.connect("clicked", self.on_mute)

        btn_row.pack_start(self.btn_mute, True, True, 0)
        box.pack_start(btn_row, False, False, 0)

        self.add(box)

    def _vol_icon(self):
        if self.muted:
            return "󰝟"
        elif self.volume <= 30:
            return "󰕿"
        elif self.volume <= 70:
            return "󰖀"
        else:
            return "󰕾"

    def _mute_label(self):
        return "󰝟  Activar" if self.muted else "󰖁  Silenciar"

    def on_volume(self, scale):
        val = scale.get_value() / 100.0
        subprocess.run(f"wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ {val:.2f}", shell=True)
        self.volume = int(scale.get_value())
        self.lbl_vol.set_text(self._vol_icon())

    def on_mute(self, btn):
        subprocess.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", shell=True)
        self.muted = not self.muted
        ctx = btn.get_style_context()
        if self.muted:
            ctx.add_class("btn-muted")
        else:
            ctx.remove_class("btn-muted")
        btn.set_label(self._mute_label())
        self.lbl_vol.set_text(self._vol_icon())

    def _enable_focus_out(self):
        self.connect("focus-out-event", lambda *_: Gtk.main_quit())
        return False

    def on_key(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()

win = VolumePopup()
win.show_all()
win.present()
win.grab_focus()
Gtk.main()
