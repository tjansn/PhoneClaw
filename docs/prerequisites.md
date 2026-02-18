# Prerequisites

Before running the OpenClaw Android setup, ensure the following.

## Required apps (F-Droid)

Install from [F-Droid](https://f-droid.org/). Do **not** use the Google Play versions; they are outdated and incompatible.

1. **Termux** — [F-Droid: Termux](https://f-droid.org/en/packages/com.termux/)
2. **Termux:API** — [F-Droid: Termux:API](https://f-droid.org/en/packages/com.termux.api/)  
   Required for hardware features (notifications, battery status, clipboard). Without it, OpenClaw's mobile features are limited.

## Optional apps

- **Termux:GUI** — For overlay and extra hardware integration. See [optional features](optional-features.md).

## Android settings

- Grant Termux (and Termux:API) the permissions it requests.
- For long-running use: disable battery optimization for Termux so the app (and OpenClaw) is not killed in the background. After setup, run `termux-wake-lock` when running the gateway.

## Network and storage

- Reliable Wi‑Fi for the initial install (npm and package downloads).
- Enough free storage for Node.js, build tools, and OpenClaw (several hundred MB; native compile can use more temporarily).
