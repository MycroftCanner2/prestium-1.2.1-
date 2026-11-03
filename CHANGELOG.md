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
