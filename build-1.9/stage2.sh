#!/bin/bash
# stage2: repos, users, kernel+firmware (Tails set), full package set
cd /workspace/work/prestium/v20; . ./chenv.sh; OLD=/workspace/work/prestium/v19/rootfs
M=stage2.done; touch $M
step(){ grep -qx "$1" $M; }
done_(){ echo "$1" >> $M; echo "== $1 done $(date -u +%T)"; }
if ! step repos; then
 for k in deb.torproject.org-keyring.gpg librewolf.gpg purplei2p.gpg; do sudo cp $OLD/usr/share/keyrings/$k $B/usr/share/keyrings/; done
 sudo tee $B/etc/apt/sources.list >/dev/null <<'S'
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware
deb http://deb.debian.org/debian testing main non-free-firmware
S
 sudo tee $B/etc/apt/sources.list.d/tor.list >/dev/null <<'S'
deb [arch=amd64 signed-by=/usr/share/keyrings/deb.torproject.org-keyring.gpg] https://deb.torproject.org/torproject.org trixie main
S
 sudo tee $B/etc/apt/sources.list.d/purplei2p.list >/dev/null <<'S'
deb [arch=amd64 signed-by=/usr/share/keyrings/purplei2p.gpg] https://repo.i2pd.xyz/debian trixie main
S
 sudo cp $OLD/etc/apt/sources.list.d/librewolf.sources $B/etc/apt/sources.list.d/
 # testing only for the firmware packages Tails takes newer than trixie; backports for firmware-nonfree
 sudo tee $B/etc/apt/preferences.d/prestium >/dev/null <<'S'
Package: *
Pin: release a=testing
Pin-Priority: -10

Package: firmware-sof-signed firmware-carl9170 firmware-ath9k-htc firmware-linux-free
Pin: release a=testing
Pin-Priority: 990

Package: *
Pin: release a=trixie-backports
Pin-Priority: 100

Package: src:firmware-nonfree
Pin: release a=trixie-backports
Pin-Priority: 990
S
 sudo rm -f $B/etc/apt/apt.conf.d/00mmdebstrap
 $C apt-get update -q || exit 1
 done_ repos
fi
if ! step users; then
 # fixed ids as in 1.8 for the accounts the firewall/ownership depend on
 $C groupadd -g 2000 i2pd; $C useradd -r -u 2000 -g 2000 -d /var/lib/i2pd -s /usr/sbin/nologin i2pd
 $C groupadd -g 1000 user; $C useradd -u 1000 -g 1000 -d /home/user -m -s /bin/bash user; $C passwd -d user
 echo 'locales locales/default_environment_locale select en_US.UTF-8
locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8
keyboard-configuration keyboard-configuration/layoutcode string us
keyboard-configuration keyboard-configuration/modelcode string pc105
firmware-ipw2x00 firmware-ipw2x00/license/accepted boolean true
iperf3 iperf3/start_daemon boolean false
tzdata tzdata/Areas select Etc
tzdata tzdata/Zones/Etc select UTC' | $C debconf-set-selections
 sudo cp $OLD/etc/default/keyboard $OLD/etc/default/locale $B/etc/default/; sudo cp $OLD/etc/locale.gen $B/etc/
 $C locale-gen
 done_ users
fi
if ! step kernel; then
 $C apt-get install $O -q -t trixie-security linux-image-amd64 || exit 1
 FW="amd64-microcode intel-microcode firmware-amd-graphics firmware-ath9k-htc firmware-atheros firmware-brcm80211 firmware-carl9170 firmware-cirrus firmware-intel-graphics firmware-intel-misc firmware-intel-sound firmware-ipw2x00 firmware-iwlwifi firmware-libertas firmware-linux firmware-linux-free firmware-linux-nonfree firmware-mediatek firmware-misc-nonfree firmware-nvidia-graphics firmware-realtek firmware-sof-signed firmware-ti-connectivity firmware-zd1211 atmel-firmware wireless-regdb"
 $C apt-get install $O -q --no-install-recommends $FW || exit 1
 done_ kernel
fi
if ! step pkgs; then
 [ -s pkglist-final.txt ] || { L=""; for p in $(cat pkglist-cand.txt); do $C apt-cache show --no-all-versions $p >/dev/null 2>&1 && L="$L $p" || echo "NOT-IN-TRIXIE $p"; done; echo "$L" > pkglist-final.txt; }
 # gajim-omemo: OMEMO is built into Gajim 2.x (package dropped after bookworm); speedcrunch: not in trixie -> bookworm build (deps satisfied by trixie)
 L=$(cat pkglist-final.txt | tr ' ' '\n' | grep -vxE 'gajim-omemo|speedcrunch' | tr '\n' ' ')
 grep -q bookworm $B/etc/apt/sources.list || { echo "deb http://deb.debian.org/debian bookworm main" | sudo tee -a $B/etc/apt/sources.list >/dev/null; printf '\nPackage: *\nPin: release n=bookworm\nPin-Priority: -10\n\nPackage: speedcrunch\nPin: release n=bookworm\nPin-Priority: 990\n' | sudo tee -a $B/etc/apt/preferences.d/prestium >/dev/null; $C apt-get update -q; }
 $C apt-get install $O -q --no-install-recommends $L live-boot live-boot-initramfs-tools tor tor-geoipdb deb.torproject.org-keyring nyx i2pd librewolf polkitd pkexec speedcrunch || exit 1
 done_ pkgs
fi
$C apt-get -q $O full-upgrade
echo STAGE2-DONE
