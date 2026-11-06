#!/bin/bash
# 2.0 r9: runs the real Tor Browser launcher (config/includes.chroot/usr/local/bin/tor-browser) with
# bwrap, but with a probe script in place of start-tor-browser, and checks what the browser would
# see inside its sandbox. Needs bwrap, python3, tor and sudo (creates /opt/tor-browser,
# /run/prestium-tbb and /usr/local/share/prestium-{tor-browser,nssdb} when absent and removes them).
set -u
H=$(cd "$(dirname "$0")/.." && pwd)
L=$H/config/includes.chroot/usr/local/bin/tor-browser
fail=0; ok() { echo "OK   $1"; }; bad() { echo "FAIL $1"; fail=1; }
created=()
mk() {   # create $1 and remember the topmost directory that did not exist, to remove it afterwards
  [ -e "$1" ] && return 0
  local top=$1; while [ ! -e "$(dirname "$top")" ]; do top=$(dirname "$top"); done
  sudo -n mkdir -p "$1"; created+=("$top")
}
mk /opt/tor-browser/Browser/TorBrowser/Data/Browser/profile.default/extensions
mk /run/prestium-tbb; mk /usr/local/share/prestium-tor-browser; mk /usr/local/share/prestium-nssdb
sudo -n chown "$(id -u)" /run/prestium-tbb /opt/tor-browser/Browser
sudo -n sh -c 'echo "user_pref(\"browser.download.dir\", \"@DOWNLOADS@\");" > /usr/local/share/prestium-tor-browser/user.js; : > /usr/local/share/prestium-nssdb/cert9.db; : > /usr/local/share/prestium-nssdb/key4.db'
T=$(mktemp -d); export HOME=$T/home; mkdir -p "$HOME"; echo secret > "$HOME/keepass.kdbx"; mkdir -p "$HOME/.ssh"
# probe = "start-tor-browser" inside the sandbox
cat > /opt/tor-browser/Browser/start-tor-browser <<'EOF'
#!/bin/sh
exec python3 - "$@" <<'PY'
import json, os, socket, subprocess, sys
r = {}
r["args"] = sys.argv[1:]
r["ifaces"] = sorted(os.listdir("/sys/class/net")) if os.path.isdir("/sys/class/net") else []
r["netdev"] = open("/proc/net/dev").read().split("\n")[2:]
def tcp(host, port):
    s = socket.socket(); s.settimeout(2)
    try: s.connect((host, port)); return "connected"
    except OSError as e: return type(e).__name__ + ":" + str(e.errno)
r["tcp_9050"] = tcp("127.0.0.1", 9050)
r["tcp_ext"] = tcp("1.1.1.1", 443)
try:
    u = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); u.sendto(b"x", ("9.9.9.9", 53)); r["udp"] = "sent"
except OSError as e: r["udp"] = type(e).__name__
s = socket.socket(socket.AF_UNIX)
try:
    s.connect(os.environ["TOR_SOCKS_IPC_PATH"]); s.sendall(b"\x05\x01\x00"); r["socks"] = s.recv(2).hex()
except OSError as e: r["socks"] = str(e)
r["home"] = sorted(os.listdir(os.environ["HOME"]))
r["nnp"] = [l for l in open("/proc/self/status") if l.startswith("NoNewPrivs")][0].split()[1]
r["hostname"] = socket.gethostname()
r["env"] = sorted(k for k in os.environ)
r["pid1"] = open("/proc/1/comm").read().strip()
try:
    r["sudo"] = subprocess.run(["sudo", "-n", "true"], capture_output=True, text=True).stderr.strip()[:80]
except OSError as e: r["sudo"] = str(e)
r["run"] = sorted(os.listdir("/run"))
print("PROBE" + json.dumps(r))
PY
EOF
chmod +x /opt/tor-browser/Browser/start-tor-browser
# a real Tor SOCKS listener on the Unix socket (no network needed for the greeting)
printf 'DataDirectory %s/tor\nSocksPort unix:/run/prestium-tbb/socks GroupWritable RelaxDirModeCheck\nUseBridges 1\nBridge 127.0.0.1:9\nControlPort 0\nLog err stderr\n' "$T" > "$T/torrc"
mkdir -m 700 "$T/tor"; chmod 2750 /run/prestium-tbb
tor -f "$T/torrc" >/dev/null 2>&1 & TP=$!
for i in $(seq 20); do [ -S /run/prestium-tbb/socks ] && break; sleep 0.5; done
# a TCP listener on 127.0.0.1:9050 outside the sandbox (must NOT be reachable from inside)
python3 -c 'import socket,time; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1); s.bind(("127.0.0.1",9050)); s.listen(5); time.sleep(30)' & LP=$!
sleep 1
out=$(DISPLAY=:0 bash "$L" "https://example.org/" 2>&1)
kill $TP $LP 2>/dev/null; wait 2>/dev/null
j=$(printf '%s\n' "$out" | sed -n 's/^PROBE//p')
if [ -z "$j" ]; then bad "probe did not run: $out"; else
  chk() { python3 -c "import json,sys; r=json.loads(sys.argv[1]); sys.exit(0 if ($2) else 1)" "$j" && ok "$1" || { bad "$1"; echo "     $j" | cut -c1-400; }; }
  # /proc/net/dev is per network namespace (authoritative). /sys/class/net still lists the host's
  # interfaces because /sys is the host's sysfs; their details are denied by AppArmor.
  chk "only loopback in the sandbox's network namespace" 'all(not l.strip() or l.strip().startswith("lo:") for l in r["netdev"])'
  chk "127.0.0.1:9050 of the host is not reachable" 'r["tcp_9050"] != "connected"'
  chk "no route to the Internet (TCP)" 'r["tcp_ext"] != "connected"'
  chk "no UDP (DNS) out" 'r["udp"] != "sent"'
  chk "Tor SOCKS Unix socket works (05 00)" 'r["socks"] == "0500"'
  chk "HOME holds only .tor-browser and Tor Browser" 'r["home"] == [".tor-browser", "Tor Browser"]'
  chk "no_new_privs set" 'r["nnp"] == "1"'
  chk "sudo can't raise privileges" 'r["sudo"] != ""'
  chk "hostname is localhost" 'r["hostname"] == "localhost"'
  chk "own PID namespace" 'r["pid1"] in ("bwrap", "start-tor-brows", "sh", "python3")'
  chk "clean environment with the Tor settings" '"TOR_SOCKS_IPC_PATH" in r["env"] and "TOR_SOCKS_PORT" not in r["env"] and "SSH_AUTH_SOCK" not in r["env"] and "DBUS_SESSION_BUS_ADDRESS" not in r["env"]'
  chk "no D-Bus or other /run sockets" 'set(r["run"]) <= {"user", "prestium-tbb", "onion-grater"}'
  chk "browser arguments passed through" 'r["args"][:1] == ["https://example.org/"] and "-profile" in r["args"]'
fi
# Tor not running: the launcher refuses to start
sudo -n rm -f /run/prestium-tbb/socks
DISPLAY=:0 bash "$L" >/dev/null 2>&1 && bad "starts without Tor's socket" || ok "refuses to start without Tor's socket"
rm -f /opt/tor-browser/Browser/start-tor-browser
for ((i=${#created[@]}-1; i>=0; i--)); do sudo -n rm -rf "${created[$i]}"; done
rm -rf "$T"
exit $fail
