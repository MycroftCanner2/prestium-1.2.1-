Disclaimer: This project and all associated materials (including software, repositories, scripts, and ISO files) are provided strictly "as is" and "as available," for informational, educational, and experimental purposes only, without any express or implied warranties of any kind—including, but not limited to, fitness for a particular purpose, security, accuracy, or non-infringement. The creator and publisher make no claims regarding the safety, integrity, or audit status of any code or binaries, explicitly disclaim any expertise or maintenance obligations, and shall not be held liable for any direct, indirect, incidental, or consequential damages, security breaches, data loss, or legal issues arising from downloading, compiling, or using this material. You assume all responsibility and risk for your use of this software, and you are solely responsible for ensuring compliance with all applicable local, state, and international laws.

> **This branch is superseded. Use Prestium 2.0.**
> Prestium 2.0 is the fully modernized Wayland version, built with live-build on Debian 13: see the [`prestium-2.0` branch](https://github.com/MycroftCanner2/prestium-1.2.1-/tree/prestium-2.0) and its `Prestium-2.0-amd64.iso.torrent`.
> Ongoing development, including the coming 2.1, continues in the new repository **[PrestiumOS](https://github.com/MycroftCanner2/PrestiumOS)**.
>
> This branch is the old version, slightly modernized and still running X11. It receives no further updates.

## Branch `prestium-1.6-update`: Prestium 1.9.1.3 (Debian 13)

This branch rebuilds Prestium **1.6** and carries the updates made on top of it. The current release is **Prestium 1.9.1.3**,
based on Debian 13 "trixie" (kernel 6.12.113, Secure Boot, Tails firmware set and Tails-style hardening).

- ISO: `Prestium-1.9.1.3-amd64.iso`, 2,592,849,920 bytes
- SHA-256: `0ef5cd8bc1129b75a932eb76d1ef0f0031cc4160faab625beba480ae17a1913f`
- Torrent: `Prestium-1.9.1.3-amd64.iso.torrent` (uploaded by the maintainer), info hash `af992b4b9912282a875821f2e072c103b1ed1359`

The ISO itself is not stored in git; use the torrent and check the SHA-256 above.

**What changed since 1.8:** see [CHANGELOG.md](CHANGELOG.md).

## What is in this branch

- `rootfs/`: the unpacked 1.9.1.3 root filesystem (the contents of the ISO's `live/filesystem.squashfs`).
- `iso/`: the 1.9.1.3 ISO tree (boot loaders, menus, kernel). The ISO has a single `live/filesystem.squashfs`, which is not committed; `rootfs/` holds its contents.
- `build-1.9.1.3/`: the scripts used to build 1.9.1.3 (stage scripts, squashfs, boot tree and ISO). See [build-1.9.1.3/README.md](build-1.9.1.3/README.md).
- `LARGE_FILES.md`: files over GitHub's 100 MB limit that are left out of git, with sizes and SHA-256.
- The older `Prestium-1.7-amd64.iso.torrent` and `Prestium-1.8-amd64.iso.torrent` are still here, unchanged.

The `main` branch holds the original Prestium 1.2.1.
