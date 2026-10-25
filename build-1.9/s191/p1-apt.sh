#!/bin/bash
# 1.9.1 package changes (resumable via markers)
source /workspace/work/prestium/v20/chenv.sh
D=/workspace/work/prestium/v20/bh/s191; L=$D/p1-apt.log
echo "START $(date -u +%T)" >> $L
if [ ! -e $D/p1-install.done ]; then
  $C apt-get install $O --no-install-recommends keepassxc kleopatra audacity claws-mail claws-mail-pgpmime claws-mail-pgpinline xss-lock i3lock snowflake-client webtunnel lyrebird >> $L 2>&1 && touch $D/p1-install.done
  echo "INSTALL rc=$? $(date -u +%T)" >> $L
fi
if [ ! -e $D/p1-purge.done ]; then
  $C apt-get purge $O sylpheed sylpheed-plugins >> $L 2>&1 && touch $D/p1-purge.done
  echo "PURGE rc=$? $(date -u +%T)" >> $L
fi
$C dpkg --audit >> $L 2>&1; echo "AUDIT rc=$?" >> $L
$C dpkg-query -W -f='${Package} ${Version}\n' keepassxc kleopatra audacity claws-mail claws-mail-pgpmime claws-mail-pgpinline xss-lock i3lock snowflake-client webtunnel lyrebird diodon >> $L 2>&1
echo "P1-DONE $(date -u +%T)" >> $L
