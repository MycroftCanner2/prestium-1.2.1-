#!/bin/bash
cd /workspace/work/prestium/v20; . ./chenv.sh
$C dpkg --configure -a
FW="firmware-amd-graphics firmware-atheros firmware-brcm80211 firmware-cirrus firmware-intel-graphics firmware-intel-misc firmware-intel-sound firmware-ipw2x00 firmware-iwlwifi firmware-libertas firmware-linux firmware-linux-nonfree firmware-mediatek firmware-misc-nonfree firmware-nvidia-graphics firmware-realtek firmware-ti-connectivity"
$C apt-get install $O -q -t trixie-backports --no-install-recommends $FW
$C apt-get -q check && echo FWUP-DONE
