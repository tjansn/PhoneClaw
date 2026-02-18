# v2 validation checklist

Run these on a real device (Termux on Android) before tagging v2 release. Ensure docs and script behavior match.

## 1. Fresh install

- [ ] Install Termux and Termux:API from F-Droid.
- [ ] Set up remote access (SSH or Tailscale) per docs/remote-access.md; from computer, SSH into the phone.
- [ ] From the SSH session on the phone, clone the repo and run setup: `pkg install -y git && git clone https://github.com/tjansn/PhoneClaw ~/phoneclaw-setup && cd ~/phoneclaw-setup && chmod +x setup_claw.sh update_claw.sh scripts/*.sh && ./setup_claw.sh`.
- [ ] Setup completes without error; post-install message shows "openclaw onboard" and "./scripts/start_claw.sh".
- [ ] Run `openclaw onboard`; when asked for daemon/service, choose No.
- [ ] Run `source ~/.bashrc` then `./scripts/start_claw.sh`.
- [ ] Run `termux-wake-lock`.
- [ ] Open http://localhost:18789 in browser; UI loads.
- [ ] Run `./scripts/status_claw.sh`; shows tmux mode.
- [ ] Run `./scripts/doctor_claw.sh`; no FAIL items.

## 2. Re-run setup (idempotent)

- [ ] From the same install, run `./setup_claw.sh` again.
- [ ] No duplicate TMPDIR/SVDIR lines in `~/.bashrc` (single "OPENCLAW-ANDROID-V2 ENV" block).
- [ ] Setup completes; OpenClaw still works (start_claw.sh, UI).

## 3. Update from tmux mode

- [ ] With gateway running in tmux, run `./update_claw.sh`.
- [ ] Script detects "tmux", stops session, updates npm, re-patches, restarts tmux session.
- [ ] UI still works; `./scripts/status_claw.sh` shows tmux.

## 4. Update from service mode

- [ ] Stop tmux: `./scripts/stop_claw.sh`. Start service: `./scripts/start_claw.sh --mode service`.
- [ ] Run `./update_claw.sh`.
- [ ] Script detects "service", stops service, updates, re-patches, restarts service.
- [ ] UI still works; `sv status openclaw` shows run.

## 5. Update when not running

- [ ] Stop gateway (stop_claw.sh or sv down).
- [ ] Run `./update_claw.sh`.
- [ ] Mode "none"; no restart; no error. Start again with start_claw.sh; works.

## 6. Recovery / doctor

- [ ] Run `./scripts/doctor_claw.sh` on a good install: all relevant checks PASS or WARN (no FAIL).
- [ ] If possible, simulate a broken state (e.g. remove TMPDIR from env, or corrupt one patched file) and run doctor; it should report FAIL with a clear remediation.

## 7. Docs alignment

- [ ] README quick start steps match script output and order.
- [ ] docs/advanced-service-mode.md matches behavior of start_claw.sh --mode service and sv commands.
- [ ] docs/troubleshooting.md mentions doctor and patch re-apply (update_claw.sh).
- [ ] No references to missing files (images, overlay_daemon.py) in README or linked docs.

When all items pass, v2 release is aligned.
