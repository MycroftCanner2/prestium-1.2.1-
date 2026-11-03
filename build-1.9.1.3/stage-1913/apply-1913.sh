#!/bin/bash
# Prestium 1.9.1.3: every change on top of the 1.9.1.2 rootfs. Idempotent: run it again any time.
# Backups of the 1.9.1.2 files (taken once, first run) in bh/backup-1913/rootfs/...
# lurch (OMEMO) + purple-xmpp-carbons are built/installed by stage-1913/lurch/build-lurch.sh (run first).
set -e
cd /workspace/work/prestium/v20
R=rootfs; B=bh/backup-1913; S=stage-1913
sudo mkdir -p $B; sudo chown $(id -u) $B
bk(){ local x; [ -e $B/.applied ] && return 0; for x in "$@"; do if sudo test -e "$R/$x" && ! sudo test -e "$B/$R/$x"; then sudo cp -a --parents "$R/$x" $B/; echo "backup $x"; fi; done; }
B32=proxy4uwdijqxac2bvdx4fuhem6njmiwukuk2gelejv2nzxka2xq.b32.i2p

echo "== 1 Unlock Volume fix in the main squashfs; no zfix layer"
sudo grep -q crypto_unknown $R/usr/local/bin/prestium-unlock-volume || { echo "rootfs unlock-volume lacks crypto_unknown fix"; exit 1; }
cmp -s stage-1912/prestium-unlock-volume <(sudo cat $R/usr/local/bin/prestium-unlock-volume) && echo "rootfs unlock-volume = stage-1912 fixed version"
if [ -e iso/live/zfix-1912.squashfs ]; then
  [ -e $B/zfix-1912.squashfs ] || cp -a iso/live/zfix-1912.squashfs $B/
  rm -f iso/live/zfix-1912.squashfs; echo "removed iso/live/zfix-1912.squashfs (copy in $B)"
fi
ls iso/live/*.squashfs

echo "== 2 I2P outproxy acetone by b32 ($B32)"
FILES="var/lib/i2pd/tunnels.conf var/lib/i2pd/i2pd.conf etc/i2pd/i2pd.conf usr/local/bin/librewolf-i2p"
bk $FILES usr/local/bin/prestium-tunnel-hops
for x in $FILES; do sudo sed -i "s/outproxy\.acetone\.i2p/$B32/g" $R/$x; done
# librewolf-i2p comment: name the outproxy and its address
sudo sed -i "s|(${B32}, http://${B32}:3128)|(acetone, http://${B32}:3128)|" $R/usr/local/bin/librewolf-i2p
sudo sed -i "s|^## Prestium 1.9.1.2: acetone outproxy.|## Prestium 1.9.1.3: acetone outproxy (b32 ${B32%%.*}...). |" $R/var/lib/i2pd/i2pd.conf
sudo chown 2000:2000 $R/var/lib/i2pd/i2pd.conf $R/var/lib/i2pd/tunnels.conf
# any other copy of the old hostname in the image (configs, docs)
for f in $(sudo grep -rlI 'outproxy\.acetone\.i2p' $R/etc $R/usr/local $R/var/lib/i2pd $R/home/user $R/usr/share/librewolf $R/usr/share/doc/prestium* 2>/dev/null); do
  bk "${f#$R/}"; sudo sed -i "s/outproxy\.acetone\.i2p/$B32/g" "$f"; echo "b32 -> $f"; done
LEFT=$(sudo grep -rlI 'outproxy\.acetone\.i2p' $R/etc $R/usr/local $R/var/lib/i2pd $R/home $R/opt/tor-browser/Browser/distribution 2>/dev/null || true)
[ -z "$LEFT" ] || { echo "old hostname still in: $LEFT"; exit 1; }
sudo grep -Hn "^outproxy = http://$B32:3128\|^destination = $B32" $R/var/lib/i2pd/tunnels.conf $R/var/lib/i2pd/i2pd.conf $R/etc/i2pd/i2pd.conf
[ "$(sudo grep -c "^destination = $B32" $R/var/lib/i2pd/tunnels.conf)" = 2 ] || { echo "socks-outproxy destinations not set"; exit 1; }
# prestium-tunnel-hops only rewrites inbound/outbound.length (outproxy tunnels skipped): run it on copies to prove the b32 lines survive
TT=$(mktemp -d); sudo cp $R/var/lib/i2pd/tunnels.conf $R/var/lib/i2pd/i2pd.conf $TT/; sudo chown $(id -u) $TT/*
sudo sed -n "/^python3 - /,/^PY$/p" $R/usr/local/bin/prestium-tunnel-hops | sed '1d;$d' > $TT/hops.py
python3 $TT/hops.py $TT/tunnels.conf $TT/i2pd.conf 5 && echo "tunnel-hops dry run (5 hops): b32 lines kept: $(grep -c "$B32" $TT/tunnels.conf) in tunnels.conf, $(grep -c "$B32" $TT/i2pd.conf) in i2pd.conf; outproxy tunnels still 1 hop: $(grep -A12 '^\[socks-outproxy-tcp\]' $TT/tunnels.conf | grep -c 'bound.length = 1')"
rm -rf $TT

echo "== 3 Pidgin: label 'Pidgin', lurch (OMEMO) + carbons + OTR loaded"
LP=/usr/lib/x86_64-linux-gnu/purple-2          # Debian's libpurple plugin dir (pkg-config purple plugindir)
sudo test -e $R/usr/lib/purple-2/lurch.so -o -e $R$LP/lurch.so || { echo "lurch.so missing: run stage-1913/lurch/build-lurch.sh"; exit 1; }
if sudo test -f $R/usr/lib/purple-2/lurch.so -a ! -L $R/usr/lib/purple-2/lurch.so; then
  sudo mv -f $R/usr/lib/purple-2/lurch.so $R$LP/lurch.so
fi
# /usr/lib/purple-2/lurch.so (as asked) -> the dir Debian's Pidgin actually scans
sudo mkdir -p $R/usr/lib/purple-2; sudo ln -sfn $LP/lurch.so $R/usr/lib/purple-2/lurch.so
sudo chmod 644 $R$LP/lurch.so; sudo test -e $R$LP/carbons.so || { echo "carbons.so missing"; exit 1; }
sudo chroot $R ldd $LP/lurch.so | grep 'not found' && { echo "lurch.so unresolved libs"; exit 1; } || echo "lurch.so libs resolve"
sudo chroot $R ls -la $LP/lurch.so $LP/carbons.so /usr/lib/purple-2/lurch.so
[ -e $B/install-pidgin-1911.sh.orig ] || cp -a stage-1911/pidgin/install-pidgin-1911.sh $B/install-pidgin-1911.sh.orig
[ -e $B/prefs.xml.orig ] || cp -a stage-1911/pidgin/prefs.xml $B/prefs.xml.orig
cmp -s $S/install-pidgin-1911.sh.new stage-1911/pidgin/install-pidgin-1911.sh || install -m755 $S/install-pidgin-1911.sh.new stage-1911/pidgin/install-pidgin-1911.sh
cmp -s $S/prefs.xml.new stage-1911/pidgin/prefs.xml || install -m644 $S/prefs.xml.new stage-1911/pidgin/prefs.xml
bk etc/xdg/openbox/menu.xml usr/local/share/applications/pidgin.desktop home/user/.purple/prefs.xml etc/skel/.purple/prefs.xml
for M in $R/etc/xdg/openbox/menu.xml $R/home/user/.config/openbox/menu.xml $R/etc/skel/.config/openbox/menu.xml; do
  sudo test -e $M || continue; bk "${M#$R/}"
  sudo sed -i 's/<item label="Pidgin (Tor + OTR)">/<item label="Pidgin">/' $M
done
PIDGIN_BK=$B ./stage-1911/pidgin/install-pidgin-1911.sh
sudo grep -n -A1 'label="Pidgin"' $R/etc/xdg/openbox/menu.xml
sudo grep -c 'Pidgin (Tor' $R/etc/xdg/openbox/menu.xml $R/usr/local/share/applications/pidgin.desktop || true
for P in $R/home/user/.purple/prefs.xml $R/etc/skel/.purple/prefs.xml; do
  echo "$P: $(sudo grep -oE "item value='[^']*'" $P | tr '\n' ' ') socks5=$(sudo grep -c "value='socks5'" $P) 9050=$(sudo grep -c "value='9050'" $P) onlyprivate=$(sudo grep -c "name='onlyprivate' type='bool' value='1'" $P)"
  sudo python3 -c "import xml.dom.minidom,sys;xml.dom.minidom.parse(sys.argv[1])" $P
done
# AppArmor: profile (complain) already allows /usr/lib/x86_64-linux-gnu/purple-2/** mr and ~/.purple/** (lurch DB);
# Pidgin still only talks to Tor 9050: no firewall change.

echo "== 4 Tor Browser 16: show NoScript's toolbar button (tor-browser#41581 hides it via extensions.hideNoScript)"
TBD=$R/opt/tor-browser/Browser/distribution
bk opt/tor-browser/Browser/distribution/policies.json
sudo python3 - $TBD/policies.json <<'EOF'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); pol=d['policies']
# default (not locked): the about:addons NoScript "toolbar button" choice still works and is kept
pol.setdefault('Preferences',{})['extensions.hideNoScript']={'Value':False,'Status':'default'}
json.dump(d,open(p,'w'),indent=2); open(p,'a').write('\n'); print('TB policies', json.dumps(pol))
EOF
sudo chown --reference=$TBD $TBD/policies.json

echo "== 5 version 1.9.1.2 -> 1.9.1.3"
for x in etc/os-release usr/lib/os-release etc/issue etc/issue.net; do
  f=$R/$x; sudo test -L $f && continue
  if sudo grep -qF '1.9.1.2' $f; then bk $x; sudo sed -i 's/1\.9\.1\.2/1.9.1.3/g' $f; echo "version -> $f"; fi
done
grep -H VERSION $R/etc/os-release
sudo python3 -c "import xml.dom.minidom,sys;xml.dom.minidom.parse(sys.argv[1]);print('menu.xml well-formed')" $R/etc/xdg/openbox/menu.xml
sync
touch $B/.applied
echo APPLY-1913-OK
