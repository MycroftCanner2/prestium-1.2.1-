Disclaimer: This project and all associated materials (including software, repositories, scripts, and ISO files) are provided strictly "as is" and "as available," for informational, educational, and experimental purposes only, without any express or implied warranties of any kind—including, but not limited to, fitness for a particular purpose, security, accuracy, or non-infringement. The creator and publisher make no claims regarding the safety, integrity, or audit status of any code or binaries, explicitly disclaim any expertise or maintenance obligations, and shall not be held liable for any direct, indirect, incidental, or consequential damages, security breaches, data loss, or legal issues arising from downloading, compiling, or using this material. You assume all responsibility and risk for your use of this software, and you are solely responsible for ensuring compliance with all applicable local, state, and international laws.

## Branch `prestium-2.0`: Prestium 2.0 (work in progress)

Prestium 2.0 rebuilds Prestium from scratch with Debian's **live-build** instead of patching an
unpacked root filesystem. It is based on Debian 13 "trixie" (amd64) and follows Tails for hardware
support: same Debian release, kernel line and firmware set, Secure Boot through shim/GRUB.

**Status:** work in progress. The released version is still **1.9.1.3** (branch `prestium-1.6-update`,
`Prestium-1.9.1.3-amd64.iso`, SHA-256 `0ef5cd8bc1129b75a932eb76d1ef0f0031cc4160faab625beba480ae17a1913f`).
No 2.0 ISO has been published.

- How to build: [BUILDING.md](BUILDING.md) (`sudo ./build.sh`)
- What changes in 2.0: [CHANGELOG.md](CHANGELOG.md)

### What changes in 2.0

1. **LibreWolf (I2P Browser) under an enforced AppArmor profile** (1.9.1.3: complain mode only).
   It can write only its own profile, cache and config, `~/Downloads` and temporary files.
2. **Feather back on I2P**: Feather uses its I2P proxy mode through i2pd's SOCKS proxy
   127.0.0.1:4447 again (as in 1.7/1.8); 1.9.x had switched it to Tor (9050, onion nodes only).
3. **Audio on more hardware**: PipeWire + WirePlumber with pipewire-pulse and pipewire-alsa (1.9.1.3
   had plain ALSA with an ALSA-only volume icon), SOF firmware, current ALSA UCM profiles, and a
   PulseAudio-compatible volume icon in the panel (pasystray). Started per user session by systemd.
4. **Current packages and firmware** at build time: trixie + updates + security, firmware from
   trixie-backports (Tails parity or better), and the newest Tor Browser, Firefox, Node.js,
   The Lounge, Feather, LibreWolf, i2pd and Tor, each checked against its publisher's signature and a
   pinned SHA-256.
5. **Tor Connection Assistant** (menu: Network → Tor Connection Assistant), described below.

### Tor Connection Assistant

Tor still connects directly at boot, as before. The assistant is a small GTK window that:

- shows Tor's bootstrap progress, read through Prestium's control-port filter (onion-grater) with a
  new read-only "tor-assistant" profile (no SETCONF, no signals);
- has a **Reconnect** button (restarts Tor);
- switches between **Direct**, **Snowflake**, **WebTunnel** and **obfs4** (built-in bridges from
  Tor Browser 16.0 and/or pasted bridge lines).

Applying a mode runs a small root helper (`/usr/local/sbin/prestium-tor-mode`, allowed through sudo
for `user` only, input validated against strict patterns) that writes Tor's drop-in
`/etc/tor/torrc.d/50-prestium-assistant.conf` and restarts Tor.

**DNS design.** Prestium has no system DNS on purpose, which is why Snowflake and WebTunnel did not
work in 1.9.x: they need to look up host names (Snowflake's front domains and STUN servers, meek's
front, the WebTunnel bridge's host). In 2.0:

- **Tor traffic is not routed through I2P.** Tor and its pluggable transports connect directly.
- Only those **host-name look-ups** go through I2P: the helper asks two DNS-over-HTTPS providers
  (Cloudflare, Quad9, Google as fallback) over HTTPS through i2pd's HTTP proxy (127.0.0.1:4444),
  which forwards them to the I2P outproxy
  (`proxy4uwdijqxac2bvdx4fuhem6njmiwukuk2gelejv2nzxka2xq.b32.i2p`). Only public IPv4 answers are
  used; when both providers answer, the common addresses are preferred.
- The answers are pinned in a marked block of `/etc/hosts`, which the transports (run by Tor as
  `debian-tor`) read; nothing else on the system resolves names. So a network that blocks or
  poisons DNS for Tor infrastructure cannot stop Snowflake or WebTunnel from finding their servers.
- The look-ups run as a dedicated user, `prestium-ptdns`, which the firewall lets reach
  127.0.0.1:4444 and nothing else.
- **Firewall stays strict**: Tor's uid may use TCP as before; **UDP is allowed for Tor's uid only
  while Snowflake mode is on** (WebRTC/STUN), never to loopback, via `/etc/ferm/prestium-tor-pt.conf`
  which the helper rewrites and ferm includes.
- Optional, experimental: **"Snowflake rendezvous via the I2P outproxy"** (shown only if the
  installed `snowflake-client` has `-proxy`): Snowflake's broker request goes through i2pd's SOCKS
  proxy (4447) and the I2P outproxy; the WebRTC data still goes directly to the Snowflake proxy.

## What is in this branch

- `auto/`, `config/`, `build.sh`, `scripts/`, `thirdparty/`: the live-build configuration
  (see [BUILDING.md](BUILDING.md)).
- `rootfs/`, `iso/`, `build-1.9.1.3/`: the 1.9.1.3 root filesystem, ISO tree and build scripts, kept
  as the reference the live-build config was derived from until 2.0 is built and tested. They will
  be removed from this branch once the live-build image fully replaces them.
- `LARGE_FILES.md`: files over GitHub's 100 MB limit left out of `rootfs/` (1.9.1.3).
- The `Prestium-1.7`, `1.8` and `1.9.1.3` torrents, unchanged.

The `main` branch holds the original Prestium 1.2.1; `prestium-1.6-update` holds the 1.6-1.9.1.3 releases.
