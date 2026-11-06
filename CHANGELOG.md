# Prestium 2.0 (draft, work in progress): changes since 1.9.1.3

Prestium 2.0 is rebuilt from scratch with Debian's live-build (see BUILDING.md); the desktop looks
and works the same. Not released yet: the download, size and SHA-256 will be added here when the
ISO is published. Changes listed are against the last release, 1.9.1.3; the 1.9.1.3 notes (changes
since 1.8) follow below.

## 2.0 r8 (firewall stop fails closed)

- Stopping or restarting the firewall (ferm), including at shutdown, now falls back to the boot-time
  drop-all (loopback only, IPv4 and IPv6) instead of Debian's default, which cleared every rule and
  allowed all traffic until ferm started again. Policies are set to DROP before the old rules are
  cleared, so there is no open moment. Firewall reloads were already atomic and are unchanged.
- Not tested on a booted ISO yet.

## 2.0 r7 (failure handling)

- **Tor mode never reports success after a failed firewall reload:** `ferm_reload()` now checks its result. A failed reload during apply rolls back; Tor is started again only after the previous firewall reloads cleanly. If that reload fails too, Tor stays **stopped**, the state file records `firewall_error`, and the assistant tells the user to restart before going online. `revert` and cancel-during-apply fail closed the same way.
- **Tor mode restores the complete previous state:** the backup records files that did not exist (they are removed on restore, instead of leaving the new ones in place) and is only used when complete (`.complete` marker). A failed `tor stop` at the start of apply aborts the change.
- **i2pd port: complete rollback:** once `i2pd.conf` is touched, any failure (including `set -e` exits) restores the previous `i2pd.conf` **and** the previous `/run/prestium/i2pd.port` and `i2pd-console.pass` (or their absence), reloads ferm to match, and exits non-zero so i2pd does not start. A failed rollback is reported as such (exit 2).
- **Reseed refresh keeps a usable fallback:** the build-shipped/previous `.su3` (possibly stale) and the existing netDb are kept aside, not deleted, until i2pd has started with the freshly verified file downloaded through Tor. On any failure both come back and the message says the previous (possibly stale) data is in use. If the current file cannot be backed up, nothing is changed. A failed `systemctl stop i2pd` aborts before netDb is touched.
- **USB watchdog non-arming is visible:** only `toram` is an expected reason not to arm. No medium, an unresolvable medium, or a fallback process that did not start → unit fails (exit 3, no restart loop) and a safety flag is raised.
- **Shutdown memory-wipe preparation is visible:** `prestium-initramfs-unpack` fails on any decompress or cpio error or a missing `/shutdown`, and raises a safety flag.
- **New `prestium-safety-notify` (session autostart):** shows a persistent critical notification and a warning dialog for every safety flag, a watchdog unit that is not running (non-`toram` boots), and a failed `prestium-initramfs-shutdown.service`. Flags are written by `/usr/local/lib/prestium/safety-flag` to `/run/prestium/safety/` and logged to the kernel log and auth log.
- **Build locking and cache integrity:** `build.sh` holds an exclusive lock for the whole run (`--resume` removes live-build's `.lock`, which is only safe when nothing else builds). `fetch-thirdparty.sh` locks the shared cache. Cached The Lounge installs are reused only when their whole tree matches the hash recorded right after the lockfile-verified `npm ci`; the cached tar has a recorded SHA-256 that is checked after staging. Cached lurch work trees must be clean against their pinned commits. Staged Tor Browser, Firefox, Node and Feather copies are re-checked against their pins after copying.
- **Tests:** `tests/test_tor_mode_failures.py` (runs the real helper with mocked systemctl and ferm) and `tests/test_i2pd_port_rollback.sh` (runs the real script with redirected paths).
- **Not tested on a booted ISO yet.**

## 2.0 r6 (security / state-machine)

- **Tor mode cancel:** cancel with no apply no longer restores PREV and stops a connected Tor; connected → refuse (use revert); connecting → stop Tor, keep config; apply-in-progress → signal apply (restore PREV). Lock/PID race: cancel waits briefly if the apply lock is held.
- **Tor Connection Assistant:** cancel UI matches the new semantics; poller no longer drives phase during applying/cancelling; external Tor stop while connecting returns to idle.
- **i2pd port:** blocking ferm reload; on reload failure restore previous `i2pd.conf`, remove `/run/prestium/i2pd.port`, exit non-zero (fail closed). Per-boot console `auth`/`pass`; password in `/run/prestium/i2pd-console.pass` for localfox.
- **I2P Torrents:** bind-mount Torrents onto itself after create (blocks post-start symlink swap); `/run/prestium-torrents/status` distinguishes `ready` vs `disabled:<reason>`.
- **i2pd systemd:** `10-hardening.conf` with `ProtectHome=read-only` (not tmpfs) so Torrents stays visible via `ReadWritePaths`.
- **onion-grater:** control socket `0660` root:user (PEERCRED unchanged).
- **tunnel-hops:** flock; success text states `:4444` is limited readiness, not tunnels built.
- **reseed:** keep previous `.su3`, one retry on start failure, restore previous file if start still fails.
- **clockfix:** only verified consensus files (`cached-*-consensus`), never `unverified-*`. `prestium-timesync` ordered `After=prestium-clockfix`.
- **The Lounge launcher:** require active unit + 128-hex token; clearer recovery text.
- **Rejected / already fixed earlier:** sudoers `--file /*` is valid (`*` matches `/` in command arguments); UDP NEW + share template + blocking ferm reload landed in 515d178; lurch commit pins are content-addressed integrity (documented), not weaker than an unsigned tar SHA.

## Build system
- **Built with live-build** from a configuration in git (package lists, Prestium's files, hooks)
  instead of upgrading and patching an unpacked root filesystem. Anyone can rebuild the ISO with
  `sudo ./build.sh`.
- Every third-party download (Tor Browser, Firefox, Node.js, The Lounge, Feather, lurch) is checked
  against its publisher's OpenPGP signature and a SHA-256 pinned in the repository; LibreWolf, i2pd
  and Tor come from their signed apt repositories.
- Fixed: 1.9.1.3 shipped the build machine's `/etc/resolv.conf` (a private nameserver address).
  2.0 ships Prestium's own (`nameserver 127.0.0.1`, no system DNS). The firewall blocked DNS anyway.
- Build downloads are HTTPS-only, redirects included (`curl --proto =https --proto-redir =https`),
  and the Debian mirrors (bootstrap, chroot, security, and the shipped sources) use `https://`.
- Removed the legacy 1.9.1.3 trees (`rootfs/`, `iso/`, `build-1.9.1.3/`) and `LARGE_FILES.md` from
  this branch; 2.0 is built only from the live-build config. They remain in the
  `prestium-1.6-update` branch and in git history.
- Supply chain (audit): the build-time apt sources for i2pd, LibreWolf and Tor are each `signed-by`
  their own key, and apt pins (`Pin: origin`) let each repository supply only its own packages
  (i2pd; LibreWolf; tor, tor-geoipdb, the keyring, lyrebird, snowflake-client, webtunnel). The
  same pins ship in the image (`/etc/apt/preferences.d/prestium-thirdparty`).
- The Lounge is pinned exactly (`thelounge` 4.5.2, not `^4.5.2`) and its npm settings
  (`thirdparty/thelounge/.npmrc`: `ignore-scripts`, `save-exact`, `min-release-age=7`) are used by the
  build. Its one git dependency, `irc-framework` (commit-pinned, no integrity hash in the lockfile),
  is now checked against a pinned SHA-256 of its installed files on every build.

## Hardware and packages
- Everything current at build time: Debian 13 trixie with updates and security fixes, kernel from
  the trixie 6.12 line (Tails' line), firmware from trixie-backports (`firmware-linux` 20260916 or
  newer, the Tails 7.15 set) plus extra firmware for network cards, TV tuners, Qualcomm and Samsung
  devices where Debian has it.
- Tor Browser 16.0, Firefox 159.0.1 (local pages only), Node.js 24.22.2, The Lounge 4.5.2,
  Feather 2.9.1 (was 2.8.1), LibreWolf, i2pd and Tor at the newest versions of their repositories.
- Secure Boot (shim + GRUB), BIOS boot and the hybrid ISO are kept.
- SpeedCrunch is no longer in Debian 13 (1.9.x carried the Debian 12 package); the menu's
  Calculator is now Galculator.
- LibreWolf extensions updated to uBlock Origin 1.75.4 and NoScript 13.6.37 (AMO-signed); Tor
  Browser's added uBlock Origin also 1.75.4.

## Audio
- **PipeWire** with **WirePlumber**, **pipewire-pulse** and **pipewire-alsa** replaces plain ALSA,
  so sound works on more hardware (USB, HDMI/DisplayPort, Bluetooth-free laptops with SOF DSPs,
  Surface devices), with current ALSA UCM profiles and SOF firmware. Started for the user session by
  systemd. The camera-and-microphone-off boot option still blocks capture devices.
- The panel's volume icon is now **pasystray** (works with PipeWire); "Volume Control" (pavucontrol)
  is unchanged in the menu. volumeicon (ALSA only) is gone.

## Security
- i2pd's per-boot port is opened inbound for IPv4 only (1.8 to 2.0 drafts opened it for IPv4 and
  IPv6). The rule now lives in ferm.conf, which reads the port from /run/prestium/i2pd.port, so a
  firewall reload (for example by the Tor Connection Assistant) no longer drops it. IPv6 stays closed.
  Both the TCP and UDP rules accept only new connections. The rule is in place before i2pd starts.
- The spare /etc/i2pd/i2pd.conf template now matches the live config (bandwidth L, share 30).
- I2P Torrents page: reworked dark theme with a header bar, card panels, a sticky table header,
  right-aligned numbers, softer status colours on the progress bars, red delete buttons, a
  highlighted totals row, focus rings, dark scrollbars and a narrow-window layout.
- i2pd UPnP is explicitly off (`[upnp] enabled = false`) instead of relying on the Linux default.
- i2pd sets `floodfill = false` and `notransit = false` explicitly (never a floodfill, still relays transit tunnels).
- polkit: the desktop user gets an allow-list of NetworkManager actions (connect, disconnect,
  Wi-Fi on/off and scan, save connections) instead of every NetworkManager action. Hotspot sharing,
  hostname and global DNS changes and the other admin actions now need authentication. The i2pd
  rule only allows start, stop and restart, and every rule needs the active local session.
- Fixed (audit): the two helpers the desktop user may run through sudo (`prestium-tunnel-hops`,
  `prestium-i2p-reseed`) ran Python as root in the caller's working directory, so a planted module
  (e.g. `re.py`) ran as root. Both now `cd /` and run Python isolated (`python3 -I`).
- "Refresh I2P reseed" / "Manual reseed file" install the new file through the same symlink-safe
  helper (`safefile`) as the other i2pd helpers, so an entry planted in i2pd's directory cannot
  redirect or swallow the install.
- **LibreWolf (I2P Browser) runs under an enforced AppArmor profile** (complain mode in 1.9.1.3).
  It can write only its own profile/cache/config, `~/Downloads` and temporary files, cannot read
  other apps' data (Pidgin, Claws Mail, Feather, keyrings, GnuPG, Tor Browser) and cannot reach Tor's
  control port. Opening a download in another app from inside the browser is not allowed; use the
  file manager.
- The firewall stays default-deny. New: the Tor Connection Assistant's DNS-over-HTTPS user may only
  reach i2pd's HTTP proxy, and Tor's uid gets UDP only while Snowflake mode is on.
- **Security audit fixes (2.0 audit, all confirmed findings):**
  - **Fixed a local root escalation** (high): the root helper that prepares I2P Torrents before every
    i2pd start created and re-owned `~/Downloads` and `~/Downloads/Torrents` as root, following a
    symlink the desktop user could put there, so any program running as the user could take over a
    system directory with `sudo systemctl restart i2pd`. The folders are now created as the user,
    and a symlink or non-directory is refused (I2P Torrents is then skipped; i2pd still starts).
  - Root helpers no longer write through files the i2pd account owns (medium): changing tunnel hops,
    the per-boot i2pd port and the torrent setup read and replace `/var/lib/i2pd/i2pd.conf`,
    `tunnels.conf` and `tunnels.conf.d/` only through a new symlink-safe helper (refuses symlinks
    and special files, writes a new file and renames it into place). `tunnels.conf.d` is now
    `root:i2pd 0750`, so i2pd can read but not change it.
  - The Lounge's setup (root, before every start) refuses symlinked directories and reads and writes
    the user file as the `thelounge` account, exclusively, then renames it (low).
- Hardening from the audit: OnionShare's onion services may only point at OnionShare's own local
  ports 127.0.0.1:17600-17650 (as in Tails); `sudo prestium-tunnel-hops` accepts only 1-7; the Tor
  assistant's bridge checks accept ASCII digits only; the reseed helper refuses a symlinked
  `i2pd.conf` or netDb.

## Feather
- **Feather is back on I2P**, as in 1.7 and 1.8: its I2P proxy mode through i2pd's SOCKS proxy
  (127.0.0.1:4447). 1.9.x had switched it to Tor (9050) with onion nodes only.

## Tor Connection Assistant (new)
- New menu entry **Network → Tor Connection Assistant**. Tor still connects directly at boot.
- Error messages appear in a fixed-height, scrollable area (long details go to **Details**), so a failed connection never makes the window bigger; the window always fits above the taskbar (1024x768 and up), and long bridge lines wrap.
- Shows Tor's bootstrap progress (through the control-port filter, read-only), a **Reconnect**
  button, and modes **Direct**, **Snowflake**, **WebTunnel** and **obfs4** (Tor Browser's built-in
  bridges and/or your own bridge lines).
- **Snowflake and WebTunnel now work without system DNS:** only the host names they need (Snowflake
  front domains and STUN servers, the WebTunnel bridge host) are resolved with DNS-over-HTTPS
  **through the I2P outproxy** and pinned for Tor's transports. Tor's own traffic never goes through
  I2P. Networks that block or poison DNS for Tor infrastructure can't stop these look-ups.
- Optional, experimental: Snowflake's rendezvous through the I2P outproxy (if snowflake-client
  supports `-proxy`).
- **Reworked in 2.0:** modes **Direct, Snowflake, WebTunnel, obfs4 and meek**. Opening the
  assistant never touches Tor; **Apply and connect** stops Tor first, resolves, writes the new
  configuration and starts Tor again, so progress runs from 0 %. **Cancel** works at any point (the
  previous configuration is put back and Tor stays stopped; **Retry** / **Revert to previous**
  offered). Choices are saved in `~/.config/prestium/tor-assistant.json`; the mode shown on start is
  the one Tor is actually using.
- **Parallel DNS-over-HTTPS through the I2P outproxy:** every needed name is asked of several DoH
  providers at once (Cloudflare, Google, Quad9, AdGuard, Mullvad; port 443 only, keep-alive
  connections through i2pd's HTTP proxy), first valid public IPv4 answer wins, results are cached.
  Fixes 2.0's first version, whose Quad9 JSON endpoint (port 5053) the outproxy always refused.
- **Snowflake fix:** Debian's `system_tor` AppArmor profile did not let the transports read the
  system CA bundle, so TLS to the Snowflake broker (and WebTunnel/meek) failed inside the
  confinement. `/etc/apparmor.d/local/system_tor` now includes `abstractions/ssl_certs` and the
  network-interface reads Snowflake's WebRTC stack needs.
- **Built-in bridges** are Tor Browser 16.0's own (`pt_config.json`, copied verbatim). Transports
  from deb.torproject.org: **snowflake-client 2.15.1+tpo**, **lyrebird 0.9.0**, **webtunnel 0.0.7**.

## Display, laptops and accessibility
- **Display Settings** (xfce4-display-settings, replaces arandr): resolution, arrangement and
  mirroring, with automatic handling of monitors plugged in or out.
- **HiDPI:** **Display Scale** (Auto from the screen's physical size, or 100-200 %), applied at
  every login to GTK/Qt apps, the panel (tint2) and Openbox. At 175/200 % GTK now gets the window
  scale together with the matching DPI, so GTK 4 dialogs and the Firefox-based browsers are no
  longer drawn too big, and the taskbar's text scales with its height (tint2 ignores the DPI, so
  its fonts are written out scaled).
- The I2P reseed windows (**Refresh I2P reseed**, **Manual reseed file**) are normal windows with a
  title bar and open centred; other zenity dialogs open centred too.
- **Laptop keys:** volume, mute, mic mute and brightness keys work, with an on-screen notification;
  **Brightness** slider in the menu (brightnessctl; the live user is in group `video`, and a udev
  rule makes the backlight writable for it).
- **Touchpad:** tap to click, natural scrolling and disable-while-typing by default; **Touchpad**
  settings in the menu (saved and re-applied at login).
- **Accessibility:** **Onboard** on-screen keyboard, in the menu. (The Orca screen reader was
  tried and removed: it did not work.)

## Apps
- **IRC (The Lounge)** no longer connects to IRC by itself. At boot the I2P tunnels are not up yet,
  so the automatic connection only produced an error (EPIPE) in the page. All networks are listed
  disconnected; right-click a network and choose **Connect** (or type `/connect`) when I2P is ready.
- **I2P Torrents** (i2pd's built-in torrent client) has a Prestium dark theme by default.
- The local-only Firefox no longer shows the Terms of Use / privacy notice / welcome pages at every
  boot (policy `SkipTermsOfUse` plus the matching first-run preferences). LibreWolf and Tor Browser
  never showed them.

## Known limitations (2.0 draft)
- See the test notes on the branch for what has and has not been verified in a VM yet.

---

# Prestium 1.9.1.3: changes since 1.8

Prestium 1.9.1.3 is a major update over 1.8. It rebases on Debian 13, adds Secure Boot and broader hardware support, adds Tails-style hardening throughout, and brings new apps and updates to existing ones. The desktop looks and works the same as 1.8.

**Download:** `Prestium-1.9.1.3-amd64.iso`, 2,592,849,920 bytes
**SHA-256:** `0ef5cd8bc1129b75a932eb76d1ef0f0031cc4160faab625beba480ae17a1913f`
**Torrent:** `Prestium-1.9.1.3-amd64.iso.torrent`, info hash `af992b4b9912282a875821f2e072c103b1ed1359`

## Base system and hardware
- **Debian 13 "trixie"** replaces Debian 12 "bookworm".
- **Kernel:** 6.12.113 replaces 6.1, on the same kernel line as Tails 7.
- **Firmware:** the same firmware set as Tails, so more hardware works out of the box.
  - Includes non-free firmware: `firmware-linux` 20260916, which replaces the 20230210 set.
  - Adds Surface and modern Intel audio (`firmware-sof-signed`), NVIDIA graphics firmware and current wireless-regdb.
  - CPU microcode updated: AMD 3.20250311.1, Intel 3.20251111.1.
- **Secure Boot:** Prestium now boots with Secure Boot on, like Tails, so Surface devices and modern laptops boot unchanged.
  - Boot chain: Microsoft-signed shim, then Debian-signed GRUB, then the Debian-signed kernel.
  - Kernel lockdown is on, and every kernel module must be signed.
  - BIOS boot and the hybrid ISO for USB and DVD are kept.
- New boot menu entry **"camera and microphone off"**. Sound output keeps working.
- **Hardware clock fix:** if the PC clock is far off (for example, a Windows dual-boot set to local time), Prestium corrects it from Tor's consensus so Tor can connect. It then sets the exact time over Tor.

## Security and privacy hardening
- **AppArmor now really enforces.** Prestium 1.8 loaded no profiles on the live system. Tor, i2pd and Tor Browser are now confined.
- **Memory erasure at shutdown, the Tails design.** On shutdown, session data is deleted and freed memory is zeroed.
- **Faster emergency shutdown:** pulling the boot USB now powers off in about 6 seconds. This also works if the USB is pulled during suspend.
- **Firewall:**
  - Fails closed if it does not load.
  - Apps can only reach an explicit list of local proxy ports.
  - Invalid packets are dropped.
  - IPv6 is off everywhere.
  - Tor is TCP-only.
- **Tor control-port filter**, like Tails' onion-grater. Tor Browser, OnionShare and Nyx get only what they need, and no app can change Tor's configuration.
- **Tor:**
  - SOCKS is isolated per destination.
  - No world-writable socket.
  - Avoids disk writes.
- **i2pd:** its random inbound port actually opens now (1.8 dropped it). SAM is off.
- **MAC address spoofing** on every network device, done before NetworkManager. Turn it off with the boot option `nomacspoof`.
- **Screen lock:** Super+L, or System → Lock Screen. The first time, it asks you to set a session password.
- **Clipboard:** Diodon replaces ClipIt and keeps no history.
- **Kernel:**
  - IOMMU isolation and DMA protection
  - Extra Spectre mitigations
  - debugfs off
  - io_uring disabled
  - TIOCSTI blocked
  - fs.protected_fifos=2
- **Fewer setuid binaries:** ntfs-3g, chfn, chsh, ssh-keysign and gst-ptp-helper lose setuid.
- A sudo rule that could read root-only files (`date`) is restricted.
- **eMudhra/emSign root certificates are distrusted** system-wide and in all three browsers, matching Tails 7.15.1.
- Network file-sharing backends in the file manager (SMB, FTP, cloud and similar) are disabled.

## Browsers
- **Tor Browser 16.0** replaces 15.0.26:
  - **uBlock Origin** is added, and both uBlock and **NoScript** are pinned and visible on the toolbar.
  - The install is read-only and runs under an enforced AppArmor profile.
  - Downloads go to a **`~/Tor Browser`** folder, as in Tails.
- **I2P Browser** (LibreWolf 159), renamed from "Web Browser (I2P)":
  - Clearnet now goes through the **acetone I2P outproxy**, `proxy4uwdijqxac2bvdx4fuhem6njmiwukuk2gelejv2nzxka2xq.b32.i2p`, which replaces StormyCloud.
  - NoScript runs in private windows.
  - HTTPS-Only stays off, because I2P sites are plain http.
- **Local-only Firefox 159**, for the I2P Router Console, IRC and I2P Torrents, is still blocked from everything else.

## I2P
- The I2P **SOCKS proxy (4447)** now reaches the clearnet through the acetone outproxy, over new outproxy tunnels.
- **Mail over I2P:** the mail.i2p (postman) SMTP and POP3 tunnels are set up.
- Bandwidth is set to L with 30% sharing.
- The StormyCloud reseed file is downloaded fresh on every build and checked before it goes in (signature against i2pd's StormyCloud certificate, at most 14 days old); the build stops if either fails.
- **Refresh I2P reseed (via Tor)** (menu: Network): downloads a fresh reseed file over Tor (StormyCloud, then reseed.onion.im), checks its signature against i2pd's reseed certificates, installs it, clears the netDb and restarts i2pd. If both fail, nothing changes and it points you to https://reseed2.i2p.net/ and **Manual reseed file** (pick a downloaded .su3; it is checked the same way).

## Communication
- **Pidgin** is new. It runs over Tor and comes with:
  - **OTR** (v3)
  - **OMEMO** (lurch) for XMPP
  - **Message Carbons**
- **Claws Mail** replaces Sylpheed. The mail.i2p account comes preconfigured, with no HTML or remote content.
- **Gajim 2.1** has OMEMO built in, and its default proxy is now Tor.
- **The Lounge (IRC):**
  - Ready-made networks for each IRC tunnel: IRC2P, IRC2P (echelon), Ilita, Ilita (r4sas) and Ilita (acetone).
  - A different random nick on each network, so your identities aren't linked.
  - Joins no channels by default.

## New and changed apps
- **Unlock Volume (new):** opens LUKS1/2, BitLocker, VeraCrypt and TrueCrypt drives and containers.
  - Supports passphrases, recovery keys, keyfiles, PIM, and hidden or system volumes.
  - Lock them again from the same menu.
- **OnionShare** (new) uses the system Tor.
- **Metadata Cleaner** (new), plus a **"Remove metadata"** right-click action in the file manager.
- **Loupe** is the new image viewer, sandboxed as in Tails.
- **Archive Manager** (file-roller with 7-Zip) is new, for zip, 7z, tar and rar.
- Several apps now use Debian packages instead of AppImages:
  - **KeePassXC** 2.7.10
  - **Kleopatra**, which replaces GpgFrontend
  - **Audacity** 3.7.3
- **Feather:** Tor only, onion nodes only.
- **VLC:** no metadata lookups over the network.
- **Updated:** LibreOffice 25.2, GIMP 3.0, VLC 3.0.24, Tor 0.4.9.15, i2pd 3.0.0 (trixie build).

## Known limitations
- Snowflake and WebTunnel bridges are installed but need DNS, which Prestium deliberately doesn't provide. obfs4 bridges work.
- LibreWolf's AppArmor profile is in complain (log-only) mode for now.
- The ISO is larger than 1.8: Debian 13, the full firmware set and the new apps add to it.
