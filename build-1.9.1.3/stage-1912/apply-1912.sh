#!/bin/bash
# Prestium 1.9.1.2: every change on top of the 1.9.1.1 rootfs. Idempotent: run it again any time.
# Backups of the 1.9.1.1 files (taken once, first run) in bh/backup-1912/rootfs/...
set -e
cd /workspace/work/prestium/v20
R=rootfs; B=bh/backup-1912; S=stage-1912
sudo mkdir -p $B; sudo chown $(id -u) $B
bk(){ local x; [ -e $B/.applied ] && return 0; for x in "$@"; do if sudo test -e "$R/$x" && ! sudo test -e "$B/$R/$x"; then sudo cp -a --parents "$R/$x" $B/; echo "backup $x"; fi; done; }
py(){ sudo python3 - "$@"; }
NS='{73a6fe31-595d-460b-a920-fcc0f8843232}'
UBO='uBlock0@raymondhill.net'

echo "== 1 i2pd: acetone outproxy (HTTP 4444 + SOCKS 4447 via 4500), postman tunnels, IRC tunnels"
bk var/lib/i2pd/i2pd.conf var/lib/i2pd/tunnels.conf etc/i2pd/i2pd.conf etc/ferm/ferm.conf usr/local/bin/librewolf-i2p usr/local/bin/prestium-tunnel-hops
py <<'EOF'
import re
R='/workspace/work/prestium/v20/rootfs'
SEC=re.compile(r'^\s*\[([^\]]+)\]\s*$')
def secs(t):
    out=[[None,[]]]
    for l in t.splitlines():
        m=SEC.match(l)
        if m: out.append([m.group(1).strip(),[l]])
        else: out[-1][1].append(l)
    return out
def join(s): return '\n'.join(l for _,b in s for l in b).rstrip('\n')+'\n'
def setkeys(s,name,kv):
    for sec in s:
        if sec[0]==name:
            body=[l for l in sec[1][1:] if not any(re.match(r'^\s*'+re.escape(k)+r'\s*=',l) for k in kv)]
            i=0
            while i<len(body) and re.match(r'^\s*[^#\s][^=]*=',body[i]): i+=1   # after existing key lines
            sec[1]=[sec[1][0]]+body[:i]+['%s = %s'%(k,v) for k,v in kv.items()]+body[i:]
            return
    raise SystemExit('no section '+name)
# real config (i2pd.service runs --conf=/var/lib/i2pd/i2pd.conf) and the unused package default in /etc
for p,real in ((R+'/var/lib/i2pd/i2pd.conf',True),(R+'/etc/i2pd/i2pd.conf',False)):
    s=secs(open(p).read())
    # [httpproxy] stays disabled in the real config: 4444 is the tunnels.conf "Web Browser HTTP Proxy"
    setkeys(s,'httpproxy',{'outproxy':'http://outproxy.acetone.i2p:3128'})
    setkeys(s,'socksproxy',{'outproxy.enabled':'true','outproxy':'127.0.0.1','outproxyport':'4500'})
    open(p,'w').write(join(s))
p=R+'/var/lib/i2pd/tunnels.conf'
s=secs(open(p).read())
setkeys(s,'Web Browser HTTP Proxy',{'outproxy':'http://outproxy.acetone.i2p:3128'})
KEYL=re.compile(r'^\s*[^#;\s][^=]*=')
def drop(s,names):
    out=[]
    for name,body in s:
        if name in names:
            last=max([i for i,l in enumerate(body) if KEYL.match(l)]+[0])
            body=body[last+1:]          # keep the comment block that introduces the next section
        out.append([name,body])
    return out
first='[socks-outproxy-udp]' not in join(s)
s=drop(s,{'IRC2P-dg','IRC-Ilita-rusirc'}|({'SMTP','POP3'} if first else set()))
t=join(s)
t=re.sub(r'\n{3,}','\n\n',t)
t=t.replace('#outproxy = http://outproxy.purokishi.i2p\n','')
t=t.replace("# The Lounge connects to 6668 (IRC2P) and 6669 (Ilita) at start; the others are\n# the same networks' other servers",
            "# The Lounge connects to 6668 (IRC2P) and 6669 (Ilita) at start; the others\n# (6665 echelon, 6670 r4sas, 6671 acetone; 1.9.1.2: dg and rusirc removed) are\n# the same networks' other servers")
if first: t+='''
# Prestium 1.9.1.2: mail.i2p (postman) for Claws Mail ("Mail (I2P)")
[postman-smtp]
type = client
address = 127.0.0.1
port = 7659
destination = smtp.postman.i2p
destinationport = 25
keys = postman-smtp.dat
inbound.quantity = 2
outbound.quantity = 2

[postman-pop3]
type = client
address = 127.0.0.1
port = 7660
destination = pop.postman.i2p
destinationport = 110
keys = postman-pop3.dat
inbound.quantity = 2
outbound.quantity = 2

# Prestium 1.9.1.2: SOCKS outproxy (acetone) behind the i2pd SOCKS proxy 4447
# ([socksproxy] outproxy = 127.0.0.1:4500 in i2pd.conf). Only i2pd itself may
# connect to 4500 (firewall).
[socks-outproxy-tcp]
type = client
address = 127.0.0.1
port = 4500
keys = transient-outproxy
destination = outproxy.acetone.i2p
destinationport = 1080
inbound.length = 1
outbound.length = 1
inbound.lengthVariance = 1
outbound.lengthVariance = 1

[socks-outproxy-udp]
type = udpclient
address = 127.0.0.1
port = 4500
keys = transient-outproxy
destination = outproxy.acetone.i2p
destinationport = 1080
'''
open(p,'w').write(t)
print('i2pd configs written')
EOF
sudo sed -i 's|^## Prestium 1.7: StormyCloud outproxy (exit.stormycloud.i2p) by its b32 address|## Prestium 1.9.1.2: acetone outproxy. [httpproxy] stays disabled: the 4444 proxy is\n## "Web Browser HTTP Proxy" in tunnels.conf (same outproxy). The StormyCloud reseed below is unrelated.|' $R/var/lib/i2pd/i2pd.conf
sudo chown 2000:2000 $R/var/lib/i2pd/i2pd.conf $R/var/lib/i2pd/tunnels.conf
# ferm: i2pd (uid 2000) -> its own SOCKS outproxy client tunnel 127.0.0.1:4500
if ! sudo grep -q 'Prestium 1.9.1.2: i2pd SOCKS outproxy' $R/etc/ferm/ferm.conf; then
py <<'EOF'
p='/workspace/work/prestium/v20/rootfs/etc/ferm/ferm.conf'
L=open(p).read().split('\n')
o=next(i for i,l in enumerate(L) if l.strip()=='chain OUTPUT {')
j=next(i for i in range(o,len(L)) if L[i].strip()=='outerface lo {')
ind=L[j][:len(L[j])-len(L[j].lstrip())]
L[j:j]=[ind+'# Prestium 1.9.1.2: i2pd SOCKS outproxy: i2pd may reach its own client tunnel 127.0.0.1:4500',
        ind+'mod owner uid-owner $i2pd_uid outerface lo daddr 127.0.0.1 proto (tcp udp) dport 4500 ACCEPT;']
open(p,'w').write('\n'.join(L)); print('ferm rule added before line',j+1)
EOF
fi
sudo chroot $R ferm --noexec --lines /etc/ferm/ferm.conf >/tmp/ferm-1912.txt 2>&1 && echo "ferm parses OK ($(grep -c 4500 /tmp/ferm-1912.txt) rules with 4500)" || { echo "FERM PARSE FAIL"; cat /tmp/ferm-1912.txt; exit 1; }
# tunnel hops: keep the outproxy tunnels at the configured 1 hop (+variance)
if ! sudo grep -q 'socks-outproxy' $R/usr/local/bin/prestium-tunnel-hops; then
  sudo sed -i 's/    if name is not None and "type" in keys(body): body = setlen(body)/    if name is not None and "type" in keys(body) and not name.startswith("socks-outproxy"): body = setlen(body)   # 1.9.1.2: outproxy tunnels keep their 1-hop setting/' $R/usr/local/bin/prestium-tunnel-hops
  sudo grep -q 'socks-outproxy' $R/usr/local/bin/prestium-tunnel-hops
fi
sudo sed -i -e 's/(exit\.stormycloud\.i2p)/(outproxy.acetone.i2p, http:\/\/outproxy.acetone.i2p:3128)/' \
  -e 's/^# Prestium: "Web Browser (I2P; clearnet via I2P outproxy)"/# Prestium: "I2P Browser"/' $R/usr/local/bin/librewolf-i2p

echo "== 2 LibreWolf: NoScript (side-loaded from distribution/extensions, unchanged) allowed in private windows"
bk usr/share/librewolf/distribution/policies.json
sudo test -e "$R/usr/share/librewolf/distribution/extensions/$NS.xpi" || { echo "LibreWolf NoScript xpi missing"; exit 1; }
py <<EOF
import json
p='/workspace/work/prestium/v20/rootfs/usr/share/librewolf/distribution/policies.json'
d=json.load(open(p)); es=d['policies'].setdefault('ExtensionSettings',{})
e=es.setdefault('$NS',{})
e['private_browsing']=True
json.dump(d,open(p,'w'),indent=4); open(p,'a').write('\n'); print('librewolf NoScript policy', e)
EOF

echo "== 3 menu label 'I2P Browser'"
bk etc/xdg/openbox/menu.xml usr/local/share/applications/librewolf.desktop home/user/.config/openbox/menu.xml etc/skel/.config/openbox/menu.xml
for f in $(sudo grep -rlE 'Web Browser \(I2P' $R/etc $R/usr/local $R/usr/share/applications $R/home/user 2>/dev/null); do
  bk "${f#$R/}"
  sudo sed -i -E 's/Web Browser \(I2P(; clearnet via I2P outproxy)?\)/I2P Browser/g' "$f"; echo "renamed in $f"
done

echo "== 4 Tor Browser 16: uBlock Origin back, NoScript + uBlock pinned to the toolbar"
TBD=$R/opt/tor-browser/Browser/distribution
bk opt/tor-browser/Browser/distribution/policies.json
# TB 15 had no uBlock (pristine tarball; policies = DisableAppUpdate only, bh/backup-1911/tb15):
# use the AMO-signed uBlock xpi LibreWolf already ships (side-load = same method as TB's NoScript)
UX=$R/usr/share/librewolf/distribution/extensions/$UBO.xpi; sudo test -e $UX || UX=
echo "uBlock xpi source: ${UX:-NONE}"
if ! sudo test -e "$TBD/extensions/$UBO.xpi"; then
  [ -n "$UX" ] || { echo "uBlock xpi not found"; exit 1; }
  sudo install -m644 "$UX" "$TBD/extensions/$UBO.xpi"
  sudo chown --reference="$TBD/extensions/$NS.xpi" "$TBD/extensions/$UBO.xpi"
fi
py <<EOF
import json
p='$TBD/policies.json'
d=json.load(open(p)); es=d['policies'].setdefault('ExtensionSettings',{})
for i in ('$NS','$UBO'):
    es.setdefault(i,{}).update({'default_area':'navbar','private_browsing':True})
d['policies']['DisableAppUpdate']=True
json.dump(d,open(p,'w'),indent=2); open(p,'a').write('\n'); print('TB policies', d)
EOF
sudo chown --reference=$TBD $TBD/policies.json
sudo ls -la $TBD $TBD/extensions $R/opt/tor-browser/Browser/is-packaged-app 2>&1 | grep -v '^total'

echo "== 5 Claws Mail account mail.i2p (POP3 7660 / SMTP 7659 via i2pd)"
cat > /tmp/claws-accountrc <<'EOF'
[Account: 1]
account_name=mail.i2p
is_default=1
name=
address=username@mail.i2p
organization=
protocol=0
receive_server=127.0.0.1
smtp_server=127.0.0.1
nntp_server=
use_nntp_auth=0
use_nntp_auth_onconnect=0
user_id=username
password=
use_apop_auth=0
remove_mail=0
message_leave_time=7
message_leave_hour=0
enable_size_limit=0
size_limit=1024
filter_on_receive=1
filterhook_on_receive=1
imap_auth_method=0
receive_at_get_all=1
max_news_articles=300
inbox=#mh/Mailbox/inbox
local_inbox=#mh/Mailbox/inbox
imap_directory=
imap_subsonly=1
low_bandwidth=0
generate_msgid=1
generate_xmailer=0
add_custom_header=0
use_smtp_auth=0
smtp_auth_method=0
smtp_user_id=
smtp_password=
pop_before_smtp=0
pop_before_smtp_timeout=5
signature_type=0
signature_path=
auto_signature=0
signature_separator=-- 
set_autocc=0
auto_cc=
set_autobcc=0
auto_bcc=
set_autoreplyto=0
auto_replyto=
enable_default_dictionary=0
default_dictionary=
enable_default_alt_dictionary=0
default_alt_dictionary=
compose_with_format=0
compose_subject_format=
compose_body_format=
reply_with_format=0
reply_quotemark=
reply_body_format=
forward_with_format=0
forward_quotemark=
forward_body_format=
default_privacy_system=
default_encrypt=0
default_encrypt_reply=1
default_sign=0
default_sign_reply=1
save_clear_text=0
encrypt_to_self=0
ssl_pop=0
ssl_imap=0
ssl_nntp=0
ssl_smtp=0
use_nonblocking_ssl=1
in_ssl_client_cert_file=
out_ssl_client_cert_file=
ssl_certs_auto_accept=0
use_tls_sni=0
set_smtpport=1
smtp_port=7659
set_popport=1
pop_port=7660
set_imapport=0
imap_port=143
set_nntpport=0
nntp_port=119
set_domain=1
domain=mail.i2p
gnutls_set_priority=0
gnutls_priority=
mark_crosspost_read=0
crosspost_color=0
set_sent_folder=0
sent_folder=
set_queue_folder=0
queue_folder=
set_draft_folder=0
draft_folder=
set_trash_folder=0
trash_folder=
imap_use_trash=1
EOF
cat > /tmp/claws-folderlist.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<folderlist>
    <folder type="mh" name="Mailbox" path="Mail" sort="0" collapsed="0">
        <folderitem type="normal" name="Mailbox" path="" sort_key="0" />
        <folderitem type="inbox" name="inbox" path="inbox" />
        <folderitem type="outbox" name="sent" path="sent" />
        <folderitem type="queue" name="queue" path="queue" />
        <folderitem type="draft" name="draft" path="draft" />
        <folderitem type="trash" name="trash" path="trash" />
    </folder>
</folderlist>
EOF
for H in home/user etc/skel; do
  bk $H/.claws-mail/accountrc $H/.claws-mail/folderlist.xml
  O=0; [ $H = home/user ] && O=1000
  sudo install -d -m700 -o $O -g $O $R/$H/.claws-mail $R/$H/Mail
  for d in inbox sent queue draft trash; do sudo install -d -m700 -o $O -g $O $R/$H/Mail/$d; done
  sudo install -m600 -o $O -g $O /tmp/claws-accountrc $R/$H/.claws-mail/accountrc
  sudo install -m600 -o $O -g $O /tmp/claws-folderlist.xml $R/$H/.claws-mail/folderlist.xml
  echo "claws -> $H"
done
sudo grep -q '4444 4447 4450 7659 7660' $R/etc/ferm/ferm.conf && echo "ferm: user may reach 7659/7660 (user_ports)"

echo "== 6 The Lounge: dg + rusirc removed, IRC2P/echelon join no channels"
bk usr/local/share/prestium-thelounge/prestium.json var/lib/thelounge/config.js usr/local/sbin/prestium-thelounge-setup
py <<'EOF'
import json
R='/workspace/work/prestium/v20/rootfs'
p=R+'/usr/local/share/prestium-thelounge/prestium.json'
u=json.load(open(p))
u['networks']=[n for n in u['networks'] if n['name'] not in ('IRC2P (dg)','Ilita (rusirc)')]
for n in u['networks']:
    if n['name'] in ('IRC2P','IRC2P (echelon)'): n['channels']=[]
json.dump(u,open(p,'w'),indent=2); open(p,'a').write('\n')
print([(n['name'],n['port'],[c['name'] for c in n['channels']]) for n in u['networks']])
p=R+'/var/lib/thelounge/config.js'
s=open(p).read()
s=s.replace('join: "#i2p,#i2p-chat,#i2p-dev",','join: "",')
s=s.replace('IRC2P 6668 (postman), IRC2P (echelon) 6665, IRC2P (dg) 6666,\n\t// Ilita 6669, Ilita (r4sas) 6670, Ilita (acetone) 6671, Ilita (rusirc) 6672',
            'IRC2P 6668 (postman), IRC2P (echelon) 6665,\n\t// Ilita 6669, Ilita (r4sas) 6670, Ilita (acetone) 6671 (1.9.1.2: dg and rusirc removed;\n\t// no default channels, users join their own)')
assert 'join: "",' in s and 'dg)' not in s.replace('dg and','')
open(p,'w').write(s)
p=R+'/usr/local/sbin/prestium-thelounge-setup'
s=open(p).read()
s=s.replace('(IRC2P 6668, echelon 6665, dg 6666;\n//   Ilita 6669, r4sas 6670, acetone 6671, rusirc 6672)','(IRC2P 6668, echelon 6665;\n//   Ilita 6669, r4sas 6670, acetone 6671)')
open(p,'w').write(s)
EOF
sudo chroot $R /opt/nodejs/bin/node -e 'const c=require("/var/lib/thelounge/config.js");console.log("config.js loads, join=["+c.defaults.join+"]")'

echo "== 7 Pidgin: rerun the (fixed) 1.9.1.1 install script (home/user prefs + menu item)"
[ -e bh/backup-1912/install-pidgin-1911.sh.orig ] || cp -a stage-1911/pidgin/install-pidgin-1911.sh bh/backup-1912/install-pidgin-1911.sh.orig
cmp -s $S/install-pidgin-1911.sh.new stage-1911/pidgin/install-pidgin-1911.sh || install -m755 $S/install-pidgin-1911.sh.new stage-1911/pidgin/install-pidgin-1911.sh
PIDGIN_BK=bh/backup-1912 ./stage-1911/pidgin/install-pidgin-1911.sh

echo "== 8 Unlock Volume"
bk usr/local/bin/prestium-unlock-volume
sudo install -m755 $S/prestium-unlock-volume $R/usr/local/bin/prestium-unlock-volume
python3 -m py_compile $S/prestium-unlock-volume && echo "unlock-volume compiles"
for p in udisks2 cryptsetup cryptsetup-bin libblockdev-crypto3 zenity dosfstools; do echo "pkg $p: $(sudo chroot $R dpkg-query -W -f='${Status} ${Version}' $p 2>&1)"; done
py <<'EOF'
import glob
R='/workspace/work/prestium/v20/rootfs'
item='''    <item label="Unlock Volume">
      <action name="Execute"><execute>/usr/local/bin/prestium-unlock-volume</execute></action>
    </item>
'''
a='''    <item label="Unlock VeraCrypt Volume">
      <action name="Execute"><execute>/usr/local/bin/prestium-unlock-veracrypt</execute></action>
    </item>
'''
for p in [R+'/etc/xdg/openbox/menu.xml']+glob.glob(R+'/home/user/.config/openbox/menu.xml')+glob.glob(R+'/etc/skel/.config/openbox/menu.xml'):
    s=open(p).read()
    if 'prestium-unlock-volume' not in s:
        assert a in s, p
        s=s.replace(a,a+item); open(p,'w').write(s); print('Unlock Volume ->',p)
EOF

echo "== 9 version 1.9.1.1 -> 1.9.1.2"
# only the release identification (comments elsewhere that say "Prestium 1.9.1.1: ..." are history, left alone)
for x in etc/os-release usr/lib/os-release etc/issue etc/issue.net; do
  f=$R/$x; sudo test -L $f && continue
  if sudo grep -qF '1.9.1.1' $f; then bk $x; sudo sed -i 's/1\.9\.1\.1/1.9.1.2/g' $f; echo "version -> $f"; fi
done
for f in etc/xdg/openbox/menu.xml; do sudo python3 -c "import xml.dom.minidom,sys;xml.dom.minidom.parse(sys.argv[1]);print('menu.xml well-formed')" $R/$f; done
sync
touch $B/.applied   # backups = state before the first run only
echo APPLY-1912-OK
