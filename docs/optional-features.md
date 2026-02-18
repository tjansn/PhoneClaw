# Optional features

These are not required for the default OpenClaw Android setup.

## Access the Dashboard from your computer (safer default)

Keep the gateway on localhost and forward the Dashboard port over SSH instead of exposing it on the LAN.

From your computer:

```bash
ssh -L 18789:127.0.0.1:18789 -p 8022 <termux_user>@<phone_ip>
```

Then open `http://localhost:18789` in your computer browser.

## Termux:GUI and screen overlay

For hardware integration and overlay capabilities:

- Install **Termux:GUI** from F-Droid and `pkg install -y termux-gui` in Termux.
- Grant the requested permissions.

Screen overlay (drawing on top of the screen) usually requires a separate helper script or daemon. This repo does not include an `overlay_daemon.py`; if you use one, run it in a separate tmux window and tell OpenClaw how to use it per that script’s documentation.

## Reboot persistence (Termux:Boot)

OpenClaw does not start automatically after a device reboot. To have the gateway (or sshd, etc.) start on boot, use **Termux:Boot** and configure it yourself. This is outside the scope of the default setup; see Termux and Termux:Boot documentation.
