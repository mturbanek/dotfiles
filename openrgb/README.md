# openrgb-resume

Reapplies an OpenRGB profile after the PC wakes from sleep.

## Problem

After resuming from suspend, the RGB lighting lost its profile. OpenRGB's own "load profile on resume" option (`resume_profile`) didn't help.

## Cause

On wake, the motherboard's USB controllers (AMD Promontory 21 chipset, X870E AORUS) reinitialize:

```
xhci-pci-prom21 0000:13:00.0: xHC error in resume, USBSTS 0x401, Reinit
```

That resets the USB RGB devices (a GIGABYTE RGB controller, `048d:5711`, and a Keychron keyboard) at the same moment OpenRGB applies its resume profile. The profile goes to devices that are about to disappear, so it's lost. The running OpenRGB GUI is left holding stale device handles.

## Fix

`openrgb-resume.service` is a system unit that runs after any sleep target. It waits 5 seconds for USB to settle, then runs a separate OpenRGB instance that loads the profile directly:

```
openrgb --noautoconnect -p <profile>
```

`--noautoconnect` makes it talk to the hardware itself instead of handing the job to the running GUI's SDK server.

## Install

Edit `User=` and the profile name (`-p`) in `openrgb-resume.service`, then:

```sh
sudo cp openrgb-resume.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable openrgb-resume.service
```

Check that it ran after a resume with `journalctl -b -u openrgb-resume`. It should log `Profile loaded successfully`.

## Notes

- The GUI's device handles are still stale after wake. Click **Rescan Devices** before making live edits in the GUI.
- If the profile still gets lost, increase the `sleep` delay.
- Tested on CachyOS, KDE Plasma 6 (Wayland), with OpenRGB 1.1.
