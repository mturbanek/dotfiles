# fastfetch

Sectioned fastfetch layout (System / Desktop / Hardware / Status) with a CachyOS kitty-graphics logo.

## Install

```
ln -s ~/dotfiles/fastfetch ~/.config/fastfetch
```

Needs a Nerd Font (MesloLGS Nerd Font here) and a terminal with the kitty graphics protocol for the logo. The `Data` and `NAS` rows read `/mnt/data` and `/mnt/nas`; change or remove them to match your mounts.

## Notes

- **NAS listed twice:** with an `x-systemd.automount` NFS mount, `/mnt/nas` has two stacked mounts, the `autofs` trigger and the real `nfs4` share. Both match `"folders": "/mnt/nas"`. `"hideFS": "autofs"` keeps only the real one. After the automount idle timeout the share is unmounted and the row is hidden until something accesses `/mnt/nas`.

## Changelog

- **v1.1** (2026-10-30): show the NAS once (`hideFS: autofs`). Clearer icons: microchip for CPU, RAM stick for Memory (both were near-identical chips), desktop tower for Host and the Hardware header (was a laptop), NAS box for NAS.
- **v1.0** (2026-10-29): initial layout and logo.
