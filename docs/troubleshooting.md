# Troubleshooting

## 1) Serial device not visible in Betaflight/iNav

- Check cable quality (data-capable USB cable).
- Check detected devices:
  ```bash
  ls /dev/ttyACM* /dev/ttyUSB*
  ```
- Confirm user groups:
  ```bash
  id
  ```
  Ensure `dialout` and `plugdev` are present.
- Re-run installer to reapply rules/groups:
  ```bash
  sudo ./scripts/install.sh
  sudo reboot
  ```

## 2) `dfu-util` cannot find target

- Verify bootloader/DFU mode on FC.
- Validate tool installed:
  ```bash
  dfu-util --version
  ```
- List USB bus:
  ```bash
  lsusb
  ```
- Replug device and rerun.

## 3) Service did not auto-start launcher

- Check service state:
  ```bash
  systemctl status field-configurator@pi.service
  ```
- Check logs:
  ```bash
  journalctl -u field-configurator@pi.service -b
  ```
- Verify repo path exists (`/home/pi/configapp` by default target user).

## 4) Chromium opens but no local app

- Ensure app files were unpacked correctly and include `index.html`:
  - `tools/betaflight/webapp/index.html`
  - `tools/inav/webapp/index.html`
  - `tools/am32/webapp/index.html` (if using web mode)
- Run self-test and inspect warnings:
  ```bash
  ./scripts/self_test.sh
  ```

## 5) tty device changes between boots

`/dev/ttyACM0` vs `/dev/ttyUSB0` can vary by hardware and attach order.
Use configurator UI port selector each session, and avoid hard-coded single-port assumptions.
