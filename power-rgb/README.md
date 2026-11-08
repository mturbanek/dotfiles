# power-rgb

Makes the desktop's RGB lighting follow the power state, using OpenRGB.

| State | Lights |
|---|---|
| Starting up (early boot until the desktop loads) | green, breathing |
| On | solid white |
| Sleeping | dim blue, slow breathing |
| Shutting down | red, breathing |
| Rebooting | amber, breathing |

The motherboard and keyboard run the breathing in hardware, so it keeps going with no process alive, including during suspend if the board keeps USB powered. The GPU (RTX 4080 FE) only has a Direct mode, so it shows solid colors.

## How it works

- **`power-rgb <state>`** (`boot|on|sleep|poweroff|reboot|shutdown`) runs the OpenRGB CLI against the hardware directly (`--noautoconnect`), with its own config dir, `/var/lib/power-rgb`. `shutdown` picks `reboot` or `poweroff` by checking whether `reboot.target` is among systemd's queued jobs.
- **`power-rgb.service`** starts in early boot (`WantedBy=sysinit.target`, after the USB RGB devices exist) and sets green. Its `ExecStop` sets red or amber. It's ordered `Before=systemd-user-sessions.service`, so at shutdown it is stopped *after* the user sessions end. Otherwise the desktop OpenRGB GUI's exit profile (white) would be applied on top of the red.
- **White** comes from the desktop OpenRGB GUI, which loads a white profile when it starts at login (`open_profile`) and after resume (see [openrgb-resume](../openrgb)).
- **`power-rgb-sleep.service`** runs `power-rgb sleep` just before `sleep.target`. Disable OpenRGB's own `suspend_profile`, or it races this with its own profile.

## Gotchas

- **Zone sizes.** A fresh OpenRGB config dir sees the motherboard's addressable headers (the case fans) as 0 LEDs, so only the onboard LEDs and the keyboard change. The sizes you set in the GUI live in `~/.config/OpenRGB/Configuration.json`. `install.sh` copies it into `/var/lib/power-rgb`; re-run it if you change zone sizes.
- **Exit codes.** The OpenRGB CLI exits 0 even when a mode name or the config dir is wrong (it just prints `Error: ...`). `power-rgb` checks the output and exits 1 instead.
- The green starts after the initrd (after the LUKS passphrase prompt), not at power-on.
- Whether the board stays lit after poweroff depends on the BIOS (ErP).

## Install

Edit the device names at the top of `power-rgb` (`openrgb --noautoconnect -l` lists them) and the mode names if your devices differ (`-ld`). The USB IDs in `power-rgb.service`'s `ExecStartPre` should match your devices (`lsusb`). Then:

```sh
sudo ./install.sh            # install + enable, sets the lights to white
sudo ./install.sh --uninstall
```

Check after boot, sleep or shutdown with `journalctl -b -u power-rgb -u power-rgb-sleep` (use `-b -1` for the previous boot's shutdown).

Tested on CachyOS, KDE Plasma 6 (Wayland), OpenRGB 1.1, with a GIGABYTE X870E AORUS PRO, a Keychron V5 Ultra 8K and an RTX 4080 FE.

## Changelog

- **v1.0** (2026-11-08): boot, on, sleep, poweroff and reboot states.
