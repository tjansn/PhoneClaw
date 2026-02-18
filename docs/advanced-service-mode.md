# Advanced: Service mode (termux-services / runit)

By default, OpenClaw is run in a **tmux** session. If you prefer a managed background service that survives terminal close (but not necessarily device reboot), you can use **termux-services** (runit).

## Prerequisites

- Completed normal setup and onboarding (`setup_claw.sh`, then `openclaw onboard`).
- When asked during `openclaw onboard` to install a daemon/system service, choose **No**; the Android-compatible service is provided by these scripts.

## How the service is set up

The setup script creates a runit service under `$PREFIX/var/service/openclaw`:

- **run:** Starts `openclaw gateway` with `TMPDIR` and `PATH` set for Termux.
- **log/run:** Uses `svlogd` to write logs under `$PREFIX/var/log/openclaw`.

It also adds `SVDIR="$PREFIX/var/service"` to your shell profile so `sv` commands work.

## Using the service

After setup and onboarding:

```bash
source ~/.bashrc   # or open a new shell
sv up openclaw
termux-wake-lock   # keep process from being killed when app is in background
```

- **Check status:** `sv status openclaw`
- **Stop:** `sv down openclaw`
- **Start:** `sv up openclaw`
- **Logs:** `tail -f $PREFIX/var/log/openclaw/current`

## Reboot

The service does **not** start automatically after a device reboot unless you use something like Termux:Boot and configure it yourself. That is intentional; see [design-decisions.md](design-decisions.md).

## Switching back to tmux

Stop the service and use the start script in tmux mode:

```bash
sv down openclaw
./scripts/start_claw.sh
```

(Use `./scripts/stop_claw.sh` first if you want the script to stop the service for you.)
