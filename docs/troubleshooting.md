# Troubleshooting

## Install takes a long time or fails

- **Native compile (llama.cpp):** OpenClaw ships with native code that Termux must compile (no glibc). First install can take **15–30 minutes**. Let it run; do not interrupt.
- **Missing dependencies:** If `npm install -g openclaw@latest` fails, install the reported system packages with `pkg install -y <package>`, then run the install again. Use the setup script when possible; it installs the expected set.

## "/tmp/openclaw" or permission denied

OpenClaw expects to use `/tmp/openclaw`, but on Termux that path is not writable. The setup script:

- Sets `TMPDIR`, `TMP`, and `TEMP` to `$PREFIX/tmp`
- Creates `$PREFIX/tmp/openclaw`
- Patches the installed OpenClaw code to use `$PREFIX/tmp/openclaw` instead of `/tmp/openclaw`

If you see errors about `/tmp/openclaw` after a **manual** install or after an **update**, run the patch step again (or run `./update_claw.sh`, which re-applies patches). Ensure your shell has:

```bash
export TMPDIR="$PREFIX/tmp"
export TMP="$TMPDIR"
export TEMP="$TMPDIR"
```

Then:

```bash
mkdir -p "$PREFIX/tmp/openclaw"
source ~/.bashrc   # or your profile
```

## No systemd / daemon errors

OpenClaw may mention systemd or a system daemon. On Android there is no systemd. That is expected. Use either:

- **Default:** Run the gateway in a tmux session (`./scripts/start_claw.sh` or follow the README).
- **Advanced:** Use the termux-services (runit) setup; see [advanced-service-mode.md](advanced-service-mode.md). When asked during `openclaw onboard` to install a daemon/service, choose **No**; the Android-compatible service is set up by our scripts.

## Gateway stops when Termux is minimized

Use `termux-wake-lock` before or after starting the gateway so the process is not killed by Android. Consider disabling battery optimization for Termux for long-running use.

## Logs and config

- Log path (if configured): under `$PREFIX/tmp/openclaw/` (e.g. `openclaw-YYYY-MM-DD.log`). Ensure that directory exists and is writable.
- Run the doctor script to check environment and patch status: `./scripts/doctor_claw.sh`.
