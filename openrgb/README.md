# openrgb-resume

Reapplies an OpenRGB profile after the PC wakes from sleep.

## Problem

After resuming from suspend, the RGB lighting lost its profile. OpenRGB's own "load profile on resume" option (`resume_profile`) didn't help.

## Cause

On wake, the motherboard's USB controllers (AMD Promontory 21 chipset, X870E AORUS) reinitialize:

```
xhci-pci-prom21 0000:13:00.0: xHC error in resume, USBSTS 0x401, Reinit
```

That resets the USB RGB devices (a GIGABYTE RGB controller, `048d:5711`, and a Keychron keyboard, `3434:0c50`) at the same moment OpenRGB applies its resume profile. The profile goes to devices that are about to disappear, so it's lost. The running OpenRGB GUI is left holding stale device handles.

A fixed delay isn't enough either. Restarting the GUI after 5 seconds sometimes ran its device detection before the USB devices came back, so it found only the GPU.

## Fix

`openrgb-resume.service` is a system unit that runs after any sleep target:

1. **Waits for the USB RGB devices.** It polls `lsusb` for both device IDs, for up to 30 seconds, then waits 3 more seconds for them to settle. The journal shows how long that took (`USB RGB devices present after Ns`).
2. **Reapplies the profile:**
   - **If the OpenRGB GUI is running** (KDE runs autostart entries as the user unit `app-OpenRGB@autostart.service`), it restarts the GUI. The new instance does a full device detection and applies its "load profile on open" profile (`open_profile`), so the GUI never ends up with stale handles.
   - **Otherwise** it runs a separate OpenRGB instance that loads the profile directly:

     ```
     openrgb --noautoconnect -p <profile>
     ```

     `--noautoconnect` makes it talk to the hardware itself instead of looking for an SDK server.

The GUI path needs `open_profile` enabled in OpenRGB's settings (Settings → General → "Load profile on open").

## Install

Edit these in `openrgb-resume.service`:

- `User=` and the UID in `XDG_RUNTIME_DIR=`
- the USB IDs in `ExecStartPre` (find yours with `lsusb`)
- the profile name (`-p`)

Then:

```sh
sudo cp openrgb-resume.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable openrgb-resume.service
```

Check that it ran after a resume with `journalctl -b -u openrgb-resume`. It logs `Restarting OpenRGB GUI` (GUI path) or `Profile loaded successfully` (CLI path). To confirm every device came back, look for the `Registering RGB controller` lines in the newest log under `~/.config/OpenRGB/logs/`.

## Profile

The profile used here, `White`, sets every device to static white (`#FFFFFF`): the motherboard in Static mode, the Keychron in Solid Color mode and the GPU in Direct mode. It is set for every profile slot in OpenRGB's settings. The profile file isn't included because OpenRGB matches profiles to devices by name, serial and location, so you'd need to save your own.

## Notes

- If a device is still missing after wake, increase the settle `sleep` in `ExecStartPre`.
- Tested on CachyOS, KDE Plasma 6 (Wayland), with OpenRGB 1.1.

## Changelog

- **v1.1** (2026-10-30): waits for the USB RGB devices to re-enumerate instead of a fixed 5-second delay, then restarts the GUI. Uses an all-white profile.
- **v1.0** (2026-10-30): reapplies the profile 5 seconds after resume with a one-off CLI instance.
