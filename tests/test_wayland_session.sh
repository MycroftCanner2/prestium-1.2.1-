#!/bin/bash
# 2.0 r10: starts the Prestium Wayland session's compositor (labwc) headless with Prestium's own
# rc.xml, menu.xml and autostart, and checks the session: config parses, the restricted socket for
# applications exists and hides the privileged protocols, prestium-run uses it, the panel and
# notifications run on the full socket. Needs labwc, waybar, mako, swaybg, swayidle, wayland-utils.
set -u
H=$(cd "$(dirname "$0")/.." && pwd)
I=$H/config/includes.chroot
fail=0; ok() { echo "OK   $1"; }; bad() { echo "FAIL $1"; fail=1; }
T=$(mktemp -d); export HOME=$T/home XDG_RUNTIME_DIR=$T/xdg; mkdir -p "$HOME" && mkdir -m 700 "$XDG_RUNTIME_DIR"
# Prestium's /etc/xdg with absolute /usr/local paths pointed at the repository
mkdir -p "$T/xdg-etc" "$T/bin"
cp -r "$I/etc/xdg/labwc" "$I/etc/xdg/waybar" "$I/etc/xdg/mako" "$T/xdg-etc/"
sed -i "s#/usr/local/lib/prestium/#$I/usr/local/lib/prestium/#g; s#/usr/local/bin/#$T/bin/#g" "$T/xdg-etc/labwc/autostart"
for f in prestium-run prestium-scale prestium-lock-screen prestium-safety-notify; do
  sed "s#/usr/local/lib/prestium/#$I/usr/local/lib/prestium/#g" "$I/usr/local/bin/$f" > "$T/bin/$f"; chmod +x "$T/bin/$f"
done
sed -i "s#/usr/local/lib/prestium/wl-context#$I/usr/local/lib/prestium/wl-context#" "$T/bin/prestium-run"
cp "$I/usr/local/lib/prestium/apps-socket" "$T/bin/apps-socket"
sed -i "s#/usr/local/lib/prestium/wl-context#$I/usr/local/lib/prestium/wl-context#" "$T/bin/apps-socket"
sed -i "s#$I/usr/local/lib/prestium/apps-socket#$T/bin/apps-socket#g" "$T/xdg-etc/labwc/autostart" "$T/bin/prestium-run"
export PATH="$T/bin:$PATH"
cleanup() { [ -n "${DBP:-}" ] && kill $DBP 2>/dev/null; pkill -P $$ 2>/dev/null; kill $LP 2>/dev/null; sleep 0.5; pkill -f "$T/xdg" 2>/dev/null; rm -rf "$T"; }
trap cleanup EXIT
eval "$(dbus-launch --sh-syntax)"; DBP=$DBUS_SESSION_BUS_PID
XDG_CONFIG_DIRS=$T/xdg-etc WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
  labwc -m > "$T/labwc.log" 2>&1 & LP=$!
for i in $(seq 80); do [ -S "$XDG_RUNTIME_DIR/wayland-apps" ] && break; sleep 0.1; done
sleep 2
grep -E '\[ERROR\]' "$T/labwc.log" | grep -v "Blocking unknown protocol" > "$T/err"
[ -s "$T/err" ] && { bad "labwc reports config errors"; cat "$T/err"; } || ok "labwc loads rc.xml and menu.xml without errors"
[ -S "$XDG_RUNTIME_DIR/wayland-apps" ] && ok "restricted socket wayland-apps created at login" || bad "no wayland-apps socket"
[ "$(cat "$XDG_RUNTIME_DIR/prestium-wayland-display" 2>/dev/null)" = wayland-0 ] && ok "full socket name recorded for the browser launchers" || bad "prestium-wayland-display"
globals() { WAYLAND_DISPLAY=$1 timeout 10 wayland-info 2>/dev/null | grep -oE "interface: '[a-z_0-9]+'" | cut -d"'" -f2 | sort -u; }
full=$(globals wayland-0); apps=$(globals wayland-apps)
n=0
for p in zwlr_screencopy_manager_v1 zwlr_export_dmabuf_manager_v1 zwp_virtual_keyboard_manager_v1 \
         zwlr_virtual_pointer_manager_v1 zwlr_data_control_manager_v1 zwlr_foreign_toplevel_manager_v1 \
         ext_foreign_toplevel_list_v1 zwp_input_method_manager_v2 wp_security_context_manager_v1 \
         zwlr_layer_shell_v1 ext_session_lock_manager_v1 zwlr_output_manager_v1 zwlr_gamma_control_manager_v1; do
  echo "$full" | grep -qx "$p" || { bad "full socket lacks $p (test setup)"; continue; }
  echo "$apps" | grep -qx "$p" && { bad "restricted socket offers $p"; n=1; }
done
[ $n = 0 ] && ok "restricted socket hides screen capture, input injection, clipboard managers, other windows, layer-shell, session lock, output/gamma control"
echo "$apps" | grep -qx xdg_wm_base && echo "$apps" | grep -qx wl_seat && ok "restricted socket still offers normal windows, input, clipboard (wl_data_device_manager)" || bad "restricted socket unusable"
[ "$(prestium-run sh -c 'echo $WAYLAND_DISPLAY')" = wayland-apps ] && ok "prestium-run puts apps on the restricted socket" || bad "prestium-run"
pgrep -f "^waybar" >/dev/null && ok "panel (waybar) running" || bad "waybar not running"
pgrep -x mako >/dev/null && ok "notifications (mako) running" || bad "mako not running"
pgrep -x swayidle >/dev/null && ok "idle lock (swayidle) running" || bad "swayidle not running"
WAYLAND_DISPLAY=wayland-apps timeout 5 waybar -c "$T/xdg-etc/waybar/config.jsonc" 2>&1 | grep -q "does not support wlr-layer-shell" \
  && ok "an app on the restricted socket can't draw a panel or overlay (layer-shell refused)" || bad "layer-shell on restricted socket"
mv "$XDG_RUNTIME_DIR/wayland-apps" "$T/moved"
[ "$(prestium-run sh -c 'echo $WAYLAND_DISPLAY $GDK_BACKEND')" = "prestium-no-wayland x11" ] && ok "no restricted socket: prestium-run gives no Wayland access at all (Xwayland only)" || bad "prestium-run fallback"
exit $fail
