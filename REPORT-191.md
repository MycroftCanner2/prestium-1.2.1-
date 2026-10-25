# Prestium 1.9.1: audit report (report only, nothing in this list was changed)

Audit date: 2026-10-24 UTC. Audited tree: `v20/rootfs`, which is the 1.9 rootfs plus fixes F1–F7 and the two 1.9.1 additions (IRC presets, Loupe + Metadata Cleaner).
Method: static review of the rootfs (configs, units, package versions, permissions), a chroot under qemu-user where that helped, and the Tails 7.15.1 release notes and design pages ([kernel hardening](https://tails.net/contribute/design/kernel_hardening/), [memory erasure](https://tails.net/contribute/design/memory_erasure/), [7.15.1](https://tails.net/news/version_7.15.1/)).
**Nothing was boot-tested.** Every point below is drawn from the files. Items marked *verify* need a boot or a QEMU run to confirm.

Severity scale: **Critical** (deanonymization or loss of amnesia under a realistic attack) > **High** > **Medium** > **Low** (hardening or cleanup).

---

## 0. Changes already in the rootfs that wait for your approval

`bh/fix191.sh` applied these before this session. They are left applied, as you asked. Originals are in `v20/bh/backup-1.9/`, laid out by path relative to `rootfs/`. To revert one, copy its file back: `sudo cp -a bh/backup-1.9/<path> rootfs/<path>`.

| # | Fix | Status | Revert with |
|---|---|---|---|
| F1 | sudo `date` regex (closes `sudo date -f /etc/shadow`, an arbitrary root file read) | already applied | `sudo cp -a bh/backup-1.9/etc/sudoers.d/date rootfs/etc/sudoers.d/date` (brings the hole back) |
| F2 | Watchdog emergency fallback: armed early; SIGKILL to all; `sysrq o` | already applied | `sudo cp -a bh/backup-1.9/usr/local/sbin/prestium-usb-watchdog rootfs/usr/local/sbin/` |
| F3 | The Lounge `UV_USE_IO_URING=0` | already applied | `sudo cp -a bh/backup-1.9/etc/systemd/system/thelounge.service rootfs/etc/systemd/system/` |
| F4 | `/home/user` 0710, group `i2ptorrents` (was `go+x`) | already applied (runtime, in `prestium-i2pd-torrents`) | `sudo cp -a bh/backup-1.9/usr/local/sbin/prestium-i2pd-torrents rootfs/usr/local/sbin/` |
| F5 | ClipIt config remnant removed | already applied | `sudo cp -a bh/backup-1.9/home/user/.config/clipit rootfs/home/user/.config/` |
| F6 | 7 dangling `/etc/rc?.d/[SK]01i2pd` links removed | already applied | `for r in 0 1 6; do sudo ln -s ../init.d/i2pd rootfs/etc/rc$r.d/K01i2pd; done; for r in 2 3 4 5; do sudo ln -s ../init.d/i2pd rootfs/etc/rc$r.d/S01i2pd; done` |
| F7 | Openbox `W-e` kfmclient → pcmanfm; tint2 clock right-click `orage` removed | already applied | `sudo cp -a bh/backup-1.9/etc/xdg/openbox/rc.xml rootfs/etc/xdg/openbox/; sudo cp -a bh/backup-1.9/etc/xdg/tint2/tint2rc rootfs/etc/xdg/tint2/; sudo cp -a bh/backup-1.9/home/user/.config/tint2/tint2rc rootfs/home/user/.config/tint2/` |

The paths come from the `bk` calls in `bh/fix191.sh`. Run `ls -R bh/backup-1.9` to see exactly what was saved.

Done this session as you asked (also in the rootfs, so **a rebuild is needed**). Backups are in `bh/backup-191-irc/` and `bh/backup-191-img/`:
- IRC: 7 network presets plus a distinct random nick per network (details in the summary at the end).
- Loupe 48.1 + glycin-loaders, Metadata Cleaner 2.5.2 (mat2 0.13.5 was already installed), menu entries, image MIME defaults, and the PCManFM "Remove metadata" action. Thunar is **not installed**; the file manager is PCManFM, so the action is a libfm/PCManFM action.

---

## a) Bad bugs: privacy, security and Tails-style hardening (ranked)

### A1. Critical: any code running as `user` can learn the real IP address (Tor control port and i2pd console are open to `user`)
- `user` is in group `debian-tor`. Debian's `tor-service-defaults-torrc` makes `/run/tor/control` group-writable and the cookie group-readable. Nothing filters it (Tails has onion-grater). Any compromised user process (LibreWolf-I2P, Gajim, VLC, LibreOffice, Sylpheed, any AppImage) can run `SETCONF UseBridges=1 Bridge=<attacker-ip:port>`. Tor (debian-tor, which ferm allows to go anywhere) then connects **directly from the real IP** to the attacker. It can also read `GETINFO circuit-status` (guards) or turn proxies off.
- ferm lets uid 1000 open TCP to **every** 127.0.0.1 port from 1024 to 65535. The i2pd web console `127.0.0.1:7070` has no authentication. Its main page shows the router's external IPv4/IPv6 address (*verify* in a boot). Any user process can read it and send it out over Tor or I2P.
- Fix (in this order):
  1. ferm: replace `daddr 127.0.0.1 proto tcp syn dport 1024:65535 { uid user ACCEPT }` with an explicit list: 4444, 4447, 4450, 7659, 7660, 9050 (plus 7656 only if a shipped app really needs SAM). Leave 7070/7685/9000 to the `prestium-localweb` gid only (it already has them).
  2. Take `user` out of `debian-tor`. Run a control-port filter (onion-grater, as Tails does; Whonix packages it) on a separate socket. Give Tor Browser only its allow-list (NEWNYM, circuit display) and OnionShare only `ADD_ONION`/`DEL_ONION`. Run Nyx through the filter or as debian-tor.

### A2. Critical: memory erasure misses the session's files (overlay tmpfs is never freed)
- Prestium relies on `init_on_free=1`. Nothing frees the overlayfs read-write branch, though: there is no `/run/initramfs` return, no shutdown hook in the initramfs, and no overlay cleanup unit. Root can't be unmounted, so the tmpfs pages holding downloads, browser profiles, documents and keys created in the session are **never freed, so never zeroed**, on a normal shutdown. Tails documents exactly this problem and solves it (initramfs-shutdown.service, run-initramfs.mount, tails-remove-overlayfs-dirs.service).
- The emergency path (F2) makes it worse: SIGKILL to all processes, then `echo o > /proc/sysrq-trigger`, which powers off at once without touching tmpfs (`/`, `/tmp`, `/run`, `/dev/shm`).
- Fix: port the Tails design. (1) A tmpfs on `/run/initramfs` with exec, the initramfs unpacked there at boot, and a systemd-shutdown in the initramfs (hook). (2) A late shutdown unit that deletes the overlay upperdir contents (`/run/live/overlay/rw/*`), `/tmp` and `/dev/shm`. (3) In the F2 fallback, before `sysrq o`: `find /run/live/overlay/rw /tmp /dev/shm -mindepth 1 -delete` (bash plus a memlocked `find`, or a static helper), then `sync`. Then test it like Tails does: fill a pattern file in `~/`, shut down, and grep a QEMU `pmemsave`/`dump-guest-memory` for the pattern.

### A3. High: compromised eMudhra (emSign) CAs are still trusted (Tails 7.15.1 emergency release)
- Tails 7.15.1 (2026-10-23) blocks **all** eMudhra certificates. Prestium has `ca-certificates 20250419+deb13u1`, which only blacklists *emSign ECC Root CA – G3* ([changelog](https://tracker.debian.org/media/packages/c/ca-certificates/changelog-20250419deb13u1)). `emSign Root CA – G1`, `emSign Root CA – C1` and `emSign ECC Root CA – C3` are still in `/etc/ssl/certs`. All four, G3 included, are compiled into NSS's builtin `libnssckbi.so` (libnss3 2:3.110-1+deb13u4).
- Affected: LibreWolf-I2P (clearnet HTTPS through the outproxy), Gajim (XMPP TLS through the outproxy), curl/wget, Sylpheed, Python apps. Tor Browser **15.0.26 is already the fixed version** (same as Tails 7.15.1).
- Fix: put `!mozilla/emSign_Root_CA_-_G1.crt`, `!mozilla/emSign_Root_CA_-_C1.crt`, `!mozilla/emSign_ECC_Root_CA_-_C3.crt` (and G3) in `/etc/ca-certificates.conf`, then `update-ca-certificates --fresh`. Point NSS at the system store: `update-alternatives --set libnssckbi.so.x86_64-linux-gnu /usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so` (p11-kit-modules is installed). Then check LibreWolf 158.0.1 with an emSign-issued test certificate.

### A4. High: Tor Browser is user-writable and unconfined
- `/opt/tor-browser` is owned by `user`, mode 0700 (the launcher even refuses to start if it isn't writable). No AppArmor profile covers it. Any user-level exploit can trojan `firefox.real` or the omni.ja files for the rest of the session. Tails ships Tor Browser root-owned and read-only, under the `torbrowser_firefox` AppArmor profile.
- Fix: root:root 0755, read-only. Keep the profile in `~/.tor-browser/profile.default`, which start-tor-browser supports through `TOR_BROWSER_PROFILE`/`-profile`. Adapt the `torbrowser.Browser.firefox` profile from Debian's torbrowser-launcher to `/opt/tor-browser` and enforce it.

### A5. High: Tor's world-writable unix SocksPort bypasses the per-uid firewall
- Debian's defaults add `SocksPort unix:/run/tor/socks WorldWritable`. ferm can't filter AF_UNIX. So `thelounge` (allowed AF_UNIX, `/run` readable) and the "local-only" Firefox (gid `prestium-localweb`) can reach Tor and through it the Internet. That breaks the guarantees that "The Lounge reaches only the IRC tunnels" and "local-only Firefox reaches only 7070/7685/9000". This is not an IP leak, but it is an exfiltration path out of the two sandboxes.
- Fix: in `/etc/tor/torrc` (currently all comments) set `SocksPort 127.0.0.1:9050 IsolateDestAddr IsolateDestPort`. A `SocksPort` line in torrc replaces every `SocksPort` from the defaults file, so the unix socket is gone. Also add `InaccessiblePaths=/run/tor` to thelounge.service.

### A6. Medium: IPv6 is not actually off; i2pd publishes the IPv6 address
- `net.ipv6.conf.all.disable_ipv6 = 0`. NetworkManager uses `ipv6.method=auto` by default and does SLAAC itself (the kernel's `accept_ra=0` doesn't stop it). `i2pd.conf` has `ipv6 = true`. On a dual-stack network i2pd gets a global address and publishes it in its RouterInfo. The 1.9 report's "IPv6 off" came from a QEMU network with no IPv6 (`hcap: ## ipv6 0` counts global addresses).
- Fix: pick one. Either really disable it (`net.ipv6.conf.{all,default}.disable_ipv6=1`, NM conf.d `ipv6.method=disabled`, i2pd `ipv6 = false`), or keep IPv6 and correct the docs. Tails disables IPv6.

### A7. Medium: Diodon clipboard history keeps passwords
- Diodon starts from `/etc/xdg/autostart` and records every clipboard entry, including passwords that KeePassXC clears from the clipboard after 10 s, in memory and in its Zeitgeist store under `~/.local/share` (tmpfs, which per A2 is not wiped). Tails ships no clipboard manager.
- Fix: drop Diodon, or at least turn off history (`use-clipboard`/`keep-clipboard-content` false, history size 0) and stop it writing to Zeitgeist.

### A8. Medium: no screen locker, empty user password
- Autologin, `user` has an empty password (`user::` in shadow), and no locker is installed (no xscreensaver, light-locker, xss-lock or i3lock). Tails lets you lock the screen and asks for a password if none was set. With an empty password and `pam_unix nullok`, polkit `auth_self` prompts accept an empty password (*verify*), so the "password needed for mount" control from 1.9 may not mean much.
- Fix: add `xss-lock` + `i3lock`/`xsecurelock`. On the first lock, ask the user to set a session password (`passwd` for `user`), as Tails does.

### A9. Medium: firewall fails open if ferm doesn't load
- `ferm.service` is `Before=network-pre.target` (good), but NetworkManager only *orders* after it. If ferm fails (syntax error, missing module), the kernel defaults (ACCEPT) stay and NM brings the network up anyway.
- Fix: a NetworkManager drop-in with `Requires=ferm.service` and `After=ferm.service`. Also load a minimal DROP-all ruleset early (`iptables-legacy-restore` in an initramfs or early unit) that ferm then replaces.

### A10. Medium: kernel command line gaps vs Tails
- Missing compared with Tails: `spec_store_bypass_disable=on`. Prestium has everything else Tails passes (`slab_nomerge slub_debug=FZ(P) mce=0 vsyscall=none init_on_free=1 page_alloc.shuffle=1 randomize_kstack_offset=on mds=full,nosmt`).
- Worth adding (beyond Tails): `debugfs=off`, `intel_iommu=on amd_iommu=force_isolation iommu=force iommu.strict=1 efi=disable_early_pci_dma` (DMA over Thunderbolt/USB4: the `thunderbolt` module isn't blocked), and `module.sig_enforce=1` (the BIOS path has no lockdown, so unsigned modules load there). `page_poison=1` does nothing extra with `init_on_free=1`.

### A11. Medium: MAC spoofing is weaker than Tails'
- NM sets `cloned-mac-address=random` (fully random, locally-administered bit set) only when a connection activates. Tails spoofs at udev time, before NM, keeps the vendor OUI so the address looks ordinary, and disables the NIC if spoofing fails. `macchanger` is installed but unused (`/etc/default/macchanger: ENABLE_ON_POST_UP_DOWN=false`).
- Fix: a udev rule (as Tails does) that runs `macchanger -e` on `add` for net devices and takes the interface down if it fails. Or at least NM `random` plus `ethernet.generate-mac-address-mask` to keep the OUI.

### A12. Low: sudo / setuid surface
- sudoers: the `date` rule is fixed (F1; it can still set any time, which only risks DoS). `prestium-power` is safe (`prestium-tunnel-hops` checks `^[1-7]$`).
- setuid root beyond what is needed: `ntfs-3g` (4755, a root-exploit history, e.g. CVE-2017-0358 and CVE-2021-33285 family), `gst-ptp-helper` (4755; Debian means it to use file capabilities, and setuid is the fallback when setcap fails in a chroot build), `ssh-keysign`, `chfn`, `chsh`, `newgrp`, `gpasswd`, `pppd` (root:dip; user isn't in dip), `ping`. Fix: `dpkg-statoverride` to 0755 for ntfs-3g, gst-ptp-helper, ssh-keysign, chfn, chsh, newgrp and pppd. udisks mounts NTFS through the kernel `ntfs3` driver or as root anyway.

---

## b) User-facing programs

The firewall is the main control: uid 1000 can't reach anything beyond 127.0.0.1, and `/etc/environment` points `http(s)_proxy` at i2pd 4450, which has **no outproxy**. So update checks, telemetry and DNS from user apps **fail closed** and don't leak. The table says what each app *tries*. With A1 unfixed, every "unconfined" entry is also a path to the real IP.

| Program (version) | Network behaviour / defaults | CVE / maintenance | Rating and suggested fix |
|---|---|---|---|
| Tor Browser 15.0.26 (/opt) | System Tor 9050; updater disabled by policy (`DisableAppUpdate`), so it never updates on its own | Current, same as Tails 7.15.1 (eMudhra fix included) | **High** because of A4 (writable, unconfined). Ship a new TB with each release |
| LibreWolf 158.0.1 "Web Browser (I2P)" | HTTP/HTTPS to i2pd 4444. **Clearnet goes out through one outproxy (`exit.stormycloud.i2p`)**. JS off, WebRTC off, DoH off, telemetry/studies/updates off by policy. HTTPS-Only off. Proxy prefs are `defaultPref` in user-writable `~/.librewolf` (the firewall still covers them) | Upstream-maintained repo; NSS builtins carry emSign (A3); unclear whether Mozilla's eMudhra block (MFSA 2026-112) reached LibreWolf | **Medium**: one operator sees every clearnet destination; the fingerprint differs from Tor Browser. Fix A3. Turn HTTPS-Only on for non-.i2p hosts. Say in the menu label that clearnet goes through an I2P outproxy |
| Firefox 158.0.1 local-only (/opt/firefox) | Only 7070/7685/9000 via gid rule | Fine | **Medium** only through A5 (unix SOCKS bypass) |
| Gajim 2.1.1 | Global proxy = I2P HTTP 4444, so XMPP over HTTP CONNECT through the same outproxy; `check_for_update=false` | Debian-maintained | **Medium**: Tails routes XMPP over Tor. Use a SOCKS5 127.0.0.1:9050 proxy (with OMEMO) as the default |
| Feather 2.8.1 (Monero) | SOCKS5 127.0.0.1:**4447 (i2pd)**, `torOnlyAllowOnion=false`, `useLocalTor=true` (contradictory); clearnet nodes can't be reached through i2pd SOCKS (no outproxy), so it works only with .i2p nodes | Upstream binary, sig-checked | **Low/usability**: set Tor 9050 with onion-only nodes (the Tails pattern), or document I2P nodes |
| KeePassXC 2.8.0 AppImage | `CheckForUpdates=false`; favicon download off by default | AppImage bundles Qt/OpenSSL outside Debian updates | **Medium (AppImages as a class)**: use Debian `keepassxc` 2.7.10 (= Tails), or extract the AppImages to /opt so FUSE and setuid fusermount3 aren't needed |
| GpgFrontend 2.2.2 AppImage | Checks GitHub for updates at start (blocked: the proxy has no outproxy); key-server lookups would go through i2pd 4450 and fail | Small project, bundled libs | **Medium**: turn off the update check in its settings; prefer Kleopatra (Tails) or plain `gpg` |
| Audacity 4.0.1 AppImage | Update check + Sentry error reporting (blocked by the firewall; turn both off in `audacity.cfg`) | 4.0 is very new; bundled libs | **Medium**: Debian `audacity` 3.7.3 (= Tails), or preseed `UpdateNoticeShown`/`SendAnonymousUsageInfo=0` |
| OnionShare 2.6.3 | System Tor control socket; `use_autoupdate=false` | Debian deb13u2 | **Low** (needs a control-port allow-list under A1) |
| VLC 3.0.24 | Asks about metadata network access on first run (art/lyrics lookups; blocked) | Current Debian security | **Low**: preseed `metadata-network-access=0` in `vlcrc` |
| LibreOffice 25.2.3 (deb13u8) | No update check in Debian builds; AppArmor profiles in **complain** mode | Current | **Low** |
| GIMP 3.0.4, FeatherPad 1.6.1, SpeedCrunch 0.12, file-roller 44.5, 7zip 25.01, Ristretto 0.13.3, Loupe 48.1, Metadata Cleaner 2.5.2/mat2 0.13.5 | No network use (Loupe's GPS-to-place lookup is the offline libgweather database, `gweather_location_find_nearest_city`) | SpeedCrunch upstream is quiet (2016 release) | **Low** |
| Sylpheed 3.8.0~beta1 | Mail client; no proxy configured, so it can't reach any server (firewalled) | Upstream effectively unmaintained (beta since 2022) | **Low/Medium**: Tails ships Thunderbird. Drop Sylpheed or document it |
| QtQR 2.1~bzr52, Onboard 1.4.1 | Offline | Both effectively unmaintained upstream | **Low**: keep or replace (e.g. `zbar-tools` + `qrencode`) |
| Diodon 1.13 | — | — | **Medium**, see A7 |
| PCManFM 1.4 + gvfs-backends | "Network" browsing (smb/dav/ftp/dnssd) is firewalled | — | **Low**: remove `gvfs-backends`' network backends (smaller attack surface; it also pulls libsmbclient) |
| Nyx 2.1.0 | Uses the control port | Maintained in Debian | Needs an allow-list under A1 |
| ModemManager 1.24 | Probes serial/USB modems; NM could bring up mobile broadband (still firewalled) | — | **Low** (Tails ships it too) |
| The Lounge 4.5.2 / Node 24.22.1 | 127.0.0.1:9000, private mode, no prefetch/uploads | Current | **Low** apart from A5 |
| i2pd 3.0.0 | See d) | Current | — |
| Tor 0.4.9.14 | See d) | Current | — |

No telemetry was found enabled anywhere: LibreWolf, Firefox and Tor Browser have it off by policy, and every other app is offline or firewalled.

---

## c) Tails 7.15.1 hardening gaps (by area)

| Area | Tails 7.15.1 | Prestium 1.9.1 rootfs | Gap / suggestion |
|---|---|---|---|
| Memory wipe | init_on_free + return to initramfs + overlay deletion (tested) | init_on_free only | **Critical, A2** |
| Emergency shutdown on medium removal | udev-watchdog, memlocked, off during suspend | prestium-usb-watchdog + F2 fallback, memlocked; no suspend handling | Add a system-sleep hook that pauses the watchdog during suspend (Tails #11729) *verify*. Fix A2 inside the fallback |
| Control port | onion-grater filter | full access for `user` | **Critical, A1** |
| Network isolation | Per-app/per-uid ports, everything else blocked | Only user, localweb, thelounge are split; user reaches every localhost port | **A1/A5** |
| AppArmor | Enforced; Tor Browser, Thunderbird, Totem, Evince … confined | Enforced for i2pd, system_tor; user apps unconfined; LibreOffice complain | **High, A4**: profile Tor Browser and LibreWolf first |
| Kernel cmdline | as in the design page | all but `spec_store_bypass_disable=on` | A10 |
| sysctl | kptr_restrict, mmap_rnd_bits max, kexec off, bpf_jit_harden … | Superset (also ptrace_scope=2, io_uring off, unprivileged_bpf off, tcp_timestamps 0, protected_* …) | Add `dev.tty.legacy_tiocsti=0`. Userns stays on (needed by bwrap, glycin, TB sandbox) |
| Swap / core dumps | none / disabled | no swap; `core_pattern=|/bin/false`, `suid_dumpable=0` | OK |
| IPv6 | disabled | **on** for i2pd/Tor on dual-stack LANs | A6 |
| MAC spoofing | macchanger at udev, OUI kept, fail = NIC off | NM random at activation | A11 |
| Hostname / DHCP | generic | `hostname-mode=none`, `dns=none` | OK |
| DNS | Tor DNSPort only | dead resolver (127.0.0.1, nothing listening) | OK (fails closed) |
| Time sync | over Tor | over Tor (prestium-htp) | OK |
| Unsafe Browser | present, off by default (captive portals) | none | Safer as is; note that captive-portal Wi-Fi can't be used |
| Bridges / PT | obfs4, Snowflake, WebTunnel + Tor Connection assistant | obfs4proxy only, no GUI | Low: add `snowflake-client`, `webtunnel` |
| Camera / mic | not blocked | not blocked | Optional: a boot option that blacklists `uvcvideo`/`snd_*` |
| Screen lock | yes | none | A8 |
| Tor Browser install | read-only, root-owned | user-writable | A4 |
| CA store | eMudhra blocked (7.15.1) | 3–4 emSign roots trusted | A3 |
| Secure Boot / lockdown | shim + signed | shim + signed GRUB, lockdown=integrity (SB only) | Add `module.sig_enforce=1` for the BIOS path (A10) |
| Persistent storage | encrypted, opt-in | none (pure amnesic) | OK by design |

---

## d) Firewall and network configuration

1. **Medium/High (= A1):** `OUTPUT … outerface lo daddr 127.0.0.1 proto tcp syn dport 1024:65535 uid-owner user ACCEPT`. It is too wide (i2pd console 7070, SAM 7656, The Lounge 9000, torrents 7685, any future local service). Use an explicit port list.
2. **Medium (= A5):** Tor `SocksPort unix:/run/tor/socks WorldWritable` (from the Debian defaults) gets around every uid and gid rule.
3. **Medium (= A9):** ferm can fail open; NM doesn't require it.
4. **Medium (= A6):** IPv6 isn't disabled; `ip6 OUTPUT` allows i2pd and debian-tor everything; `i2pd ipv6 = true`.
5. **Low:** `ip6 OUTPUT outerface lo ACCEPT` comes before the owner rules, so every uid (except localweb/thelounge, rejected first) reaches every `::1` service. Restrict it like IPv4, or drop it if IPv6 is disabled.
6. **Low:** debian-tor and i2pd may send anything (TCP+UDP, any port). Tor needs only TCP (unless Snowflake is added). Suggest `mod owner uid-owner $tor_uid proto tcp ACCEPT`. i2pd needs both.
7. **Low:** no `mod state state INVALID DROP` in OUTPUT (Tails has it, against conntrack-INVALID leaks). Cheap to add at the top of OUTPUT.
8. **Low:** dead rule: `dport 631` for user (CUPS isn't installed). Remove it.
9. **Low:** the `INPUT` PRESTIUM_I2PD chain opens the per-boot i2pd port (TCP NEW + UDP). That is needed for a reachable router, but it makes the machine identifiable as an I2P router on the LAN/ISP. i2pd also runs with `bandwidth = X` (unlimited) and `share = 70` (transit on). Consider `bandwidth = L/O`, `share` 20–30, or `notransit = true` for a lower profile (a trade-off against helping the network).
10. **Low:** i2pd `[sam] enabled = true` (comment: "for XD"; no shipped app uses SAM). Turn it off, or restrict it per item 1. `[socksproxy] 4447` is on with no outproxy (OK). The tunnels.conf comment calls a SOCKS proxy unnecessary, yet i2pd.conf enables it; it is used by Feather and Gajim's I2P SOCKS preset.
11. **Low:** i2pd reseed uses only the bundled `stormycloud-i2pseeds.su3` (`urls =` empty, `verify = true`). Good for privacy, but the file ages and bootstrap will start failing; refresh it each release.
12. **Low:** Tor `torrc` is empty, so it runs on Debian defaults: no `Sandbox 1`, no `AvoidDiskWrites 1`, no `IsolateDestAddr/IsolateDestPort` on 9050 (Tor Browser isolates by SOCKS auth, but other apps share circuits). Suggest `SocksPort 127.0.0.1:9050 IsolateDestAddr IsolateDestPort` (also fixes A5), `AvoidDiskWrites 1`, `Sandbox 1` (check it with the system_tor AppArmor profile).
13. **Low:** `/etc/environment` proxies everything to i2pd 4450 (no outproxy), so CLI tools fail closed for clearnet (good). There is no `no_proxy=127.0.0.1,localhost`, so tools that honour it also send local requests to i2pd.
14. **OK:** OUTPUT/INPUT/FORWARD policy DROP, root has no outbound, the localweb gid and thelounge uid rules are correct for TCP, DNS is dead, NM connectivity check is off, hostname isn't sent, machine-id is regenerated each boot (empty file in the image), and `NetworkManager` starts after `network-pre.target` (after ferm).

---

## Summary of what changed in the rootfs this session (a rebuild is needed)
- `usr/local/share/prestium-thelounge/prestium.json`: 7 networks. IRC2P 6668 (postman) and Ilita 6669 connect at start. IRC2P (echelon) 6665, IRC2P (dg) 6666, Ilita (r4sas) 6670, Ilita (acetone) 6671 and Ilita (rusirc) 6672 are listed disconnected with host and port already set (select one, then "Connect"). IRC2P presets join #i2p, #i2p-chat, #i2p-dev (no #i2p-help). Ilita presets have no channels.
- `usr/local/sbin/prestium-thelounge-setup`: one distinct random nick per network. Before, all networks got the **same** nick, which linked the IRC2P and Ilita identities.
- `var/lib/thelounge/config.js` (comment only; `defaults` is a single object in The Lounge 4.5, so it stays IRC2P 6668) and the `var/lib/i2pd/tunnels.conf` comment.
- Packages: `loupe 48.1-3`, `glycin-loaders 1.2.1+ds-2`, `metadata-cleaner 2.5.2+ds-1`, plus `libgweather-4-0t64`, `libgweather-4-common`, `libgeocode-glib-2-0`, `geocode-glib-common`, `gir1.2-adw-1` (apt, signature-verified, `--no-install-recommends`; `dpkg --audit` clean).
- `etc/xdg/openbox/menu.xml`: Image Viewer → `loupe`, new "Metadata Cleaner". `etc/xdg/mimeapps.list`: 23 image types → Loupe, then Ristretto.
- `usr/share/file-manager/actions/prestium-remove-metadata.desktop` + `usr/local/bin/prestium-remove-metadata` (mat2, writes `name.cleaned.ext`, keeps the original, zenity result).
