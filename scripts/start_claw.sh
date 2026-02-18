#!/data/data/com.termux/files/usr/bin/bash

# Start OpenClaw gateway. Default: tmux session. Optional: --mode service (runit).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMUX_SESSION="${OPENCLAW_TMUX_SESSION:-openclaw}"
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Ensure env for service or child processes
[ -n "${PREFIX:-}" ] || export PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
[ -n "${TMPDIR:-}" ] && export TMPDIR="$PREFIX/tmp" || export TMPDIR="$PREFIX/tmp"
export PATH="$PREFIX/bin:$PATH"

MODE="tmux"
while [ $# -gt 0 ]; do
  case "$1" in
    --mode)
      MODE="${2:-tmux}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [ "$MODE" = "service" ]; then
  export SVDIR="${SVDIR:-$PREFIX/var/service}"
  if command -v sv >/dev/null 2>&1; then
    sv up openclaw
    echo -e "${GREEN}OpenClaw started (service). Run termux-wake-lock; UI: http://localhost:18789${NC}"
  else
    echo -e "${RED}sv not found. Install termux-services or use: ./scripts/start_claw.sh (tmux)${NC}"
    exit 1
  fi
  exit 0
fi

# Tmux default
if ! command -v tmux >/dev/null 2>&1; then
  echo -e "${RED}tmux not found. Install with: pkg install -y tmux${NC}"
  exit 1
fi

if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  echo -e "${YELLOW}Session $TMUX_SESSION already exists. Attach with: tmux attach -t $TMUX_SESSION${NC}"
  exit 0
fi

tmux new-session -d -s "$TMUX_SESSION" "export TMPDIR=\"$PREFIX/tmp\" TMP=\"$PREFIX/tmp\" TEMP=\"$PREFIX/tmp\" PATH=\"$PREFIX/bin:\$PATH\"; openclaw gateway"
echo -e "${GREEN}OpenClaw started in tmux session '$TMUX_SESSION'. Run termux-wake-lock; UI: http://localhost:18789${NC}"
echo -e "Attach: tmux attach -t $TMUX_SESSION"
