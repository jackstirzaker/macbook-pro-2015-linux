#!/bin/bash
# MacBook Pro 2015 Fedora Optimization Script
# Run with: sudo bash macbook-optimize.sh

set -e

echo "=========================================="
echo "MacBook Pro 2015 - Fedora Optimization"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo bash $0"
    exit 1
fi

echo ""
echo "[1/7] Installing power management (TLP)..."
# TLP conflicts with tuned, so remove it first
dnf remove -y tuned tuned-ppd 2>/dev/null || true
dnf install -y tlp tlp-rdw powertop
systemctl enable --now tlp
systemctl mask power-profiles-daemon 2>/dev/null || true
echo "    ✓ TLP installed and enabled"

echo ""
echo "[2/7] Installing temperature sensors..."
dnf install -y lm_sensors
echo "    ✓ lm_sensors installed"

echo ""
echo "[3/7] Installing build dependencies..."
dnf install -y git make gcc coreutils

echo ""
echo "[4/7] Building and installing fan control (mbpfan from source)..."
BUILD_DIR="/tmp/macbook-build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if git clone https://github.com/linux-on-mac/mbpfan.git; then
    cd mbpfan
    make
    make install

    # Tune fan curve: wider ramp zone so fans don't jump at ~66°C
    sed -i \
        -e 's/^low_temp = .*/low_temp = 63/' \
        -e 's/^high_temp = .*/high_temp = 75/' \
        -e 's/^max_temp = .*/max_temp = 90/' \
        -e 's/^polling_interval = .*/polling_interval = 2/' \
        /etc/mbpfan.conf

    # Create systemd service file
    cat > /etc/systemd/system/mbpfan.service << 'SERVICEEOF'
[Unit]
Description=A fan manager daemon for MacBook Pro
After=syslog.target

[Service]
Type=simple
ExecStart=/usr/sbin/mbpfan -f
Restart=always

[Install]
WantedBy=multi-user.target
SERVICEEOF

    systemctl daemon-reload
    systemctl enable mbpfan
    systemctl restart mbpfan
    echo "    ✓ mbpfan built and installed"
else
    echo "    ⚠ Could not clone mbpfan repo"
fi

echo ""
echo "[5/7] Configuring function keys (F1-F12 as default)..."
echo "options hid_apple fnmode=2" > /etc/modprobe.d/hid_apple.conf
echo "    ✓ Function keys configured (reboot required)"

echo ""
echo "[6/7] Setting up keyboard backlight persistence..."
cat > /etc/systemd/system/keyboard-backlight.service << 'EOF'
[Unit]
Description=Set keyboard backlight on boot

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 128 > /sys/class/leds/smc::kbd_backlight/brightness'

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable keyboard-backlight.service
# Turn on now
echo 128 > /sys/class/leds/smc::kbd_backlight/brightness
echo "    ✓ Keyboard backlight configured and enabled"

echo ""
echo "[7/7] Fixing Chrome for AMD GPU (XWayland workaround)..."
# Get the actual user (not root)
ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
mkdir -p "$ACTUAL_HOME/.config"
echo '--ozone-platform=x11' >> "$ACTUAL_HOME/.config/chrome-flags.conf"
chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/.config/chrome-flags.conf"
echo "    ✓ Chrome configured to use XWayland (fixes Mesa regression)"

# Clean up
rm -rf "$BUILD_DIR"

echo ""
echo "=========================================="
echo "Optimization Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ TLP power management enabled"
echo "  ✓ lm_sensors installed"
echo "  ✓ mbpfan cooling optimized"
echo "  ✓ Function keys set to F1-F12 mode"
echo "  ✓ Keyboard backlight enabled"
echo "  ✓ Chrome XWayland fix applied"
echo ""
echo "Reboot to apply all changes:"
echo "  sudo reboot"
echo ""
