#!/bin/bash
# 1.9.1.1: apt upgrade + pidgin/otr in the chroot
cd /workspace/work/prestium/v20; . ./chenv.sh
$C apt-get update 2>&1 | tail -15
$C apt-get $O -s upgrade | grep '^Inst' > bh/backup-1911/apt-upgrade-plan.txt
$C apt-get $O upgrade 2>&1 | tail -30
$C apt-get $O --no-install-recommends install pidgin pidgin-otr 2>&1 | tail -15
$C apt-get clean
echo "APT-EXIT $?"
