import os, re, subprocess, glob, shutil
R='/workspace/work/prestium/v19/rootfs'; F='/workspace/work/prestium/v19/files'; DL='/workspace/work/prestium/v19/dl'
def p(x): return R+x
def rd(x): return open(p(x),encoding='utf-8',errors='surrogateescape').read()
def wr(x,s): open(p(x),'w',encoding='utf-8',errors='surrogateescape').write(s)
def inst(src,dst,mode,uid=0,gid=0):
    shutil.copyfile(src,p(dst)); os.chmod(p(dst),mode); os.chown(p(dst),uid,gid)
def ch(*a): subprocess.check_call(['chroot',R,'env','PATH=/usr/sbin:/usr/bin:/sbin:/bin']+list(a))
log=[]
# 1 emergency shutdown + memory wipe
inst(F+'/prestium-usb-watchdog','/usr/local/sbin/prestium-usb-watchdog',0o755)
inst(F+'/prestium-usb-watchdog.service','/etc/systemd/system/prestium-usb-watchdog.service',0o644)
os.makedirs(p('/usr/lib/systemd/system-sleep'),exist_ok=True)
inst(F+'/prestium-usb-watchdog.sleep','/usr/lib/systemd/system-sleep/prestium-usb-watchdog',0o755)
m=rd('/etc/memlockd.cfg')
if 'Prestium' not in m: wr('/etc/memlockd.cfg', m.rstrip('\n')+'\n\n'+open(F+'/memlockd-prestium.cfg').read())
# 2 time sync over Tor
inst(F+'/prestium-timesync','/usr/local/sbin/prestium-timesync',0o755)
inst(F+'/prestium-timesync.service','/etc/systemd/system/prestium-timesync.service',0o644)
if 'prestium-htp' not in rd('/etc/passwd'):
    ch('adduser','--system','--group','--no-create-home','--home','/nonexistent','--shell','/usr/sbin/nologin','prestium-htp')
fe=rd('/etc/ferm/ferm.conf')
if 'prestium-htp' not in fe:
    old='''				daddr 127.0.0.1 proto tcp syn dport 631 {
					mod owner uid-owner $user_uid ACCEPT;
				}
'''
    new=old+'''
				# Prestium 1.8: clock sync (prestium-timesync) may only reach Tor's SOCKS port
				daddr 127.0.0.1 proto tcp syn dport 9050 {
					mod owner uid-owner prestium-htp ACCEPT;
				}
'''
    assert fe.count(old)==1; fe=fe.replace(old,new)
    fe=fe.replace('\t\t\t\t# Huh?\n','\t\t\t\t# user apps may only reach local proxies (I2P, Tor, CUPS)\n').replace('\t\t\t\t# End of huh\n','')
    fe=re.sub(r'\n\t\t\t\n\t\t\t\n','\n',fe)
    wr('/etc/ferm/ferm.conf',fe)
# 3 privilege escalation fixes
wr('/etc/sudoers.d/veracrypt','# Prestium 1.8: VeraCrypt only. The old rule also allowed passwordless\n# "sudo mount" with any arguments, which any program could use to become root\n# (and root can bypass the firewall). /usr/bin/uptime was never needed.\n%veracrypt_grp  ALL=(root) NOPASSWD:/usr/bin/veracrypt\n')
os.chmod(p('/etc/sudoers.d/veracrypt'),0o440)
ch('passwd','-l','root')
# 4 kernel / sysctl / modules
s=rd('/etc/sysctl.d/99-prestium-hardening.conf')
if 'Prestium 1.8' not in s: wr('/etc/sysctl.d/99-prestium-hardening.conf', s.rstrip('\n')+'\n'+open(F+'/sysctl-18.conf').read())
inst(F+'/prestium-blacklist.conf','/etc/modprobe.d/prestium-blacklist.conf',0o644)
# 5 network privacy
inst(F+'/40-prestium-privacy.conf','/etc/NetworkManager/conf.d/40-prestium-privacy.conf',0o644)
if os.path.islink(p('/etc/resolv.conf')) or os.path.exists(p('/etc/resolv.conf')): os.remove(p('/etc/resolv.conf'))
inst(F+'/resolv.conf','/etc/resolv.conf',0o644)
# 6 services
ch('systemctl','enable','prestium-usb-watchdog.service','prestium-timesync.service','memlockd.service')
for t in ['apt-daily.timer','apt-daily-upgrade.timer','man-db.timer','dpkg-db-backup.timer','e2scrub_all.timer','fstrim.timer','e2scrub_reap.service']:
    subprocess.call(['chroot',R,'systemctl','disable',t])
# 7 i2pd clean-up
t=rd('/var/lib/i2pd/tunnels.conf')
out=[];skip=False
for l in t.split('\n'):
    if l.startswith('['): skip=(l.strip()=='[Monero SOCKS Proxy]')
    if not skip: out.append(l)
t2='\n'.join(out)  # drop only the Monero section; HexChat/System/SMTP/POP3 stay
assert t2!=t; wr('/var/lib/i2pd/tunnels.conf',t2)
c=rd('/var/lib/i2pd/i2pd.conf')
c2=re.sub(r'(\[i2pcontrol\]\n(?:#.*\n|\s*\n)*?)enabled = true','\\1## Prestium 1.8: off (unused; default password "itoopie" let any local program reconfigure the router)\nenabled = false',c)
assert c2!=c; wr('/var/lib/i2pd/i2pd.conf',c2)
st=os.stat(p('/var/lib/i2pd/stormycloud-i2pseeds.su3'))
shutil.copyfile(DL+'/stormycloud-i2pseeds.su3',p('/var/lib/i2pd/stormycloud-i2pseeds.su3')); os.chown(p('/var/lib/i2pd/stormycloud-i2pseeds.su3'),st.st_uid,st.st_gid); os.chmod(p('/var/lib/i2pd/stormycloud-i2pseeds.su3'),st.st_mode&0o777)
wr('/etc/i2pd/tunnels.conf','# Prestium: not used. i2pd runs with --tunconf=/var/lib/i2pd/tunnels.conf\n# (see /etc/systemd/system/i2pd.service.d/prestium.conf).\n')
# 8 qBittorrent 5.3.0
shutil.rmtree(p('/opt/qbittorrent')); shutil.copytree(DL+'/qbt',p('/opt/qbittorrent'),symlinks=True)
subprocess.check_call(['chown','-R','0:0',p('/opt/qbittorrent')]); subprocess.check_call(['chmod','-R','u+rwX,go+rX,go-w',p('/opt/qbittorrent')])
wr('/usr/local/bin/qbittorrent','#!/bin/sh\n# Prestium 1.8: official qBittorrent 5.3.0 AppImage (extracted), see /opt/qbittorrent\nexec /opt/qbittorrent/AppRun "$@"\n')
# 9 version
o=rd('/usr/lib/os-release'); wr('/usr/lib/os-release',o.replace('VERSION_ID="1.7"','VERSION_ID="1.8"').replace('VERSION="1.7 (bookworm)"','VERSION="1.8 (bookworm)"'))
wr('/etc/issue','Prestium 1.8 \\n \\l\n\n'); wr('/etc/issue.net','Prestium 1.8\n')
# 10 clean-up of build leftovers
for g in ['/var/log/*.log','/var/log/apt/*','/var/cache/apt/*.bin','/var/cache/apt/archives/*.deb','/var/lib/apt/lists/*_*','/var/cache/debconf/*-old','/var/lib/dpkg/*-old','/home/user/.bash_history','/root/.bash_history','/var/backups/*','/tmp/*','/var/tmp/*','/etc/*-','/etc/.pwd.lock','/var/lib/systemd/random-seed']:
    for f in glob.glob(p(g)):
        if os.path.isdir(f) and not os.path.islink(f): shutil.rmtree(f)
        else: os.remove(f)
        log.append(f[len(R):])
for d in ['/root/.cache','/root/.ssh']:
    if os.path.isdir(p(d)) and not os.listdir(p(d)): os.rmdir(p(d))
for f in ['/var/log/btmp','/var/log/wtmp','/var/log/lastlog']:
    if os.path.exists(p(f)): open(p(f),'w').close()
print('removed',len(log)); print('\n'.join(log[:80]))
