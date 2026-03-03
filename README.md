# Raspberry Pi Field Configurator (Offline)

Offline launcher appliance for Betaflight, iNav, and AM32 on Raspberry Pi OS.

## What this repo provides

- Fullscreen Python launcher (`launcher/main.py`) with large touch-friendly buttons.
- Mouse wheel / keyboard navigation support.
- Offline firmware cache + index generator.
- One-shot installer for fresh Pi OS (`scripts/install.sh`).
- Kiosk startup using systemd + Xorg + Chromium.

## Install on Raspberry Pi OS

```bash
git clone <your-repo-url> ~/configapp
cd ~/configapp
sudo ./scripts/install.sh
sudo reboot
```

Installer tasks:
- Installs dependencies (Chromium, Tk, Xorg, dfu-util, etc.).
- Copies repo to `~/configapp` for target user.
- Creates and enables `field-configurator@<user>.service`.
- Adds udev rules and group memberships for USB serial/DFU access.
- Builds initial firmware index and runs first-run checks.

## Update workflow

```bash
cd ~/configapp
git pull
sudo ./scripts/install.sh
```

The installer is designed to be idempotent and safe to rerun.

## Tool packaging (offline)

This project does not bundle upstream configurators by default.

### Betaflight

1. Download official Betaflight Configurator offline/static release.
2. Extract contents into `tools/betaflight/webapp/` so `index.html` exists.
3. Launch from the main launcher.

### iNav

1. Download official iNav Configurator offline/static release.
2. Extract contents into `tools/inav/webapp/` so `index.html` exists.
3. Launch from the main launcher.

### AM32

Use one of:
- Drop executable at `tools/am32/am32-tool` and `chmod +x` it.
- Or place static web app into `tools/am32/webapp/`.

## Firmware cache

Directory layout:

```text
firmware-cache/
  betaflight/<target>/<version>/*.hex
  inav/<target>/<version>/*.hex
```

Generate/update index:

```bash
python3 tools/firmware_indexer.py
```

This writes `firmware-cache/firmware_index.json` with target/version/path/sha256 metadata.

The launcher includes **Offline Firmware Manager** to inspect cache and import files from mounted USB media.

## Verification

Run:

```bash
./scripts/self_test.sh
```

Checks include compile validation, service unit sanity, tool artifact presence, dfu-util, and tty permission display.

## Known limitations

- WebSerial/WebUSB browser prompts may still appear depending on Chromium policy.
- Upstream tool releases must be manually downloaded once and copied to local storage.
- Device naming can vary (`ttyACM*` vs `ttyUSB*`) by USB adapter/driver.

See `docs/troubleshooting.md` for common fixes.
