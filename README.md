Disclaimer: This project and all associated materials (including software, repositories, scripts, and ISO files) are provided strictly "as is" and "as available," for informational, educational, and experimental purposes only, without any express or implied warranties of any kind—including, but not limited to, fitness for a particular purpose, security, accuracy, or non-infringement. The creator and publisher make no claims regarding the safety, integrity, or audit status of any code or binaries, explicitly disclaim any expertise or maintenance obligations, and shall not be held liable for any direct, indirect, incidental, or consequential damages, security breaches, data loss, or legal issues arising from downloading, compiling, or using this material. You assume all responsibility and risk for your use of this software, and you are solely responsible for ensuring compliance with all applicable local, state, and international laws.

## Known issues

- **No in-system browser updater:** LibreWolf and Firefox stay at the versions in the image. Tor
  Browser is the current signed stable release at build time, but a running system does not update
  it later.
- **Claws Mail PGP:** PGP does not work in Claws Mail at the moment and shows errors.

## Branch `prestium-2.0`: Prestium 2.1

Prestium 2.1 is the current release on this branch. It is based on Prestium 2.0: a from-scratch
rebuild with Debian's **live-build**, Debian 13 "trixie" (amd64), and Tails-aligned hardware
support: same Debian release, kernel line and firmware set, Secure Boot through shim/GRUB.

Build the 2.1 ISO with `sudo ./build.sh` (output: `Prestium-2.1-amd64.iso`). The previous 2.0 ISO
remains available through `Prestium-2.0-amd64.iso.torrent` on this branch. The earlier release,
**1.9.1.3**, stays on branch `prestium-1.6-update` (`Prestium-1.9.1.3-amd64.iso`, SHA-256
`0ef5cd8bc1129b75a932eb76d1ef0f0031cc4160faab625beba480ae17a1913f`).

- How to build: [BUILDING.md](BUILDING.md) (`sudo ./build.sh`)
- What changed in 2.1, and earlier in 2.0: [CHANGELOG.md](CHANGELOG.md)

### What changes in 2.1

See [CHANGELOG.md](CHANGELOG.md) for the combined list of changes since 2.0, and for the earlier
2.0 changes since 1.9.1.3.
