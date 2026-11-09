Disclaimer: This project and all associated materials (including software, repositories, scripts, and ISO files) are provided strictly "as is" and "as available," for informational, educational, and experimental purposes only, without any express or implied warranties of any kind—including, but not limited to, fitness for a particular purpose, security, accuracy, or non-infringement. The creator and publisher make no claims regarding the safety, integrity, or audit status of any code or binaries, explicitly disclaim any expertise or maintenance obligations, and shall not be held liable for any direct, indirect, incidental, or consequential damages, security breaches, data loss, or legal issues arising from downloading, compiling, or using this material. You assume all responsibility and risk for your use of this software, and you are solely responsible for ensuring compliance with all applicable local, state, and international laws.

## Known issues

- **No browser updater:** Tor Browser, LibreWolf and Firefox are fixed at the versions in this build, so they will become out of date over time.
- **Claws Mail PGP:** PGP does not work in Claws Mail at the moment and shows errors.
- **No more security audits or updates:** this branch is final and no longer receives security audits or updates. Use [PrestiumOS](https://github.com/MycroftCanner2/PrestiumOS) for ongoing development.

## Branch `prestium-2.0`: Prestium 2.0 (complete, final version)

Prestium 2.0 rebuilds Prestium from scratch with Debian's **live-build** instead of patching an
unpacked root filesystem. It is based on Debian 13 "trixie" (amd64) and follows Tails for hardware
support: same Debian release, kernel line and firmware set, Secure Boot through shim/GRUB.

**Status: complete.** This branch is the final version of Prestium 2.0. Its objective, fully
modernizing the original 2023 Prestium build, has been met, and no further changes will be made here.

**Future development continues in the new repository, PrestiumOS:**
https://github.com/MycroftCanner2/PrestiumOS (its `main` branch starts from this 2.0 branch).
Please open issues and send changes there.

The 2.0 ISO is available through `Prestium-2.0-amd64.iso.torrent` on this branch. The previous release,
**1.9.1.3**, stays on branch `prestium-1.6-update` (`Prestium-1.9.1.3-amd64.iso`, SHA-256
`0ef5cd8bc1129b75a932eb76d1ef0f0031cc4160faab625beba480ae17a1913f`).

- How to build: [BUILDING.md](BUILDING.md) (`sudo ./build.sh`)
- What changes in 2.0: [CHANGELOG.md](CHANGELOG.md)

### What changes in 2.0

See [CHANGELOG.md](CHANGELOG.md) for the full, unified list of changes since 1.9.1.3.

### Tor Connection Assistant

Tor still connects directly at boot, as before. The assistant is a small GTK window that:

- shows Tor's bootstrap progress, read through Prestium's control-port filter (onion-grater) with a
  new read-only "tor-assistant" profile (no SETCONF, no signals);
- has a **Reconnect** button (restarts Tor);
- switches between **Direct**, **Snowflake**, **WebTunnel**, **obfs4** and **meek** (built-in
  bridges are Tor Browser 16.0's `pt_config.json`, verbatim, and/or pasted bridge lines; transports
  snowflake-client 2.15.1+tpo, lyrebird 0.9.0 and webtunnel 0.0.7 from deb.torproject.org);
- never touches Tor when opened. **Apply and connect** stops Tor, resolves, writes the configuration
  and starts Tor again (progress from 0 %); **Cancel** works at any point and leaves the previous
  configuration in place with Tor stopped (**Retry** / **Revert to previous**). Choices are saved in
  `~/.config/prestium/tor-assistant.json`.

Applying a mode runs a small root helper (`/usr/local/sbin/prestium-tor-mode`, allowed through sudo
for `user` only, input validated against strict patterns) that writes Tor's drop-in
`/etc/tor/torrc.d/50-prestium-assistant.conf` and restarts Tor.

**DNS design.** Prestium has no system DNS on purpose, which is why Snowflake and WebTunnel did not
work in 1.9.x: they need to look up host names (Snowflake's front domains and STUN servers, meek's
front, the WebTunnel bridge's host). In 2.0:

- **Tor traffic is not routed through I2P.** Tor and its pluggable transports connect directly.
- Only those **host-name look-ups** go through I2P: the helper asks several DNS-over-HTTPS providers
  **in parallel** (Cloudflare, Google, Quad9, AdGuard, Mullvad; port 443 only, keep-alive HTTPS
  connections) through i2pd's HTTP proxy (127.0.0.1:4444), which forwards them to the I2P outproxy
  (`proxy4uwdijqxac2bvdx4fuhem6njmiwukuk2gelejv2nzxka2xq.b32.i2p`). The first valid answer (public
  IPv4 only) wins, failing providers are dropped, and answers are cached.
- The answers are pinned in a marked block of `/etc/hosts`, which the transports (run by Tor as
  `debian-tor`) read; nothing else on the system resolves names. So a network that blocks or
  poisons DNS for Tor infrastructure cannot stop Snowflake or WebTunnel from finding their servers.
- The look-ups run as a dedicated user, `prestium-ptdns`, which the firewall lets reach
  127.0.0.1:4444 and nothing else.
- **Firewall stays strict**: Tor's uid may use TCP as before; **UDP is allowed for Tor's uid only
  while Snowflake mode is on** (WebRTC/STUN), never to loopback, via `/etc/ferm/prestium-tor-pt.conf`
  which the helper rewrites and ferm includes.
- **Snowflake under AppArmor:** Debian's `system_tor` profile blocked the transports from reading the
  system CA bundle, so Snowflake's TLS to its broker failed; `/etc/apparmor.d/local/system_tor`
  adds `abstractions/ssl_certs` and the network reads Snowflake's WebRTC stack needs.
- Optional, experimental: **"Snowflake rendezvous via the I2P outproxy"** (shown only if the
  installed `snowflake-client` has `-proxy`): Snowflake's broker request goes through i2pd's SOCKS
  proxy (4447) and the I2P outproxy; the WebRTC data still goes directly to the Snowflake proxy.

## What is in this branch

- `auto/`, `config/`, `build.sh`, `scripts/`, `thirdparty/`: the live-build configuration
  (see [BUILDING.md](BUILDING.md)).
- No release torrents: the `Prestium-1.7`, `1.8` and `1.9.1.3` `.torrent` files were removed from
  this branch (they remain in git history).

The `main` branch holds the original Prestium 1.2.1; `prestium-1.6-update` holds the 1.6-1.9.1.3 releases.
