#!/bin/sh
# Install power-rgb (run with sudo). Undo: sudo ./install.sh --uninstall
set -eu
cd "$(dirname "$0")"
if [ "${1:-}" = --uninstall ]; then
    systemctl disable power-rgb.service power-rgb-sleep.service || true
    rm -f /etc/systemd/system/power-rgb.service /etc/systemd/system/power-rgb-sleep.service /usr/local/bin/power-rgb
    rm -rf /var/lib/power-rgb
    systemctl daemon-reload
    echo "power-rgb removed"; exit 0
fi
install -m 755 power-rgb /usr/local/bin/power-rgb
install -m 644 power-rgb.service /etc/systemd/system/power-rgb.service
install -m 644 power-rgb-sleep.service /etc/systemd/system/power-rgb-sleep.service
# Zone sizes (the case ARGB headers) live in the desktop OpenRGB's
# Configuration.json; without it the CLI sees those headers as 0 LEDs.
user_home=$(getent passwd "${SUDO_USER:?run with sudo from your desktop user}" | cut -d: -f6)
install -d -m 755 /var/lib/power-rgb
install -m 644 "$user_home/.config/OpenRGB/Configuration.json" /var/lib/power-rgb/Configuration.json
systemctl daemon-reload
systemctl enable power-rgb.service power-rgb-sleep.service
# Start it now so the next shutdown runs ExecStop (it flashes green), then back to white
systemctl start power-rgb.service
/usr/local/bin/power-rgb on
systemctl status --no-pager power-rgb.service | head -5
echo "Installed. Next boot: green breathing until login; shutdown: red; reboot: amber; sleep: dim blue breathing."
