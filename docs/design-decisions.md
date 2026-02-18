# OpenClaw Android v2 — Design Decisions

This document locks the v2 defaults for the project. Scripts and documentation must align with these decisions.

## Runtime mode

- **Default (recommended):** Run OpenClaw in a **tmux** session. Easiest to understand, survives detach, no runit dependency for first-time users.
- **Advanced (opt-in):** Run via **termux-services** (runit). Documented in [advanced-service-mode.md](advanced-service-mode.md). Setup may install service definitions but must not start the service until the user has completed onboarding and explicitly chooses service mode.

## Reboot persistence

- **Not enabled by default.** Reboot persistence (e.g. Termux:Boot) is optional and must be documented separately. No script shall silently enable start-on-boot without user action.

## Environment

- **Termux-only** for the quick-start path. No proot or Debian chroot assumptions in the canonical flow.
- **Required apps:** Termux (from F-Droid only) and Termux:API.
- **Optional:** Termux:GUI for overlay and extra hardware features; documented as optional.

## Installation vs runtime

- **Setup script:** Installs dependencies, OpenClaw, patches, and (optionally) service definitions. It does not start the gateway before the user runs `openclaw onboard`.
- **Runtime control:** Dedicated scripts (`start_claw.sh`, `stop_claw.sh`, `status_claw.sh`) handle starting/stopping; default start uses tmux unless user chooses service mode.
