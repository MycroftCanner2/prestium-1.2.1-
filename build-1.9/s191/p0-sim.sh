#!/bin/bash
# simulate package changes (resumable: just rerun)
source /workspace/work/prestium/v20/chenv.sh
L=/workspace/work/prestium/v20/bh/s191/p0-sim.log
echo "START $(date -u +%T)" > $L
$C apt-get update -q >> $L 2>&1; echo "UPD $?" >> $L
for p in keepassxc kleopatra gpa audacity claws-mail claws-mail-pgpmime claws-mail-pgpinline xss-lock i3lock snowflake-client webtunnel lyrebird obfs4proxy onion-grater python3-stem; do
  $C apt-cache policy $p 2>&1 | head -3 >> $L
done
$C apt-get -s install --no-install-recommends keepassxc kleopatra audacity claws-mail claws-mail-pgpmime claws-mail-pgpinline xss-lock i3lock snowflake-client >> $L 2>&1
$C apt-get -s purge sylpheed sylpheed-plugins >> $L 2>&1
echo "SIM-DONE $(date -u +%T)" >> $L
