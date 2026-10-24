#!/bin/bash
cd /workspace/work/prestium/v20; . ./chenv.sh
$C dpkg --configure -a
$C apt-get install $O -q --no-install-recommends onionshare onionshare-cli file-roller 7zip p7zip-full
$C apt-get purge $O -q gpg-wks-server exim4-base exim4-config exim4-daemon-light
$C apt-get -q check && echo S3PRE-DONE
