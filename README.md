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
