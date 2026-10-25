# Prestium 1.9.1: security audit fixes (Tails 7.15.1 parity) and bug fixes

1.9.1 is built on the Prestium 1.9 rootfs (1.9 ISO SHA-256 `2a88ecf404b35ff8a4038d1b8db393a8d50fa5118629aa3d7814eb2e7ca621cc`).
ISO: `Prestium-1.9.1-amd64.iso`, 2,272,788,480 bytes, SHA-256 `117f487f1d884a89f4ffba926c12ddfce7c9999741c00a1d7c95c95961c00676` (also in `Prestium-1.9.1-amd64.iso.sha256`). There is **no torrent** for 1.9.1.
It contains the bug fixes F1–F7 and 8–11 below and **every item of the audit `REPORT-191.md`** (A1–A12, b, c, d 1–13), with the user's changes to A7 (Diodon kept, history off), b (Claws Mail instead of Sylpheed, LibreWolf HTTPS-Only kept off) and A4 (~/Tor Browser folder).
Boot test: see "QEMU test" at the end.
Severity order used below: security/privacy leak > boot/network breakage > app breakage > cosmetic.
No fix weakens hardening.

## Fixed in the rootfs

| # | Severity | Bug | Fix |
|---|---|---|---|
| 1 | **Security** (local privilege boundary; inherited from 1.8) | `/etc/sudoers.d/date` allowed `user` to run `/usr/bin/date` as root with **any** arguments, without a password. `sudo date -f /etc/shadow` (or any root-only file, e.g. Tor/i2pd state) prints the file line by line in the "invalid date" errors (GTFOBins). Confirmed with `sudo -l -U user /usr/bin/date -f /etc/shadow` in the chroot | The rule is now a sudo regex: only `date [-u] -s\|--set <date words>` is allowed. The date words must start with a digit or letter (never `-`) and can't contain `/`. Setting the clock still works (`sudo date -s "2026-10-24 12:00:00"`); `-f`, `-r`, `--file` and every other option are refused. Checked with `visudo -c` and `sudo -l -U user …` in the chroot |
| 2 | **Security/privacy** (memory wipe on medium removal) | Emergency shutdown: the 1.9 `@prestium-emergency` fallback was spawned only **after** the medium disappeared, which meant exec'ing `/bin/bash` from a medium that was already gone. It then waited a fixed 8 s. The QEMU run before the fallback existed took 52 s from USB removal to power-off | The fallback is now started when the watchdog is **armed**, while the medium is still present. It sleeps on a bash builtin and is woken by SIGUSR1 from the watchdog. It gives `systemctl --force poweroff` 3 s, then sends SIGKILL to every process except itself and PID 1 (their memory is freed, and so zeroed, `init_on_free=1`). After 2 s more it powers off with `echo o > /proc/sysrq-trigger`. Worst case is about 6 s after removal. Its argv[0] starts with `@`, so systemd-shutdown's killing spree spares it. On a normal shutdown it is stopped with the unit (it does not ignore SIGTERM) |
| 3 | Privacy hardening (narrower than 1.9) | I2P Torrents fix in 1.9: `chmod go+x /home/user`, which lets **every** account (thelounge, debian-tor, …) traverse the 0700 home | Traversal now goes only to group `i2ptorrents` (members `user` and `i2pd`): `chgrp i2ptorrents /home/user; chmod 0710`. i2pd can still reach `~/Downloads/Torrents` (2770 user:i2ptorrents), and no other account can enter the home |
| 4 | App breakage risk | The Lounge with `kernel.io_uring_disabled=2` (new in 1.9). Node/libuv falls back to its thread pool when `io_uring_setup` fails, but whether it uses io_uring at all depends on the libuv version | `Environment=UV_USE_IO_URING=0` added to `thelounge.service`, so libuv never tries io_uring (deterministic, no EPERM path). The unit's other sandboxing is unchanged |
| 5 | Cosmetic | ClipIt remnant: `/home/user/.config/clipit/clipitrc` was still in the live home (the package was purged in 1.9) | Removed |
| 6 | Cosmetic | 7 dangling SysV links `/etc/rc?.d/[SK]01i2pd` → `../init.d/i2pd`. The init script was removed on purpose in 1.8, and systemd uses `i2pd.service` | Removed |
| 7 | Cosmetic (inherited from 1.8) | Openbox `W-e` ran `kfmclient openProfile filemanagement` (KDE, not installed). The tint2 clock right-click ran `orage` (not installed) | `W-e` now opens `pcmanfm`. The clock right-click does nothing |

The original files are kept in `v20/bh/backup-1.9/` (not part of the image).

## Added in the rootfs (1.9.1, user request; needs the ISO rebuild)

| # | Change | Details |
|---|---|---|
| 8 | **The Lounge: one preset per i2pd IRC tunnel** | The user template now has 7 networks with host 127.0.0.1 and the port already set: IRC2P 6668 (irc.postman.i2p), IRC2P (echelon) 6665, IRC2P (dg) 6666, Ilita 6669 (irc.ilita.i2p), Ilita (r4sas) 6670, Ilita (acetone) 6671, Ilita (rusirc) 6672. IRC2P and Ilita connect at start as before. The alternate servers are listed disconnected: select one, then "Connect". No port editing needed. IRC2P presets join #i2p, #i2p-chat, #i2p-dev (no #i2p-help); Ilita presets have no auto channels (no #dev). The I2P identities are unchanged (IRC2P tunnels share irc2p-keys.dat, Ilita tunnels ilita-keys.dat) |
| 9 | **The Lounge: distinct nick per network** (privacy) | `prestium-thelounge-setup` gave every network the same random nick, which linked the IRC2P and Ilita identities. Each network now gets its own random `anonNNNN` |
| 10 | **Image Viewer: Loupe** (as in Tails 7) | `loupe` 48.1-3 + `glycin-loaders` 1.2.1 from trixie (apt, signatures verified). Image decoding runs in glycin's bubblewrap sandbox (no network). Openbox menu "Image Viewer" now starts Loupe. `/etc/xdg/mimeapps.list` sends its 23 image types to Loupe, with Ristretto (still installed) as the fallback |
| 11 | **Metadata Cleaner + "Remove metadata"** (as in Tails) | `metadata-cleaner` 2.5.2 (mat2 0.13.5 was already installed). New Openbox menu item "Metadata Cleaner". PCManFM right-click action "Remove metadata" (`/usr/share/file-manager/actions/prestium-remove-metadata.desktop` → `/usr/local/bin/prestium-remove-metadata`) runs mat2 and writes `name.cleaned.ext` next to each file. The original is unchanged and a dialog shows the result. Thunar isn't part of Prestium, so the action is for PCManFM |

Verified in the chroot: config.js and the template parse; The Lounge 4.5.2 starts and loads the user with 7 networks and distinct nicks; `gio mime image/png` → Loupe; mat2 cleans a PNG (`--no-sandbox` only in the chroot, because bwrap can't run under qemu-user). Not boot-tested.

## Checked, no bug found
- **ClipIt → Diodon**: the `clipit` package is purged. There are no ClipIt references in the Openbox autostart, menu.xml or rc.xml, in tint2, in the desktop entries or in `/etc/xdg/autostart`. In 1.8, ClipIt was only started from the Openbox autostart (`clipit &`). It had no keybind and no menu entry, so there is nothing to rewire. Diodon (+ libdiodon0) is installed and starts from `/etc/xdg/autostart/diodon-autostart.desktop`.
- **Volume tray icon**: the trixie volumeicon (0.5.1+git20230228) shows a hidden 1×1 tray icon when there is **no ALSA card**, as in the QEMU VM without a sound device. With a card it shows normally. Autostart is unchanged from 1.8 (`tint2 &`, `volumeicon &`). GTK status icons embed once the tray appears, so start order doesn't matter. No change; this needs a check on real hardware or in a VM with `-device ich9-intel-hda`.
- **I2P Torrents on 7685**: the root cause (0700 home, so i2pd couldn't reach the torrent dir) was fixed in 1.9 and narrowed in fix 3. AppArmor `local/usr.bin.i2pd` allows `~/Downloads/Torrents/**`. Not yet confirmed in a boot.
- **Feather, GpgFrontend, Audacity** (and FeatherPad): all of them open windows in a chroot under Xvfb. No DT_NEEDED library is missing anywhere under `/opt` or `/usr/local` (63 ELF files checked; the only hit is Firefox's `gmp-clearkey` plugin needing `libmozsqlite3.so`, which Firefox itself loads first). `fusermount` → `fusermount3` (setuid) and `libfuse2t64` are present for the AppImages, and `fuse` isn't blocked in modprobe.d. The VM showed "no window" because of TCG slowness and the old test timeout. Not a rootfs bug.
- **AppArmor**: all 130 profiles in `/etc/apparmor.d` parse (`apparmor_parser -QTK` in the chroot, every return code 0).
- **sudoers**: `visudo -c` OK. The other rule (`prestium-power`: poweroff/reboot, `systemctl restart i2pd`, `prestium-tunnel-hops`) is argument-safe: `prestium-tunnel-hops` checks its only argument against `^[1-7]$` before it does anything as root.
- **polkit**: `/etc/polkit-1/rules.d` is root:polkitd 0750 and only has the two Prestium rules.
- **ferm**: `ferm --noexec --lines /etc/ferm/ferm.conf` parses.
- **sysctl**: only one key is overridden, `kernel.core_pattern` (Debian `core` → Prestium `|/bin/false`, intended). `zz-prestium-hardening.conf` sorts last. `50-bubblewrap.conf` sets `kernel.unprivileged_userns_clone=1`, which is the same as 1.8.
- **Scripts**: `bash -n`/`dash -n` pass on every script in `/usr/local/bin` and `/usr/local/sbin`. `shellcheck -S warning` reports only one unused loop variable. The two Python tools compile. No bookworm-only tools (ifconfig, netstat, plain `iptables`/nft mix-ups, ntpdate) are used.
- **systemd**: no Exec path in a Prestium unit or drop-in is missing (the only misses are Debian's `quotaon*`/`rc-local`, which are inactive by design). There are no dangling `.wants` links. The `/dev/null` links are deliberate masks.
- **Desktop entries / menu**: every `Exec=` in the applications, autostart and menu.xml exists.

## Audit fixes (REPORT-191.md), all approved

Backups of every changed file: `v20/bh/backup-191-fix/` (by path relative to `rootfs/`). Staged sources: `v20/bh/s191/files/`.

### a) Privacy, security and Tails-style hardening

| # | Fix in 1.9.1 | Status |
|---|---|---|
| A1 | **Firewall:** `user` may open TCP on 127.0.0.1 only to 4444, 4447, 4450 (I2P proxies), 7659/7660 (postman SMTP/POP3), 9050 (Tor SOCKS) and 17600–17650 (OnionShare's own local web server). 7070/7685/9000 stay reserved for the local-only Firefox gid; The Lounge keeps its own uid rule (IRC tunnels 6665–6672); SAM 7656 is off. **`user` is no longer in `debian-tor`.** New **Tor control-port filter** `prestium-onion-grater` (Python, `/run/onion-grater/control`; Debian has no onion-grater package and Whonix's needs Whonix helper packages, so it is a small Tails-style rewrite). It identifies each client by SO_PEERCRED + `/proc/<pid>/exe`/cmdline and applies an allow-list: **Tor Browser** (`/opt/tor-browser/Browser/firefox.real`): NEWNYM, circuit display (circuit-status, ns/id, ip-to-country, CIRC events, STREAM events only for SOCKS-authenticated streams), onion client auth; **OnionShare**: ADD_ONION only to 127.0.0.1 targets, DEL_ONION, HS_DESC events; **Nyx**: read-only GETINFO/GETCONF (no `address*`), events, NEWNYM. Nothing can SETCONF/RESETCONF/LOADCONF, so no app can set an attacker bridge. Unknown programs, other uids and the local-only Firefox group are refused. The service runs as its own user `onion-grater` (group debian-tor), with only CAP_SYS_PTRACE (to read the client's /proc/pid/exe) and a strict systemd sandbox. Tor Browser (`TOR_CONTROL_IPC_PATH`), OnionShare (`socket_file_path`) and Nyx (`nyx -s`) point at it | done |
| A2 | **Memory erasure at shutdown (Tails design).** New initramfs hook puts a `/shutdown` script into the initramfs. `prestium-initramfs-shutdown.service` unpacks the initramfs (without firmware/modules) into a `/run/initramfs` tmpfs at boot; systemd-shutdown switches to it at the very end and `/shutdown` deletes the overlay read-write branch (`/run/live/overlay/rw`, `work`), `/tmp`, `/var/tmp`, `/dev/shm`, detaches the old root, then powers off/reboots. `prestium-wipe-session.service` (stopped after all services and the desktop) deletes the same session files earlier in shutdown. The F2 emergency fallback now deletes them too (memlocked `find`, before and after the SIGKILL) before `sysrq o`. Freed pages are zeroed by `init_on_free=1` | done (test: see QEMU test) |
| A3 | `/etc/ca-certificates.conf`: `!` for **all four** emSign roots (G1, C1, ECC C3, ECC G3), `update-ca-certificates --fresh` (145 roots, 0 emSign). System NSS: trixie has no `libnssckbi` alternative, so `libnssckbi.so` is diverted (dpkg-divert) and replaced by a link to `p11-kit-trust.so`. **Tor Browser, LibreWolf and the local-only Firefox carry the emSign roots in their own built-in list (libxul)** and ignore the system store, and Firefox policies cannot remove built-in roots, so each launcher seeds a new profile with an NSS database (`/usr/local/share/prestium-nssdb`) that marks the four roots **explicitly distrusted** (`certutil -t p,p,p`), which overrides the built-in trust. For that, Tor Browser and LibreWolf now use the profile cert DB (`security.nocertdb=false`; the profile lives in RAM; Firefox no longer stores intermediates there). LibreWolf now always uses the fixed profile `~/.librewolf/prestium` | done |
| A4 | **Tor Browser**: `/opt/tor-browser` is root:root and read-only (dirs 0755, files 0644/0755) and runs in "packaged" mode; the profile is `~/.tor-browser/profile.default` (NoScript copied from the install). **Enforced AppArmor profile `torbrowser_firefox`** (adapted from torbrowser-launcher/Tails): the install read-only, `~/.tor-browser` read-write, and of the rest of the home **only `~/Tor Browser/`**, the onion-grater socket but never `/run/tor`. **`~/Tor Browser`** (as in Tails) exists in `/etc/skel` and `/home/user` and is the download and upload folder (`browser.download.dir`, `folderList=2`, `useDownloadDir=true`, `lastDir`), with a bookmark in the PCManFM sidebar (GTK bookmarks). **LibreWolf**: AppArmor profile `librewolf` in **complain** mode (logs only): enforcing a profile that misses one of LibreWolf's sandbox/GPU/extension paths would break the browser, so the denials logged in complain mode are the basis for a later enforced profile | done (TB enforced, LibreWolf complain) |
| A5 | `/etc/tor/torrc`: `SocksPort 127.0.0.1:9050 IsolateDestAddr IsolateDestPort` (replaces the Debian default socks lines, so the world-writable unix socket `/run/tor/socks` is gone), `AvoidDiskWrites 1`, `ClientUseIPv6 0`. The Lounge: `InaccessiblePaths=/run/tor /run/onion-grater`. **`Sandbox 1` was dropped** after the first QEMU test: Tor refuses managed proxies in Sandbox mode (`Managed proxies are not compatible with Sandbox mode` → `--verify-config` fails → `tor@default` failed at boot, no Tor at all). Keeping the obfs4/Snowflake/WebTunnel `ClientTransportPlugin` lines (bridges) matters more, and Tails doesn't use `Sandbox` either; Tor stays confined by the enforced `system_tor` AppArmor profile and the systemd hardening of `tor@default` | done (Sandbox dropped) |
| A6 | IPv6 off: `net.ipv6.conf.{all,default,lo}.disable_ipv6=1`, NetworkManager `ipv6.method=disabled`, i2pd `ipv6 = false`, ip6tables drops all output (only ESTABLISHED in) | done |
| A7 | (user change) **Diodon kept** and autostarting; system dconf database `/etc/dconf/db/local` with **locks**: `keep-clipboard-content=false`, `recent-items-size=1` (0 means "no limit" in Diodon's Zeitgeist query), `use-primary=false`, `add-images=false`, `synchronize-clipboards=false`. **Zeitgeist recording off**: its D-Bus activation is overridden (`/usr/local/share/dbus-1/services`, `Exec=/bin/false`) and its user units are masked, so Diodon stores no history | done |
| A8 | `xss-lock` + `i3lock` (autostart; also "Lock Screen" in the System menu and Super+L). The first lock asks the user to set a session password (zenity; set through a root helper that only works while no password is set, `sudo` rule for exactly that helper); without a password the screen isn't locked. Autologin is kept | done |
| A9 | `NetworkManager.service` now `Requires=`/`After=ferm.service`. New `prestium-firewall-early.service` (sysinit, before network-pre/ferm/NM) sets DROP policies (loopback allowed) on legacy iptables/ip6tables, so a ferm failure fails closed | done |
| A10 | Boot line (BIOS, EFI, all entries): `spec_store_bypass_disable=on debugfs=off intel_iommu=on amd_iommu=force_isolation iommu=force iommu.strict=1 efi=disable_early_pci_dma module.sig_enforce=1`. All 4230 kernel modules in the image were checked: every one carries a signature | done |
| A11 | udev rule `70-prestium-mac-spoof.rules`: every physical network device gets `macchanger -e` (vendor part kept, Tails-style) on `add`, before NetworkManager; if spoofing fails the device is taken down and unbound. NM now uses `cloned-mac-address=preserve`. Boot option `nomacspoof` turns it off | done |
| A12 | `dpkg-statoverride` 0755 (no setuid): `ntfs-3g`, `gst-ptp-helper` (no file capabilities either), `ssh-keysign`, `chfn`, `chsh`, `newgrp`; `pppd` root:dip 0755 | done |

### b) Programs

| Program | Change | Status |
|---|---|---|
| KeePassXC | AppImage removed; Debian `keepassxc` 2.7.10 (= Tails) | done |
| GPG frontend | GpgFrontend AppImage removed; Debian `kleopatra` 24.12.3 (as in Tails); menu "Kleopatra (GnuPG)" | done |
| Audacity | AppImage removed; Debian `audacity` 3.7.3 (= Tails); `audacity.cfg` preseeded (update check off) | done |
| Gajim | default global proxy is now **Tor SOCKS 127.0.0.1:9050** (the I2P presets stay selectable) | done |
| LibreWolf | menu label **"Web Browser (I2P; clearnet via I2P outproxy)"**; (user change) **HTTPS-Only and HTTPS-First stay off** (`dom.security.https_only_mode=false`, `https_first=false`, also as `pref` in the overrides) because I2P sites are plain http; emSign distrust (A3); AppArmor complain (A4) | done |
| Feather | Tor 127.0.0.1:9050, onion-only nodes (`torOnlyAllowOnion=true`, privacy level "all over Tor") | done |
| VLC | `vlcrc`: `metadata-network-access=0`, no privacy prompt | done |
| Mail | (user change) **Sylpheed removed; Claws Mail 4.3.1** + `claws-mail-pgpmime`/`pgpinline` from trixie (no RSS/online plugins), menu **"Mail (I2P)"**. First start opens Claws' account wizard **prefilled** from `~/.claws-mail/accountrc.tmpl` (skel + home): postman via the i2pd tunnels, SMTP 127.0.0.1:7659 (auth), POP3 127.0.0.1:7660, no SSL (the tunnel is encrypted end to end). Left to enter: name, @mail.i2p address, postman user name/password (postman needs them). `clawsrc`: no HTML rendering plugin, no remote content, time zone hidden, no automatic checks. Claws has no update check or favicon fetching in this build. The SMTP/POP3 tunnels were already in `tunnels.conf`; the firewall allows 7659/7660 for `user` | done |
| gvfs | network backends disabled by dpkg-divert (afp, dav, dns-sd, ftp(s), google, http, nfs, onedrive, sftp, smb, network, wsdd); local ones (MTP, cdda, gphoto2, archive, trash) kept | done |

### c) Tails gaps

| Item | Change | Status |
|---|---|---|
| sysctl | `dev.tty.legacy_tiocsti=0` | done |
| Watchdog during suspend | 1.8 already had a sleep hook, but it stopped the watchdog and started it again after resume, so a medium pulled **during** suspend went unnoticed. Now: SIGSTOP before sleep; after resume, wait up to 10 s for the medium: back → restart (re-armed), gone → continue the frozen watchdog, which powers off | done |
| Bridges | `lyrebird` (obfs4), `snowflake-client` and `webtunnel` from deb.torproject.org, `ClientTransportPlugin` lines in torrc (bridges stay off by default), AppArmor `local/system_tor` allows `webtunnel-client`. **obfs4 bridges work.** Snowflake and WebTunnel need a DNS resolver (host names in their bridge lines) and Snowflake also UDP; Prestium has no clearnet resolver by design and Tor stays TCP-only (d6), so those two won't connect as shipped | partial (installed; snowflake/webtunnel unusable without DNS) |
| Camera/mic | new boot menu entry **"camera and microphone off"** (`prestium.nocammic`): udev makes video4linux devices and ALSA capture devices inaccessible (mode 0000, no seat ACL); sound output keeps working | done |

### d) Firewall and network

1. explicit port list (A1) – done. 2. unix SocksPort removed (A5) – done. 3. NM requires ferm + early drop-all (A9) – done. 4. IPv6 disabled (A6) – done. 5. `::1` no longer open: ip6 OUTPUT accepts nothing new – done. 6. Tor (debian-tor) TCP only – done (UDP not opened: Snowflake can't work without DNS anyway, see c). 7. `mod state state INVALID DROP` first in OUTPUT and INPUT (both families) – done. 8. dead CUPS 631 rule removed – done. 9. i2pd `bandwidth = L`, `share = 30` – done. 10. i2pd SAM off (no shipped program uses 7656) – done. 11. reseed file refreshed: `stormycloud-i2pseeds.su3` 2026-10-23 → 2026-10-24 build, signature (RSA-SHA512, signer admin@stormycloud.org) verified against i2pd's bundled certificate – done. 12. torrc (A5) – done. 13. `no_proxy`/`NO_PROXY=127.0.0.1,localhost,::1` in `/etc/environment` – done.

Verification in the chroot: `ferm --noexec` OK, `apparmor_parser -QTK` OK (torbrowser_firefox, librewolf, system_tor, usr.bin.i2pd), `visudo -c` OK, `dpkg --audit` clean, `sh -n`/`bash -n` OK on every new or edited script, `systemd-analyze verify` OK on the new units, initramfs contains `/shutdown` + busybox.

## QEMU test

QEMU, UEFI with Secure Boot (shim + GRUB), 2026-10-25 UTC, final ISO `117f487f…`:
- Boot: Secure Boot OK, kernel with `module.sig_enforce=1` and the new parameters; desktop reached; no failed units.
- Tor: `tor@default` active (the 1.9.1 pre-release failed because `Sandbox 1` is incompatible with bridge plugins; Sandbox removed), Bootstrapped 100%, SOCKS check HTTP 200. onion-grater listening on `/run/onion-grater/control`.
- AppArmor: `system_tor` and `torbrowser_firefox` (+2 sub-profiles) enforced; Tor Browser runs confined (`firefox.real` in enforce); LibreWolf complain.
- Leak tests: clearnet direct blocked, HTP clearnet blocked, no DNS (expected). IPv6 disabled; firewall loaded with INVALID drop, user port allow-list, Tor TCP-only.
- i2pd active, reseed OK, 11 client tunnels; The Lounge, memlockd, USB watchdog active; VeraCrypt volume create/lock/unlock OK; sudo list as intended.
- Shutdown: `system_powerdown` completed cleanly in 95 s.
- Not verified: A2 RAM-wipe dump (the QEMU memory dump produced no file, so before/after scans are empty). `prestium-tunnel-hops` rollback test with i2pd forced to fail did not restore the previous config (`restored=NO`); normal hops changes and input validation pass. The test still expects SAM port 7656, which 1.9.1 disables on purpose.

## Still open
- Snowflake/WebTunnel bridges need a DNS resolver that Prestium deliberately doesn't have (see c).
- LibreWolf's AppArmor profile is in complain mode; enforce it once the logged denials have been reviewed on real hardware.
- The onion-grater profiles for OnionShare and Nyx identify the program by its command line (as Tails does), which a local attacker can imitate; what they allow can't reveal the IP address or change Tor's configuration.
- Not tested on real hardware: Loupe + glycin sandbox, the PCManFM action, the IRC presets, the volume icon with a sound card, MAC spoofing on real NICs, the IOMMU options on real machines, suspend/resume with the watchdog.
- The home `~/.config/tint2/tint2rc` (identical to 1.8) still lists launcher items for desktop files that don't exist (firefox/iceweasel/chromium/google-chrome). tint2 skips them; left as in 1.8 to keep the look.
