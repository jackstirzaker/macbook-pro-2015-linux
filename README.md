# MacBook Pro 2015 Linux Optimization

Fixes and optimizations for running Linux (Fedora) on a 2015 MacBook Pro 15" with AMD Radeon R9 M370X.

## Hardware

- **Model**: MacBook Pro 11,5 (Mid-2015 15")
- **CPU**: Intel Core i7 (Crystal Well)
- **GPU**: Intel Iris Pro + AMD Radeon R9 M370X
- **WiFi**: Broadcom BCM43602

## What This Fixes

| Issue | Solution |
|-------|----------|
| Poor battery life | TLP power management |
| Loud fans | mbpfan (built from source) |
| Keyboard backlight off | systemd service to enable on boot |
| F1-F12 keys act as media keys | hid_apple fnmode=2 |
| Chrome UI glitches | XWayland workaround for Mesa regression |
| Temperature monitoring | lm_sensors |

## Quick Install

```bash
sudo bash optimize.sh
sudo reboot
```

## Known Issues

### Chrome/Chromium UI Glitches (Mesa 24.3.0+ Regression)

There's a known regression in Mesa 24.3.0+ that causes Chrome to glitch on older AMD GPUs (GCN era) when running on native Wayland.

**Fix**: Force Chrome to use XWayland:
```bash
echo '--ozone-platform=x11' >> ~/.config/chrome-flags.conf
```

Or launch manually:
```bash
google-chrome --ozone-platform=x11
```

### FaceTime HD Camera

The FaceTime HD camera requires the `bcwc_pcie` driver which must be compiled from source and requires matching `kernel-devel` packages. Not included in this script.

See: https://github.com/patjak/bcwc_pcie

## Manual Fixes

### Keyboard Backlight (Immediate)

```bash
# Turn on (0-255)
echo 128 | sudo tee /sys/class/leds/smc::kbd_backlight/brightness

# Turn off
echo 0 | sudo tee /sys/class/leds/smc::kbd_backlight/brightness
```

### Check GPU in Use

```bash
glxinfo | grep "OpenGL renderer"
```

## Tested On

- Fedora 43 (Kernel 6.17.x - 6.18.x)
- Mesa 25.x

## References

- [Linux Mint Forums - Screen Glitches Fix](https://forums.linuxmint.com/viewtopic.php?t=452438)
- [Mesa Chrome Regression Bug](https://bugzilla.redhat.com/show_bug.cgi?id=2193335)
- [mbpfan](https://github.com/linux-on-mac/mbpfan)
- [Arch Wiki - MacBookPro11,x](https://wiki.archlinux.org/title/MacBookPro11,x)

## License

MIT
