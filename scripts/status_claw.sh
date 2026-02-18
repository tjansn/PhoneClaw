#!/data/data/com.termux/files/usr/bin/bash

# Show OpenClaw runtime mode and status.

set -euo pipefail

TMUX_SESSION="${OPENCLAW_TMUX_SESSION:-openclaw}"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "OpenClaw status"
echo "---------------"

# Service
export SVDIR="${SVDIR:-$PREFIX/var/service}"
if command -v sv >/dev/null 2>&1 && [ -d "$SVDIR/openclaw" ]; then
  if sv status openclaw 2>/dev/null | grep -q "run:"; then
    echo -e "Mode:    ${GREEN}service (runit)${NC}"
    sv status openclaw
    echo "UI:     http://localhost:18789"
    exit 0
  fi
fi

# Tmux
if command -v tmux >/dev/null 2>&1 && tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  echo -e "Mode:    ${GREEN}tmux (session: $TMUX_SESSION)${NC}"
  echo "Attach: tmux attach -t $TMUX_SESSION"
  echo "UI:     http://localhost:18789"
  exit 0
fi

echo -e "${YELLOW}OpenClaw is not running. Start with: ./scripts/start_claw.sh${NC}"
exit 1
