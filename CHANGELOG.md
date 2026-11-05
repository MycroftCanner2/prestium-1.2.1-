# Prestium 2.0 (draft, work in progress): changes since 1.9.1.3

Prestium 2.0 is rebuilt from scratch with Debian's live-build (see BUILDING.md); the desktop looks
and works the same. Not released yet: the download, size and SHA-256 will be added here when the
ISO is published. Changes listed are against the last release, 1.9.1.3; the 1.9.1.3 notes (changes
since 1.8) follow below.

## Build system
- **Built with live-build** from a configuration in git (package lists, Prestium's files, hooks)
  instead of upgrading and patching an unpacked root filesystem. Anyone can rebuild the ISO with
  `sudo ./build.sh`.
- Every third-party download (Tor Browser, Firefox, Node.js, The Lounge, Feather, lurch) is checked
  against its publisher's OpenPGP signature and a SHA-256 pinned in the repository; LibreWolf, i2pd
  and Tor come from their signed apt repositories.
- Fixed: 1.9.1.3 shipped the build machine's `/etc/resolv.conf` (a private nameserver address).
  2.0 ships Prestium's own (`nameserver 127.0.0.1`, no system DNS). The firewall blocked DNS anyway.

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
- **LibreWolf (I2P Browser) runs under an enforced AppArmor profile** (complain mode in 1.9.1.3).
  It can write only its own profile/cache/config, `~/Downloads` and temporary files, cannot read
  other apps' data (Pidgin, Claws Mail, Feather, keyrings, GnuPG, Tor Browser) and cannot reach Tor's
  control port. Opening a download in another app from inside the browser is not allowed; use the
  file manager.
- The firewall stays default-deny. New: the Tor Connection Assistant's DNS-over-HTTPS user may only
  reach i2pd's HTTP proxy, and Tor's uid gets UDP only while Snowflake mode is on.

## Feather
- **Feather is back on I2P**, as in 1.7 and 1.8: its I2P proxy mode through i2pd's SOCKS proxy
  (127.0.0.1:4447). 1.9.x had switched it to Tor (9050) with onion nodes only.

## Tor Connection Assistant (new)
- New menu entry **Network → Tor Connection Assistant**. Tor still connects directly at boot.
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
  every login to GTK/Qt apps, the panel (tint2) and Openbox.
- **Laptop keys:** volume, mute, mic mute and brightness keys work, with an on-screen notification;
  **Brightness** slider in the menu (brightnessctl; the live user is in group `video`, and a udev
  rule makes the backlight writable for it).
- **Touchpad:** tap to click, natural scrolling and disable-while-typing by default; **Touchpad**
  settings in the menu (saved and re-applied at login).
- **Accessibility:** **Orca** screen reader (speech-dispatcher + eSpeak NG) and **Onboard**
  on-screen keyboard, in the menu.

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
- Bandwidth is set to L with 30% sharing, and the reseed file is refreshed and signature-checked.

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
