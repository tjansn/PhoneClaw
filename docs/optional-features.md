# Optional features

These are not required for the default OpenClaw Android setup.

## LAN access to the Dashboard

By default the gateway binds to localhost. To access the UI from another device on the same Wi‑Fi (e.g. `http://<phone-ip>:18789`), set in your OpenClaw config:

- `gateway.bind` to `lan` (so the gateway listens on `0.0.0.0`).

Config is typically under your home directory or where `openclaw onboard` wrote it (e.g. `openclaw.json`).

## Termux:GUI and screen overlay

For hardware integration and overlay capabilities:

- Install **Termux:GUI** from F-Droid and `pkg install -y termux-gui` in Termux.
- Grant the requested permissions.

Screen overlay (drawing on top of the screen) usually requires a separate helper script or daemon. This repo does not include an `overlay_daemon.py`; if you use one, run it in a separate tmux window and tell OpenClaw how to use it per that script’s documentation.

## Reboot persistence (Termux:Boot)

OpenClaw does not start automatically after a device reboot. To have the gateway (or sshd, etc.) start on boot, use **Termux:Boot** and configure it yourself. This is outside the scope of the default setup; see Termux and Termux:Boot documentation.
