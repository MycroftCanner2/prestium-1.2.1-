#!/bin/bash
# stage3: carry over every Prestium customization from the 1.8 rootfs onto the fresh trixie rootfs
set -e
cd /workspace/work/prestium/v20; . ./chenv.sh
OLD=/workspace/work/prestium/v19/rootfs; DL=/workspace/work/prestium/v20/dl
M=stage3.done; touch $M
step(){ grep -qx "$1" $M; }
done_(){ echo "$1" >> $M; echo "== $1 done $(date -u +%T)"; }
SR="sudo"

if ! step users; then
  for g in autologin i2ptorrents prestium-localweb; do $C getent group $g >/dev/null || $C groupadd -r $g; done
  $C getent passwd prestium-htp >/dev/null || $C useradd -r -U -M -d /nonexistent -s /usr/sbin/nologin prestium-htp
  $C getent passwd thelounge >/dev/null || $C useradd -r -U -M -d /var/lib/thelounge -s /usr/sbin/nologin thelounge
  $C usermod -a -G i2pd,debian-tor,autologin,i2ptorrents,prestium-localweb user
  $C usermod -a -G i2ptorrents i2pd
  $C usermod -s /usr/sbin/nologin root
  $C passwd -l root
  $C passwd -d user
  done_ users
fi

if ! step overlay; then
  $SR python3 overlay.py overlay-list.txt
  $SR python3 overlay.py overlay-conf.txt
  # i2pd: Prestium's real config files (package ships symlinks to /etc/i2pd)
  for f in i2pd.conf tunnels.conf; do [ -L $B/var/lib/i2pd/$f ] && { echo "ERROR $f still symlink"; exit 1; }; done
  $SR install -o 2000 -g 2000 -m 0644 $DL/su3.new $B/var/lib/i2pd/stormycloud-i2pseeds.su3
  done_ overlay
fi

if ! step merges; then
  printf 'Prestium 1.9 \\n \\l\n\n' | $SR tee $B/etc/issue >/dev/null
  printf 'Prestium 1.9\n' | $SR tee $B/etc/issue.net >/dev/null
  $SR tee $B/usr/lib/os-release >/dev/null <<'EOF'
PRETTY_NAME="Prestium"
NAME="Prestium"
VERSION_ID="1.9"
VERSION="1.9 (trixie)"
ID=prestium
ID_LIKE=debian
VERSION_CODENAME=trixie
HOME_URL="https://prestium.org/"
EOF
  # memlockd: trixie default + Prestium emergency-shutdown block
  $SR sh -c "sed -n '/^# Prestium 1.8: keep what/,\$p' $OLD/etc/memlockd.cfg > /tmp/mlk"
  sudo grep -q 'Prestium' $B/etc/memlockd.cfg || { echo | $SR tee -a $B/etc/memlockd.cfg >/dev/null; $SR sh -c "cat /tmp/mlk >> $B/etc/memlockd.cfg"; }
  # plymouth theme
  sudo grep -q '^Theme=connect' $B/etc/plymouth/plymouthd.conf || printf '[Daemon]\nTheme=connect\n' | $SR tee -a $B/etc/plymouth/plymouthd.conf >/dev/null
  # LibreWolf: new upstream librewolf.cfg + Prestium block; policies.json = upstream + Prestium changes (upstream unchanged otherwise)
  if ! sudo grep -q 'PRESTIUM BEGIN' $B/usr/share/librewolf/librewolf.cfg; then
    $SR sh -c "echo >> $B/usr/share/librewolf/librewolf.cfg; sed -n '/==== PRESTIUM BEGIN ====/,/==== PRESTIUM END ====/p' $OLD/usr/share/librewolf/librewolf.cfg >> $B/usr/share/librewolf/librewolf.cfg"
  fi
  $SR cp $OLD/usr/share/librewolf/distribution/policies.json $B/usr/share/librewolf/distribution/policies.json
  $SR rm -f $B/etc/apparmor.d/librewolf $B/etc/init.d/i2pd
  # live-boot: SATA/IDE optical fallback (internal disks stay hidden by the ahci/libata blacklist)
  $SR python3 - <<'EOF'
p='/workspace/work/prestium/v20/rootfs/usr/lib/live/boot/9990-main.sh'
s=open(p).read()
blk='''				# Prestium: ahci/libata are blacklisted so internal disks stay hidden.
				# If no USB live medium shows up, the image was probably booted from a
				# SATA/IDE optical drive (DVD or a VM's CD drive): load only those
				# drivers, then keep looking.
				if [ "$i" -eq 8 ]
				then
					for m in scsi_common scsi_mod cdrom sr_mod libata ata_piix ata_generic libahci ahci
					do
						f=$(find /lib/modules/$(uname -r) /usr/lib/modules/$(uname -r) -name "${m}.ko*" 2>/dev/null | head -n1)
						[ -n "$f" ] && insmod "$f" 2>/dev/null
					done
					sleep 2
				fi

'''
anchor='''				if [ -n "${livefs_root}" ]
				then
					break
				fi

				sleep 1
				i=$((i + 1))'''
if 'Prestium: ahci/libata' not in s:
    assert s.count(anchor)==1, 'anchor'
    s=s.replace(anchor, anchor.replace('				sleep 1\n', blk+'				sleep 1\n'))
    open(p,'w').write(s)
print('9990 patched')
EOF
  # ferm: Tor's uid differs on trixie -> match by name (same rule)
  $SR sed -i 's/^def \$tor_uid = 107;/def $tor_uid = debian-tor;/' $B/etc/ferm/ferm.conf
  sudo grep -q 'def $tor_uid = debian-tor;' $B/etc/ferm/ferm.conf
  # AppArmor: Debian skips loading profiles on a live overlay (ConditionPathExists=!/run/live/overlay/work); Prestium enforces them
  $SR mkdir -p $B/etc/systemd/system/apparmor.service.d
  printf '# Prestium 1.9: load AppArmor profiles on the live system too (Debian skips them on a live overlay)\n[Unit]\nConditionPathExists=\n' | $SR tee $B/etc/systemd/system/apparmor.service.d/prestium-live.conf >/dev/null
  # The Lounge defaults: #i2p-help (closed) and Ilita #dev removed from every default
  $SR sed -i 's/join: "#i2p,#i2p-chat,#i2p-dev,#i2p-help"/join: "#i2p,#i2p-chat,#i2p-dev"/' $B/var/lib/thelounge/config.js
  $SR python3 - <<'EOF'
import json
p='/workspace/work/prestium/v20/rootfs/usr/local/share/prestium-thelounge/prestium.json'
u=json.load(open(p))
for n in u['networks']:
    n['channels']=[c for c in n['channels'] if not (c['name']=='#i2p-help' or (n['name']=='Ilita' and c['name']=='#dev'))]
json.dump(u,open(p,'w'),indent=2); open(p,'a').write('\n')
print([(n['name'],[c['name'] for c in n['channels']]) for n in u['networks']])
EOF
  if sudo grep -rq 'i2p-help' $B/var/lib/thelounge $B/usr/local/share/prestium-thelounge $B/usr/local/sbin/prestium-thelounge-setup; then echo 'ERROR i2p-help remains'; exit 1; fi
  done_ merges
fi

if ! step opt; then
  $SR rm -rf $B/opt/tor-browser $B/opt/firefox $B/opt/nodejs $B/opt/thelounge /tmp/nodex
  $SR tar -xJf $DL/tb.tar.xz -C $B/opt
  $SR mkdir -p $B/opt/tor-browser/Browser/distribution
  $SR cp $OLD/opt/tor-browser/Browser/distribution/policies.json $B/opt/tor-browser/Browser/distribution/
  $SR chown -R 1000:1000 $B/opt/tor-browser; $SR chmod 700 $B/opt/tor-browser
  $SR tar -xJf $DL/ff.tar.xz -C $B/opt
  $SR cp $OLD/opt/firefox/distribution/policies.json $B/opt/firefox/distribution/
  $SR chown -R root:root $B/opt/firefox
  $SR mkdir -p /tmp/nodex $B/opt/nodejs/bin; $SR tar -xJf $DL/node.tar.xz -C /tmp/nodex
  $SR install -m 0755 /tmp/nodex/node-v24.22.1-linux-x64/bin/node $B/opt/nodejs/bin/node
  $SR install -m 0644 /tmp/nodex/node-v24.22.1-linux-x64/LICENSE $B/opt/nodejs/LICENSE
  $SR rm -rf /tmp/nodex
  echo "/opt/thelounge/**" > /tmp/ol-lounge; $SR python3 overlay.py /tmp/ol-lounge
  # AppImages / Feather (all signature- or digest-verified in dl/)
  $SR rm -f $B/usr/local/bin/KeePassXC-*.AppImage $B/usr/local/bin/keepassxc
  $SR install -m 0755 $DL/kpxc.AppImage $B/usr/local/bin/KeePassXC-2.8.0.AppImage
  $SR ln -sf KeePassXC-2.8.0.AppImage $B/usr/local/bin/keepassxc
  $SR install -m 0755 $DL/audacity.AppImage $B/usr/local/bin/audacity-4.0.1.AppImage
  $SR install -m 0755 $DL/gpgfe.AppImage $B/usr/local/bin/GpgFrontend-2.2.2.AppImage
  $SR sh -c "unzip -p $DL/feather.zip feather-2.8.1 > $B/usr/local/bin/feather"; $SR chmod 0755 $B/usr/local/bin/feather
  done_ opt
fi

if ! step apps; then
  # OnionShare (as in Tails) on the system Tor: control socket /run/tor/control (user is in debian-tor), cookie auth
  for d in $B/etc/skel/.config/onionshare $B/home/user/.config/onionshare; do
    $SR mkdir -p $d
    printf '{\n  "connection_type": "socket_file",\n  "socket_file_path": "/run/tor/control",\n  "auth_type": "no_auth",\n  "auto_connect": true,\n  "use_autoupdate": false\n}\n' | $SR tee $d/onionshare.json >/dev/null
  done
  $SR chown -R 1000:1000 $B/home/user/.config/onionshare
  # Openbox menu: OnionShare; Archive Manager = File Roller (Tails' archive manager)
  $SR python3 - <<'EOF'
p='/workspace/work/prestium/v20/rootfs/etc/xdg/openbox/menu.xml'
s=open(p).read()
if 'onionshare' not in s:
    a='''    <item label="IRC (The Lounge)">
      <action name="Execute"><execute>/usr/local/bin/prestium-irc</execute></action>
    </item>
'''
    assert a in s
    s=s.replace(a, a+'''    <item label="OnionShare">
      <action name="Execute"><execute>onionshare</execute></action>
    </item>
''')
s=s.replace('<item label="Archive Manager">\n      <action name="Execute"><execute>xarchiver</execute></action>','<item label="Archive Manager">\n      <action name="Execute"><execute>file-roller</execute></action>')
assert 'file-roller' in s
open(p,'w').write(s)
EOF
  # archives open in File Roller (zip, rar, 7z, tar...)
  $SR mkdir -p $B/etc/xdg
  $SR tee $B/etc/xdg/mimeapps.list >/dev/null <<'EOF'
[Default Applications]
application/zip=org.gnome.FileRoller.desktop
application/x-zip-compressed=org.gnome.FileRoller.desktop
application/vnd.rar=org.gnome.FileRoller.desktop
application/x-rar=org.gnome.FileRoller.desktop
application/x-rar-compressed=org.gnome.FileRoller.desktop
application/x-7z-compressed=org.gnome.FileRoller.desktop
application/x-tar=org.gnome.FileRoller.desktop
application/x-compressed-tar=org.gnome.FileRoller.desktop
application/x-xz-compressed-tar=org.gnome.FileRoller.desktop
application/x-bzip-compressed-tar=org.gnome.FileRoller.desktop
application/gzip=org.gnome.FileRoller.desktop
EOF
  done_ apps
fi

if ! step alternatives; then
  $C update-alternatives --set x-www-browser /usr/bin/librewolf
  $C update-alternatives --set gnome-www-browser /usr/bin/librewolf
  $C update-alternatives --set x-terminal-emulator /usr/bin/lxterm
  $C update-alternatives --set x-session-manager /usr/bin/openbox-session
  $C update-alternatives --set x-window-manager /usr/bin/openbox
  $C update-alternatives --set editor /bin/nano
  $C update-alternatives --set pager /usr/bin/less
  $C update-alternatives --set pinentry /usr/bin/pinentry-gnome3 || true
  $C update-alternatives --set iptables /usr/sbin/iptables-nft
  $C update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
  $C update-alternatives --set lightdm-greeter /usr/share/xgreeters/lightdm-gtk-greeter.desktop || true
  done_ alternatives
fi

if ! step systemd; then
  # same enable set as 1.8
  $C systemctl enable prestium-timesync.service prestium-usb-watchdog.service thelounge.service i2pd.service tor.service memlockd.service \
     ferm.service apparmor.service NetworkManager.service ModemManager.service wpa_supplicant.service udisks2.service console-setup.service \
     keyboard-setup.service networking.service pcscd.socket systemd-pstore.service remote-fs.target ifupdown-wait-online.service lightdm.service
  $C systemctl mask NetworkManager-wait-online.service
  # no timers (live system), as in 1.8
  $SR rm -rf $B/etc/systemd/system/timers.target.wants
  done_ systemd
fi
echo STAGE3-DONE
