#!/bin/bash
source /workspace/work/prestium/v20/chenv.sh
V=/workspace/work/prestium/v20; B=$V/rootfs; L=$V/bh/s191/p4-verify.log
echo "START $(date -u +%T)" > $L
echo "--- initrd /shutdown" >> $L
python3 - >> $L 2>&1 <<'PY'
import subprocess
d=open('/workspace/work/prestium/v20/rootfs/boot/initrd.img-6.12.113+deb13-amd64','rb').read(); off=0
while d[off:off+6] in (b'070701',b'070702'):
    while True:
        ns=int(d[off+94:off+102],16); fs=int(d[off+54:off+62],16); name=d[off+110:off+110+ns-1]
        off+=110+ns; off=(off+3)&~3; off+=fs; off=(off+3)&~3
        if name==b'TRAILER!!!': break
    while d[off]==0: off+=1
p=subprocess.run('zstd -dcq | cpio -t --quiet 2>/dev/null',shell=True,input=d[off:],capture_output=True)
names=p.stdout.decode().split('\n')
print('entries',len(names),'shutdown:',[n for n in names if n.rstrip('/').endswith('shutdown') and 'systemd' not in n][:5], 'busybox:',[n for n in names if n.endswith('busybox')][:2])
PY
echo "--- ferm" >> $L; $C ferm --noexec --lines /etc/ferm/ferm.conf > $V/bh/s191/ferm-lines.txt 2>> $L; echo "ferm rc=$?" >> $L
echo "--- visudo" >> $L; $C visudo -c >> $L 2>&1; echo "visudo rc=$?" >> $L
echo "--- dpkg audit" >> $L; $C dpkg --audit >> $L 2>&1; echo "audit rc=$?" >> $L
echo "--- sh -n" >> $L
for f in usr/local/bin/tor-browser usr/local/bin/librewolf-i2p usr/local/bin/prestium-localfox usr/local/bin/prestium-lock-screen usr/local/sbin/prestium-session-password usr/local/sbin/prestium-firewall-early usr/local/sbin/prestium-wipe-session usr/local/lib/prestium-spoof-mac usr/lib/systemd/system-sleep/prestium-usb-watchdog usr/share/prestium/initramfs-shutdown usr/share/initramfs-tools/hooks/prestium-shutdown; do sh -n $B/$f && echo "ok $f" >> $L || echo "FAIL $f" >> $L; done
bash -n $B/usr/local/sbin/prestium-usb-watchdog && echo "ok bash watchdog" >> $L
python3 -m py_compile $B/usr/local/sbin/prestium-onion-grater $B/usr/local/sbin/prestium-initramfs-unpack && echo "ok py" >> $L
echo "--- apparmor" >> $L
for p in torbrowser.Browser.firefox usr.share.librewolf.librewolf system_tor usr.bin.i2pd; do timeout 900 $C apparmor_parser -QTK /etc/apparmor.d/$p >> $L 2>&1; echo "aa $p rc=$?" >> $L; done
echo "--- systemd units" >> $L; $C systemd-analyze verify --man=no prestium-onion-grater.service prestium-firewall-early.service prestium-initramfs-shutdown.service prestium-wipe-session.service >> $L 2>&1; echo "verify rc=$?" >> $L
echo "P4-DONE $(date -u +%T)" >> $L
