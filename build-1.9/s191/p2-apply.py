#!/usr/bin/python3
# Prestium 1.9.1: install staged files + in-place edits into v20/rootfs.
# Every existing file is backed up to bh/backup-191-fix/<path> before it is changed
# (first backup wins, so re-running is safe). Removed files are moved there.
# Resumable: each step writes a marker in bh/s191/markers/.
import os, shutil, sqlite3, json, re, stat, sys, subprocess, time
V = "/workspace/work/prestium/v20"
R = V + "/rootfs"
ST = V + "/bh/s191/files"
BK = V + "/bh/backup-191-fix"
MK = V + "/bh/s191/markers"
LOG = V + "/bh/s191/p2-apply.log"
os.makedirs(MK, exist_ok=True)
UID = 1000

def log(m):
    with open(LOG, "a") as f:
        f.write(time.strftime("%H:%M:%S ", time.gmtime()) + m + "\n")

def backup(rel):
    src = os.path.join(R, rel)
    dst = os.path.join(BK, rel)
    if os.path.lexists(src) and not os.path.lexists(dst):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if os.path.isdir(src) and not os.path.islink(src):
            shutil.copytree(src, dst, symlinks=True)
        else:
            shutil.copy2(src, dst, follow_symlinks=False)

def remove(rel):
    src = os.path.join(R, rel)
    dst = os.path.join(BK, rel)
    if not os.path.lexists(src):
        return
    if os.path.lexists(dst):
        if os.path.isdir(src) and not os.path.islink(src): shutil.rmtree(src)
        else: os.unlink(src)
    else:
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.move(src, dst)
    log("removed (moved to backup) " + rel)

def step(name, fn):
    m = os.path.join(MK, name)
    if os.path.exists(m):
        return
    fn()
    open(m, "w").close()
    log("STEP " + name + " done")

def is_home(rel):
    return rel.startswith("home/user")

def put_file(rel, src, mode=None):
    dst = os.path.join(R, rel)
    backup(rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if os.path.lexists(dst) and (os.path.islink(dst) or not os.path.isdir(dst)):
        os.unlink(dst)
    shutil.copyfile(src, dst)
    if mode is None:
        mode = 0o755 if (os.stat(src).st_mode & 0o111) else 0o644
    os.chmod(dst, mode)
    own = UID if is_home(rel) else 0
    os.chown(dst, own, own)

def install_staged():
    for root, dirs, files in os.walk(ST):
        for d in dirs:
            rel = os.path.relpath(os.path.join(root, d), ST)
            p = os.path.join(R, rel)
            if not os.path.isdir(p):
                os.makedirs(p)
                os.chmod(p, 0o755)
                os.chown(p, 0, 0)
        for f in files:
            src = os.path.join(root, f)
            rel = os.path.relpath(src, ST)
            mode = None
            if rel.startswith("etc/sudoers.d/"): mode = 0o440
            if rel.startswith("usr/local/share/prestium-nssdb/") and f.endswith(".db"): mode = 0o644
            put_file(rel, src, mode)
            log("installed " + rel)

def copy_skel_to_home():
    # new skel files also go into the live home of "user"
    for rel in [".claws-mail/accountrc.tmpl", ".claws-mail/clawsrc", ".config/vlc/vlcrc",
                ".config/audacity/audacity.cfg", ".config/gtk-3.0/bookmarks", ".gtk-bookmarks"]:
        src = os.path.join(R, "etc/skel", rel)
        hrel = "home/user/" + rel
        d = os.path.dirname(os.path.join(R, hrel))
        # create parent dirs owned by user
        parts = os.path.relpath(d, R + "/home/user").split("/")
        cur = R + "/home/user"
        for p in parts:
            if p in ("", "."): continue
            cur = os.path.join(cur, p)
            if not os.path.isdir(cur):
                os.mkdir(cur, 0o700); os.chown(cur, UID, UID)
        put_file(hrel, src, 0o600)
    for base, own in (("etc/skel", 0), ("home/user", UID)):
        tb = os.path.join(R, base, "Tor Browser")
        if not os.path.isdir(tb):
            os.mkdir(tb)
        os.chmod(tb, 0o700 if own else 0o755)
        os.chown(tb, own, own)
    # skel claws dir perms
    os.chmod(os.path.join(R, "etc/skel/.claws-mail"), 0o700)
    log("skel->home copies done")

def edit(rel, fn):
    p = os.path.join(R, rel)
    if not os.path.exists(p):
        log("MISSING " + rel); return
    backup(rel)
    st = os.stat(p)
    s = open(p, encoding="utf-8").read()
    n = fn(s)
    if n != s:
        with open(p, "w", encoding="utf-8") as f: f.write(n)
        os.chown(p, st.st_uid, st.st_gid); os.chmod(p, stat.S_IMODE(st.st_mode))
        log("edited " + rel)
    else:
        log("unchanged " + rel)

def i2pd(s):
    s = re.sub(r"(?m)^ipv6 = true$", "ipv6 = false", s)
    s = re.sub(r"(?m)^bandwidth = X$", "bandwidth = L", s)
    s = re.sub(r"(?m)^share = 70$", "share = 30", s)
    s = re.sub(r"(?m)^enabled = true ## Set this to true if you want to use XD or XD-Cli for torrenting\.$",
               "## Prestium 1.9.1: SAM off (no shipped app uses it; set true for XD/XD-Cli)\nenabled = false", s)
    return s

def environment(s):
    if "no_proxy" in s: return s
    return s.rstrip("\n") + '\nno_proxy="127.0.0.1,localhost,::1"\nNO_PROXY="127.0.0.1,localhost,::1"\n'

def menu(s):
    rep = [
     ('<item label="Web Browser (I2P)">', '<item label="Web Browser (I2P; clearnet via I2P outproxy)">'),
     ('<item label="GPG Frontend">\n      <action name="Execute"><execute>gpgfrontend</execute></action>',
      '<item label="Kleopatra (GnuPG)">\n      <action name="Execute"><execute>kleopatra</execute></action>'),
     ('<item label="Sylpheed E-mail">\n      <action name="Execute"><execute>sylpheed</execute></action>',
      '<item label="Mail (I2P)">\n      <action name="Execute"><execute>claws-mail</execute></action>'),
     ('<execute>x-terminal-emulator -e nyx</execute>',
      '<execute>x-terminal-emulator -e nyx -s /run/onion-grater/control</execute>'),
     ('    <item label="Terminal">\n      <action name="Execute"><execute>x-terminal-emulator</execute></action>\n    </item>',
      '    <item label="Terminal">\n      <action name="Execute"><execute>x-terminal-emulator</execute></action>\n    </item>\n    <item label="Lock Screen">\n      <action name="Execute"><execute>/usr/local/bin/prestium-lock-screen</execute></action>\n    </item>'),
    ]
    for a, b in rep:
        if b in s: continue
        if a not in s: log("menu: pattern not found: " + a[:50]); continue
        s = s.replace(a, b)
    return s

def rcxml(s):
    if 'key="W-l"' in s: return s
    kb = ('  <keybind key="W-l">\n    <action name="Execute">\n'
          '      <command>/usr/local/bin/prestium-lock-screen</command>\n    </action>\n  </keybind>\n')
    i = s.find('  <keybind key="W-e">')
    if i < 0: log("rc.xml: W-e not found"); return s
    return s[:i] + kb + s[i:]

def cacerts(s):
    for c in ["mozilla/emSign_Root_CA_-_G1.crt", "mozilla/emSign_Root_CA_-_C1.crt",
              "mozilla/emSign_ECC_Root_CA_-_C3.crt", "mozilla/emSign_ECC_Root_CA_-_G3.crt"]:
        if re.search(r"(?m)^!" + re.escape(c) + "$", s): continue
        if re.search(r"(?m)^" + re.escape(c) + "$", s):
            s = re.sub(r"(?m)^" + re.escape(c) + "$", "!" + c, s)
        else:
            s = s.rstrip("\n") + "\n!" + c + "\n"
    return s

def lw_overrides(s):
    s = s.replace('defaultPref("security.nocertdb", true);',
                  '// Prestium 1.9.1: certificate database on (in RAM) so the profile\'s explicit\n'
                  '// distrust of the eMudhra (emSign) roots overrides the built-in list\n'
                  'defaultPref("security.nocertdb", false);')
    if "Prestium 1.9.1: HTTPS-Only" not in s:
        s += ('\n// Prestium 1.9.1: HTTPS-Only / HTTPS-First stay OFF (I2P sites are plain http)\n'
              'pref("dom.security.https_only_mode", false);\npref("dom.security.https_only_mode_pbm", false);\n'
              'pref("dom.security.https_first", false);\npref("dom.security.https_first_pbm", false);\n'
              'pref("dom.security.https_first_schemeless", false);\n')
    return s

def onionshare(s):
    d = json.loads(s)
    d["connection_type"] = "socket_file"
    d["socket_file_path"] = "/run/onion-grater/control"
    d["auth_type"] = "no_auth"
    return json.dumps(d, indent=2) + "\n"

def feather(s):
    d = json.loads(s)
    d.update({"proxy": 1, "useLocalTor": True, "torHost": "127.0.0.1", "torPort": 9050,
              "socks5Host": "127.0.0.1", "socks5Port": "9050",
              "torOnlyAllowOnion": True, "torPrivacyLevel": 2})
    return json.dumps(d, indent=4) + "\n"

def gajim(rel):
    p = os.path.join(R, rel)
    if not os.path.exists(p): log("MISSING " + rel); return
    backup(rel)
    st = os.stat(p)
    c = sqlite3.connect(p)
    row = c.execute("select settings from settings where name='app'").fetchone()
    d = json.loads(row[0]); d["global_proxy"] = "Tor"
    c.execute("update settings set settings=? where name='app'", (json.dumps(d),))
    c.commit(); c.close()
    os.chown(p, st.st_uid, st.st_gid)
    log("gajim global_proxy=Tor in " + rel)

def edits():
    edit("var/lib/i2pd/i2pd.conf", i2pd)
    edit("etc/environment", environment)
    edit("etc/xdg/openbox/menu.xml", menu)
    edit("etc/xdg/openbox/rc.xml", rcxml)
    edit("etc/ca-certificates.conf", cacerts)
    for r in ["home/user/.librewolf/librewolf.overrides.cfg",
              "home/user/.config/librewolf/librewolf/librewolf.overrides.cfg"]:
        edit(r, lw_overrides)
    for b in ["etc/skel", "home/user"]:
        edit(b + "/.config/onionshare/onionshare.json", onionshare)
        edit(b + "/.config/feather/settings.json", feather)
        gajim(b + "/.config/gajim/settings.sqlite")

def removals():
    for r in ["usr/local/bin/KeePassXC-2.8.0.AppImage", "usr/local/bin/keepassxc",
              "usr/local/bin/GpgFrontend-2.2.2.AppImage", "usr/local/bin/gpgfrontend",
              "usr/local/bin/audacity-4.0.1.AppImage", "usr/local/bin/audacity",
              "etc/skel/.sylpheed-2.0", "home/user/.sylpheed-2.0"]:
        remove(r)

def torbrowser():
    tb = os.path.join(R, "opt/tor-browser")
    # record original ownership/modes once
    rec = os.path.join(BK, "opt-tor-browser-perms.txt")
    if not os.path.exists(rec):
        os.makedirs(BK, exist_ok=True)
        subprocess.run(["sh", "-c", "find '%s' -printf '%%U:%%G %%m %%P\\n' > '%s'" % (tb, rec)], check=True)
    open(os.path.join(tb, "Browser/is-packaged-app"), "w").close()
    for root, dirs, files in os.walk(tb):
        for n in dirs + files:
            p = os.path.join(root, n)
            os.lchown(p, 0, 0)
            if os.path.islink(p): continue
            m = stat.S_IMODE(os.lstat(p).st_mode)
            if os.path.isdir(p): os.chmod(p, 0o755)
            else: os.chmod(p, 0o755 if (m & 0o100) else 0o644)
    os.lchown(tb, 0, 0); os.chmod(tb, 0o755)
    log("tor-browser: root:root, dirs 0755, files 0644/0755, is-packaged-app added")

def gvfs():
    # handled by dpkg-divert in the chroot step (p3); nothing here
    pass

step("10-install-staged", install_staged)
step("20-skel-home", copy_skel_to_home)
step("30-edits", edits)
step("40-removals", removals)
step("50-torbrowser", torbrowser)
log("P2-DONE")
print("P2-DONE")
