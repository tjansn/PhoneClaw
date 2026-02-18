#!/data/data/com.termux/files/usr/bin/bash

# Stop OpenClaw gateway (tmux or service). Idempotent.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMUX_SESSION="${OPENCLAW_TMUX_SESSION:-openclaw}"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

stopped=0

# Stop service if running
export SVDIR="${SVDIR:-$PREFIX/var/service}"
if command -v sv >/dev/null 2>&1 && [ -d "$SVDIR/openclaw" ]; then
  if sv status openclaw 2>/dev/null | grep -q "run:"; then
    sv down openclaw
    echo -e "${GREEN}Stopped OpenClaw (service).${NC}"
    stopped=1
  fi
fi

# Kill tmux session if present
if command -v tmux >/dev/null 2>&1 && tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
  echo -e "${GREEN}Stopped OpenClaw (tmux session $TMUX_SESSION).${NC}"
  stopped=1
fi

if [ "$stopped" -eq 0 ]; then
  echo -e "${YELLOW}OpenClaw was not running (no active tmux session or service).${NC}"
fi
