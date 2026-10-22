#!/bin/bash
set -e
V=/workspace/work/prestium/v19; R=$V/rootfs; F=$V/files/v20
bash $V/host.sh >/dev/null 2>&1
# --- users/groups (chroot, no mounts needed)
CH="sudo chroot $R env PATH=/usr/sbin:/usr/bin:/sbin:/bin"
grep -q '^thelounge:' $R/etc/passwd || $CH useradd --system --user-group --home-dir /var/lib/thelounge --no-create-home --shell /usr/sbin/nologin thelounge
grep -q '^prestium-localweb:' $R/etc/group || $CH groupadd --system prestium-localweb
$CH usermod -aG prestium-localweb user
grep -E '^(thelounge|prestium-localweb|user):' $R/etc/passwd $R/etc/group
# --- HexChat leftovers
sudo rm -rf $R/home/user/.config/hexchat $R/etc/skel/.config/hexchat
# --- Firefox (official tarball, signature verified separately)
sudo rm -rf $R/opt/firefox
sudo tar -xJf $V/dl/ff/firefox-158.0.1.tar.xz -C $R/opt
sudo chown -R root:root $R/opt/firefox
sudo install -d -m 755 $R/opt/firefox/distribution
sudo install -m 644 $F/policies.json $R/opt/firefox/distribution/policies.json
# --- Node.js (official, signature verified separately) - only the runtime
sudo rm -rf $R/opt/nodejs /tmp/nodex; mkdir -p /tmp/nodex
tar -xJf $V/dl/node/node-v24.22.1-linux-x64.tar.xz -C /tmp/nodex
sudo install -d -m 755 $R/opt/nodejs $R/opt/nodejs/bin
sudo install -m 755 /tmp/nodex/node-v24.22.1-linux-x64/bin/node $R/opt/nodejs/bin/node
sudo install -m 644 /tmp/nodex/node-v24.22.1-linux-x64/LICENSE $R/opt/nodejs/LICENSE
rm -rf /tmp/nodex
# --- The Lounge (npm, registry signatures verified)
sudo rm -rf $R/opt/thelounge; sudo install -d -m 755 $R/opt/thelounge
sudo cp -a /tmp/lounge/package.json /tmp/lounge/package-lock.json /tmp/lounge/node_modules $R/opt/thelounge/
sudo chown -R root:root $R/opt/thelounge; sudo chmod -R u+rwX,go+rX,go-w $R/opt/thelounge
# home
sudo rm -rf $R/var/lib/thelounge
sudo install -d -m 700 $R/var/lib/thelounge $R/var/lib/thelounge/users $R/var/lib/thelounge/packages $R/var/lib/thelounge/packages/node_modules
sudo install -m 600 $F/config.js $R/var/lib/thelounge/config.js
sudo install -m 600 $F/packages.json $R/var/lib/thelounge/packages/package.json
sudo cp -r $F/autologin $R/var/lib/thelounge/packages/node_modules/thelounge-prestium-autologin
sudo chmod 700 $R/var/lib/thelounge/packages/node_modules/thelounge-prestium-autologin; sudo chmod 600 $R/var/lib/thelounge/packages/node_modules/thelounge-prestium-autologin/*
LU=$(awk -F: '$1=="thelounge"{print $3":"$4}' $R/etc/passwd)
sudo chown -R $LU $R/var/lib/thelounge
sudo install -d -m 755 $R/usr/local/share/prestium-thelounge $R/usr/local/share/prestium-localfox
sudo install -m 644 $F/prestium.json $R/usr/local/share/prestium-thelounge/prestium.json
sudo install -m 644 $F/user.js $R/usr/local/share/prestium-localfox/user.js
sudo install -m 755 $F/prestium-thelounge-setup $R/usr/local/sbin/prestium-thelounge-setup
sudo install -m 755 $F/prestium-localfox $F/prestium-irc $F/prestium-i2p-console $R/usr/local/bin/
sudo install -m 644 $F/thelounge.service $R/etc/systemd/system/thelounge.service
sudo ln -sfn /etc/systemd/system/thelounge.service $R/etc/systemd/system/multi-user.target.wants/thelounge.service
# --- prestium-torrents opens in the local Firefox
sudo sed -i 's|^os.execvp("librewolf-i2p", \["librewolf-i2p", b + "web/"\])$|os.execvp("/usr/local/bin/prestium-localfox", ["prestium-localfox", b + "web/"])|' $R/usr/local/bin/prestium-torrents
grep -n execvp $R/usr/local/bin/prestium-torrents
# --- desktop entries
sudo tee $R/usr/share/applications/prestium-irc.desktop >/dev/null <<'D'
[Desktop Entry]
Type=Application
Name=IRC (The Lounge)
Comment=Chat on the IRC2P and Ilita networks over I2P (opens in the local-only Firefox)
Exec=/usr/local/bin/prestium-irc
Icon=internet-group-chat
Categories=Network;Chat;IRCClient;
Terminal=false
D
sudo tee $R/usr/share/applications/prestium-i2p-console.desktop >/dev/null <<'D'
[Desktop Entry]
Type=Application
Name=I2P Router Console
Comment=i2pd web console (opens in the local-only Firefox)
Exec=/usr/local/bin/prestium-i2p-console
Icon=network-workgroup
Categories=Network;
Terminal=false
D
sudo rm -f $R/usr/share/applications/io.github.Hexchat.desktop
$CH update-desktop-database -q /usr/share/applications
grep -c -i hexchat $R/usr/share/applications/mimeinfo.cache || true
# --- menu
sudo python3 - $R/etc/xdg/openbox/menu.xml <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old_console='''  <item label="I2P WebConsole">
    <action name="Execute"><execute>librewolf-i2p "http://127.0.0.1:7070"</execute></action>
  </item>'''
new_console='''  <item label="I2P Router Console">
    <action name="Execute"><execute>/usr/local/bin/prestium-i2p-console</execute></action>
  </item>'''
old_hex='''    <item label="HexChat IRC">
      <action name="Execute"><execute>hexchat</execute></action>
    </item>'''
new_irc='''    <item label="IRC (The Lounge)">
      <action name="Execute"><execute>/usr/local/bin/prestium-irc</execute></action>
    </item>'''
assert s.count(old_console)==1 and s.count(old_hex)==1
s=s.replace(old_console,new_console).replace(old_hex,new_irc)
open(p,'w').write(s)
PY
# --- i2pd tunnels: drop the HexChat SOCKS proxy (4449), add the IRC client tunnels
sudo python3 - $R/var/lib/i2pd/tunnels.conf $F/irc-tunnels.conf <<'PY'
import sys,re
p,add=sys.argv[1],sys.argv[2]; s=open(p).read()
old='''[HexChat SOCKS Proxy]
type = socks
address = 127.0.0.1
port = 4449
inbound.quantity = 2
outbound.quantity = 2

'''
assert s.count(old)==1; s=s.replace(old,'')
assert '[IRC2P]' not in s
s=s.rstrip('\n')+'\n'+open(add).read()
open(p,'w').write(s)
PY
sudo chown 2000:2000 $R/var/lib/i2pd/tunnels.conf; sudo chmod 644 $R/var/lib/i2pd/tunnels.conf
ls -la $R/var/lib/i2pd/ | grep -E 'tunnels|i2pd.conf'
echo INST20-DONE
